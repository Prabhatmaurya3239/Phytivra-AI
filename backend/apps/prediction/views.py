from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import LeafImage
from .serializers import LeafImageSerializer


class LeafImageUploadView(APIView):

    def post(self, request):

        serializer = LeafImageSerializer(
            data=request.data
        )

        if serializer.is_valid():

            leaf_image = serializer.save()

            image_url = request.build_absolute_uri(
                leaf_image.image.url
            )

            return Response(
                {
                    'message': 'Image uploaded successfully.',
                    'image_id': leaf_image.id,
                    'image_url': image_url
                },
                status=status.HTTP_201_CREATED
            )

        return Response(
            {
                'errors': serializer.errors
            },
            status=status.HTTP_400_BAD_REQUEST
        )