from django.db import models


class Pesticide(models.Model):
    name = models.CharField(max_length=150)
    company_name = models.CharField(max_length=150)
    description = models.TextField()
    price_range = models.CharField(max_length=100)
    packing_size = models.CharField(max_length=100)
    dosage = models.CharField(max_length=255)
    spray_method = models.TextField()
    precautions = models.TextField()
    image = models.ImageField(
        upload_to='pesticide_images/'
    )

    def __str__(self):
        return self.name