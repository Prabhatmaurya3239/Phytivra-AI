# from django.urls import path

# from .views import (
#     LeafImageUploadView,
#     DiseasePredictionView,
#     MLPredictionView
# )


# urlpatterns = [

#     path(
#         'upload/',
#         LeafImageUploadView.as_view(),
#         name='leaf-image-upload'
#     ),
#     path(
#         "predict/",
#         DiseasePredictionView.as_view(),
#         name="disease-prediction"
#     ),
#     path(
#         "predict/",
#         MLPredictionView.as_view(),
#         name="ml-prediction"
#     ),

# ]

from django.urls import path

from .views import (
    LeafImageUploadView,
    DiseasePredictionView,
    MLPredictionView
)


urlpatterns = [

    # Upload leaf image
    path(
        "upload/",
        LeafImageUploadView.as_view(),
        name="leaf-image-upload"
    ),

    # Send uploaded image for prediction
    path(
        "predict/",
        DiseasePredictionView.as_view(),
        name="disease-prediction"
    ),

    # Receive result from ML model
    path(
        "ml-result/",
        MLPredictionView.as_view(),
        name="ml-prediction"
    ),

]