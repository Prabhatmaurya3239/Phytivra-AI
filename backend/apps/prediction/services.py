from .config import get_confidence_threshold


def process_prediction(
    crop,
    disease,
    confidence,
    status
):
    """
    Decide the next step based on ML confidence.
    """

    threshold = get_confidence_threshold()

    # -----------------------------------------
    # Failed prediction
    # -----------------------------------------

    if status == "failed":

        return {
            "status": "failed",
            "workflow": "follow_up",
            "crop": crop,
            "disease": disease,
            "confidence": confidence,
            "threshold": threshold,
            "next_step": "follow_up_questions"
        }

    # -----------------------------------------
    # High confidence
    # -----------------------------------------

    if confidence >= threshold:

        return {
            "status": "success",
            "workflow": "direct_recommendation",
            "crop": crop,
            "disease": disease,
            "confidence": confidence,
            "threshold": threshold,
            "next_step": "recommendation"
        }

    # -----------------------------------------
    # Low confidence
    # -----------------------------------------

    return {
        "status": "low_confidence",
        "workflow": "agentic_ai",
        "crop": crop,
        "disease": disease,
        "confidence": confidence,
        "threshold": threshold,
        "next_step": "follow_up_questions"
    }