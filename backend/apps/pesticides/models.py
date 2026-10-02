from django.db import models
from django.core.validators import MinLengthValidator


class Pesticide(models.Model):
    name = models.CharField(
        max_length=150,
        db_index=True,
        validators=[MinLengthValidator(2)],
        blank=True,
        default=""
    )
    company_name = models.CharField(
        max_length=150,
        db_index=True,
        blank=True,
        default=""
    )
    description = models.TextField(blank=True, default="")
    price_range = models.CharField(max_length=100, blank=True, default="")
    packing_size = models.CharField(max_length=100, blank=True, default="")
    dosage = models.CharField(max_length=255, blank=True, default="")
    spray_method = models.TextField(blank=True, default="")
    precautions = models.TextField(blank=True, default="")
    image = models.ImageField(
        upload_to='pesticide_images/',
        blank=True,
        null=True
    )
    availability = models.BooleanField(default=True, db_index=True)

    pesticide_id = models.CharField(
        max_length=100,
        unique=True,
        blank=True,
        null=True,
        db_index=True
    )
    product_name = models.CharField(
        max_length=255,
        db_index=True,
        validators=[MinLengthValidator(2)],
        blank=True,
        default=""
    )
    active_ingredients = models.TextField(blank=True, default="")
    formulation = models.CharField(max_length=255, blank=True, default="")
    pesticide_type = models.CharField(max_length=100, blank=True, default="")
    company_manufacturer = models.CharField(
        max_length=255,
        db_index=True,
        blank=True,
        default=""
    )
    target_crops = models.TextField(blank=True, default="")
    target_disease_pest = models.TextField(blank=True, default="")
    purpose = models.TextField(blank=True, default="")
    application_method = models.TextField(blank=True, default="")
    dosage_rate = models.TextField(blank=True, default="")
    water_volume_information = models.TextField(blank=True, default="")
    crop_stage = models.CharField(max_length=255, blank=True, default="")
    safety_precautions = models.TextField(blank=True, default="")
    packaging = models.CharField(max_length=255, blank=True, default="")
    price_information = models.CharField(max_length=255, blank=True, default="")
    product_image_url_reference = models.URLField(max_length=500, blank=True, default="")
    source_url = models.URLField(max_length=500, blank=True, default="")
    source_type = models.CharField(max_length=100, blank=True, default="")
    last_verified_date = models.DateField(blank=True, null=True)
    notes = models.TextField(blank=True, default="")

    class Meta:
        ordering = ["product_name", "name"]
        constraints = [
            models.UniqueConstraint(
                fields=["name", "company_name"],
                name="unique_pesticide_name_company",
            )
        ]
        indexes = [
            models.Index(fields=["name", "company_name"]),
            models.Index(fields=["product_name", "company_manufacturer"]),
        ]

    def clean(self):
        super().clean()
        self.name = (self.name or '').strip()
        self.company_name = (self.company_name or '').strip()
        self.product_name = (self.product_name or '').strip()
        self.company_manufacturer = (self.company_manufacturer or '').strip()

    def save(self, *args, **kwargs):
        self.full_clean()
        self.name = (self.name or '').strip()
        self.company_name = (self.company_name or '').strip()
        self.product_name = (self.product_name or '').strip()
        self.company_manufacturer = (self.company_manufacturer or '').strip()
        super().save(*args, **kwargs)

    def __str__(self):
        return self.product_name or self.name or self.pesticide_id or "Pesticide"