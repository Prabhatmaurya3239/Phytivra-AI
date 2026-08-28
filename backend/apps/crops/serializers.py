from rest_framework import serializers

from .models import Crop


class CropSerializer(serializers.ModelSerializer):

    class Meta:
        model = Crop
        fields = [
            'id',
            'name',
            'scientific_name',
            'description',
            'image',
        ]