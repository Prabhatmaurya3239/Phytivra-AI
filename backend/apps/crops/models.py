from django.db import models
from django.core.validators import MinLengthValidator


class Crop(models.Model):
    name = models.CharField(
        max_length=100,
        unique=True,
        db_index=True,
        validators=[
            MinLengthValidator(2)
        ]
        )
    scientific_name = models.CharField(
        max_length=150,
        unique=True
        )
    description = models.TextField()
    image = models.ImageField(
        upload_to='crop_images/',
        blank=True,
        null=True
        )
    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name
    