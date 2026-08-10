from django.urls import path

from .views import (
    DiseaseListView,
    DiseaseDetailView,
)


urlpatterns = [

    path(
        '',
        DiseaseListView.as_view(),
        name='disease-list'
    ),

    path(
        '<int:pk>/',
        DiseaseDetailView.as_view(),
        name='disease-detail'
    ),

]