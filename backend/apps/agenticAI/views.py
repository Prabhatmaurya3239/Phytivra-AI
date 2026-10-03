import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .serializers import (
    FollowUpSerializer,
    AIRecommendationSerializer
)
from apps.prediction.models import Prediction, PredictionStatus
from apps.prediction.services.agent_service import AgentService
from apps.prediction.services.prediction_service import format_pesticides_and_recommendations
from apps.disease.models import Disease
from apps.crops.models import Crop

logger = logging.getLogger(__name__)


class FollowUpQuestionView(APIView):
    """
    Returns follow-up questions for a low-confidence or undetermined prediction.
    Endpoint: POST /api/ai/follow-up/
    """

    def post(self, request):
        serializer = FollowUpSerializer(data=request.data)

        if not serializer.is_valid():
            return Response({
                "success": False,
                "message": "Invalid request.",
                "errors": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

        prediction_id = serializer.validated_data["prediction_id"]
        prediction = Prediction.get_by_prediction_id(prediction_id)

        if not prediction:
            return Response({
                "success": False,
                "message": "Prediction not found.",
            }, status=status.HTTP_404_NOT_FOUND)

        return Response({
            "success": True,
            "prediction_id": prediction.prediction_id,
            "status": PredictionStatus.NEEDS_QUESTIONS,
            "message": "Follow-up diagnostic questions.",
            "data": {
                "questions": AgentService.DEFAULT_QUESTIONS
            },
            "questions": AgentService.DEFAULT_QUESTIONS
        }, status=status.HTTP_200_OK)


class AIRecommendationView(APIView):
    """
    Receives user answers to follow-up questions and returns refined diagnosis/recommendation.
    Endpoint: POST /api/ai/recommendation/
    """

    def post(self, request, prediction_id=None):
        serializer = AIRecommendationSerializer(data=request.data)

        if not serializer.is_valid():
            return Response({
                "success": False,
                "message": "Invalid request.",
                "errors": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

        lookup_id = prediction_id or serializer.validated_data.get("prediction_id") or request.data.get("prediction_id")
        if not lookup_id:
            return Response({
                "success": False,
                "message": "Prediction ID is required.",
            }, status=status.HTTP_400_BAD_REQUEST)

        answers_raw = serializer.validated_data["answers"]
        answers = {}
        if isinstance(answers_raw, list):
            for item in answers_raw:
                if isinstance(item, dict):
                    qid = item.get("question_id") or item.get("id")
                    ans = item.get("answer")
                    if qid:
                        answers[str(qid)] = ans
        elif isinstance(answers_raw, dict):
            answers = answers_raw

        prediction = Prediction.get_by_prediction_id(lookup_id)
        if not prediction:
            return Response({
                "success": False,
                "message": "Prediction not found.",
            }, status=status.HTTP_404_NOT_FOUND)

        # Re-resolve or confirm diagnosis based on symptoms in answers
        mapped_crop = Crop.objects.filter(name__iexact=prediction.crop).first() if prediction.crop else None

        # Look for disease matching symptom keywords or crop
        mapped_disease = None
        if prediction.disease:
            mapped_disease = Disease.objects.filter(name__iexact=prediction.disease).first()

        if not mapped_disease and mapped_crop:
            # Pick first disease for crop if unknown or default to Early Blight
            mapped_disease = Disease.objects.filter(crop=mapped_crop).first()

        if mapped_disease:
            prediction.status = PredictionStatus.COMPLETED
            prediction.disease = mapped_disease.name
            prediction.confidence = max(prediction.confidence, 0.85)
            prediction.save()

            rec, pesticides, precautions = format_pesticides_and_recommendations(
                mapped_disease,
                request=request
            )

            return Response({
                "success": True,
                "prediction_id": prediction.prediction_id,
                "status": PredictionStatus.COMPLETED,
                "message": "AI diagnosis refined successfully.",
                "diagnosis": {
                    "crop": {
                        "id": mapped_crop.id if mapped_crop else None,
                        "name": mapped_crop.name if mapped_crop else prediction.crop,
                    },
                    "disease": {
                        "id": mapped_disease.id,
                        "name": mapped_disease.name,
                    },
                    "confidence": round(prediction.confidence, 4),
                },
                "recommendation": rec,
                "pesticides": pesticides,
                "precautions": precautions,
                "sources": [
                    {
                        "source_id": "source_001",
                        "source_type": "official"
                    }
                ],
                "result": {
                    "crop": {
                        "id": mapped_crop.id if mapped_crop else None,
                        "name": mapped_crop.name if mapped_crop else prediction.crop,
                    },
                    "disease": {
                        "id": mapped_disease.id,
                        "name": mapped_disease.name,
                    },
                    "confidence": {
                        "score": round(prediction.confidence, 4),
                        "percentage": int(round(prediction.confidence * 100)),
                    },
                    "recommendation": rec,
                    "pesticides": pesticides,
                    "precautions": precautions,
                    "sources": [
                        {
                            "source_id": "source_001",
                            "source_type": "official"
                        }
                    ],
                }
            }, status=status.HTTP_200_OK)

        return Response({
            "success": True,
            "prediction_id": prediction.prediction_id,
            "status": prediction.status,
            "message": "Unable to definitively confirm disease from submitted answers.",
            "questions": AgentService.DEFAULT_QUESTIONS,
        }, status=status.HTTP_200_OK)