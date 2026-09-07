from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .serializers import (
    FollowUpSerializer,
    AIRecommendationSerializer
)


class FollowUpQuestionView(APIView):

    def post(self, request):

        serializer = FollowUpSerializer(
            data=request.data
        )

        if not serializer.is_valid():

            return Response({
                "success": False,
                "message": "Invalid request",
                "errors": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            "success": True,
            "message": "Follow-up questions endpoint is ready",
            "data": {
                "questions": [
                    "Which crop is this?",
                    "What symptoms do you observe?",
                    "When did you first notice the symptoms?"
                ]
            }
        })


class AIRecommendationView(APIView):

    def post(self, request):

        serializer = AIRecommendationSerializer(
            data=request.data
        )

        if not serializer.is_valid():

            return Response({
                "success": False,
                "message": "Invalid request",
                "errors": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            "success": True,
            "message": "AI recommendation endpoint is ready",
            "data": {
                "crop": None,
                "disease": None,
                "confidence": None,
                "recommendations": []
            }
        })