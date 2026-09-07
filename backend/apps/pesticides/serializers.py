from rest_framework import serializers

from .models import Pesticide


class PesticideSerializer(serializers.ModelSerializer):

    class Meta:
        model = Pesticide

        fields = [
            'id',
            'name',
            'company_name',
            'description',
            'price_range',
            'packing_size',
            'dosage',
            'spray_method',
            'precautions',
            'image',
            'availability',
        ]
    def validate_name(self, value):

        value = value.strip()

        if len(value) < 2:
            raise serializers.ValidationError(
                "Pesticide name must contain at least 2 characters."
            )

        return value
    def get_image(self, obj):

        if not obj.image:
            return None

        request = self.context.get("request")

        if request:
            return request.build_absolute_uri(
                obj.image.url
            )

        return obj.image.url