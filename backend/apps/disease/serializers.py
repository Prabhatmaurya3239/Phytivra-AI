from rest_framework import serializers

from .models import Disease


class DiseaseSerializer(serializers.ModelSerializer):

    crop_name = serializers.CharField(
        source='crop.name',
        read_only=True
    )

    class Meta:
        model = Disease

        fields = [
            'id',
            'name',
            'crop',
            'crop_name',
            'symptoms',
            'causes',
            'description',
            'severity',
            'image',
        ]