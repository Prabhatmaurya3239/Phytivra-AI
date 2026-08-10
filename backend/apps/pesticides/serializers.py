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
        ]