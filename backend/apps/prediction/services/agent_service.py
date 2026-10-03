import logging
import requests
from django.conf import settings

logger = logging.getLogger(__name__)


class AgentServiceException(Exception):
    """Base exception for Agentic AI service."""
    pass


class AgentService:
    """
    Service client for Agentic AI workflow (used during low-confidence or unknown disease predictions).
    Communicates with external Agentic AI service if configured, or provides a standardized fallback.
    """

    DEFAULT_QUESTIONS = [
        {
            "id": "q1",
            "type": "text",
            "question": "What specific symptoms do you observe on the plant leaves or stems?",
        },
        {
            "id": "q2",
            "type": "single_choice",
            "question": "Which part of the plant is predominantly affected?",
            "options": [
                "Older leaves",
                "New leaves",
                "Fruit",
                "Stem",
                "Whole plant"
            ],
        },
        {
            "id": "q3",
            "type": "single_choice",
            "question": "When did you first notice the symptoms?",
            "options": [
                "Within the last 3 days",
                "Within the past week",
                "More than a week ago"
            ],
        },
    ]

    @classmethod
    def build_payload(
        cls,
        prediction_id: str,
        ml_result: dict,
        language: str = "en",
        user_context: dict = None,
    ) -> dict:
        """
        Builds the standardized input contract for Agentic AI:
        {
            "prediction_id": "pred_000002",
            "language": "en",
            "ml_result": {
                "crop": {"id": 1, "name": "Tomato"},
                "disease": {"id": null, "name": null},
                "confidence": 0.48
            },
            "user_context": {
                "user_note": "Yellow spots are visible on leaves."
            }
        }
        """
        return {
            "prediction_id": prediction_id,
            "language": language,
            "ml_result": ml_result,
            "user_context": user_context or {},
        }

    @classmethod
    def process(
        cls,
        prediction_id: str,
        ml_result: dict,
        language: str = "en",
        user_context: dict = None,
    ) -> dict:
        """
        Sends standardized input to Agentic AI and receives/normalizes response.
        If external service is unavailable or not configured, returns standardized questions.
        """
        agent_url = getattr(settings, "AGENT_SERVICE_URL", "").strip()
        timeout = getattr(settings, "AGENT_SERVICE_TIMEOUT", 15)
        payload = cls.build_payload(
            prediction_id=prediction_id,
            ml_result=ml_result,
            language=language,
            user_context=user_context,
        )

        if not agent_url:
            # Fallback/boundary: return questions according to contract
            return {
                "success": True,
                "status": "needs_questions",
                "prediction_id": prediction_id,
                "ml_result": ml_result,
                "questions": cls.DEFAULT_QUESTIONS,
            }

        try:
            resp = requests.post(agent_url, json=payload, timeout=timeout)
            if resp.status_code == 200:
                data = resp.json()
                return cls.normalize_agent_response(data, prediction_id, ml_result)
            logger.warning("Agentic AI service returned status %s", resp.status_code)
        except requests.exceptions.RequestException as exc:
            logger.warning("Agentic AI service call failed: %s", exc)

        # Fallback to diagnostic questions on failure/unavailable
        return {
            "success": True,
            "status": "needs_questions",
            "prediction_id": prediction_id,
            "ml_result": ml_result,
            "questions": cls.DEFAULT_QUESTIONS,
        }

    @classmethod
    def normalize_agent_response(
        cls,
        data: dict,
        prediction_id: str,
        ml_result: dict,
    ) -> dict:
        """
        Normalizes external Agentic AI response matching the contract.
        Can either be completed diagnosis or needs_questions.
        """
        if not isinstance(data, dict):
            return {
                "success": True,
                "status": "needs_questions",
                "prediction_id": prediction_id,
                "ml_result": ml_result,
                "questions": cls.DEFAULT_QUESTIONS,
            }

        status_val = data.get("status", "needs_questions")
        if status_val == "completed":
            diagnosis = data.get("diagnosis", {})
            crop = diagnosis.get("crop", ml_result.get("crop", {}))
            disease = diagnosis.get("disease", ml_result.get("disease", {}))
            confidence = diagnosis.get("confidence", 0.85)

            return {
                "success": True,
                "status": "completed",
                "prediction_id": prediction_id,
                "diagnosis": {
                    "crop": crop,
                    "disease": disease,
                    "confidence": float(confidence),
                },
                "recommendation": data.get(
                    "recommendation",
                    {"summary": "Management information is available."}
                ),
                "pesticides": data.get("pesticides", []),
                "precautions": data.get("precautions", []),
                "sources": data.get("sources", []),
            }

        # Otherwise status == 'needs_questions'
        return {
            "success": True,
            "status": "needs_questions",
            "prediction_id": prediction_id,
            "ml_result": ml_result,
            "questions": data.get("questions", cls.DEFAULT_QUESTIONS),
        }
