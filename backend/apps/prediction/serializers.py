# from rest_framework import serializers

# from .models import LeafImage, Prediction


# class LeafImageSerializer(serializers.ModelSerializer):

#     class Meta:
#         model = LeafImage

#         fields = [
#             'id',
#             'image',
#             'uploaded_at',
#         ]

#         read_only_fields = [
#             'id',
#             'uploaded_at',
#         ]

#     def validate_image(self, image):

#         allowed_types = [
#             'image/jpeg',
#             'image/png',
#             'image/webp',
#         ]

#         if image.content_type not in allowed_types:
#             raise serializers.ValidationError(
#                 "Only JPG, JPEG, PNG and WEBP images are allowed."
#             )

#         max_size = 5 * 1024 * 1024

#         if image.size > max_size:
#             raise serializers.ValidationError(
#                 "Image size must not exceed 5 MB."
#             )

#         return image

# class PredictionRequestSerializer(serializers.Serializer):

#     image_id = serializers.IntegerField(
#         required=True
#     )

# class PredictionSerializer(serializers.ModelSerializer):

#     class Meta:
#         model = Prediction

#         fields = [
#             "id",
#             "crop",
#             "disease",
#             "confidence",
#             "status",
#             "created_at",
#         ]

#         read_only_fields = [
#             "id",
#             "created_at",
#         ]


# class MLPredictionInputSerializer(serializers.Serializer):

#     crop = serializers.CharField(
#         max_length=100,
#         required=False,
#         allow_blank=True,
#         allow_null=True
#     )

#     disease = serializers.CharField(
#         max_length=150,
#         required=False,
#         allow_blank=True,
#         allow_null=True
#     )

#     confidence = serializers.FloatField(
#         min_value=0.0,
#         max_value=1.0
#     )

#     status = serializers.ChoiceField(
#         choices=[
#             "success",
#             "failed",
#             "pending"
#         ]
#     )

from rest_framework import serializers

from .models import LeafImage, Prediction

from apps.disease.models import Disease
from apps.crops.models import Crop

# --------------------------------------------------
# IMAGE UPLOAD SERIALIZER
# --------------------------------------------------

class LeafImageSerializer(serializers.ModelSerializer):

    class Meta:
        model = LeafImage

        fields = [
            "id",
            "image",
            "uploaded_at",
        ]

        read_only_fields = [
            "id",
            "uploaded_at",
        ]

    def validate_image(self, image):

        allowed_types = [
            "image/jpeg",
            "image/png",
            "image/webp",
        ]

        if image.content_type not in allowed_types:

            raise serializers.ValidationError(
                "Only JPG, JPEG, PNG and WEBP images are allowed."
            )

        max_size = 5 * 1024 * 1024

        if image.size > max_size:

            raise serializers.ValidationError(
                "Image size must not exceed 5 MB."
            )

        return image


# --------------------------------------------------
# PREDICTION REQUEST SERIALIZER
# --------------------------------------------------

class PredictionRequestSerializer(serializers.Serializer):

    image_id = serializers.IntegerField(
        required=True
    )


# --------------------------------------------------
# PREDICTION RESPONSE SERIALIZER
# --------------------------------------------------

class PredictionSerializer(serializers.ModelSerializer):

    class Meta:
        model = Prediction

        fields = [
            "id",
            "crop",
            "disease",
            "confidence",
            "status",
            "created_at",
        ]

        read_only_fields = [
            "id",
            "created_at",
        ]


# --------------------------------------------------
# ML PREDICTION INPUT SERIALIZER
# --------------------------------------------------

class MLPredictionInputSerializer(serializers.Serializer):

    crop = serializers.CharField(
        max_length=100,
        required=False,
        allow_blank=True,
        allow_null=True
    )

    disease = serializers.CharField(
        max_length=150,
        required=False,
        allow_blank=True,
        allow_null=True
    )

    confidence = serializers.FloatField(
        min_value=0.0,
        max_value=1.0
    )

    status = serializers.ChoiceField(
        choices=[
            "success",
            "failed",
            "pending"
        ]
        
    )
    def validate(self, data):

        crop_name = data["crop"]
        disease_name = data["disease"]

        try:
            crop = Crop.objects.get(
                name__iexact=crop_name
            )
        except Crop.DoesNotExist:
            raise serializers.ValidationError({
                "crop": "The specified crop was not found."
            })

        try:
            disease = Disease.objects.get(
                name__iexact=disease_name,
                crop=crop
            )
        except Disease.DoesNotExist:
            raise serializers.ValidationError({
                "disease": "The specified disease was not found for this crop."
            })

        data["crop"] = crop.name
        data["disease"] = disease.name

        return data