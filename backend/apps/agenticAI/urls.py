from django.urls import path

from .views import (
    FollowUpQuestionView,
    AIRecommendationView
)


urlpatterns = [
    path(
        "follow-up/",
        FollowUpQuestionView.as_view(),
        name="ai-follow-up"
    ),

    path(
        "recommendation/",
        AIRecommendationView.as_view(),
        name="ai-recommendation"
    ),
]