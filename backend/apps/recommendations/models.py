from django.db import models

from apps.disease.models import Disease
from apps.pesticides.models import Pesticide


class Recommendation(models.Model):
    disease = models.ForeignKey(
        Disease,
        on_delete=models.CASCADE,
        related_name='recommendations'
    )

    pesticide = models.ForeignKey(
        Pesticide,
        on_delete=models.CASCADE,
        related_name='recommendations'
    )

    created_at = models.DateTimeField(auto_now_add=True)
    dosage = models.CharField(max_length=255, blank=True)
    notes = models.TextField(blank=True)

    class Meta:
        unique_together = ('disease', 'pesticide')

    def __str__(self):
        return f"{self.disease.name} - {self.pesticide.name}"