from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Crop
from .serializers import CropSerializer


class CropListView(APIView):

    def get(self, request):
        crops = Crop.objects.all()

        serializer = CropSerializer(
            crops,
            many=True,
            context={'request': request}
        )

        return Response(
            serializer.data,
            status=status.HTTP_200_OK
        )


class CropDetailView(APIView):

    def get(self, request, pk):

        try:
            crop = Crop.objects.get(pk=pk)

        except Crop.DoesNotExist:
            return Response(
                {
                    'error': 'Crop not found'
                },
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = CropSerializer(
            crop,
            context={'request': request}
        )

        return Response(
            serializer.data,
            status=status.HTTP_200_OK
        )
