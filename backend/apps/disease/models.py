from django.db import models
from apps.crops.models import Crop


class Disease(models.Model):

    SEVERITY_CHOICES = [
        ('Low', 'Low'),
        ('Medium', 'Medium'),
        ('High', 'High'),
    ]

    crop = models.ForeignKey(
        Crop,
        on_delete=models.CASCADE,
        related_name='diseases'
    )

    name = models.CharField(max_length=150)
    symptoms = models.TextField()
    causes = models.TextField()
    description = models.TextField()

    severity = models.CharField(
        max_length=10,
        choices=SEVERITY_CHOICES
    )

    image = models.ImageField(
        upload_to='disease_images/'
    )

    def __str__(self):
        return f"{self.crop.name} - {self.name}"