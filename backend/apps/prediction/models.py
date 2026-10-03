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
class PredictionStatus(models.TextChoices):
    PROCESSING = "processing", "Processing"
    COMPLETED = "completed", "Completed"
    NEEDS_QUESTIONS = "needs_questions", "Needs Questions"
    FAILED = "failed", "Failed"
    # Legacy choices for backward compatibility with existing records
    SUCCESS = "success", "Success"
    PENDING = "pending", "Pending"


class Prediction(models.Model):

    STATUS_CHOICES = PredictionStatus.choices

    image = models.ForeignKey(
        LeafImage,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="predictions"
    )

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
        default=PredictionStatus.PROCESSING
    )

    model_name = models.CharField(
        max_length=100,
        blank=True,
        null=True
    )

    model_version = models.CharField(
        max_length=50,
        blank=True,
        null=True
    )

    error_message = models.TextField(
        blank=True,
        null=True
    )

    user_note = models.TextField(
        blank=True,
        null=True
    )

    language = models.CharField(
        max_length=10,
        default="en"
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    @property
    def prediction_id(self):
        return f"pred_{self.id:06d}"

    @classmethod
    def get_by_prediction_id(cls, pred_id):
        if not pred_id:
            return None
        try:
            if isinstance(pred_id, str) and pred_id.startswith("pred_"):
                raw_id = int(pred_id.replace("pred_", ""))
            else:
                raw_id = int(pred_id)
            return cls.objects.filter(id=raw_id).first()
        except (ValueError, TypeError):
            return None

    def __str__(self):
        return f"{self.prediction_id}: {self.crop or 'Unknown'} - {self.disease or 'Unknown'} ({self.status})"