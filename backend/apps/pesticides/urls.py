from django.urls import path

from .views import (
    PesticideListView,
    PesticideDetailView,
)


urlpatterns = [

    path(
        '',
        PesticideListView.as_view(),
        name='pesticide-list'
    ),

    path(
        '<int:pk>/',
        PesticideDetailView.as_view(),
        name='pesticide-detail'
    ),

]