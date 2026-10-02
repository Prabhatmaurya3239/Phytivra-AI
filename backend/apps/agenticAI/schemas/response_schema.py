"""
Pydantic / DRF schemas for Agentic AI module.
Ensures strict contract adherence for both Backend and Flutter consumption.
"""

from typing import List, Optional, Dict, Any
from dataclasses import dataclass, asdict


@dataclass
class CropInfo:
    id: Optional[Any] = None
    name: str = ""


@dataclass
class DiseaseInfo:
    id: Optional[Any] = None
    name: str = ""


@dataclass
class MLResult:
    crop: Optional[CropInfo] = None
    disease: Optional[DiseaseInfo] = None
    confidence: float = 0.0


@dataclass
class QuestionItem:
    id: str
    question: str
    type: str = "text"
    required: bool = True


@dataclass
class UserAnswer:
    question_id: str
    answer: str


@dataclass
class PesticideRecommendationItem:
    id: Any
    name: str
    company: str
    purpose: str
    source_id: str


@dataclass
class RecommendationDetails:
    summary: str
    pesticides: List[PesticideRecommendationItem]


@dataclass
class SourceItem:
    source_id: str
    source_type: str


@dataclass
class StandardRecommendationResponse:
    success: bool
    status: str
    diagnosis: Dict[str, Any]
    recommendation: RecommendationDetails
    precautions: List[str]
    sources: List[SourceItem]

    def to_dict(self):
        return {
            "success": self.success,
            "status": self.status,
            "diagnosis": self.diagnosis,
            "recommendation": {
                "summary": self.recommendation.summary,
                "pesticides": [asdict(p) for p in self.recommendation.pesticides]
            },
            "precautions": self.precautions,
            "sources": [asdict(s) for s in self.sources]
        }


@dataclass
class FollowUpQuestionResponse:
    success: bool
    status: str
    prediction_id: str
    questions: List[QuestionItem]

    def to_dict(self):
        return {
            "success": self.success,
            "status": self.status,
            "prediction_id": self.prediction_id,
            "questions": [asdict(q) for q in self.questions]
        }


@dataclass
class UnavailableInfoResponse:
    verified_information_available: bool = False
    message: str = "Verified information is not available for this case."
    success: bool = False
    status: str = "unverified"

    def to_dict(self):
        return {
            "success": self.success,
            "status": self.status,
            "verified_information_available": self.verified_information_available,
            "message": self.message
        }
