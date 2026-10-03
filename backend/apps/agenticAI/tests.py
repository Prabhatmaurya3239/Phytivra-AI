from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status

from apps.crops.models import Crop
from apps.disease.models import Disease
from apps.pesticides.models import Pesticide
from apps.prediction.models import Prediction, PredictionStatus


class AgenticAITests(TestCase):

    def setUp(self):
        self.client = APIClient()
        self.crop = Crop.objects.create(
            name="Tomato",
            scientific_name="Solanum lycopersicum",
            description="Tomato crop"
        )
        self.pesticide = Pesticide.objects.create(
            name="Score",
            company_name="Syngenta India Ltd.",
            description="Fungicide",
            price_range="INR 400",
            packing_size="100ml",
            dosage="1 ml/L",
            spray_method="Foliar",
            precautions="Use mask"
        )
        self.disease = Disease.objects.create(
            crop=self.crop,
            name="Early Blight",
            severity="Medium",
            symptoms="Concentric rings",
            causes="Fungus",
            description="Fungal blight"
        )
        self.disease.recommended_pesticides.add(self.pesticide)

        self.prediction = Prediction.objects.create(
            crop="Tomato",
            disease="Early Blight",
            confidence=0.48,
            status=PredictionStatus.NEEDS_QUESTIONS
        )

    def test_follow_up_questions_endpoint(self):
        response = self.client.post(
            reverse("ai-follow-up"),
            {"prediction_id": self.prediction.prediction_id},
            format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertEqual(data["status"], PredictionStatus.NEEDS_QUESTIONS)
        self.assertIn("questions", data)
        self.assertTrue(len(data["questions"]) > 0)

    def test_ai_recommendation_submission_endpoint(self):
        response = self.client.post(
            reverse("ai-recommendation"),
            {
                "prediction_id": self.prediction.prediction_id,
                "answers": {
                    "q1": "Brown concentric spots on lower leaves",
                    "q2": "Older leaves"
                }
            },
            format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertEqual(data["status"], PredictionStatus.COMPLETED)
        self.assertIn("result", data)
        self.assertEqual(data["result"]["crop"]["name"], "Tomato")
        self.assertEqual(data["result"]["disease"]["name"], "Early Blight")
        self.assertTrue(data["result"]["confidence"]["percentage"] >= 85)

    def test_invalid_prediction_id(self):
        response = self.client.post(
            reverse("ai-follow-up"),
            {"prediction_id": "pred_999999"},
            format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
