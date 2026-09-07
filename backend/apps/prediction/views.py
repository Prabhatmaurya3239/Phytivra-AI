# from rest_framework.views import APIView
# from rest_framework.response import Response
# from rest_framework import status

# from .models import LeafImage,Prediction
# from .serializers import LeafImageSerializer,PredictionSerializer,MLPredictionInputSerializer


# class LeafImageUploadView(APIView):

#     def post(self, request):

#         serializer = LeafImageSerializer(
#             data=request.data
#         )

#         if serializer.is_valid():

#             leaf_image = serializer.save()

#             image_url = request.build_absolute_uri(
#                 leaf_image.image.url
#             )

#             return Response(
#                 {
#                     'message': 'Image uploaded successfully.',
#                     'image_id': leaf_image.id,
#                     'image_url': image_url
#                 },
#                 status=status.HTTP_201_CREATED
#             )

#         return Response(
#             {
#                 'errors': serializer.errors
#             },
#             status=status.HTTP_400_BAD_REQUEST
#         )

# class DiseasePredictionView(APIView):

#     def post(self, request):

#         serializer = PredictionRequestSerializer(
#             data=request.data
#         )

#         if not serializer.is_valid():

#             return Response({
#                 "success": False,
#                 "message": "Invalid prediction request",
#                 "errors": serializer.errors
#             }, status=status.HTTP_400_BAD_REQUEST)

#         return Response({
#             "success": True,
#             "message": "Disease prediction endpoint is ready",
#             "data": {
#                 "crop": None,
#                 "disease": None,
#                 "confidence": 0,
#                 "status": "pending"
#             }
#         })

# class MLPredictionView(APIView):

#     def post(self, request):

#         serializer = MLPredictionInputSerializer(
#             data=request.data
#         )

#         if not serializer.is_valid():

#             return Response(
#                 {
#                     "success": False,
#                     "message": "Invalid ML prediction data",
#                     "errors": serializer.errors
#                 },
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         prediction = Prediction.objects.create(
#             crop=serializer.validated_data["crop"],
#             disease=serializer.validated_data["disease"],
#             confidence=serializer.validated_data["confidence"],
#             status=serializer.validated_data["status"]
#         )

#         return Response(
#             {
#                 "success": True,
#                 "message": "ML prediction received successfully",
#                 "data": {
#                     "crop": prediction.crop,
#                     "disease": prediction.disease,
#                     "confidence": prediction.confidence,
#                     "status": prediction.status
#                 }
#             },
#             status=status.HTTP_201_CREATED
#         )

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .services import process_prediction
from django.db import DatabaseError

from .models import LeafImage, Prediction
from .serializers import (
    LeafImageSerializer,
    PredictionSerializer,
    PredictionRequestSerializer,
    MLPredictionInputSerializer
)
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status


class AIRecommendationView(APIView):

    def post(self, request):

        crop = request.data.get("crop")
        disease = request.data.get("disease")
        answers = request.data.get("answers", {})

        # Check required parameters
        if not crop or not disease:

            return Response(
                {
                    "success": False,
                    "message": "Crop and disease are required."
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # -----------------------------------
        # CALL AGENTIC AI SERVICE HERE
        # -----------------------------------

        try:

            ai_response = agentic_ai_service(
                crop=crop,
                disease=disease,
                answers=answers
            )

        except Exception:

            return Response(
                {
                    "success": False,
                    "message": "The AI service is temporarily unavailable."
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        # -----------------------------------
        # RETURN AI RESPONSE
        # -----------------------------------

        return Response(
            {
                "success": True,
                "message": "AI recommendation generated successfully.",
                "data": ai_response
            },
            status=status.HTTP_200_OK
        )

# --------------------------------------------------
# 1. IMAGE UPLOAD
# --------------------------------------------------

class LeafImageUploadView(APIView):

    def post(self, request):

        serializer = LeafImageSerializer(
            data=request.data
        )

        if not serializer.is_valid():

            return Response(
                {
                    "success": False,
                    "message": "Image upload failed",
                    "errors": serializer.errors
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        try:

            leaf_image = serializer.save()

            image_url = request.build_absolute_uri(
                leaf_image.image.url
            )

            return Response(
                {
                    "success": True,
                    "message": "Image uploaded successfully.",
                    "data": {
                        "image_id": leaf_image.id,
                        "image_url": image_url
                    }
                },
                status=status.HTTP_201_CREATED
            )

        except Exception:

            return Response(
                {
                    "success": False,
                    "message": "Unable to process the uploaded image."
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# --------------------------------------------------
# 2. DISEASE PREDICTION REQUEST
# --------------------------------------------------

class DiseasePredictionView(APIView):

    def post(self, request):

        serializer = PredictionRequestSerializer(
            data=request.data
        )

        if not serializer.is_valid():

            return Response(
                {
                    "success": False,
                    "message": "Invalid prediction request",
                    "errors": serializer.errors
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        image_id = serializer.validated_data["image_id"]

        try:
            leaf_image = LeafImage.objects.get(
                id=image_id
            )

        except LeafImage.DoesNotExist:

            return Response(
                {
                    "success": False,
                    "message": "Image not found",
                    "errors": {
                        "image_id": "Invalid image ID"
                    }
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # --------------------------------------------------
        # ML MODEL WILL BE CONNECTED HERE BY PRABHAT
        # --------------------------------------------------

        return Response(
            {
                "success": True,
                "message": "Prediction request received",
                "data": {
                    "image_id": leaf_image.id,
                    "crop": None,
                    "disease": None,
                    "confidence": 0.0,
                    "status": "pending"
                }
            },
            status=status.HTTP_200_OK
        )


# --------------------------------------------------
# 3. ML PREDICTION RESULT
# --------------------------------------------------

class MLPredictionView(APIView):

    def post(self, request):

        serializer = MLPredictionInputSerializer(
            data=request.data
        )

        if not serializer.is_valid():

            return Response(
                {
                    "success": False,
                    "message": "Invalid ML prediction data",
                    "errors": serializer.errors
                },
                status=status.HTTP_400_BAD_REQUEST
            )
        data = serializer.validated_data

        if data["status"] == "failed":

            return Response(
                {
                    "success": False,
                    "message": "Unable to predict disease from the uploaded image.",
                    "data": {
                        "crop": data.get("crop"),
                        "disease": None,
                        "confidence": data.get("confidence", 0),
                        "status": "failed"
                    }
                },
                status=status.HTTP_422_UNPROCESSABLE_ENTITY
            )

        crop = serializer.validated_data.get("crop")
        disease = serializer.validated_data.get("disease")
        confidence = serializer.validated_data["confidence"]
        prediction_status = serializer.validated_data["status"]

        # Save ML prediction
        try:

            prediction = Prediction.objects.create(
                crop=data["crop"],
                disease=data["disease"],
                confidence=data["confidence"],
                status=data["status"]
            )

        except DatabaseError as e:

            return Response(
                {
                    "success": False,
                    "message": "Unable to save prediction false",
                    
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


        # Process confidence-based workflow
        workflow = process_prediction(
            crop=crop,
            disease=disease,
            confidence=confidence,
            status=prediction_status
        )

        return Response(
            {
                "success": True,
                "message": "Prediction processed successfully",

                "data": {
                    "prediction_id": prediction.id,
                    "crop": crop,
                    "disease": disease,
                    "confidence": confidence,
                    "status": prediction_status,

                    "workflow": workflow["workflow"],
                    "next_step": workflow["next_step"],
                    "threshold": workflow["threshold"]
                }
            },
            status=status.HTTP_201_CREATED
        )