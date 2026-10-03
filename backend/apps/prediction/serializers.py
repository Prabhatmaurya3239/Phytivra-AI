from rest_framework import serializers

from .models import LeafImage, Prediction
from apps.disease.models import Disease
from apps.crops.models import Crop


# --------------------------------------------------
# 1. IMAGE UPLOAD SERIALIZER
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

        if hasattr(image, "content_type") and image.content_type not in allowed_types:
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
# 2. PREDICTION REQUEST SERIALIZER
# --------------------------------------------------

class PredictionRequestSerializer(serializers.Serializer):
    """
    Accepts either an existing 'image_id' (from /upload/)
    OR a direct multipart 'image' file upload.
    Also accepts optional 'language' and 'user_note'.
    """
    image_id = serializers.IntegerField(
        required=False,
        allow_null=True
    )
    image = serializers.ImageField(
        required=False,
        allow_null=True
    )
    language = serializers.CharField(
        required=False,
        default="en",
        max_length=10
    )
    user_note = serializers.CharField(
        required=False,
        allow_blank=True,
        default=""
    )

    def validate(self, data):
        image_id = data.get("image_id")
        image = data.get("image")

        if not image_id and not image:
            raise serializers.ValidationError({
                "image": "Either 'image_id' or 'image' file is required."
            })

        if image_id:
            try:
                data["leaf_image"] = LeafImage.objects.get(id=image_id)
            except LeafImage.DoesNotExist:
                raise serializers.ValidationError({
                    "image_id": "Invalid image ID. Image not found."
                })

        if image:
            allowed_types = [
                "image/jpeg",
                "image/png",
                "image/webp",
            ]
            if hasattr(image, "content_type") and image.content_type not in allowed_types:
                raise serializers.ValidationError({
                    "image": "Only JPG, JPEG, PNG and WEBP images are allowed."
                })

            max_size = 5 * 1024 * 1024
            if image.size > max_size:
                raise serializers.ValidationError({
                    "image": "Image size must not exceed 5 MB."
                })

        return data


# --------------------------------------------------
# 3. PREDICTION MODEL SERIALIZER
# --------------------------------------------------

class PredictionSerializer(serializers.ModelSerializer):
    prediction_id = serializers.CharField(read_only=True)

    class Meta:
        model = Prediction
        fields = [
            "id",
            "prediction_id",
            "crop",
            "disease",
            "confidence",
            "status",
            "model_name",
            "model_version",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "prediction_id",
            "created_at",
        ]


# --------------------------------------------------
# 4. ML PREDICTION INPUT SERIALIZER (Legacy Task 3)
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
            "pending",
            "processing",
            "completed",
            "needs_questions",
        ]
    )

    def validate(self, data):
        crop_name = data.get("crop")
        disease_name = data.get("disease")

        if crop_name:
            try:
                crop = Crop.objects.get(name__iexact=crop_name)
                data["crop"] = crop.name
            except Crop.DoesNotExist:
                raise serializers.ValidationError({
                    "crop": "The specified crop was not found."
                })

            if disease_name:
                try:
                    disease = Disease.objects.get(name__iexact=disease_name, crop=crop)
                    data["disease"] = disease.name
                except Disease.DoesNotExist:
                    raise serializers.ValidationError({
                        "disease": "The specified disease was not found for this crop."
                    })

        return data