from django.contrib import admin

from .models import Crop


@admin.register(Crop)
class CropAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'name',
        'scientific_name',
    )

    search_fields = (
        'name',
        'scientific_name',
    )