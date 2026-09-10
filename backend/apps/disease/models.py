from django.db import models
from apps.crops.models import Crop
from apps.pesticides.models import Pesticide
from django.core.validators import MinLengthValidator

class Disease(models.Model):

    SEVERITY_CHOICES = [
        ('Low', 'Low'),
        ('Medium', 'Medium'),
        ('High', 'High'),
    ]

    crop = models.ForeignKey(
        Crop,
        on_delete=models.CASCADE,
        related_name='diseases',
        db_index=True
    )

    name = models.CharField(
        max_length=150,
        validators=[
            MinLengthValidator(2)]
    )
    symptoms = models.TextField()
    causes = models.TextField()
    description = models.TextField()

    severity = models.CharField(
        max_length=10,
        choices=SEVERITY_CHOICES,
        db_index=True
    )

    image = models.ImageField(
        upload_to='disease_images/',
        blank=True,
        null=True
    )
    recommended_pesticides = models.ManyToManyField(
    Pesticide,
    related_name="diseases",
    blank=True
    )
    class Meta:

        ordering = ["name"]

        constraints = [
            models.UniqueConstraint(
                fields=["crop", "name"],
                name="unique_disease_per_crop"
            )
        ]

        indexes = [
            models.Index(
                fields=["crop", "name"]
            ),
            models.Index(
                fields=["crop", "severity"]
            ),
        ]
    def __str__(self):
        return f"{self.crop.name} - {self.name}"