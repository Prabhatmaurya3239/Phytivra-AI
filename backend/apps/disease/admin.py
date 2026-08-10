from django.contrib import admin

from .models import Disease


@admin.register(Disease)
class DiseaseAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'name',
        'crop',
        'severity',
    )

    list_filter = (
        'severity',
        'crop',
    )

    search_fields = (
        'name',
        'crop__name',
    )
