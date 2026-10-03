# Task 3 – Agentic AI Retrieval & Recommendation Workflow Report
**Assigned To:** Naman Uttam  
**Role:** Agentic AI Developer  
**Status:** Completed & Validated Locally  
**Date:** 2026-10-02  

---

## 1. Executive Summary

Task 3 establishes the initial **Agentic AI Retrieval and Recommendation Workflow** for the Phytivra-AI project. The module translates the approved pesticide knowledge base (`docs/pesticide knowledge base v1.xlsx`) into an autonomous reasoning pipeline that:
- Evaluates machine learning confidence thresholds (High Confidence $\ge 0.70$ vs. Low Confidence $< 0.70$).
- Autonomously generates farmer-friendly follow-up questions when uncertainty is detected.
- Processes farmer answers and reconciles contextual clues with plant diagnosis.
- Employs a dual-layer retrieval system:
  1. **Exact Structured Queries:** Uses normalized relational filtering for verified trade brands, chemical manufacturers, formulations, and regulatory approvals.
  2. **Unstructured RAG (Retrieval-Augmented Generation):** Retrieves agronomic notes, safety precautions, resistance management, and ICAR/CIBRC statutory advisory notes.
- Strictly adheres to **No-Hallucination & Safety Rules** (never invents trade names, active ingredients, dosages, or unverified claims).
- Supports bilingual output in **English** (`en`) and **Hindi** (`hi`).
- Produces fixed, standardized JSON structures ready for direct consumption by the Django backend and Flutter mobile application without parsing Markdown blocks.

---

## 2. Architecture Diagram

### Decision & Retrieval Flow

```
                      +-----------------------------+
                      |   ML Prediction / Input     |
                      |   (Crop, Disease, Conf)     |
                      +--------------+--------------+
                                     |
                                     v
                       +-------------+-------------+
                       |  Confidence Gating Gate   |
                       |      (Threshold 0.70)     |
                       +------+---------------+----+
                              |               |
              Confidence < 0.70               Confidence >= 0.70
                              |               |
                              v               v
               +--------------+----+    +-----+--------------------+
               | Follow-up Question|    | Identify Crop & Disease  |
               | Generation (q1-q3)|    +-------------+------------+
               +--------------+----+                  |
                              |                       |
                              v                       |
               +--------------+----+                  |
               | Receive Answers   |                  |
               | from Farmer       |                  |
               +--------------+----+                  |
                              |                       |
                              +-----------+-----------+
                                          |
                                          v
                   +----------------------+----------------------+
                   |      Dual-Layer Knowledge Retrieval         |
                   |                                             |
                   |  1. Structured DB: Exact Matches & Verified |
                   |  2. Unstructured RAG: Advisories & Notes    |
                   +----------------------+----------------------+
                                          |
                                          v
                   +----------------------+----------------------+
                   |          Verification Gate                  |
                   |   (Filters out unverified products)         |
                   +----------------------+----------------------+
                                          |
                        +-----------------+-----------------+
                        |                                   |
                  No Data Found                     Verified Data Present
                        |                                   |
                        v                                   v
             +----------+----------+             +----------+----------+
             | Fallback Response   |             | Prompt Synthesis    |
             | (verified_info:     |             | & Localization      |
             |      false)         |             | (English / Hindi)   |
             +----------+----------+             +----------+----------+
                        |                                   |
                        +-----------------+-----------------+
                                          |
                                          v
                               +----------+----------+
                               | Fixed Output Schema |
                               |   (Django / Flutter)|
                               +---------------------+
```

---

## 3. Modular Code Structure

The implementation follows the recommended modular architecture specified in **Section 21**:

```text
backend/apps/agenticAI/
│
├── data/
│   ├── kb_loader.py          # Standalone parser for 'pesticide knowledge base v1.xlsx'
│   └── kb_cache.json         # High-performance structured knowledge base cache
│
├── services/
│   ├── __init__.py
│   ├── agent_service.py       # Central orchestrator: confidence check & flow state machine
│   ├── retrieval_service.py   # Exact structured database retrieval with verification filters
│   ├── rag_service.py         # Unstructured context retrieval for agronomic guidelines
│   └── question_service.py    # Follow-up question generator for uncertain ML predictions
│
├── prompts/
│   ├── __init__.py
│   └── recommendation_prompt.py # System prompts & bilingual localization dictionary (en/hi)
│
├── schemas/
│   ├── __init__.py
│   └── response_schema.py     # Pydantic & dataclass schemas ensuring fixed API contract
│
├── tests/
│   ├── __init__.py
│   ├── test_agentic_flow.py   # Tests covering the 5 mandatory scenarios (Section 17)
│   └── test_api_endpoints.py  # Django REST API view integration tests
│
├── serializers.py             # DRF serializers
├── views.py                   # REST endpoints (/api/ai/follow-up/ & /api/ai/recommendation/)
├── urls.py                    # URL configuration
└── tests.py                   # Django test entry point
```

---

## 4. Test Scenarios & Verified Payloads

All 5 required test cases from **Section 17** have been implemented and verified via automated test suites (`Ran 8 tests in 0.265s, OK`).

### Case 1 — High Confidence (Confidence = 0.92)
**Input Payload:**
```json
{
  "prediction_id": "pred_demo_high_001",
  "language": "en",
  "ml_result": {
    "crop": { "id": 1, "name": "Tomato" },
    "disease": { "id": 1, "name": "Early Blight" },
    "confidence": 0.92
  },
  "user_context": {
    "note": "Dark brown concentric rings observed on lower tomato leaves."
  }
}
```

**Output Response:**
```json
{
  "success": true,
  "status": "completed",
  "diagnosis": {
    "crop": { "id": 1, "name": "Tomato" },
    "disease": { "id": 1, "name": "Early Blight" },
    "confidence": 0.92
  },
  "recommendation": {
    "summary": "Relevant management information was found.",
    "pesticides": [
      {
        "id": "P006",
        "name": "Saaf / Sixer / Companion",
        "company": "UPL Ltd. / Dhanuka Agritech",
        "purpose": "Early blight (Alternaria solani), Septoria leaf spot",
        "source_id": "S006"
      }
    ]
  },
  "precautions": [
    "PHI: 3-5 days. Use personal protective equipment (gloves, mask)"
  ],
  "sources": [
    {
      "source_id": "S006",
      "source_type": "official"
    }
  ]
}
```

---

### Case 2 — Low Confidence Flow (Confidence = 0.48)

#### Step 2A: Initial Request & Question Generation
**Input Payload:**
```json
{
  "prediction_id": "pred_demo_low_002",
  "language": "en",
  "ml_result": {
    "crop": { "id": 1, "name": "Tomato" },
    "disease": { "id": 1, "name": "Early Blight" },
    "confidence": 0.48
  },
  "user_context": {
    "note": "Yellow spots are visible on the leaves."
  }
}
```

**Output Response (`status: "needs_questions"`):**
```json
{
  "success": true,
  "status": "needs_questions",
  "prediction_id": "pred_demo_low_002",
  "questions": [
    {
      "id": "q3",
      "question": "How long have you noticed these symptoms?",
      "type": "text",
      "required": true
    },
    {
      "id": "q4",
      "question": "Are the spots or symptoms spreading to new leaves or neighboring plants?",
      "type": "text",
      "required": false
    },
    {
      "id": "q5",
      "question": "Have you already applied any pesticide, fungicide, or foliar fertilizer?",
      "type": "text",
      "required": false
    }
  ]
}
```

#### Step 2B: Receiving User Answers & Final Recommendation
**Input Payload with Farmer Answers:**
```json
{
  "prediction_id": "pred_demo_low_002",
  "language": "en",
  "ml_result": {
    "crop": { "id": 1, "name": "Tomato" },
    "disease": { "id": 1, "name": "Early Blight" },
    "confidence": 0.48
  },
  "answers": [
    { "question_id": "q1", "answer": "Tomato" },
    { "question_id": "q2", "answer": "Concentric rings and yellow halos visible" },
    { "question_id": "q3", "answer": "Around 5 days" }
  ]
}
```

**Output Response:**
```json
{
  "success": true,
  "status": "completed",
  "diagnosis": {
    "crop": { "id": 1, "name": "Tomato" },
    "disease": { "id": 1, "name": "Early Blight" },
    "confidence": 0.85
  },
  "recommendation": {
    "summary": "Relevant management information was found.",
    "pesticides": [
      {
        "id": "P006",
        "name": "Saaf / Sixer / Companion",
        "company": "UPL Ltd. / Dhanuka Agritech",
        "purpose": "Early blight (Alternaria solani), Septoria leaf spot",
        "source_id": "S006"
      }
    ]
  },
  "precautions": [
    "PHI: 3-5 days. Use personal protective equipment (gloves, mask)"
  ],
  "sources": [
    {
      "source_id": "S006",
      "source_type": "official"
    }
  ]
}
```

---

### Case 3 — No Relevant Knowledge (Safeguard)
**Input Payload:**
```json
{
  "prediction_id": "pred_demo_unknown_003",
  "language": "en",
  "ml_result": {
    "crop": { "id": 999, "name": "ExoticSpaceCrop" },
    "disease": { "id": 999, "name": "UnknownBlight" },
    "confidence": 0.95
  }
}
```

**Output Response:**
```json
{
  "success": false,
  "status": "unverified",
  "verified_information_available": false,
  "message": "Verified information is not available for this case."
}
```

---

### Case 4 — Unverified Product Safety
When searching for unverified chemical products or unmapped indications:
- The system filters out any item with `is_verified == False` or without official regulatory authority.
- It returns `{"verified_information_available": false}` rather than hallucinating or recommending unapproved chemicals.

---

### Case 5 — Hindi Request (`language: "hi"`)
**Input Payload:**
```json
{
  "prediction_id": "pred_demo_hindi_005",
  "language": "hi",
  "ml_result": {
    "crop": { "id": 1, "name": "Tomato" },
    "disease": { "id": 1, "name": "Early Blight" },
    "confidence": 0.91
  }
}
```

**Output Response:**
```json
{
  "success": true,
  "status": "completed",
  "diagnosis": {
    "crop": { "id": 1, "name": "Tomato" },
    "disease": { "id": 1, "name": "Early Blight" },
    "confidence": 0.91
  },
  "recommendation": {
    "summary": "प्रासंगिक फसल प्रबंधन एवं कीटनाशक जानकारी पाई गई।",
    "pesticides": [
      {
        "id": "P006",
        "name": "Saaf / Sixer / Companion",
        "company": "UPL Ltd. / Dhanuka Agritech",
        "purpose": "Early blight (Alternaria solani), Septoria leaf spot",
        "source_id": "S006"
      }
    ]
  },
  "precautions": [
    "PHI: 3-5 days. Use personal protective equipment (gloves, mask)"
  ],
  "sources": [
    {
      "source_id": "S006",
      "source_type": "official"
    }
  ]
}
```

---

## 5. API Endpoints

The module integrates directly into the project's URL structure under `/api/ai/`:

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/ai/recommendation/` | Primary Agentic AI flow (handles direct diagnosis & answer reconciliation) |
| `POST` | `/api/ai/follow-up/` | Explicit follow-up question generation endpoint |

---

## 6. Definition of Done & Checklist Status

- [x] Excel knowledge base parsed (`docs/pesticide knowledge base v1.xlsx`)
- [x] Structured retrieval layer implemented (Pesticides, Active Ingredients, Companies)
- [x] Unstructured RAG layer implemented (Agronomic notes, Regulatory guidelines)
- [x] Confidence gate operational ($\ge 0.70$ high vs. $< 0.70$ low)
- [x] Follow-up question generator implemented
- [x] User answers reconciliation workflow tested
- [x] Anti-hallucination rules enforced (missing info $\rightarrow$ unverified response)
- [x] Source awareness preserved (`source_id`, `source_type: "official"`)
- [x] English and Hindi multilingual support validated
- [x] Fixed API contract adhering to Flutter & Django specifications
- [x] Automated test suite running and passing 8/8 tests
