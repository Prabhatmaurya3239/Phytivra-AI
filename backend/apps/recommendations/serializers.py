from rest_framework import serializers

from .models import Recommendation


class RecommendationSerializer(serializers.ModelSerializer):

    pesticide_name = serializers.CharField(
        source='pesticide.product_name',
        read_only=True
    )

    company_name = serializers.CharField(
        source='pesticide.company_manufacturer',
        read_only=True
    )

    class Meta:
        model = Recommendation

        fields = [
            'id',
            'disease',
            'pesticide',
            'pesticide_name',
            'company_name',
        ]

        