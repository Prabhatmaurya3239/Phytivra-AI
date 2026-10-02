"""
API Endpoint Integration Tests for Agentic AI:
Tests:
- POST /api/ai/follow-up/
- POST /api/ai/recommendation/
"""

from rest_framework.test import APITestCase
from rest_framework import status


class AgenticAIAPITests(APITestCase):
    def test_recommendation_high_confidence(self):
        url = "/api/ai/recommendation/"
        payload = {
            "prediction_id": "pred_api_001",
            "language": "en",
            "ml_result": {
                "crop": {"id": 1, "name": "Tomato"},
                "disease": {"id": 1, "name": "Early Blight"},
                "confidence": 0.88
            },
            "user_context": {"note": "Visible spots on lower leaves"}
        }

        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertEqual(data["status"], "completed")
        self.assertEqual(data["diagnosis"]["crop"]["name"], "Tomato")
        self.assertGreater(len(data["recommendation"]["pesticides"]), 0)

    def test_recommendation_low_confidence_flow(self):
        url = "/api/ai/recommendation/"
        # Initial uncertain request
        payload = {
            "prediction_id": "pred_api_002",
            "language": "en",
            "ml_result": {
                "crop": {"id": 1, "name": "Tomato"},
                "disease": {"id": 1, "name": "Early Blight"},
                "confidence": 0.45
            },
            "user_context": {}
        }

        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertEqual(data["status"], "needs_questions")
        self.assertIn("questions", data)
        self.assertGreater(len(data["questions"]), 0)

        # Submit answers back to recommendation endpoint
        answers_payload = {
            "prediction_id": "pred_api_002",
            "language": "en",
            "ml_result": {
                "crop": {"id": 1, "name": "Tomato"},
                "disease": {"id": 1, "name": "Early Blight"},
                "confidence": 0.45
            },
            "answers": [
                {"question_id": "q1", "answer": "Tomato"},
                {"question_id": "q3", "answer": "3 days"}
            ]
        }
        res2 = self.client.post(url, answers_payload, format="json")
        self.assertEqual(res2.status_code, status.HTTP_200_OK)
        d2 = res2.json()
        self.assertTrue(d2["success"])
        self.assertEqual(d2["status"], "completed")

    def test_explicit_follow_up_endpoint(self):
        url = "/api/ai/follow-up/"
        payload = {
            "prediction_id": "pred_follow_001",
            "crop": "Tomato",
            "disease": "Early Blight",
            "language": "en"
        }
        response = self.client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertEqual(data["status"], "needs_questions")
        self.assertIn("questions", data)
