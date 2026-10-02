from django.contrib import admin

from .models import Pesticide


@admin.register(Pesticide)
class PesticideAdmin(admin.ModelAdmin):
    fieldsets = (
        ("Basic Product Info", {
            "fields": (
                "pesticide_id",
                "product_name",
                "active_ingredients",
                "formulation",
                "pesticide_type",
                "company_name",
                "company_manufacturer",
            )
        }),
        ("Target & Purpose", {
            "fields": (
                "target_crops",
                "target_disease_pest",
                "purpose",
                "application_method",
                "crop_stage",
            )
        }),
        ("Dosage & Safety", {
            "fields": (
                "dosage",
                "dosage_rate",
                "water_volume_information",
                "safety_precautions",
                "precautions",
            )
        }),
        ("Price & Availability", {
            "fields": (
                "packaging",
                "price_range",
                "price_information",
                "availability",
            )
        }),
        ("Media & Source", {
            "fields": (
                "product_image_url_reference",
                "image",
                "source_url",
                "source_type",
                "last_verified_date",
                "notes",
                "description",
            )
        }),
    )

    list_display = (
        "product_name",
        "company_name",
        "company_manufacturer",
        "pesticide_type",
        "availability",
        "last_verified_date",
    )

    search_fields = (
        "product_name",
        "company_name",
        "company_manufacturer",
        "target_disease_pest",
        "target_crops",
    )

    list_filter = (
        "availability",
        "pesticide_type",
        "source_type",
    )