from rest_framework import serializers


class FollowUpSerializer(serializers.Serializer):
    prediction_id = serializers.CharField(
        required=True
    )


class AIRecommendationSerializer(serializers.Serializer):
    prediction_id = serializers.CharField(
        required=True
    )
    answers = serializers.DictField(
        required=True
    )