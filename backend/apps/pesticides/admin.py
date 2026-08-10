from django.contrib import admin

from .models import Pesticide


@admin.register(Pesticide)
class PesticideAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'name',
        'company_name',
        'price_range',
        'packing_size',
    )

    search_fields = (
        'name',
        'company_name',
    )