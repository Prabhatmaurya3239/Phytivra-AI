from django.db import models


class LeafImage(models.Model):

    image = models.ImageField(
        upload_to='leaf_images/'
    )

    uploaded_at = models.DateTimeField(
        auto_now_add=True
    )

    def __str__(self):
        return self.image.name
class Prediction(models.Model):

    STATUS_CHOICES = [
        ("success", "Success"),
        ("failed", "Failed"),
        ("pending", "Pending"),
    ]

    crop = models.CharField(
        max_length=100,
        blank=True,
        null=True
    )

    disease = models.CharField(
        max_length=150,
        blank=True,
        null=True
    )

    confidence = models.FloatField(
        default=0.0
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="pending"
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    def __str__(self):
        return f"{self.crop} - {self.disease}"