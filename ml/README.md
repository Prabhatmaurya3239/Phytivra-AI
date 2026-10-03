# Phytivra-AI ML & Agentic AI FastAPI Service

Microservice providing Machine Learning prediction inference, Agentic AI reasoning fallbacks, and Voice Chatbot integration for crop disease diagnosis.

## Features
- **Contract Compliant**: Matches the exact JSON contract agreed upon between ML, Django Backend, and Flutter.
- **Configurable Confidence Gating**: Supports high-confidence (>= 0.70), low-confidence (< 0.70), and unknown disease predictions.
- **Agentic AI Diagnostics**: Follow-up question generation and symptom reconciliation in both **English and Hindi**.
- **Pesticide Knowledge Base**: CIBRC/ICAR verified recommendations for Early Blight and other crop conditions without hallucination.
- **Voice Chatbot & Voice Search**: Full voice assistant endpoints supporting speech-to-text, agricultural symptom parsing, and audio text generation.

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Service health status |
| `POST` | `/predict` | ML crop disease prediction from leaf image |
| `POST` | `/agentic-ai/follow-up` | Generates diagnostic follow-up questions for low-confidence cases |
| `POST` | `/agentic-ai/recommendation` | Reconciles user answers and returns verified pesticide recommendation |
| `POST` | `/voice/chat` | Agricultural chatbot processing voice/text queries in EN/HI |
| `POST` | `/voice/transcribe` | Transcribes audio speech to text |
| `GET` | `/voice/suggestions` | High-frequency voice search prompts for farmers |

---

## Running the Service

### Option 1: Using the provided Batch Script
Double-click `run_service.bat` or run:
```cmd
ml\run_service.bat
```

### Option 2: Using the Python Virtualenv directly
```cmd
.\venv\Scripts\uvicorn.exe ml.app:app --host 127.0.0.1 --port 8001 --reload
```
Interactive Swagger Documentation will be accessible at:
[http://127.0.0.1:8001/docs](http://127.0.0.1:8001/docs)

---

## Running Tests
To verify all 10 test scenarios across ML, Agentic AI, and Voice:
```cmd
.\venv\Scripts\python.exe ml\test_service.py
```
