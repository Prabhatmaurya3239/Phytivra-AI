from django.urls import path

from .views import LeafImageUploadView


urlpatterns = [

    path(
        'upload/',
        LeafImageUploadView.as_view(),
        name='leaf-image-upload'
    ),

]