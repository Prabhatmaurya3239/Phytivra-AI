from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Recommendation
from .serializers import RecommendationSerializer


class DiseaseRecommendationView(APIView):

    def get(self, request, disease_id):

        recommendations = Recommendation.objects.filter(
            disease_id=disease_id
        ).select_related(
            'pesticide',
            'disease'
        )

        if not recommendations.exists():
            return Response(
                {
                    'message': 'No recommendations found for this disease.'
                },
                status=status.HTTP_200_OK
            )

        serializer = RecommendationSerializer(
            recommendations,
            many=True,
            context={'request': request}
        )

        return Response(
            serializer.data,
            status=status.HTTP_200_OK
        )
