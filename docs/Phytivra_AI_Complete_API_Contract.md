# Phytivra-AI — Complete API Contract & Integration Documentation

> **Purpose:** This is the single source of truth for the Flutter, Django, ML, and Agentic AI team.
>
> Every member should build against the request/response structures defined here.
> Frontend dummy data, backend serializers, ML output, Agentic AI input/output, database seed data, and integration tests must follow this contract.
>
> **Important:** The original project documentation already defines Crop, Disease, Pesticide, Recommendation, and Image Upload APIs. This document keeps those structures and adds the end-to-end prediction/AI contract needed to keep all modules aligned.

---

# 1. Project Flow

```text
Flutter App
    |
    | 1. Upload leaf image
    v
Django Backend
    |
    | 2. Store image / create prediction request
    v
ML Model
    |
    | 3. Return crop + disease + confidence
    v
Django Backend
    |
    | 4A. High confidence
    |        -> retrieve disease/pesticide data
    |
    | 4B. Low confidence
    |        -> send context to Agentic AI
    v
Agentic AI + RAG / Knowledge Base
    |
    | 5. Questions / reasoning / recommendation
    v
Django Backend
    |
    | 6. One normalized JSON response
    v
Flutter App
```

## 1.1 Core Rule

There must be **one normalized JSON structure** between modules.

Do not create separate response formats such as:

```text
Frontend format A
Backend format B
ML format C
Agentic AI format D
```

Instead:

```text
ML -> MLResult schema
Agentic AI -> AgentResult schema
Backend -> PredictionResponse schema
Flutter -> consumes PredictionResponse
```

---

# 2. Base URL

Current local base URL:

```text
http://127.0.0.1:8000/api/
```

Examples:

```text
GET http://127.0.0.1:8000/api/crops/
GET http://127.0.0.1:8000/api/diseases/
POST http://127.0.0.1:8000/api/prediction/upload/
```

For deployment, replace the host only. Do not change endpoint paths without team agreement.

Example:

```text
https://api.example.com/api/
```

---

# 3. Common API Rules

## 3.1 Content Types

JSON APIs:

```http
Content-Type: application/json
```

Image upload:

```http
Content-Type: multipart/form-data
```

## 3.2 JSON Naming Convention

Use:

```text
snake_case
```

Correct:

```json
{
  "crop_id": 1,
  "disease_id": 2,
  "confidence_score": 0.92
}
```

Do not mix:

```text
cropId
cropID
crop-name
CropName
```

## 3.3 IDs

Use integer IDs for database resources:

```json
{
  "id": 1
}
```

For prediction/session/request tracking, use a unique string ID if required:

```json
{
  "prediction_id": "pred_000001"
}
```

## 3.4 Confidence

ML confidence must always be represented as a decimal between `0` and `1`.

```text
0.00 <= confidence <= 1.00
```

Example:

```json
{
  "confidence": 0.92
}
```

Frontend may display:

```text
92%
```

Do not send `"92%"` from ML.

## 3.5 Null Values

If information is not available:

```json
{
  "disease_id": null,
  "disease_name": null
}
```

Do not invent values.

---

# 4. Standard Error Format

All new APIs should preferably use:

```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Image is required.",
    "fields": {
      "image": [
        "This field is required."
      ]
    }
  }
}
```

Example:

```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Disease not found.",
    "fields": {}
  }
}
```

Common error codes:

| Code | Meaning |
|---|---|
| `INVALID_REQUEST` | Invalid input |
| `VALIDATION_ERROR` | Field validation failed |
| `NOT_FOUND` | Resource not found |
| `INVALID_IMAGE` | Unsupported image |
| `IMAGE_TOO_LARGE` | Image exceeds limit |
| `ML_ERROR` | ML prediction failed |
| `AI_ERROR` | Agentic AI failed |
| `LOW_CONFIDENCE` | Prediction below configured threshold |
| `NO_RECOMMENDATION` | No verified recommendation available |
| `SERVER_ERROR` | Internal error |

---

# 5. Existing Data APIs

These structures are based on the existing Phytivra-AI API documentation.

---

# 5.1 Crop APIs

## GET `/api/crops/`

Returns all crops.

### Response

```json
[
  {
    "id": 1,
    "name": "Tomato",
    "scientific_name": "Solanum lycopersicum",
    "description": "Tomato is an important vegetable crop.",
    "image": "http://127.0.0.1:8000/media/crop_images/tomato.jpg"
  }
]
```

### Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| `id` | integer | yes | Crop ID |
| `name` | string | yes | Common crop name |
| `scientific_name` | string | no | Scientific name |
| `description` | string | no | Crop description |
| `image` | string/null | no | Image URL |

---

## GET `/api/crops/<id>/`

Returns one crop.

Example:

```text
GET /api/crops/1/
```

### Response

```json
{
  "id": 1,
  "name": "Tomato",
  "scientific_name": "Solanum lycopersicum",
  "description": "Tomato is an important vegetable crop.",
  "image": "http://127.0.0.1:8000/media/crop_images/tomato.jpg"
}
```

---

# 5.2 Disease APIs

## GET `/api/diseases/`

### Response

```json
[
  {
    "id": 1,
    "name": "Early Blight",
    "crop": 1,
    "symptoms": "Small dark brown spots appear on older leaves.",
    "causes": "Commonly associated with Alternaria solani.",
    "description": "A common fungal disease of tomato.",
    "severity": "Medium",
    "image": "http://127.0.0.1:8000/media/disease_images/tomato_early_blight.jpg"
  }
]
```

### Fields

| Field | Type | Required |
|---|---|---:|
| `id` | integer | yes |
| `name` | string | yes |
| `crop` | integer | yes |
| `symptoms` | string | no |
| `causes` | string | no |
| `description` | string | no |
| `severity` | string | no |
| `image` | string/null | no |

Allowed severity values:

```text
Low
Medium
High
Critical
Unknown
```

---

## GET `/api/diseases/<id>/`

Example:

```text
GET /api/diseases/1/
```

Response follows the disease object above.

---

# 5.3 Pesticide APIs

## GET `/api/pesticides/`

### Response

```json
[
  {
    "id": 1,
    "name": "Amistar Top",
    "company_name": "Syngenta India Ltd.",
    "description": "Product description.",
    "price_range": "Verify current local price",
    "packing_size": "200 ml, 500 ml, 1 L",
    "dosage": "Use according to the current approved product label.",
    "spray_method": "Foliar spray according to approved recommendations.",
    "precautions": "Follow the approved product label.",
    "image": "http://127.0.0.1:8000/media/pesticide_images/amistar_top.jpg"
  }
]
```

### Important

Pesticide dosage, safety, application, price, and availability must not be invented.

Use verified/approved source information. If data is not verified, return an explicit value such as:

```text
Not Verified
```

or:

```text
Verify current local price
```

---

## GET `/api/pesticides/<id>/`

Example:

```text
GET /api/pesticides/1/
```

Returns the complete pesticide object.

---

# 5.4 Recommendation API

## GET `/api/recommendations/<disease_id>/`

Example:

```text
GET /api/recommendations/1/
```

### Response

```json
{
  "disease": {
    "id": 1,
    "name": "Early Blight"
  },
  "recommended_pesticides": [
    {
      "id": 1,
      "name": "Amistar",
      "company_name": "Syngenta India Ltd.",
      "description": "Product description.",
      "price_range": "Verify current local price",
      "packing_size": "Available according to current product information",
      "dosage": "Use according to the current approved product label.",
      "spray_method": "Foliar spray according to approved recommendations.",
      "precautions": "Follow all current label instructions.",
      "image": "http://127.0.0.1:8000/media/pesticide_images/amistar.jpg"
    }
  ]
}
```

If none are mapped:

```json
{
  "disease": {
    "id": 1,
    "name": "Early Blight"
  },
  "recommended_pesticides": []
}
```

---

# 5.5 Image Upload API

## POST `/api/prediction/upload/`

### Content Type

```text
multipart/form-data
```

### Request

Field:

```text
image = tomato_leaf.jpg
```

Supported:

```text
JPG
JPEG
PNG
WEBP
```

Maximum size:

```text
5 MB
```

### Current Response

```json
{
  "message": "Image uploaded successfully.",
  "image_id": 1,
  "image_url": "http://127.0.0.1:8000/media/leaf_images/tomato_leaf.jpg"
}
```

---

# 6. NEW — End-to-End Prediction Contract

The following APIs are the recommended integration contract for the complete ML + Agentic AI flow.

The team should agree on these structures before implementation.

---

# 6.1 Create Prediction

## POST `/api/predictions/`

Purpose:

Start a complete crop-health analysis.

### Content Type

```text
multipart/form-data
```

### Request Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| `image` | file | yes | Crop leaf image |
| `language` | string | yes | `en` or `hi` |
| `crop_id` | integer | no | Optional known crop |
| `location` | string | no | Optional user location |
| `user_note` | string | no | Optional symptom note |

### Example

```text
image = tomato_leaf.jpg
language = en
crop_id = 1
location = Uttar Pradesh
user_note = Yellow spots are visible on older leaves.
```

### Initial Response

```json
{
  "success": true,
  "prediction_id": "pred_000001",
  "status": "processing",
  "image": {
    "id": 1,
    "url": "http://127.0.0.1:8000/media/leaf_images/tomato_leaf.jpg"
  }
}
```

### Status Values

```text
processing
ml_completed
needs_questions
completed
failed
```

---

# 6.2 Get Prediction Result

## GET `/api/predictions/<prediction_id>/`

Example:

```text
GET /api/predictions/pred_000001/
```

### High-Confidence Example

```json
{
  "success": true,
  "prediction_id": "pred_000001",
  "status": "completed",

  "input": {
    "image_url": "http://127.0.0.1:8000/media/leaf_images/tomato_leaf.jpg",
    "language": "en"
  },

  "ml_result": {
    "crop": {
      "id": 1,
      "name": "Tomato"
    },
    "disease": {
      "id": 1,
      "name": "Early Blight"
    },
    "confidence": 0.92
  },

  "recommendation": {
    "available": true,
    "type": "disease_management",
    "message": "Management information is available for the detected condition."
  },

  "pesticides": [],

  "questions": [],

  "metadata": {
    "model_name": "Phytivra-ML",
    "model_version": "1.0.0"
  }
}
```

---

# 6.3 Low-Confidence Response

If ML confidence is below the agreed threshold:

```json
{
  "success": true,
  "prediction_id": "pred_000002",
  "status": "needs_questions",

  "ml_result": {
    "crop": {
      "id": 1,
      "name": "Tomato"
    },
    "disease": null,
    "confidence": 0.48
  },

  "questions": [
    {
      "id": "q1",
      "type": "text",
      "question": "What symptoms are you seeing on the plant?"
    },
    {
      "id": "q2",
      "type": "single_choice",
      "question": "Where are the symptoms mainly visible?",
      "options": [
        "Older leaves",
        "New leaves",
        "Fruit",
        "Stem",
        "Whole plant"
      ]
    }
  ],

  "recommendation": null
}
```

### Important

The exact confidence threshold must be configured by the ML/integration team.

Example only:

```text
confidence >= 0.70 -> high confidence
confidence < 0.70 -> low confidence / further analysis
```

Do not hard-code this example unless the team officially approves it.

---

# 7. ML Module Contract

ML must return a predictable object.

## 7.1 ML Input

Backend sends:

```json
{
  "image_url": "http://127.0.0.1:8000/media/leaf_images/tomato_leaf.jpg",
  "image_id": 1,
  "prediction_id": "pred_000001"
}
```

If the ML service receives a file instead, the transport can differ, but the output schema must remain the same.

---

## 7.2 ML Output — Success

```json
{
  "success": true,
  "prediction_id": "pred_000001",

  "prediction": {
    "crop": {
      "id": 1,
      "name": "Tomato"
    },
    "disease": {
      "id": 1,
      "name": "Early Blight"
    },
    "confidence": 0.92
  },

  "model": {
    "name": "Phytivra-ML",
    "version": "1.0.0"
  }
}
```

---

## 7.3 ML Output — Unknown / Low Confidence

```json
{
  "success": true,
  "prediction_id": "pred_000003",

  "prediction": {
    "crop": {
      "id": null,
      "name": null
    },
    "disease": {
      "id": null,
      "name": null
    },
    "confidence": 0.31
  },

  "model": {
    "name": "Phytivra-ML",
    "version": "1.0.0"
  }
}
```

ML must not force a disease name when the model cannot reliably identify one.

---

# 8. Agentic AI Contract

Agentic AI should not invent a separate data structure.

---

# 8.1 Agent Input

Backend sends:

```json
{
  "prediction_id": "pred_000002",

  "language": "en",

  "image": {
    "id": 2,
    "url": "http://127.0.0.1:8000/media/leaf_images/unknown.jpg"
  },

  "ml_result": {
    "crop": {
      "id": 1,
      "name": "Tomato"
    },
    "disease": {
      "id": null,
      "name": null
    },
    "confidence": 0.48
  },

  "user_context": {
    "location": "Uttar Pradesh",
    "user_note": "Leaves are turning yellow."
  },

  "conversation": []
}
```

---

# 8.2 Agent Question Response

```json
{
  "success": true,
  "status": "needs_questions",

  "questions": [
    {
      "id": "q1",
      "type": "text",
      "question": "What symptoms are you seeing?"
    },
    {
      "id": "q2",
      "type": "single_choice",
      "question": "Which part of the plant is affected?",
      "options": [
        "Leaves",
        "Stem",
        "Fruit",
        "Roots",
        "Whole plant"
      ]
    }
  ]
}
```

---

# 8.3 Submit Agent Answers

## POST `/api/predictions/<prediction_id>/answers/`

### Request

```json
{
  "answers": [
    {
      "question_id": "q1",
      "answer": "Yellow spots with brown edges."
    },
    {
      "question_id": "q2",
      "answer": "Leaves"
    }
  ]
}
```

### Response

```json
{
  "success": true,
  "status": "processing",
  "prediction_id": "pred_000002"
}
```

---

# 8.4 Agent Final Result

```json
{
  "success": true,
  "status": "completed",

  "diagnosis": {
    "crop": {
      "id": 1,
      "name": "Tomato"
    },
    "disease": {
      "id": 1,
      "name": "Early Blight"
    },

    "confidence": 0.86,
    "source": "ml_plus_agentic_analysis"
  },

  "recommendation": {
    "type": "disease_management",
    "summary": "Management information is available for the identified condition.",
    "actions": [
      "Remove severely affected plant material where appropriate.",
      "Follow verified crop-management guidance."
    ]
  },

  "pesticides": [],

  "precautions": [
    "Follow the current approved product label if a pesticide is used."
  ],

  "sources": [
    {
      "title": "Verified Knowledge Source",
      "url": "https://example.com/source",
      "source_type": "official"
    }
  ]
}
```

---

# 9. Chat / Follow-Up API

If the project includes a conversational Agentic AI interface:

## POST `/api/ai/chat/`

### Request

```json
{
  "prediction_id": "pred_000002",
  "message": "The lower leaves are getting brown spots.",
  "language": "en"
}
```

### Response

```json
{
  "success": true,
  "prediction_id": "pred_000002",

  "message": {
    "role": "assistant",
    "content": "Can you tell me whether the spots have a circular pattern?"
  },

  "next_action": "ask_question",

  "question": {
    "id": "q3",
    "type": "text",
    "question": "Do the spots have a circular pattern?"
  }
}
```

### Final Chat Response

```json
{
  "success": true,
  "prediction_id": "pred_000002",

  "message": {
    "role": "assistant",
    "content": "The available information is consistent with the identified condition."
  },

  "next_action": "show_result"
}
```

---

# 10. Normalized Final Result for Flutter

Flutter should primarily consume this structure rather than trying to understand internal ML/Agentic AI implementation.

```json
{
  "success": true,
  "prediction_id": "pred_000001",
  "status": "completed",

  "result": {
    "crop": {
      "id": 1,
      "name": "Tomato",
      "scientific_name": "Solanum lycopersicum"
    },

    "disease": {
      "id": 1,
      "name": "Early Blight",
      "severity": "Medium",
      "description": "Disease description.",
      "symptoms": "Observed symptoms.",
      "causes": "Known causes."
    },

    "confidence": {
      "score": 0.92,
      "percentage": 92
    },

    "recommendation": {
      "available": true,
      "type": "disease_management",
      "summary": "Management information is available.",
      "actions": [
        "Follow verified crop-management guidance."
      ]
    },

    "pesticides": [
      {
        "id": 1,
        "name": "Example Product",
        "company_name": "Example Company",
        "description": "Verified product description.",
        "price_range": "Not Verified",
        "packing_size": "Not Verified",
        "dosage": "Use according to current approved label.",
        "spray_method": "Follow approved label.",
        "precautions": "Follow approved label.",
        "image": null
      }
    ],

    "precautions": [
      "Use only verified product information.",
      "Follow the current approved product label."
    ]
  },

  "sources": [
    {
      "title": "Verified source",
      "url": "https://example.com/source",
      "source_type": "official"
    }
  ]
}
```

---

# 11. Frontend Dummy Data Rules

The Flutter developer can work without the backend being ready.

Create:

```text
mock/
├── crops.json
├── diseases.json
├── pesticides.json
├── prediction_high_confidence.json
├── prediction_low_confidence.json
├── agent_questions.json
├── agent_final_result.json
└── api_errors.json
```

## 11.1 High Confidence Dummy

```json
{
  "success": true,
  "prediction_id": "pred_demo_001",
  "status": "completed",
  "result": {
    "crop": {
      "id": 1,
      "name": "Tomato",
      "scientific_name": "Solanum lycopersicum"
    },
    "disease": {
      "id": 1,
      "name": "Early Blight",
      "severity": "Medium",
      "description": "Demo disease description.",
      "symptoms": "Demo symptoms.",
      "causes": "Demo causes."
    },
    "confidence": {
      "score": 0.92,
      "percentage": 92
    },
    "recommendation": {
      "available": true,
      "type": "disease_management",
      "summary": "Demo recommendation.",
      "actions": [
        "Demo action."
      ]
    },
    "pesticides": [],
    "precautions": []
  },
  "sources": []
}
```

## 11.2 Low Confidence Dummy

```json
{
  "success": true,
  "prediction_id": "pred_demo_002",
  "status": "needs_questions",
  "ml_result": {
    "crop": {
      "id": 1,
      "name": "Tomato"
    },
    "disease": {
      "id": null,
      "name": null
    },
    "confidence": 0.48
  },
  "questions": [
    {
      "id": "q1",
      "type": "text",
      "question": "What symptoms are you seeing?"
    },
    {
      "id": "q2",
      "type": "single_choice",
      "question": "Which part of the plant is affected?",
      "options": [
        "Leaves",
        "Stem",
        "Fruit",
        "Roots",
        "Whole plant"
      ]
    }
  ]
}
```

---

# 12. Database Data Contract

The database should support at least these relationships:

```text
Crop
  |
  | 1-to-many
  v
Disease
  |
  | many-to-many
  v
Pesticide
```

Additional entities:

```text
Prediction
PredictionAnswer
Recommendation
KnowledgeSource
```

Recommended logical structure:

```text
Crop
- id
- name
- scientific_name
- description
- image

Disease
- id
- crop_id
- name
- symptoms
- causes
- description
- severity
- image

Pesticide
- id
- name
- active_ingredients
- company_name
- description
- price_range
- packing_size
- dosage
- spray_method
- precautions
- image
- source_url
- source_type
- last_verified_at

Prediction
- id / prediction_id
- image_id
- crop_id
- disease_id
- confidence
- status
- language
- created_at

PredictionAnswer
- id
- prediction_id
- question_id
- answer

KnowledgeSource
- id
- title
- url
- source_type
- verified
- last_verified_at
```

---

# 13. Seed / Dummy Data

Backend developer should create seed data using the same fields.

## Crop

```json
{
  "id": 1,
  "name": "Tomato",
  "scientific_name": "Solanum lycopersicum",
  "description": "Demo crop.",
  "image": null
}
```

## Disease

```json
{
  "id": 1,
  "crop": 1,
  "name": "Early Blight",
  "symptoms": "Demo symptoms.",
  "causes": "Demo causes.",
  "description": "Demo disease.",
  "severity": "Medium",
  "image": null
}
```

## Pesticide

```json
{
  "id": 1,
  "name": "Demo Product",
  "company_name": "Demo Company",
  "description": "Demo record for development.",
  "price_range": "Not Verified",
  "packing_size": "Not Verified",
  "dosage": "Not Verified",
  "spray_method": "Not Verified",
  "precautions": "Verify current approved label.",
  "image": null
}
```

> Seed/demo records must be clearly treated as development data. Do not present invented pesticide data to a real farmer as verified information.

---

# 14. API Ownership

| Module | Owner | Must Implement |
|---|---|---|
| Crop APIs | Saloni | CRUD/read APIs + serializers |
| Disease APIs | Saloni | Disease APIs + relations |
| Pesticide APIs | Saloni | Pesticide APIs + source fields |
| Recommendation API | Saloni | Disease → pesticide mapping |
| Image Upload | Saloni | Upload + validation |
| ML Contract | Prabhat | ML input/output schema |
| ML Model | Prabhat | Prediction + confidence |
| Agentic AI Contract | Naman | Agent input/output |
| RAG/Knowledge Retrieval | Naman | Retrieval structure + sources |
| Flutter UI | Pratham | UI based on contract |
| Flutter API Client | Pratham | API service layer |
| Final Integration | Prabhat | End-to-end integration |

---

# 15. Git / Integration Rule

Branches:

```text
main
develop
feature/flutter
feature/backend
feature/ml
feature/agentic-ai
```

Flow:

```text
feature branch
      |
      v
Pull Request
      |
      v
develop
      |
      v
Integration Testing
      |
      v
main
```

Nobody should silently change an API response used by another member.

---

# 16. API Change Rule

If someone wants to change:

```text
field name
field type
endpoint
request format
response format
required/optional status
enum value
```

they must first update:

```text
API Contract
```

and inform all affected members.

Example:

Bad:

```text
Backend changes "confidence" to "confidence_score"
without informing ML and Flutter.
```

Correct:

```text
Team discusses change
        ↓
API Contract updated
        ↓
ML updated
        ↓
Backend updated
        ↓
Flutter updated
        ↓
Integration test
```

---

# 17. End-to-End Example

## Step 1 — Flutter uploads image

```http
POST /api/predictions/
Content-Type: multipart/form-data
```

```text
image = tomato_leaf.jpg
language = en
```

Backend:

```json
{
  "success": true,
  "prediction_id": "pred_000001",
  "status": "processing"
}
```

## Step 2 — ML processes image

ML receives:

```json
{
  "prediction_id": "pred_000001",
  "image_url": "..."
}
```

ML returns:

```json
{
  "success": true,
  "prediction": {
    "crop": {
      "id": 1,
      "name": "Tomato"
    },
    "disease": {
      "id": 1,
      "name": "Early Blight"
    },
    "confidence": 0.92
  }
}
```

## Step 3 — Backend checks confidence

```text
0.92
  |
  +--> high confidence
          |
          v
      knowledge retrieval
```

## Step 4 — Agentic AI is used when needed

```text
0.48
  |
  +--> low confidence
          |
          v
     Agentic AI
          |
          v
     Questions
          |
          v
     User answers
          |
          v
     Final analysis
```

## Step 5 — Flutter gets normalized result

Flutter does not need to know whether the final result came from:

```text
ML only
ML + RAG
ML + Agentic AI
```

It receives the same final response structure.

---

# 18. Testing Checklist

Every API should be tested for:

### Success

```text
200
201
```

### Invalid input

```text
400
```

### Not found

```text
404
```

### Server failure

```text
500
```

### Image

```text
valid JPG
valid PNG
valid WEBP
invalid extension
>5 MB
missing image
```

### ML

```text
high confidence
low confidence
unknown crop
unknown disease
model failure
```

### Agentic AI

```text
question generated
answer submitted
follow-up question
final result
AI failure
```

### Language

```text
en
hi
```

---

# 19. Flutter Developer Checklist

Pratham should build:

```text
ApiService
  |
  +-- getCrops()
  +-- getDiseases()
  +-- getDiseaseDetails()
  +-- getPesticides()
  +-- getPesticideDetails()
  +-- getRecommendations()
  +-- uploadPrediction()
  +-- getPrediction()
  +-- submitAnswers()
  +-- sendChatMessage()
```

Create Dart models corresponding to the JSON keys.

Do not create different field names just for Flutter.

---

# 20. Backend Developer Checklist

Saloni should provide:

```text
/api/crops/
/api/crops/<id>/

/api/diseases/
/api/diseases/<id>/

/api/pesticides/
/api/pesticides/<id>/

/api/recommendations/<disease_id>/

/api/prediction/upload/

/api/predictions/
/api/predictions/<prediction_id>/
/api/predictions/<prediction_id>/answers/

/api/ai/chat/
```

The final exact availability of the new end-to-end endpoints should be coordinated with the integration lead before implementation.

---

# 21. ML Developer Checklist

Prabhat should ensure:

```text
Input:
prediction_id
image

Output:
success
prediction_id
prediction.crop
prediction.disease
prediction.confidence
model.name
model.version
```

Rules:

```text
confidence = decimal 0..1
unknown = null
never invent disease
include model version
```

---

# 22. Agentic AI Developer Checklist

Naman should ensure:

```text
Input:
prediction_id
language
image context
ML result
user context
conversation
```

Output:

```text
status
questions
diagnosis
recommendation
pesticides
precautions
sources
```

The Agentic AI must use the same IDs and field names as the backend.

---

# 23. Source / RAG Contract

When knowledge retrieval is used, every retrieved factual recommendation should be traceable to a source where applicable.

Example:

```json
{
  "source_id": 12,
  "title": "Verified Source Name",
  "url": "https://example.com/source",
  "source_type": "official",
  "verified": true,
  "last_verified_at": "2026-08-10"
}
```

Suggested `source_type` values:

```text
official
government
research
manufacturer
database
other
```

Do not create fake URLs for dummy records.

For development:

```json
{
  "sources": []
}
```

is acceptable.

---

# 24. Final Single Source of Truth

Before any member starts implementing a module, they should check this document.

```text
                    API CONTRACT
                         |
        +----------------+----------------+
        |                |                |
      Flutter          Backend            ML
        |                |                |
        +----------------+----------------+
                         |
                    Agentic AI
                         |
                       RAG
```

### Golden Rule

**Same endpoint + same request + same response + same field names = successful integration.**

---

# 25. Current vs Planned API Status

| API | Status |
|---|---|
| GET `/api/crops/` | Existing documented API |
| GET `/api/crops/<id>/` | Existing documented API |
| GET `/api/diseases/` | Existing documented API |
| GET `/api/diseases/<id>/` | Existing documented API |
| GET `/api/pesticides/` | Existing documented API |
| GET `/api/pesticides/<id>/` | Existing documented API |
| GET `/api/recommendations/<disease_id>/` | Existing documented API |
| POST `/api/prediction/upload/` | Existing documented API |
| POST `/api/predictions/` | Proposed end-to-end contract |
| GET `/api/predictions/<prediction_id>/` | Proposed end-to-end contract |
| POST `/api/predictions/<prediction_id>/answers/` | Proposed end-to-end contract |
| POST `/api/ai/chat/` | Proposed conversational contract |

**Do not claim a proposed endpoint is implemented until the backend has actually implemented and tested it.**

---

# 26. Team Sign-Off

Before development continues, all four members should confirm:

```text
[ ] Flutter developer understands response JSON
[ ] Backend developer understands request/response JSON
[ ] ML developer agrees with MLResult schema
[ ] Agentic AI developer agrees with AgentResult schema
[ ] Database fields are mapped to API fields
[ ] Dummy data follows this document
[ ] Error format is understood
[ ] Confidence format is understood
[ ] Low-confidence flow is understood
[ ] High-confidence flow is understood
[ ] API changes require team discussion
```

**Once this contract is approved, this file becomes the integration reference for the project.**
