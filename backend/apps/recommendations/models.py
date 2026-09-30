from django.db import models


# ------------------ Crop Model ------------------

class Crop(models.Model):
    name = models.CharField(max_length=100)
    scientific_name = models.CharField(max_length=150)
    description = models.TextField()
    image = models.ImageField(upload_to='crop_images/')

    def __str__(self):
        return self.name


# ------------------ Pesticide Model ------------------

class Pesticide(models.Model):
    name = models.CharField(max_length=150)
    company_name = models.CharField(max_length=150)
    description = models.TextField()

    price_range = models.CharField(max_length=100)
    packing_size = models.CharField(max_length=100)

    dosage = models.CharField(max_length=255)
    spray_method = models.TextField()
    precautions = models.TextField()

    image = models.ImageField(upload_to='pesticide_images/')

    def __str__(self):
        return self.name


# ------------------ Disease Model ------------------

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

    image = models.ImageField(upload_to='disease_images/')

    # One Disease → Many Pesticides
    recommended_pesticides = models.ManyToManyField(
        Pesticide,
        related_name='diseases',
        blank=True
    )

    def __str__(self):
        return f"{self.crop.name} - {self.name}"