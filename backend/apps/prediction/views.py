import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.db import DatabaseError

from .models import LeafImage, Prediction, PredictionStatus
from .serializers import (
    LeafImageSerializer,
    PredictionSerializer,
    PredictionRequestSerializer,
    MLPredictionInputSerializer,
)
from .services import PredictionService, process_prediction
from .services.prediction_service import format_pesticides_and_recommendations
from apps.disease.models import Disease
from apps.crops.models import Crop

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# 1. Image Upload View
# ---------------------------------------------------------------------------

class LeafImageUploadView(APIView):
    """
    Upload a leaf image for disease diagnosis.
    Endpoint: POST /api/prediction/upload/
    """

    def post(self, request):
        serializer = LeafImageSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(
                {
                    "success": False,
                    "message": "Image upload failed.",
                    "errors": serializer.errors,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            leaf_image = serializer.save()
            image_url = request.build_absolute_uri(leaf_image.image.url)

            return Response(
                {
                    "success": True,
                    "message": "Image uploaded successfully.",
                    "image_id": leaf_image.id,
                    "image_url": image_url,
                    "data": {
                        "image_id": leaf_image.id,
                        "image_url": image_url,
                    },
                },
                status=status.HTTP_201_CREATED,
            )

        except Exception as exc:
            logger.exception("Failed to save uploaded image: %s", exc)
            return Response(
                {
                    "success": False,
                    "message": "Unable to process the uploaded image.",
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


# ---------------------------------------------------------------------------
# 2. Disease Prediction View (Thin Controller)
# ---------------------------------------------------------------------------

class DiseasePredictionView(APIView):
    """
    Main entry point for crop disease prediction.
    Endpoints:
      POST /api/prediction/predict/
      GET  /api/prediction/predict/<prediction_id>/
      GET  /api/prediction/<prediction_id>/
    """

    def post(self, request):
        serializer = PredictionRequestSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(
                {
                    "success": False,
                    "message": "Invalid prediction request.",
                    "errors": serializer.errors,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        validated_data = serializer.validated_data
        leaf_image = validated_data.get("leaf_image")

        # If direct image file was provided instead of image_id, persist it first
        if not leaf_image and validated_data.get("image"):
            leaf_image = LeafImage.objects.create(
                image=validated_data["image"]
            )

        language = validated_data.get("language", "en")
        user_note = validated_data.get("user_note", "")

        # Call service layer to orchestrate the prediction flow
        response_data, http_status = PredictionService.execute_prediction(
            leaf_image=leaf_image,
            language=language,
            user_note=user_note,
            request=request,
        )

        return Response(response_data, status=http_status)

    def get(self, request, prediction_id=None):
        """
        Retrieves prediction results by prediction_id (e.g. pred_000001) or primary key ID.
        """
        lookup_id = prediction_id or request.query_params.get("prediction_id") or request.query_params.get("id")

        if not lookup_id:
            return Response(
                {
                    "success": False,
                    "message": "Prediction ID is required.",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        prediction = Prediction.get_by_prediction_id(lookup_id)
        if not prediction:
            return Response(
                {
                    "success": False,
                    "message": "Prediction not found.",
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        # Build response according to status
        if prediction.status == PredictionStatus.COMPLETED or prediction.status == "success":
            mapped_disease = None
            if prediction.disease:
                mapped_disease = Disease.objects.filter(name__iexact=prediction.disease).first()

            rec, pesticides, precautions = format_pesticides_and_recommendations(
                mapped_disease,
                request=request
            )

            crop_obj = Crop.objects.filter(name__iexact=prediction.crop).first() if prediction.crop else None

            return Response({
                "success": True,
                "prediction_id": prediction.prediction_id,
                "status": PredictionStatus.COMPLETED,
                "result": {
                    "crop": {
                        "id": crop_obj.id if crop_obj else None,
                        "name": prediction.crop,
                    },
                    "disease": {
                        "id": mapped_disease.id if mapped_disease else None,
                        "name": prediction.disease,
                    },
                    "confidence": {
                        "score": round(prediction.confidence, 4),
                        "percentage": int(round(prediction.confidence * 100)),
                    },
                    "recommendation": rec,
                    "pesticides": pesticides,
                    "precautions": precautions,
                }
            }, status=status.HTTP_200_OK)

        elif prediction.status == PredictionStatus.NEEDS_QUESTIONS:
            crop_obj = Crop.objects.filter(name__iexact=prediction.crop).first() if prediction.crop else None
            return Response({
                "success": True,
                "prediction_id": prediction.prediction_id,
                "status": PredictionStatus.NEEDS_QUESTIONS,
                "ml_result": {
                    "crop": {
                        "id": crop_obj.id if crop_obj else None,
                        "name": prediction.crop,
                    },
                    "disease": {
                        "id": None,
                        "name": prediction.disease,
                    },
                    "confidence": round(prediction.confidence, 4),
                },
                "questions": [
                    {
                        "id": "q1",
                        "type": "text",
                        "question": "What specific symptoms do you observe on the leaves or stems?",
                    },
                    {
                        "id": "q2",
                        "type": "single_choice",
                        "question": "Which part of the plant is predominantly affected?",
                        "options": ["Older leaves", "New leaves", "Fruit", "Stem", "Whole plant"],
                    }
                ]
            }, status=status.HTTP_200_OK)

        else:
            return Response({
                "success": False,
                "prediction_id": prediction.prediction_id,
                "status": prediction.status,
                "message": prediction.error_message or "Prediction processing failed.",
            }, status=status.HTTP_200_OK)


# ---------------------------------------------------------------------------
# 3. ML Prediction View (Legacy Task 3 Support)
# ---------------------------------------------------------------------------

class MLPredictionView(APIView):
    """
    Receives direct ML prediction payloads. Retained for backward compatibility.
    Endpoint: POST /api/prediction/ml-result/
    """

    def post(self, request):
        serializer = MLPredictionInputSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(
                {
                    "success": False,
                    "message": "Invalid ML prediction data",
                    "errors": serializer.errors,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        data = serializer.validated_data

        if data["status"] == "failed":
            return Response(
                {
                    "success": False,
                    "message": "Unable to predict disease from the uploaded image.",
                    "data": {
                        "crop": data.get("crop"),
                        "disease": None,
                        "confidence": data.get("confidence", 0),
                        "status": "failed",
                    },
                },
                status=status.HTTP_422_UNPROCESSABLE_ENTITY,
            )

        crop = data.get("crop")
        disease = data.get("disease")
        confidence = data["confidence"]
        prediction_status = data["status"]

        try:
            prediction = Prediction.objects.create(
                crop=crop,
                disease=disease,
                confidence=confidence,
                status=prediction_status,
            )
        except DatabaseError:
            return Response(
                {
                    "success": False,
                    "message": "Unable to save prediction.",
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        workflow = process_prediction(
            crop=crop,
            disease=disease,
            confidence=confidence,
            status=prediction_status,
        )

        return Response(
            {
                "success": True,
                "message": "Prediction processed successfully",
                "data": {
                    "prediction_id": prediction.prediction_id,
                    "crop": crop,
                    "disease": disease,
                    "confidence": confidence,
                    "status": prediction_status,
                    "workflow": workflow["workflow"],
                    "next_step": workflow["next_step"],
                    "threshold": workflow["threshold"],
                },
            },
            status=status.HTTP_201_CREATED,
        )