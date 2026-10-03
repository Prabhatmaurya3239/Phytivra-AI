import logging
from typing import Tuple, Optional, Dict, Any

from django.conf import settings
from apps.crops.models import Crop
from apps.disease.models import Disease
from apps.prediction.models import LeafImage, Prediction, PredictionStatus
from apps.prediction.config import get_confidence_threshold
from .ml_service import MLService, MLServiceException
from .agent_service import AgentService

logger = logging.getLogger(__name__)


def map_crop_and_disease(
    ml_crop_dict: Optional[Dict[str, Any]],
    ml_disease_dict: Optional[Dict[str, Any]]
) -> Tuple[Dict[str, Any], Dict[str, Any], Optional[Crop], Optional[Disease]]:
    """
    Maps crop and disease names/IDs from ML response with database records.
    Case-insensitive matching is used when direct ID matches are not present.
    """
    mapped_crop = None
    mapped_disease = None

    crop_id = ml_crop_dict.get("id") if ml_crop_dict else None
    crop_name = ml_crop_dict.get("name") if ml_crop_dict else None

    # 1. Map Crop
    if crop_id:
        mapped_crop = Crop.objects.filter(id=crop_id).first()
    if not mapped_crop and crop_name:
        mapped_crop = Crop.objects.filter(name__iexact=str(crop_name).strip()).first()

    # 2. Map Disease
    disease_id = ml_disease_dict.get("id") if ml_disease_dict else None
    disease_name = ml_disease_dict.get("name") if ml_disease_dict else None

    if disease_id:
        mapped_disease = Disease.objects.filter(id=disease_id).first()
    if not mapped_disease and disease_name:
        if mapped_crop:
            mapped_disease = Disease.objects.filter(
                name__iexact=str(disease_name).strip(),
                crop=mapped_crop
            ).first()
        if not mapped_disease:
            mapped_disease = Disease.objects.filter(
                name__iexact=str(disease_name).strip()
            ).first()

    # Construct final normalized dictionaries
    final_crop = {
        "id": mapped_crop.id if mapped_crop else crop_id,
        "name": mapped_crop.name if mapped_crop else crop_name,
    }
    final_disease = {
        "id": mapped_disease.id if mapped_disease else disease_id,
        "name": mapped_disease.name if mapped_disease else disease_name,
    }

    return final_crop, final_disease, mapped_crop, mapped_disease


def format_pesticides_and_recommendations(
    mapped_disease: Optional[Disease],
    request=None,
) -> Tuple[Dict[str, Any], list, list]:
    """
    Fetches associated pesticides, precautions, and recommendation details
    from existing Task 3 database relationships if mapped_disease exists.
    """
    if not mapped_disease:
        return (
            {"available": False, "summary": "No verified recommendation available."},
            [],
            [],
        )

    # 1. Recommendations summary
    recommendation = {
        "available": True,
        "summary": f"Management information is available for {mapped_disease.name}.",
    }

    # 2. Pesticides
    pesticides = []
    precautions = []

    for pesticide in mapped_disease.recommended_pesticides.all():
        img_url = None
        if pesticide.image:
            if request:
                img_url = request.build_absolute_uri(pesticide.image.url)
            else:
                img_url = pesticide.image.url

        pesticides.append({
            "id": pesticide.id,
            "name": pesticide.name,
            "company_name": pesticide.company_name,
            "description": pesticide.description,
            "price_range": pesticide.price_range,
            "packing_size": pesticide.packing_size,
            "dosage": pesticide.dosage,
            "spray_method": pesticide.spray_method,
            "precautions": pesticide.precautions,
            "image": img_url,
        })

        if pesticide.precautions and pesticide.precautions not in precautions:
            precautions.append(pesticide.precautions)

    if not precautions:
        precautions = [
            "Follow all local safety precautions.",
            "Always follow the current approved product label if a pesticide is used."
        ]

    return recommendation, pesticides, precautions


class PredictionService:
    """
    Orchestrates the complete end-to-end prediction pipeline:
    1. Receives image/request
    2. Creates tracking Prediction record with status=processing
    3. Calls ML service
    4. Validates ML response
    5. Maps Crop & Disease with Database records
    6. Compares confidence against configurable threshold
    7. High confidence -> status=completed
    8. Low confidence/unknown disease -> Agentic AI workflow -> status=needs_questions
    9. ML error -> status=failed
    10. Returns unified Flutter response
    """

    @classmethod
    def execute_prediction(
        cls,
        leaf_image: LeafImage,
        language: str = "en",
        user_note: str = "",
        request=None,
        forced_confidence: float = None,
        forced_crop: dict = None,
        forced_disease: dict = None,
        simulate_ml_failure: bool = False,
    ) -> Tuple[Dict[str, Any], int]:
        """
        Executes end-to-end prediction workflow for an uploaded leaf image.
        Returns (response_dict, http_status_code).
        """
        # STEP 1 & 2: Identify image & create prediction record with status=processing
        prediction = Prediction.objects.create(
            image=leaf_image,
            status=PredictionStatus.PROCESSING,
            language=language,
            user_note=user_note,
        )
        prediction_id = prediction.prediction_id

        # STEP 3: Call ML Service
        try:
            image_url = None
            if request and leaf_image and leaf_image.image:
                image_url = request.build_absolute_uri(leaf_image.image.url)

            ml_response = MLService.predict(
                image_path_or_file=leaf_image.image.file if leaf_image and leaf_image.image else None,
                prediction_id=prediction_id,
                image_url=image_url,
                forced_confidence=forced_confidence,
                forced_crop=forced_crop,
                forced_disease=forced_disease,
                simulate_failure=simulate_ml_failure,
            )

        except MLServiceException as exc:
            logger.error("ML service failed for %s: %s", prediction_id, exc)
            prediction.status = PredictionStatus.FAILED
            prediction.error_message = str(exc)
            prediction.save(update_fields=["status", "error_message"])

            return {
                "success": False,
                "prediction_id": prediction_id,
                "status": PredictionStatus.FAILED,
                "message": "ML prediction service was unable to process the image.",
                "errors": {
                    "ml": str(exc)
                }
            }, 502

        except Exception as exc:
            logger.exception("Unexpected error calling ML service for %s", prediction_id)
            prediction.status = PredictionStatus.FAILED
            prediction.error_message = str(exc)
            prediction.save(update_fields=["status", "error_message"])

            return {
                "success": False,
                "prediction_id": prediction_id,
                "status": PredictionStatus.FAILED,
                "message": "An unexpected error occurred during prediction processing.",
            }, 500

        # STEP 4: Extract and validate ML prediction data
        ml_prediction = ml_response["prediction"]
        confidence = float(ml_prediction["confidence"])
        model_meta = ml_response.get("model", {})

        # STEP 5: Map Crop and Disease with database
        final_crop, final_disease, mapped_crop, mapped_disease = map_crop_and_disease(
            ml_prediction.get("crop"),
            ml_prediction.get("disease")
        )

        prediction.crop = final_crop.get("name")
        prediction.disease = final_disease.get("name")
        prediction.confidence = confidence
        prediction.model_name = model_meta.get("name", "Phytivra-ML")
        prediction.model_version = model_meta.get("version", "1.0.0")

        # STEP 6: Apply configurable confidence threshold
        threshold = get_confidence_threshold()
        is_disease_known = bool(final_disease.get("name") and final_disease.get("id"))

        if confidence >= threshold and is_disease_known:
            # ----------------------------------------------------
            # HIGH CONFIDENCE FLOW -> status = completed
            # ----------------------------------------------------
            prediction.status = PredictionStatus.COMPLETED
            prediction.save()

            recommendation, pesticides, precautions = format_pesticides_and_recommendations(
                mapped_disease,
                request=request,
            )

            response_data = {
                "success": True,
                "prediction_id": prediction.prediction_id,
                "status": PredictionStatus.COMPLETED,
                "result": {
                    "crop": final_crop,
                    "disease": final_disease,
                    "confidence": {
                        "score": round(confidence, 4),
                        "percentage": int(round(confidence * 100)),
                    },
                    "recommendation": recommendation,
                    "pesticides": pesticides,
                    "precautions": precautions,
                },
            }
            return response_data, 200

        # --------------------------------------------------------
        # LOW CONFIDENCE OR UNKNOWN DISEASE FLOW -> status = needs_questions
        # --------------------------------------------------------
        prediction.status = PredictionStatus.NEEDS_QUESTIONS
        prediction.save()

        # Call Agentic AI service
        agent_result = AgentService.process(
            prediction_id=prediction.prediction_id,
            ml_result={
                "crop": final_crop,
                "disease": final_disease,
                "confidence": confidence,
            },
            language=language,
            user_context={"user_note": user_note} if user_note else {},
        )

        # If Agentic AI returned a completed diagnosis with confirmed result:
        if agent_result.get("status") == "completed":
            prediction.status = PredictionStatus.COMPLETED
            diag = agent_result.get("diagnosis", {})
            diag_crop = diag.get("crop", final_crop)
            diag_disease = diag.get("disease", final_disease)
            diag_conf = float(diag.get("confidence", confidence))

            prediction.crop = diag_crop.get("name", prediction.crop)
            prediction.disease = diag_disease.get("name", prediction.disease)
            prediction.confidence = diag_conf
            prediction.save()

            return {
                "success": True,
                "prediction_id": prediction.prediction_id,
                "status": PredictionStatus.COMPLETED,
                "result": {
                    "crop": diag_crop,
                    "disease": diag_disease,
                    "confidence": {
                        "score": round(diag_conf, 4),
                        "percentage": int(round(diag_conf * 100)),
                    },
                    "recommendation": agent_result.get(
                        "recommendation",
                        {"available": True, "summary": "Management information is available."}
                    ),
                    "pesticides": agent_result.get("pesticides", []),
                    "precautions": agent_result.get("precautions", []),
                },
            }, 200

        # Otherwise status remains needs_questions
        return {
            "success": True,
            "prediction_id": prediction.prediction_id,
            "status": PredictionStatus.NEEDS_QUESTIONS,
            "ml_result": {
                "crop": final_crop,
                "disease": final_disease,
                "confidence": round(confidence, 4),
            },
            "questions": agent_result.get("questions", AgentService.DEFAULT_QUESTIONS),
        }, 200


# Keep process_prediction function for backward compatibility with existing tests/views
def process_prediction(crop, disease, confidence, status):
    """
    Decide the next step based on ML confidence.
    Retained for backward compatibility.
    """
    threshold = get_confidence_threshold()

    if status == "failed":
        return {
            "status": "failed",
            "workflow": "follow_up",
            "crop": crop,
            "disease": disease,
            "confidence": confidence,
            "threshold": threshold,
            "next_step": "follow_up_questions"
        }

    if confidence >= threshold and disease:
        return {
            "status": "success",
            "workflow": "direct_recommendation",
            "crop": crop,
            "disease": disease,
            "confidence": confidence,
            "threshold": threshold,
            "next_step": "recommendation"
        }

    return {
        "status": "low_confidence",
        "workflow": "agentic_ai",
        "crop": crop,
        "disease": disease,
        "confidence": confidence,
        "threshold": threshold,
        "next_step": "follow_up_questions"
    }
