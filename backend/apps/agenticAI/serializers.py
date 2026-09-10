from rest_framework import serializers


class FollowUpSerializer(serializers.Serializer):

    prediction_id = serializers.IntegerField(
        required=True
    )


class AIRecommendationSerializer(serializers.Serializer):

    prediction_id = serializers.IntegerField(
        required=True
    )

    answers = serializers.DictField(
        required=True
    )