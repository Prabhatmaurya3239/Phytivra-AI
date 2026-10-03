from django.urls import path

from .views import DiseaseRecommendationView


urlpatterns = [

    path(
        '<int:disease_id>/',
        DiseaseRecommendationView.as_view(),
        name='disease-recommendations-direct'
    ),
    path(
        'disease/<int:disease_id>/',
        DiseaseRecommendationView.as_view(),
        name='disease-recommendations'
    ),

]