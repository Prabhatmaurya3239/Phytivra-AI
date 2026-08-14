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
