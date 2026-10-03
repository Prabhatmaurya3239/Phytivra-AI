from django.conf import settings


def get_confidence_threshold():
    return getattr(
        settings,
        "ML_CONFIDENCE_THRESHOLD",
        0.70
    )