from rest_framework import serializers

from .models import LeafImage


class LeafImageSerializer(serializers.ModelSerializer):

    class Meta:
        model = LeafImage

        fields = [
            'id',
            'image',
            'uploaded_at',
        ]

        read_only_fields = [
            'id',
            'uploaded_at',
        ]

    def validate_image(self, image):

        allowed_types = [
            'image/jpeg',
            'image/png',
            'image/webp',
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