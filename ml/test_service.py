"""
Unit & Integration Test Suite for Phytivra ML & Agentic AI FastAPI Service.
Verifies all required scenarios from Task 3 & Task 4.
"""

import sys
import os

# Add ml folder to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi.testclient import TestClient
from app import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    print("[PASS] [TEST 1] Health Check Passed")


def test_high_confidence_prediction():
    response = client.post(
        "/predict",
        data={"prediction_id": "pred_test_001", "mode": "high_confidence"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["prediction"]["confidence"] >= 0.70
    assert data["prediction"]["crop"]["name"] == "Tomato"
    assert data["prediction"]["disease"]["name"] == "Early Blight"
    print(f"[PASS] [TEST 2] High Confidence ML Prediction Passed (Confidence: {data['prediction']['confidence']})")


def test_low_confidence_prediction():
    response = client.post(
        "/predict",
        data={"prediction_id": "pred_test_002", "mode": "low_confidence"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    print(f"[PASS] [TEST 3] Low Confidence ML Prediction Passed (Confidence: {data['prediction']['confidence']})")


def test_unknown_disease_prediction():
    response = client.post(
        "/predict",
        data={"prediction_id": "pred_test_003", "mode": "unknown"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["prediction"]["disease"]["name"] is None
    print("[PASS] [TEST 4] Unknown Disease Prediction Passed")


def test_agentic_follow_up_questions():
    # English questions
    resp_en = client.post(
        "/agentic-ai/follow-up",
        json={"prediction_id": "pred_test_002", "language": "en"}
    )
    assert resp_en.status_code == 200
    data_en = resp_en.json()
    assert data_en["status"] == "needs_questions"
    assert len(data_en["questions"]) >= 3

    # Hindi questions
    resp_hi = client.post(
        "/agentic-ai/follow-up",
        json={"prediction_id": "pred_test_002", "language": "hi"}
    )
    assert resp_hi.status_code == 200
    data_hi = resp_hi.json()
    assert data_hi["status"] == "needs_questions"
    assert "लक्षण" in data_hi["questions"][0]["question"]
    print("[PASS] [TEST 5] Agentic AI Bilingual Question Generation Passed")


def test_agentic_recommendation():
    payload = {
        "prediction_id": "pred_test_002",
        "language": "en",
        "answers": [
            {"question_id": "q1", "answer": "Concentric rings and yellow leaf margin"},
            {"question_id": "q2", "answer": "Older leaves"}
        ]
    }
    response = client.post("/agentic-ai/recommendation", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "completed"
    assert len(data["pesticides"]) > 0
    assert len(data["sources"]) > 0
    assert data["diagnosis"]["disease"]["name"] == "Early Blight"
    print("[PASS] [TEST 6] Agentic AI Recommendation Resolution Passed")


def test_voice_chat_english():
    response = client.post(
        "/voice/chat",
        json={"query": "My tomato leaves have yellow spots and rings, what spray to use?", "language": "en"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["detected_crop"] == "Tomato"
    assert data["detected_disease"] == "Early Blight"
    assert len(data["spoken_text"]) > 0
    assert len(data["pesticides"]) > 0
    print("[PASS] [TEST 7] English Voice Chat & Diagnosis Passed")


def test_voice_chat_hindi():
    response = client.post(
        "/voice/chat",
        json={"query": "टमाटर की पत्तियों पर पीले धब्बे और झुलसा रोग दिख रहा है", "language": "hi"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["detected_crop"] == "Tomato"
    assert "अगेती झुलसा" in data["reply_text"]
    assert len(data["spoken_text"]) > 0
    print("[PASS] [TEST 8] Hindi Voice Chat & Audio Text Passed")


def test_voice_suggestions():
    resp_en = client.get("/voice/suggestions?language=en")
    assert resp_en.status_code == 200
    assert len(resp_en.json()["suggestions"]) > 0

    resp_hi = client.get("/voice/suggestions?language=hi")
    assert resp_hi.status_code == 200
    assert len(resp_hi.json()["suggestions"]) > 0
    print("[PASS] [TEST 9] Voice Search Suggestions Passed")


def test_voice_transcription():
    response = client.post(
        "/voice/transcribe",
        data={"language": "hi", "simulated_speech": "टमाटर में पीले धब्बे"}
    )
    assert response.status_code == 200
    assert response.json()["transcript"] == "टमाटर में पीले धब्बे"
    print("[PASS] [TEST 10] Voice Speech-to-Text Transcription Passed")


if __name__ == "__main__":
    print("=" * 60)
    print("RUNNING PHYTIVRA-AI ML & AGENTIC AI FASTAPI TEST SUITE")
    print("=" * 60)
    test_health()
    test_high_confidence_prediction()
    test_low_confidence_prediction()
    test_unknown_disease_prediction()
    test_agentic_follow_up_questions()
    test_agentic_recommendation()
    test_voice_chat_english()
    test_voice_chat_hindi()
    test_voice_suggestions()
    test_voice_transcription()
    print("=" * 60)
    print("ALL 10 ML & AGENTIC AI SERVICE TESTS PASSED PERFECTLY!")
    print("=" * 60)
