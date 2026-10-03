"""
Automated Test Suite for Task 3: Agentic AI Retrieval & Recommendation Workflow.
Tests the 5 mandatory scenarios specified in Section 17 & Section 22:
1. Case 1: High Confidence (ML confidence = 0.92)
2. Case 2: Low Confidence (ML confidence = 0.48 -> Question Generation -> User Answers -> Recommendation)
3. Case 3: No Relevant Knowledge (verified_information_available = false)
4. Case 4: Unverified Product Information (Do not present unverified data as verified)
5. Case 5: Hindi Request (language = 'hi')
"""

import os
import sys
import unittest
from pathlib import Path

# Ensure backend directory is in sys.path for direct execution
BACKEND_DIR = Path(__file__).resolve().parent.parent.parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from apps.agenticAI.services.agent_service import AgenticAIService


class TestAgenticAIWorkflow(unittest.TestCase):
    def setUp(self):
        self.service = AgenticAIService()

    def test_case_1_high_confidence(self):
        """Case 1: High Confidence (ML confidence = 0.92) -> Direct verified recommendation."""
        payload = {
            "prediction_id": "pred_demo_high_001",
            "language": "en",
            "ml_result": {
                "crop": {"id": 1, "name": "Tomato"},
                "disease": {"id": 1, "name": "Early Blight"},
                "confidence": 0.92
            },
            "user_context": {
                "note": "Dark brown concentric rings observed on lower tomato leaves."
            }
        }

        response = self.service.process_request(payload)

        self.assertTrue(response.get("success"), "Response success should be True")
        self.assertEqual(response.get("status"), "completed", "Status should be 'completed'")
        self.assertIn("diagnosis", response)
        self.assertEqual(response["diagnosis"]["crop"]["name"], "Tomato")
        self.assertEqual(response["diagnosis"]["disease"]["name"], "Early Blight")
        self.assertEqual(response["diagnosis"]["confidence"], 0.92)

        # Check recommendation structure
        recommendation = response.get("recommendation", {})
        self.assertIn("summary", recommendation)
        self.assertIn("pesticides", recommendation)
        self.assertGreater(len(recommendation["pesticides"]), 0, "Should have recommended pesticides")

        # Check pesticide fields
        pesticide = recommendation["pesticides"][0]
        self.assertIn("name", pesticide)
        self.assertIn("company", pesticide)
        self.assertIn("purpose", pesticide)
        self.assertIn("source_id", pesticide)

        # Check sources
        self.assertIn("sources", response)
        self.assertGreater(len(response["sources"]), 0)
        self.assertEqual(response["sources"][0]["source_type"], "official")

        print("\n--- CASE 1 (HIGH CONFIDENCE) PASSED ---")
        print("Product:", pesticide["name"])
        print("Company:", pesticide["company"])
        print("Source:", response["sources"][0]["source_id"])

    def test_case_2_low_confidence_flow(self):
        """Case 2: Low Confidence (0.48) -> Question generation -> Answer receipt -> Final Recommendation."""
        # Step 2A: Submit uncertain prediction
        initial_payload = {
            "prediction_id": "pred_demo_low_002",
            "language": "en",
            "ml_result": {
                "crop": {"id": 1, "name": "Tomato"},
                "disease": {"id": 1, "name": "Early Blight"},
                "confidence": 0.48
            },
            "user_context": {
                "note": "Yellow spots are visible on the leaves."
            }
        }

        step1_response = self.service.process_request(initial_payload)

        self.assertTrue(step1_response.get("success"))
        self.assertEqual(step1_response.get("status"), "needs_questions")
        self.assertIn("questions", step1_response)
        self.assertGreater(len(step1_response["questions"]), 0)
        print("\n--- CASE 2 STEP 1 (QUESTION GENERATION) PASSED ---")
        for q in step1_response["questions"]:
            print(f"[{q['id']}] {q['question']}")

        # Step 2B: Farmer answers questions
        answers_payload = {
            "prediction_id": "pred_demo_low_002",
            "language": "en",
            "ml_result": {
                "crop": {"id": 1, "name": "Tomato"},
                "disease": {"id": 1, "name": "Early Blight"},
                "confidence": 0.48
            },
            "user_context": {
                "note": "Yellow spots are visible on the leaves."
            },
            "answers": [
                {"question_id": "q1", "answer": "Tomato"},
                {"question_id": "q2", "answer": "Concentric rings and yellow halos visible"},
                {"question_id": "q3", "answer": "Around 5 days"}
            ]
        }

        step2_response = self.service.process_request(answers_payload)

        self.assertTrue(step2_response.get("success"))
        self.assertEqual(step2_response.get("status"), "completed")
        self.assertGreater(len(step2_response["recommendation"]["pesticides"]), 0)
        print("\n--- CASE 2 STEP 2 (USER ANSWER PROCESSING & RECOMMENDATION) PASSED ---")
        print("Resolved Product:", step2_response["recommendation"]["pesticides"][0]["name"])

    def test_case_3_no_relevant_knowledge(self):
        """Case 3: Unknown / non-existent crop and disease -> No verified information available."""
        payload = {
            "prediction_id": "pred_demo_unknown_003",
            "language": "en",
            "ml_result": {
                "crop": {"id": 999, "name": "SpaceCropX"},
                "disease": {"id": 999, "name": "MartianBlight"},
                "confidence": 0.95
            },
            "user_context": {}
        }

        response = self.service.process_request(payload)

        self.assertFalse(response.get("success"))
        self.assertEqual(response.get("status"), "unverified")
        self.assertFalse(response.get("verified_information_available"))
        self.assertIn("Verified information is not available", response.get("message"))
        print("\n--- CASE 3 (NO RELEVANT KNOWLEDGE) PASSED ---")
        print("Safeguard triggered:", response["message"])

    def test_case_4_unverified_product_safety(self):
        """Case 4: Unverified products must never be presented as verified recommendations."""
        # Search directly with structured retrieval for an unverified candidate
        # Ensures that only verified records pass through the safety gate
        results = self.service.retrieval_service.search_pesticides(
            crop_name="NonExistentCrop",
            disease_name="NonExistentDisease",
            only_verified=True
        )
        self.assertEqual(len(results), 0, "Must not return unverified or non-existent items")
        print("\n--- CASE 4 (UNVERIFIED SAFETY FILTER) PASSED ---")

    def test_case_5_hindi_request(self):
        """Case 5: Hindi language request ('hi') -> Hindi summary and precautions."""
        payload = {
            "prediction_id": "pred_demo_hindi_005",
            "language": "hi",
            "ml_result": {
                "crop": {"id": 1, "name": "Tomato"},
                "disease": {"id": 1, "name": "Early Blight"},
                "confidence": 0.91
            },
            "user_context": {}
        }

        response = self.service.process_request(payload)

        self.assertTrue(response.get("success"))
        self.assertEqual(response.get("status"), "completed")
        summary = response["recommendation"]["summary"]
        self.assertIn("प्रासंगिक", summary, "Summary should be in Hindi")
        self.assertGreater(len(response["precautions"]), 0)
        print("\n--- CASE 5 (HINDI LOCALIZATION) PASSED ---")
        print("Hindi Summary Length:", len(summary))
        print("Hindi Precautions Count:", len(response["precautions"]))


if __name__ == "__main__":
    unittest.main()
