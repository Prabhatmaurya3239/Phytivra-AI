"""
Follow-Up Question Service
Implements Section 5 & 6 of Task 3:
- Generates targeted, farmer-friendly follow-up questions when ML confidence is low.
- Limits questions to the necessary context (crop confirmation, symptoms, duration, previous treatments).
- Supports English and Hindi localization.
"""

from typing import List, Dict, Any
from apps.agenticAI.schemas.response_schema import QuestionItem
from apps.agenticAI.prompts.recommendation_prompt import get_localized_string


class QuestionService:
    @staticmethod
    def generate_follow_up_questions(
        crop_name: str = "",
        disease_name: str = "",
        user_context: Dict[str, Any] = None,
        language: str = "en"
    ) -> List[QuestionItem]:
        """
        Generates context-aware follow-up questions for low-confidence ML diagnoses.
        Avoids redundant questions if information is already specified in user_context.
        """
        user_context = user_context or {}
        note = user_context.get("note", "").lower()
        questions = []

        # Question 1: Crop confirmation if missing or uncertain
        if not crop_name or crop_name.lower() in ["unknown", "none", ""]:
            questions.append(
                QuestionItem(
                    id="q1",
                    question=get_localized_string("question_crop", language),
                    type="text",
                    required=True
                )
            )

        # Question 2: Symptoms description (if not already detailed in note)
        if not note or len(note) < 5:
            questions.append(
                QuestionItem(
                    id="q2",
                    question=get_localized_string("question_symptoms", language),
                    type="text",
                    required=True
                )
            )

        # Question 3: Symptom duration (vital for determining disease stage)
        questions.append(
            QuestionItem(
                id="q3",
                question=get_localized_string("question_duration", language),
                type="text",
                required=True
            )
        )

        # Question 4: Spreading check
        questions.append(
            QuestionItem(
                id="q4",
                question=get_localized_string("question_spreading", language),
                type="text",
                required=False
            )
        )

        # Question 5: Previous treatments check
        questions.append(
            QuestionItem(
                id="q5",
                question=get_localized_string("question_previous_treatment", language),
                type="text",
                required=False
            )
        )

        # Limit to top 2-3 essential questions to keep it farmer-friendly and not overwhelming
        return questions[:3]
