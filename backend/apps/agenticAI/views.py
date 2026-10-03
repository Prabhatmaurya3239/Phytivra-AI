"""
Views for Agentic AI workflow.
Integrates FollowUpQuestionView and AIRecommendationView with the AgenticAIService pipeline.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .serializers import (
    FollowUpSerializer,
    AIRecommendationSerializer,
    AgenticRequestSerializer
)
from .services.agent_service import AgenticAIService
from .services.question_service import QuestionService
from .schemas.response_schema import FollowUpQuestionResponse

agent_service = AgenticAIService()


class FollowUpQuestionView(APIView):
    """
    Endpoint for explicitly requesting follow-up questions.
    POST /api/ai/follow-up/
    """
    def post(self, request):
        serializer = FollowUpSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                "success": False,
                "message": "Invalid request payload",
                "errors": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        prediction_id = data.get("prediction_id", "pred_demo_001")
        crop = data.get("crop", "")
        disease = data.get("disease", "")
        language = data.get("language", "en")
        user_context = data.get("user_context", {})

        questions = QuestionService.generate_follow_up_questions(
            crop_name=crop,
            disease_name=disease,
            user_context=user_context,
            language=language
        )

        resp = FollowUpQuestionResponse(
            success=True,
            status="needs_questions",
            prediction_id=prediction_id,
            questions=questions
        )

        return Response(resp.to_dict(), status=status.HTTP_200_OK)


class AIRecommendationView(APIView):
    """
    Primary Agentic AI Recommendation Endpoint.
    POST /api/ai/recommendation/
    Orchestrates confidence check, follow-up questions, retrieval, and response synthesis.
    """
    def post(self, request):
        serializer = AIRecommendationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                "success": False,
                "message": "Invalid request payload",
                "errors": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

        # Process through Agentic AI pipeline
        result = agent_service.process_request(request.data)
        return Response(result, status=status.HTTP_200_OK)