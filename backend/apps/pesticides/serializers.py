from rest_framework import serializers

from .models import Pesticide


class PesticideSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = Pesticide

        fields = [
            'id',
            'pesticide_id',
            'product_name',
            'active_ingredients',
            'formulation',
            'pesticide_type',
            'company_name',
            'company_manufacturer',
            'target_crops',
            'target_disease_pest',
            'purpose',
            'application_method',
            'dosage',
            'dosage_rate',
            'water_volume_information',
            'crop_stage',
            'safety_precautions',
            'precautions',
            'packaging',
            'price_range',
            'price_information',
            'availability',
            'product_image_url_reference',
            'image',
            'source_url',
            'source_type',
            'last_verified_date',
            'notes',
            'description',
        ]

    def validate_product_name(self, value):
        value = (value or '').strip()

        if len(value) < 2:
            raise serializers.ValidationError(
                "Product name must contain at least 2 characters."
            )

        return value

    def validate_company_name(self, value):
        value = (value or '').strip()

        if len(value) < 2:
            raise serializers.ValidationError(
                "Company name must contain at least 2 characters."
            )

        return value

    def get_image(self, obj):
        if not obj.image:
            return None

        request = self.context.get("request")

        if request:
            return request.build_absolute_uri(obj.image.url)

        return obj.image.url