from rest_framework import serializers


class FollowUpSerializer(serializers.Serializer):
    prediction_id = serializers.CharField(
        required=True
    )


class AIRecommendationSerializer(serializers.Serializer):
    prediction_id = serializers.CharField(
        required=False,
        allow_blank=True,
    )
    answers = serializers.JSONField(
        required=True
    )