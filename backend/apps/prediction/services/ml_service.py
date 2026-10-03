import logging
import os
import requests
from django.conf import settings

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Exceptions
# ---------------------------------------------------------------------------

class MLServiceException(Exception):
    """Base exception for ML service errors."""
    pass


class MLTimeoutException(MLServiceException):
    """Raised when communication with ML service times out."""
    pass


class MLUnavailableException(MLServiceException):
    """Raised when ML service is unreachable or returns 5xx."""
    pass


class MLValidationException(MLServiceException):
    """Raised when ML service returns an invalid response payload."""
    pass


# ---------------------------------------------------------------------------
# Response Validation
# ---------------------------------------------------------------------------

def validate_ml_response(data: dict) -> dict:
    """
    Validates that the ML service response complies with the standard contract:
    {
        "success": true,
        "prediction_id": "pred_000001",
        "prediction": {
            "crop": {"id": 1, "name": "Tomato"},
            "disease": {"id": 1, "name": "Early Blight"},
            "confidence": 0.92
        },
        "model": {
            "name": "Phytivra-ML",
            "version": "1.0.0"
        }
    }
    """
    if not isinstance(data, dict):
        raise MLValidationException("ML response must be a JSON object.")

    if not data.get("success", False):
        raise MLServiceException(data.get("message", "ML prediction failed."))

    prediction = data.get("prediction")
    if not isinstance(prediction, dict):
        raise MLValidationException("ML response missing 'prediction' object.")

    # Validate confidence
    if "confidence" not in prediction:
        raise MLValidationException("ML prediction missing 'confidence' field.")

    confidence = prediction.get("confidence")
    if not isinstance(confidence, (int, float)):
        try:
            confidence = float(confidence)
        except (ValueError, TypeError):
            raise MLValidationException("Confidence score must be numeric.")

    if not (0.0 <= confidence <= 1.0):
        raise MLValidationException("Confidence score must be between 0.0 and 1.0.")

    # Validate crop
    crop = prediction.get("crop")
    if crop is not None and not isinstance(crop, dict):
        raise MLValidationException("Crop in prediction must be a dictionary or null.")

    # Validate disease
    disease = prediction.get("disease")
    if disease is not None and not isinstance(disease, dict):
        raise MLValidationException("Disease in prediction must be a dictionary or null.")

    # Validate model metadata
    model = data.get("model", {})
    if not isinstance(model, dict):
        model = {}

    model_name = model.get("name", "Phytivra-ML")
    model_version = model.get("version", "1.0.0")

    return {
        "success": True,
        "prediction_id": data.get("prediction_id", "pred_000001"),
        "prediction": {
            "crop": {
                "id": crop.get("id") if crop else None,
                "name": crop.get("name") if crop else None,
            } if crop else {"id": None, "name": None},
            "disease": {
                "id": disease.get("id") if disease else None,
                "name": disease.get("name") if disease else None,
            } if disease else {"id": None, "name": None},
            "confidence": float(confidence),
        },
        "model": {
            "name": str(model_name),
            "version": str(model_version),
        },
    }


# ---------------------------------------------------------------------------
# Dummy ML Service
# ---------------------------------------------------------------------------

class DummyMLService:
    """
    Dummy ML implementation for local development and automated testing.
    Shares the exact same contract as the production ML model service.
    """
    DEFAULT_MODEL_NAME = "Demo-ML"
    DEFAULT_MODEL_VERSION = "0.1.0"

    @classmethod
    def predict(
        cls,
        image_path_or_url: str = None,
        prediction_id: str = "pred_demo_001",
        forced_confidence: float = None,
        forced_crop: dict = None,
        forced_disease: dict = None,
        simulate_failure: bool = False,
    ) -> dict:
        if simulate_failure:
            raise MLUnavailableException("ML prediction service is currently unavailable.")

        confidence = 0.92 if forced_confidence is None else float(forced_confidence)
        crop = forced_crop if forced_crop is not None else {"id": 1, "name": "Tomato"}
        disease = forced_disease if forced_disease is not None else {"id": 1, "name": "Early Blight"}

        return {
            "success": True,
            "prediction_id": prediction_id,
            "prediction": {
                "crop": crop,
                "disease": disease,
                "confidence": confidence,
            },
            "model": {
                "name": cls.DEFAULT_MODEL_NAME,
                "version": cls.DEFAULT_MODEL_VERSION,
            },
        }


# ---------------------------------------------------------------------------
# ML Service Client
# ---------------------------------------------------------------------------

class MLService:
    """
    Client for interacting with the ML prediction pipeline.
    Dispatches to real ML HTTP endpoint or Dummy ML based on settings.
    """

    @classmethod
    def predict(
        cls,
        image_path_or_file=None,
        prediction_id: str = "pred_000001",
        image_url: str = None,
        forced_confidence: float = None,
        forced_crop: dict = None,
        forced_disease: dict = None,
        simulate_failure: bool = False,
    ) -> dict:
        use_dummy = getattr(settings, "USE_DUMMY_ML", True)
        ml_service_url = getattr(settings, "ML_SERVICE_URL", "").strip()

        # If dummy ML is enabled or no external ML URL is provided, use DummyMLService
        if use_dummy or not ml_service_url:
            raw = DummyMLService.predict(
                image_path_or_url=image_url or str(image_path_or_file),
                prediction_id=prediction_id,
                forced_confidence=forced_confidence,
                forced_crop=forced_crop,
                forced_disease=forced_disease,
                simulate_failure=simulate_failure,
            )
            return validate_ml_response(raw)

        # External HTTP communication
        timeout = getattr(settings, "ML_SERVICE_TIMEOUT", 10)
        files = None
        file_handle_to_close = None

        try:
            data = {"prediction_id": prediction_id}
            if image_url:
                data["image_url"] = image_url

            if hasattr(image_path_or_file, "read"):
                image_path_or_file.seek(0)
                file_name = getattr(image_path_or_file, "name", "leaf.jpg")
                files = {"image": (file_name, image_path_or_file.read())}
            elif isinstance(image_path_or_file, str) and os.path.exists(image_path_or_file):
                file_handle_to_close = open(image_path_or_file, "rb")
                files = {"image": file_handle_to_close}

            response = requests.post(
                ml_service_url,
                data=data,
                files=files,
                timeout=timeout
            )

            if response.status_code >= 500:
                raise MLUnavailableException(
                    f"ML service error: HTTP {response.status_code}"
                )
            if response.status_code != 200:
                raise MLServiceException(
                    f"ML service returned unexpected status: HTTP {response.status_code}"
                )

            return validate_ml_response(response.json())

        except requests.exceptions.Timeout as exc:
            logger.error("ML service timeout: %s", exc)
            raise MLTimeoutException("ML prediction service timed out.") from exc
        except requests.exceptions.ConnectionError as exc:
            logger.error("ML service connection error: %s", exc)
            raise MLUnavailableException("ML prediction service unavailable.") from exc
        except requests.exceptions.RequestException as exc:
            logger.error("ML service request error: %s", exc)
            raise MLServiceException(f"Communication error with ML service: {exc}") from exc
        except ValueError as exc:
            logger.error("ML service invalid json: %s", exc)
            raise MLValidationException(f"Invalid JSON returned by ML service: {exc}") from exc
        finally:
            if file_handle_to_close:
                try:
                    file_handle_to_close.close()
                except Exception:
                    pass
