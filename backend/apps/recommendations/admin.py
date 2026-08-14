from django.contrib import admin

from .models import Recommendation


@admin.register(Recommendation)
class RecommendationAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'disease',
        'pesticide',
        'created_at',
    )

    list_filter = (
        'disease',
        'pesticide',
    )

    search_fields = (
        'disease__name',
        'pesticide__name',
    )
