from django.urls import path

from .views import (
    LeafImageUploadView,
    DiseasePredictionView,
    MLPredictionView,
)
from apps.agenticAI.views import AIRecommendationView

urlpatterns = [
    # 1. Upload leaf image
    path(
        "upload/",
        LeafImageUploadView.as_view(),
        name="leaf-image-upload",
    ),

    # 2. Main prediction endpoint
    path(
        "predict/",
        DiseasePredictionView.as_view(),
        name="disease-prediction",
    ),

    # 3. Retrieve prediction by prediction_id (e.g. pred_000001)
    path(
        "predict/<str:prediction_id>/",
        DiseasePredictionView.as_view(),
        name="disease-prediction-detail",
    ),
    path(
        "<str:prediction_id>/",
        DiseasePredictionView.as_view(),
        name="prediction-detail",
    ),

    # 4. Answers submission endpoint (Agentic AI reconciliation)
    path(
        "<str:prediction_id>/answers/",
        AIRecommendationView.as_view(),
        name="prediction-answers",
    ),
    path(
        "predict/<str:prediction_id>/answers/",
        AIRecommendationView.as_view(),
        name="prediction-predict-answers",
    ),

    # 5. Receive result from ML model (legacy Task 3)
    path(
        "ml-result/",
        MLPredictionView.as_view(),
        name="ml-prediction",
    ),
]