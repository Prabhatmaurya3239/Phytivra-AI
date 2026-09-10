from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Recommendation
from .serializers import RecommendationSerializer
from apps.disease.models import Disease
from apps.pesticides.serializers import PesticideSerializer
from apps.pesticides.models import Pesticide

class DiseaseRecommendationView(APIView):

    def get(self, request, disease_id):

        disease = get_object_or_404(
            Disease,
            id=disease_id
        )

        pesticides =  (
            disease.recommended_pesticides
            .filter(availability=True)
            .order_by("name")
        )
        

        serializer = PesticideSerializer(
            pesticides,
            many=True,
            context={"request": request}
        )

        return Response(
            {
                "success": True,

                "disease": {
                    "id": disease.id,
                    "name": disease.name,
                    "crop": disease.crop.name,
                    "severity": disease.severity
                },

                "recommendations": serializer.data,

                "count": pesticides.count()
            },

            status=status.HTTP_200_OK
        )