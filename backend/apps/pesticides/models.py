from django.db import models
from django.core.validators import MinLengthValidator

class Pesticide(models.Model):
    name = models.CharField(
        max_length=150,
        db_index=True,
        validators=[
            MinLengthValidator(2)
        ]
    )
    company_name = models.CharField(
        max_length=150,
        db_index=True
    )
    description = models.TextField()
    price_range = models.CharField(max_length=100)
    packing_size = models.CharField(max_length=100)
    dosage = models.CharField(max_length=255)
    spray_method = models.TextField()
    precautions = models.TextField()
    image = models.ImageField(
        upload_to='pesticide_images/',
        blank=True,
        null=True
    )

    availability = models.BooleanField(
        default=True,
        db_index=True
    )
    class Meta:
        ordering = ["name"]

        indexes = [
            models.Index(
                fields=["name", "company_name"]
            ),
        ]


    def __str__(self):
        return self.name