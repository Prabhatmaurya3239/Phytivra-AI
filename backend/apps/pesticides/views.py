from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Pesticide
from .serializers import PesticideSerializer


class PesticideListView(APIView):

    def get(self, request):

        pesticides = Pesticide.objects.all()

        serializer = PesticideSerializer(
            pesticides,
            many=True,
            context={'request': request}
        )

        return Response(
            serializer.data,
            status=status.HTTP_200_OK
        )


class PesticideDetailView(APIView):

    def get(self, request, pk):

        try:
            pesticide = Pesticide.objects.get(pk=pk)

        except Pesticide.DoesNotExist:
            return Response(
                {
                    'error': 'Pesticide not found'
                },
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = PesticideSerializer(
            pesticide,
            context={'request': request}
        )

        return Response(
            serializer.data,
            status=status.HTTP_200_OK
        )