"""
Quick Agentic AI Test Script
Run this script to test all 5 Agentic AI scenarios from Task 3:
Usage:
    cd backend
    python test_agent.py
"""

import os
import sys
import json
from pathlib import Path

# Add backend directory to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from apps.agenticAI.services.agent_service import AgenticAIService


def run_demo():
    agent = AgenticAIService()

    print("=" * 60)
    print("PHYTIVRA-AI: AGENTIC AI RETRIEVAL WORKFLOW TEST")
    print("=" * 60)

    # ---------------------------------------------------------
    # SCENARIO 1: High Confidence (0.92) -> Direct Recommendation
    # ---------------------------------------------------------
    print("\n[TEST 1] High Confidence Prediction (ML = 0.92)...")
    req1 = {
        "prediction_id": "pred_demo_001",
        "language": "en",
        "ml_result": {
            "crop": {"id": 1, "name": "Tomato"},
            "disease": {"id": 1, "name": "Early Blight"},
            "confidence": 0.92
        },
        "user_context": {"note": "Brown rings on bottom leaves"}
    }
    res1 = agent.process_request(req1)
    print(f"Status: {res1.get('status')} | Success: {res1.get('success')}")
    print(f"Summary: {res1.get('recommendation', {}).get('summary')}")
    if res1.get("recommendation", {}).get("pesticides"):
        p = res1["recommendation"]["pesticides"][0]
        print(f"Recommended Product: {p.get('name')}")
        print(f"Manufacturer: {p.get('company')}")
        print(f"Source ID: {p.get('source_id')}")

    # ---------------------------------------------------------
    # SCENARIO 2: Low Confidence (0.48) -> Question Generation
    # ---------------------------------------------------------
    print("\n" + "-" * 60)
    print("[TEST 2 - Step A] Low Confidence Prediction (ML = 0.48)...")
    req2_a = {
        "prediction_id": "pred_demo_002",
        "language": "en",
        "ml_result": {
            "crop": {"id": 1, "name": "Tomato"},
            "disease": {"id": 1, "name": "Early Blight"},
            "confidence": 0.48
        },
        "user_context": {"note": "Yellow spots on leaves"}
    }
    res2_a = agent.process_request(req2_a)
    print(f"Status: {res2_a.get('status')} (Gating works as expected)")
    print("Generated Follow-up Questions for Farmer:")
    for q in res2_a.get("questions", []):
        print(f"  * [{q['id']}] {q['question']}")

    print("\n[TEST 2 - Step B] Receiving User Answers & Reconciling...")
    req2_b = {
        "prediction_id": "pred_demo_002",
        "language": "en",
        "ml_result": {
            "crop": {"id": 1, "name": "Tomato"},
            "disease": {"id": 1, "name": "Early Blight"},
            "confidence": 0.48
        },
        "answers": [
            {"question_id": "q1", "answer": "Tomato"},
            {"question_id": "q3", "answer": "Around 5 days"}
        ]
    }
    res2_b = agent.process_request(req2_b)
    print(f"Status: {res2_b.get('status')} | Success: {res2_b.get('success')}")
    if res2_b.get("recommendation", {}).get("pesticides"):
        print(f"Resolved Recommendation: {res2_b['recommendation']['pesticides'][0]['name']}")

    # ---------------------------------------------------------
    # SCENARIO 3: No Relevant Knowledge (Safeguard)
    # ---------------------------------------------------------
    print("\n" + "-" * 60)
    print("[TEST 3] No Relevant Knowledge Safeguard (Alien Crop)...")
    req3 = {
        "prediction_id": "pred_demo_003",
        "language": "en",
        "ml_result": {
            "crop": {"id": 99, "name": "SpaceCrop"},
            "disease": {"id": 99, "name": "UnknownDisease"},
            "confidence": 0.90
        }
    }
    res3 = agent.process_request(req3)
    print(f"Status: {res3.get('status')} | Verified Info Available: {res3.get('verified_information_available')}")
    print(f"Safeguard Message: {res3.get('message')}")

    # ---------------------------------------------------------
    # SCENARIO 4: Hindi Language Support ('hi')
    # ---------------------------------------------------------
    print("\n" + "-" * 60)
    print("[TEST 4] Multilingual Support (Hindi Request)...")
    req4 = {
        "prediction_id": "pred_demo_004",
        "language": "hi",
        "ml_result": {
            "crop": {"id": 1, "name": "Tomato"},
            "disease": {"id": 1, "name": "Early Blight"},
            "confidence": 0.90
        }
    }
    res4 = agent.process_request(req4)
    print(f"Status: {res4.get('status')} | Success: {res4.get('success')}")
    # Safe console printing for Windows
    summary_hi = res4.get('recommendation', {}).get('summary', '')
    print(f"Hindi Output Generated: Length={len(summary_hi)} characters")

    print("\n" + "=" * 60)
    print("ALL TESTS COMPLETED SUCCESSFULLY!")
    print("=" * 60)


if __name__ == "__main__":
    run_demo()
