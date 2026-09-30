from django.urls import path,include
from .views import home

urlpatterns = [
    path('', home, name='home'),
    path(
        'crops/',
        include('apps.crops.urls')
    ),

    path(
        'disease/',
        include('apps.disease.urls')
    ),

    path(
        'pesticides/',
        include('apps.pesticides.urls')
    ),

    path(
        'recommendations/',
        include('apps.recommendations.urls')
    ),
    path(
        'prediction/',
        include('apps.prediction.urls')
    ),
]