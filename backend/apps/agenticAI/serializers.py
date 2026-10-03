"""
Serializers for Agentic AI REST API.
Supports both the new comprehensive Task 3 contract and backward compatibility.
"""

from rest_framework import serializers


class MLResultCropSerializer(serializers.Serializer):
    id = serializers.IntegerField(required=False, allow_null=True)
    name = serializers.CharField(required=False, allow_blank=True, default="")


class MLResultDiseaseSerializer(serializers.Serializer):
    id = serializers.IntegerField(required=False, allow_null=True)
    name = serializers.CharField(required=False, allow_blank=True, default="")


class MLResultSerializer(serializers.Serializer):
    crop = MLResultCropSerializer(required=False)
    disease = MLResultDiseaseSerializer(required=False)
    confidence = serializers.FloatField(required=False, default=0.0)


class UserAnswerItemSerializer(serializers.Serializer):
    question_id = serializers.CharField(required=True)
    answer = serializers.CharField(required=True)


class AgenticRequestSerializer(serializers.Serializer):
    prediction_id = serializers.CharField(required=False, default="pred_demo_001")
    language = serializers.CharField(required=False, default="en")
    ml_result = MLResultSerializer(required=False)
    user_context = serializers.DictField(required=False, default=dict)
    answers = serializers.ListField(
        child=serializers.DictField(),
        required=False,
        default=list
    )


class FollowUpSerializer(serializers.Serializer):
    prediction_id = serializers.CharField(required=False, default="pred_demo_001")
    crop = serializers.CharField(required=False, allow_blank=True, default="")
    disease = serializers.CharField(required=False, allow_blank=True, default="")
    language = serializers.CharField(required=False, default="en")
    user_context = serializers.DictField(required=False, default=dict)


class AIRecommendationSerializer(serializers.Serializer):
    prediction_id = serializers.CharField(required=False, default="pred_demo_001")
    language = serializers.CharField(required=False, default="en")
    ml_result = MLResultSerializer(required=False)
    user_context = serializers.DictField(required=False, default=dict)
    answers = serializers.ListField(
        child=serializers.DictField(),
        required=False,
        default=list
    )