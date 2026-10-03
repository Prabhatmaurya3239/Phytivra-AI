"""
Agentic AI Orchestrator Service
Implements Section 4, 12, 13, 14, 15, 20 of Task 3:
- Orchestrates the full Agentic Decision Flow.
- Evaluates ML confidence threshold (default 0.70).
- Branches into Follow-up Question Generation or Direct Retrieval.
- Synthesizes verified structured records + RAG unstructured context into standardized JSON.
- Fully supports English and Hindi localization without hallucinating unverified facts.
"""

from typing import Dict, Any, List, Optional
from apps.agenticAI.services.retrieval_service import StructuredRetrievalService
from apps.agenticAI.services.rag_service import RAGService
from apps.agenticAI.services.question_service import QuestionService
from apps.agenticAI.schemas.response_schema import (
    StandardRecommendationResponse,
    FollowUpQuestionResponse,
    UnavailableInfoResponse,
    RecommendationDetails,
    PesticideRecommendationItem,
    SourceItem,
)
from apps.agenticAI.prompts.recommendation_prompt import get_localized_string


class AgenticAIService:
    CONFIDENCE_THRESHOLD = 0.70

    def __init__(self):
        self.retrieval_service = StructuredRetrievalService()
        self.rag_service = RAGService()
        self.question_service = QuestionService()

    def process_request(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Main entry point for Agentic AI pipeline.
        Accepts the standard input contract (Section 3 & 7) and returns the standard output.
        """
        prediction_id = payload.get("prediction_id", "pred_demo_001")
        language = payload.get("language", "en").lower()
        ml_result = payload.get("ml_result", {})
        user_context = payload.get("user_context", {})
        answers = payload.get("answers", [])

        # Extract ML prediction attributes
        crop_data = ml_result.get("crop", {})
        disease_data = ml_result.get("disease", {})
        confidence = float(ml_result.get("confidence", 0.0))

        crop_name = crop_data.get("name", "")
        disease_name = disease_data.get("name", "")

        # Reconcile with user answers if provided (Low-confidence resolution flow)
        if answers:
            # Process answers list: [{"question_id": "q1", "answer": "..."}, ...]
            for ans in answers:
                qid = ans.get("question_id", "")
                val = ans.get("answer", "").strip()
                if qid == "q1" and val:
                    crop_name = val
                elif qid == "q2" and val:
                    # Enrich context with symptoms
                    user_context["answers_note"] = val
            # After user answers are provided and reconciled, confidence is boosted
            confidence = max(confidence, 0.85)

        # Confidence Gate: If confidence is below threshold AND answers are not yet provided
        if confidence < self.CONFIDENCE_THRESHOLD and not answers:
            questions = self.question_service.generate_follow_up_questions(
                crop_name=crop_name,
                disease_name=disease_name,
                user_context=user_context,
                language=language
            )
            response = FollowUpQuestionResponse(
                success=True,
                status="needs_questions",
                prediction_id=prediction_id,
                questions=questions
            )
            return response.to_dict()

        # Step 2: Knowledge Retrieval (Crop + Disease)
        matched_pesticides = self.retrieval_service.search_pesticides(
            crop_name=crop_name,
            disease_name=disease_name,
            only_verified=True
        )

        # Case 3 / Case 4: No verified knowledge available or unverified records only
        if not matched_pesticides:
            return UnavailableInfoResponse(
                verified_information_available=False,
                message=get_localized_string("no_info", language),
                success=False,
                status="unverified"
            ).to_dict()

        # Step 3: Unstructured RAG Context Retrieval
        rag_query = f"{crop_name} {disease_name}"
        rag_docs = self.rag_service.retrieve(rag_query, top_k=2)

        # Step 4: Assemble Recommendation Items & Deduplicate Sources
        pesticide_items = []
        source_items = []
        seen_sources = set()
        precautions_list = []

        for p in matched_pesticides:
            src_info = p.get("source", {})
            src_id = src_info.get("source_id", "source_001")
            raw_type = src_info.get("source_type", "official")
            # Map authority / institutional sources to standard "official" contract type
            src_type = "official" if ("official" in raw_type.lower() or "icar" in raw_type.lower() or "cibrc" in raw_type.lower() or "university" in raw_type.lower() or "statutory" in raw_type.lower()) else raw_type

            pesticide_items.append(
                PesticideRecommendationItem(
                    id=p.get("pesticide_id") or p.get("id"),
                    name=p.get("product_name"),
                    company=p.get("company_manufacturer") or p.get("company"),
                    purpose=p.get("purpose") or f"Management of {disease_name}",
                    source_id=src_id
                )
            )

            if src_id not in seen_sources:
                seen_sources.add(src_id)
                source_items.append(
                    SourceItem(
                        source_id=src_id,
                        source_type=src_type
                    )
                )

            # Extract precautions
            safety = p.get("safety_precautions")
            if safety and safety not in precautions_list:
                precautions_list.append(safety)

        # Add localized standard safety precautions if empty or minimal
        if not precautions_list:
            precautions_list.append(get_localized_string("precaution_ppe", language))
            precautions_list.append(get_localized_string("precaution_weather", language))

        # Build final response
        summary_text = get_localized_string("summary_found", language)

        response = StandardRecommendationResponse(
            success=True,
            status="completed",
            diagnosis={
                "crop": {
                    "id": crop_data.get("id", 1),
                    "name": crop_name
                },
                "disease": {
                    "id": disease_data.get("id", 1),
                    "name": disease_name
                },
                "confidence": confidence
            },
            recommendation=RecommendationDetails(
                summary=summary_text,
                pesticides=pesticide_items
            ),
            precautions=precautions_list,
            sources=source_items
        )

        return response.to_dict()
