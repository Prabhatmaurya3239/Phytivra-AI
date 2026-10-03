import io
import os
from unittest.mock import patch
from PIL import Image

from django.test import TestCase, override_settings
from django.conf import settings
from django.urls import reverse
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework.test import APIClient
from rest_framework import status

from apps.crops.models import Crop
from apps.disease.models import Disease
from apps.pesticides.models import Pesticide
from apps.prediction.models import LeafImage, Prediction, PredictionStatus
from apps.prediction.services import (
    PredictionService,
    MLService,
    DummyMLService,
    map_crop_and_disease,
)
from apps.prediction.services.ml_service import (
    validate_ml_response,
    MLValidationException,
    MLUnavailableException,
    MLTimeoutException,
)


def create_dummy_image(name="test_leaf.jpg", fmt="JPEG", size=(100, 100)):
    """Helper to generate an in-memory dummy image file."""
    file_obj = io.BytesIO()
    image = Image.new("RGB", size, color=(0, 128, 0))
    image.save(file_obj, format=fmt)
    file_obj.seek(0)
    return SimpleUploadedFile(
        name=name,
        content=file_obj.read(),
        content_type=f"image/{fmt.lower() if fmt != 'JPEG' else 'jpeg'}"
    )


class PredictionIntegrationTests(TestCase):
    """
    Test suite for Task 4 — Backend & ML End-to-End Integration.
    Covers:
      - Test 1: High Confidence (status = completed)
      - Test 2: Low Confidence (status = needs_questions)
      - Test 3: Unknown Disease (status = needs_questions)
      - Test 4: ML Failure (status = failed)
      - Record creation before ML call
      - Numeric confidence validation
      - Crop & disease database mapping
      - Unified Flutter contract compliance
      - Dummy ML contract consistency
    """

    def setUp(self):
        self.client = APIClient()

        # Seed test database with Crop, Disease, and Pesticide
        self.crop = Crop.objects.create(
            name="Tomato",
            scientific_name="Solanum lycopersicum",
            description="Important vegetable crop"
        )
        self.pesticide = Pesticide.objects.create(
            name="Amistar",
            company_name="Syngenta India Ltd.",
            description="Broad-spectrum fungicide",
            price_range="INR 500-700",
            packing_size="200ml",
            dosage="1 ml/L",
            spray_method="Foliar spray",
            precautions="Wear protective gear"
        )
        self.disease = Disease.objects.create(
            crop=self.crop,
            name="Early Blight",
            severity="Medium",
            symptoms="Dark brown spots with concentric rings",
            causes="Alternaria solani fungus",
            description="Common fungal disease of tomato"
        )
        self.disease.recommended_pesticides.add(self.pesticide)

        # Upload a test leaf image
        self.test_image_file = create_dummy_image()
        self.leaf_image = LeafImage.objects.create(image=self.test_image_file)

    def tearDown(self):
        leaf_dir = settings.MEDIA_ROOT / "leaf_images"
        if os.path.exists(leaf_dir):
            for fname in os.listdir(leaf_dir):
                if fname.startswith("test_leaf") or fname.startswith("direct_leaf"):
                    try:
                        os.remove(os.path.join(leaf_dir, fname))
                    except Exception:
                        pass

    @classmethod
    def tearDownClass(cls):
        super().tearDownClass()
        import gc
        gc.collect()
        leaf_dir = str(settings.MEDIA_ROOT / "leaf_images")
        if os.path.exists(leaf_dir):
            for fname in os.listdir(leaf_dir):
                if fname.startswith("test_leaf") or fname.startswith("direct_leaf"):
                    try:
                        os.remove(os.path.join(leaf_dir, fname))
                    except Exception:
                        pass

    # -----------------------------------------------------------------------
    # TEST 1 — HIGH CONFIDENCE (confidence = 0.92) -> status = completed
    # -----------------------------------------------------------------------
    def test_high_confidence_prediction(self):
        """
        TEST 1: Input confidence = 0.92 (>= threshold 0.70)
        Expected: status = completed with full result details.
        """
        response = self.client.post(
            reverse("disease-prediction"),
            {"image_id": self.leaf_image.id},
            format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()

        self.assertTrue(data["success"])
        self.assertEqual(data["status"], PredictionStatus.COMPLETED)
        self.assertTrue(data["prediction_id"].startswith("pred_"))

        # Verify unified result structure
        self.assertIn("result", data)
        result = data["result"]

        self.assertEqual(result["crop"]["name"], "Tomato")
        self.assertEqual(result["disease"]["name"], "Early Blight")
        self.assertEqual(result["confidence"]["score"], 0.92)
        self.assertEqual(result["confidence"]["percentage"], 92)

        # Verify recommendations & pesticides populated from DB
        self.assertTrue(result["recommendation"]["available"])
        self.assertEqual(len(result["pesticides"]), 1)
        self.assertEqual(result["pesticides"][0]["name"], "Amistar")
        self.assertTrue(len(result["precautions"]) > 0)

        # Verify database record updated
        pred_record = Prediction.get_by_prediction_id(data["prediction_id"])
        self.assertIsNotNone(pred_record)
        self.assertEqual(pred_record.status, PredictionStatus.COMPLETED)
        self.assertEqual(pred_record.confidence, 0.92)

    # -----------------------------------------------------------------------
    # TEST 2 — LOW CONFIDENCE (confidence = 0.48) -> status = needs_questions
    # -----------------------------------------------------------------------
    def test_low_confidence_prediction(self):
        """
        TEST 2: Input confidence = 0.48 (< threshold 0.70)
        Expected: status = needs_questions with Agentic AI questions.
        """
        with patch.object(
            MLService, "predict",
            return_value={
                "success": True,
                "prediction_id": "pred_000002",
                "prediction": {
                    "crop": {"id": 1, "name": "Tomato"},
                    "disease": {"id": 1, "name": "Early Blight"},
                    "confidence": 0.48,
                },
                "model": {"name": "Phytivra-ML", "version": "1.0.0"}
            }
        ):
            response = self.client.post(
                reverse("disease-prediction"),
                {"image_id": self.leaf_image.id},
                format="json"
            )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()

        self.assertTrue(data["success"])
        self.assertEqual(data["status"], PredictionStatus.NEEDS_QUESTIONS)
        self.assertIn("ml_result", data)
        self.assertEqual(data["ml_result"]["confidence"], 0.48)

        # Verify Agentic AI questions are attached
        self.assertIn("questions", data)
        self.assertTrue(len(data["questions"]) > 0)
        self.assertIn("id", data["questions"][0])
        self.assertIn("question", data["questions"][0])

        # Verify DB status
        pred_record = Prediction.get_by_prediction_id(data["prediction_id"])
        self.assertEqual(pred_record.status, PredictionStatus.NEEDS_QUESTIONS)
        self.assertEqual(pred_record.confidence, 0.48)

    # -----------------------------------------------------------------------
    # TEST 3 — UNKNOWN DISEASE (disease = null) -> status = needs_questions
    # -----------------------------------------------------------------------
    def test_unknown_disease_prediction(self):
        """
        TEST 3: Input disease = null / unknown (even if confidence is high)
        Expected: status = needs_questions
        """
        with patch.object(
            MLService, "predict",
            return_value={
                "success": True,
                "prediction_id": "pred_000003",
                "prediction": {
                    "crop": {"id": 1, "name": "Tomato"},
                    "disease": {"id": None, "name": None},
                    "confidence": 0.95,
                },
                "model": {"name": "Phytivra-ML", "version": "1.0.0"}
            }
        ):
            response = self.client.post(
                reverse("disease-prediction"),
                {"image_id": self.leaf_image.id},
                format="json"
            )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()

        self.assertTrue(data["success"])
        self.assertEqual(data["status"], PredictionStatus.NEEDS_QUESTIONS)
        self.assertIsNone(data["ml_result"]["disease"]["name"])
        self.assertIn("questions", data)

        # Verify DB status
        pred_record = Prediction.get_by_prediction_id(data["prediction_id"])
        self.assertEqual(pred_record.status, PredictionStatus.NEEDS_QUESTIONS)

    # -----------------------------------------------------------------------
    # TEST 4 — ML FAILURE -> status = failed
    # -----------------------------------------------------------------------
    def test_ml_failure(self):
        """
        TEST 4: ML service unavailable or error
        Expected: status = failed, error message stored, HTTP 502/error.
        """
        with patch.object(
            MLService, "predict",
            side_effect=MLUnavailableException("ML service unavailable.")
        ):
            response = self.client.post(
                reverse("disease-prediction"),
                {"image_id": self.leaf_image.id},
                format="json"
            )

        self.assertEqual(response.status_code, status.HTTP_502_BAD_GATEWAY)
        data = response.json()

        self.assertFalse(data["success"])
        self.assertEqual(data["status"], PredictionStatus.FAILED)
        self.assertIn("ML prediction service was unable to process", data["message"])

        # Verify that prediction record was still saved in DB with status=failed
        pred_record = Prediction.get_by_prediction_id(data["prediction_id"])
        self.assertIsNotNone(pred_record)
        self.assertEqual(pred_record.status, PredictionStatus.FAILED)
        self.assertIn("ML service unavailable", pred_record.error_message)

    # -----------------------------------------------------------------------
    # VERIFICATION: Prediction record is created before ML call
    # -----------------------------------------------------------------------
    def test_prediction_record_created_before_ml_call(self):
        """
        Verifies that Prediction record is created in database before calling ML service.
        """
        created_predictions_count = []

        def mock_ml_predict(*args, **kwargs):
            # Record how many predictions exist when ML is executing
            created_predictions_count.append(Prediction.objects.count())
            # Check status of the latest prediction
            latest = Prediction.objects.latest("created_at")
            self.assertEqual(latest.status, PredictionStatus.PROCESSING)
            return {
                "success": True,
                "prediction_id": kwargs.get("prediction_id", "pred_000001"),
                "prediction": {
                    "crop": {"id": 1, "name": "Tomato"},
                    "disease": {"id": 1, "name": "Early Blight"},
                    "confidence": 0.92,
                },
                "model": {"name": "Phytivra-ML", "version": "1.0.0"}
            }

        initial_count = Prediction.objects.count()
        with patch.object(MLService, "predict", side_effect=mock_ml_predict):
            response = self.client.post(
                reverse("disease-prediction"),
                {"image_id": self.leaf_image.id},
                format="json"
            )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(created_predictions_count), 1)
        self.assertEqual(created_predictions_count[0], initial_count + 1)

    # -----------------------------------------------------------------------
    # VERIFICATION: ML Response validation & numeric confidence
    # -----------------------------------------------------------------------
    def test_ml_response_validation_numeric_confidence(self):
        """
        Validates ML contract enforcement: confidence must be numeric and in [0, 1].
        """
        # Valid response
        valid_payload = {
            "success": True,
            "prediction_id": "pred_000001",
            "prediction": {
                "crop": {"id": 1, "name": "Tomato"},
                "disease": {"id": 1, "name": "Early Blight"},
                "confidence": 0.92
            },
            "model": {"name": "Phytivra-ML", "version": "1.0.0"}
        }
        res = validate_ml_response(valid_payload)
        self.assertIsInstance(res["prediction"]["confidence"], float)
        self.assertEqual(res["prediction"]["confidence"], 0.92)

        # Invalid confidence string
        invalid_confidence = {
            "success": True,
            "prediction": {"crop": {}, "disease": {}, "confidence": "invalid"}
        }
        with self.assertRaises(MLValidationException):
            validate_ml_response(invalid_confidence)

        # Out of bounds confidence
        out_of_bounds = {
            "success": True,
            "prediction": {"crop": {}, "disease": {}, "confidence": 1.5}
        }
        with self.assertRaises(MLValidationException):
            validate_ml_response(out_of_bounds)

    # -----------------------------------------------------------------------
    # VERIFICATION: Crop & Disease database mapping
    # -----------------------------------------------------------------------
    def test_crop_and_disease_db_mapping(self):
        """
        Verifies case-insensitive mapping against database records.
        """
        ml_crop = {"id": None, "name": "tomato"}
        ml_disease = {"id": None, "name": "early blight"}

        final_crop, final_disease, mapped_crop, mapped_disease = map_crop_and_disease(
            ml_crop, ml_disease
        )

        self.assertIsNotNone(mapped_crop)
        self.assertEqual(mapped_crop.id, self.crop.id)
        self.assertIsNotNone(mapped_disease)
        self.assertEqual(mapped_disease.id, self.disease.id)

    # -----------------------------------------------------------------------
    # VERIFICATION: Dummy ML and Real ML follow the same contract
    # -----------------------------------------------------------------------
    def test_dummy_ml_and_real_ml_contract(self):
        """
        Verifies Dummy ML service adheres strictly to Section 5 ML contract.
        """
        dummy_out = DummyMLService.predict(prediction_id="pred_demo_001")
        self.assertTrue(dummy_out["success"])
        self.assertEqual(dummy_out["prediction_id"], "pred_demo_001")
        self.assertIn("crop", dummy_out["prediction"])
        self.assertIn("disease", dummy_out["prediction"])
        self.assertIn("confidence", dummy_out["prediction"])
        self.assertIsInstance(dummy_out["prediction"]["confidence"], float)
        self.assertIn("model", dummy_out)
        self.assertIn("name", dummy_out["model"])
        self.assertIn("version", dummy_out["model"])

    # -----------------------------------------------------------------------
    # VERIFICATION: Direct image upload to predict endpoint
    # -----------------------------------------------------------------------
    def test_direct_image_prediction_upload(self):
        """
        Verifies that Flutter can post multipart image directly to /predict/
        without calling /upload/ first.
        """
        img_file = create_dummy_image("direct_leaf.jpg")
        response = self.client.post(
            reverse("disease-prediction"),
            {"image": img_file, "language": "en", "user_note": "Spots on lower leaves"},
            format="multipart"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertEqual(data["status"], PredictionStatus.COMPLETED)

    # -----------------------------------------------------------------------
    # VERIFICATION: Retrieval of prediction details by ID
    # -----------------------------------------------------------------------
    def test_prediction_detail_retrieval(self):
        """
        Verifies GET /api/prediction/predict/<prediction_id>/
        """
        pred = Prediction.objects.create(
            image=self.leaf_image,
            crop="Tomato",
            disease="Early Blight",
            confidence=0.92,
            status=PredictionStatus.COMPLETED
        )

        response = self.client.get(
            reverse("disease-prediction-detail", kwargs={"prediction_id": pred.prediction_id})
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertEqual(data["prediction_id"], pred.prediction_id)
        self.assertEqual(data["result"]["crop"]["name"], "Tomato")
        self.assertEqual(data["result"]["disease"]["name"], "Early Blight")

    # -----------------------------------------------------------------------
    # VERIFICATION: Missing image or invalid input
    # -----------------------------------------------------------------------
    def test_missing_image_validation(self):
        """
        Verifies that requesting prediction without image_id or image returns 400 Bad Request.
        """
        response = self.client.post(
            reverse("disease-prediction"),
            {},
            format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        data = response.json()
        self.assertFalse(data["success"])
        self.assertIn("image", data["errors"])

    def test_invalid_image_id(self):
        """
        Verifies that requesting prediction with non-existent image_id returns 400 Bad Request.
        """
        response = self.client.post(
            reverse("disease-prediction"),
            {"image_id": 999999},
            format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        data = response.json()
        self.assertFalse(data["success"])
        self.assertIn("image_id", data["errors"])
