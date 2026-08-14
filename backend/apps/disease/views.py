from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Disease
from .serializers import DiseaseSerializer


class DiseaseListView(APIView):

    def get(self, request):

        diseases = Disease.objects.select_related(
            'crop'
        ).all()

        serializer = DiseaseSerializer(
            diseases,
            many=True,
            context={'request': request}
        )

        return Response(
            serializer.data,
            status=status.HTTP_200_OK
        )


class DiseaseDetailView(APIView):

    def get(self, request, pk):

        try:
            disease = Disease.objects.select_related(
                'crop'
            ).get(pk=pk)

        except Disease.DoesNotExist:
            return Response(
                {
                    'error': 'Disease not found'
                },
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = DiseaseSerializer(
            disease,
            context={'request': request}
        )

        return Response(
            serializer.data,
            status=status.HTTP_200_OK
        )