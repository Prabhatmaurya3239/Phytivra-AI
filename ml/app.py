"""
Phytivra-AI Machine Learning & Agentic AI Inference Service
Built with FastAPI.
Implements the finalized ML & Agentic AI API contract with realistic fallbacks,
confidence gating, and mock inference for end-to-end integration.
"""

import os
from typing import List, Optional, Union, Dict, Any
from fastapi import FastAPI, File, UploadFile, Form, Query, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI(
    title="Phytivra ML & Agentic AI Service",
    description="Microservice providing real/fallback inference for ML prediction and Agentic AI reasoning.",
    version="1.0.0",
)

# Enable CORS for Flutter web and local frontends
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------

class CropSchema(BaseModel):
    id: Optional[int] = 1
    name: Optional[str] = "Tomato"


class DiseaseSchema(BaseModel):
    id: Optional[int] = 1
    name: Optional[str] = "Early Blight"
    severity: Optional[str] = "Medium"


class ModelMetadataSchema(BaseModel):
    name: str = "Phytivra-ML-FastAPI"
    version: str = "1.0.0"


class PredictionDataSchema(BaseModel):
    crop: CropSchema
    disease: DiseaseSchema
    confidence: float = Field(..., ge=0.0, le=1.0)


class MLResponseSchema(BaseModel):
    success: bool = True
    prediction_id: str
    prediction: PredictionDataSchema
    model: ModelMetadataSchema


class QuestionItemSchema(BaseModel):
    id: str
    question: str
    type: str = "text"
    options: List[str] = []
    required: bool = True


class FollowUpRequestSchema(BaseModel):
    prediction_id: str
    language: str = "en"
    ml_result: Optional[Dict[str, Any]] = None
    user_context: Optional[Dict[str, Any]] = None


class FollowUpResponseSchema(BaseModel):
    success: bool = True
    status: str = "needs_questions"
    prediction_id: str
    questions: List[QuestionItemSchema]


class UserAnswerItem(BaseModel):
    question_id: str
    answer: Union[str, int, float, bool, List[str]]


class RecommendationRequestSchema(BaseModel):
    prediction_id: str
    language: str = "en"
    answers: Union[List[UserAnswerItem], Dict[str, Any]]
    ml_result: Optional[Dict[str, Any]] = None


# ---------------------------------------------------------------------------
# Knowledge Base Fallback Data (Based on Task 2 & 3 research)
# ---------------------------------------------------------------------------

DEFAULT_QUESTIONS_EN = [
    QuestionItemSchema(
        id="q1",
        question="What specific symptoms do you observe on the plant leaves or stems?",
        type="text",
        required=True,
    ),
    QuestionItemSchema(
        id="q2",
        question="Which part of the plant is predominantly affected?",
        type="single_choice",
        options=["Older leaves", "New leaves", "Fruit", "Stem", "Whole plant"],
        required=True,
    ),
    QuestionItemSchema(
        id="q3",
        question="How long have you noticed these symptoms in your field?",
        type="single_choice",
        options=["Within the last 3 days", "Within the past week", "More than a week ago"],
        required=True,
    ),
    QuestionItemSchema(
        id="q4",
        question="Are the spots spreading to neighboring plants or new leaves?",
        type="boolean",
        required=False,
    ),
]

DEFAULT_QUESTIONS_HI = [
    QuestionItemSchema(
        id="q1",
        question="पौधे की पत्तियों या तनों पर आपको क्या विशिष्ट लक्षण दिखाई दे रहे हैं?",
        type="text",
        required=True,
    ),
    QuestionItemSchema(
        id="q2",
        question="पौधे का कौन सा भाग मुख्य रूप से प्रभावित है?",
        type="single_choice",
        options=["पुरानी पत्तियां", "नई पत्तियां", "फल", "तना", "पूरा पौधा"],
        required=True,
    ),
    QuestionItemSchema(
        id="q3",
        question="आप कितने समय से इन लक्षणों को देख रहे हैं?",
        type="single_choice",
        options=["पिछले 3 दिनों से", "पिछले 1 सप्ताह से", "1 सप्ताह से अधिक समय से"],
        required=True,
    ),
    QuestionItemSchema(
        id="q4",
        question="क्या ये धब्बे नई पत्तियों या आस-पास के पौधों में भी फैल रहे हैं?",
        type="boolean",
        required=False,
    ),
]

PESTICIDE_KNOWLEDGE_BASE = {
    "early_blight": {
        "crop": {"id": 1, "name": "Tomato"},
        "disease": {"id": 1, "name": "Early Blight", "severity": "Medium"},
        "pesticides": [
            {
                "id": 1,
                "name": "Saaf / Companion (Mancozeb 63% + Carbendazim 12% WP)",
                "company_name": "UPL Ltd. / Indofil",
                "active_ingredient": "Mancozeb 63% + Carbendazim 12% WP",
                "description": "Broad spectrum contact and systemic fungicide highly effective against leaf spots and blights.",
                "dosage": "1.5 to 2.0 grams per liter of water",
                "spray_method": "Foliar spray ensuring thorough coverage of upper and lower leaf surfaces.",
                "packing_size": "250g, 500g, 1kg",
                "price_range": "₹380 - ₹480 per 500g",
                "precautions": "Wear mask and gloves during preparation. Do not harvest within 7 days of application.",
                "source_url": "https://cibrc.gov.in",
                "source_type": "government",
            },
            {
                "id": 2,
                "name": "Amistar Top (Azoxystrobin 18.2% + Difenoconazole 11.4% SC)",
                "company_name": "Syngenta India Ltd.",
                "active_ingredient": "Azoxystrobin + Difenoconazole",
                "description": "Dual action systemic fungicide for preventative and curative disease control.",
                "dosage": "1 ml per liter of water",
                "spray_method": "High-volume foliar spray at early onset of disease.",
                "packing_size": "200ml, 500ml, 1L",
                "price_range": "Verify current local market price",
                "precautions": "Rotate with other fungicide modes of action to prevent fungal resistance.",
                "source_url": "https://www.syngenta.co.in",
                "source_type": "manufacturer",
            }
        ],
        "precautions": [
            "Always wear protective clothing, gloves, and face shield while handling chemicals.",
            "Spray in early morning or late afternoon to minimize bee toxicity and spray drift.",
            "Follow strict post-harvest withholding intervals as printed on product label."
        ],
        "sources": [
            {
                "title": "Central Insecticides Board & Registration Committee (CIBRC) Approved List",
                "url": "https://cibrc.gov.in",
                "source_type": "government",
                "verified": True
            },
            {
                "title": "ICAR-Indian Agricultural Research Institute Crop Protection Guide",
                "url": "https://www.iari.res.in",
                "source_type": "official",
                "verified": True
            }
        ]
    }
}


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.get("/")
def root():
    return {
        "service": "Phytivra-AI ML & Agentic AI Microservice",
        "status": "online",
        "version": "1.0.0",
        "docs_url": "/docs",
        "endpoints": {
            "ml_predict": "POST /predict",
            "agentic_follow_up": "POST /agentic-ai/follow-up",
            "agentic_recommendation": "POST /agentic-ai/recommendation",
            "health": "GET /health",
        },
    }


@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "phytivra-ml", "version": "1.0.0"}


@app.post("/predict", response_model=MLResponseSchema)
async def predict_crop_disease(
    image: Optional[UploadFile] = File(None),
    prediction_id: str = Form("pred_000001"),
    image_url: Optional[str] = Form(None),
    mode: str = Form("high_confidence"), # 'high_confidence', 'low_confidence', 'unknown'
    forced_confidence: Optional[float] = Form(None),
):
    """
    Standard ML prediction endpoint consumed by Django backend and standalone clients.
    Supports high_confidence, low_confidence, and unknown disease scenarios.
    """
    # Decide confidence score
    if forced_confidence is not None:
        conf = max(0.0, min(1.0, float(forced_confidence)))
    elif mode == "low_confidence":
        conf = 0.48
    elif mode == "unknown":
        conf = 0.31
    else:
        conf = 0.92

    # Construct response matching the agreed MLResult contract
    if mode == "unknown" or conf < 0.40:
        crop_data = CropSchema(id=None, name=None)
        disease_data = DiseaseSchema(id=None, name=None, severity="Unknown")
    elif mode == "low_confidence" or conf < 0.70:
        crop_data = CropSchema(id=1, name="Tomato")
        disease_data = DiseaseSchema(id=None, name=None, severity="Unknown")
    else:
        crop_data = CropSchema(id=1, name="Tomato")
        disease_data = DiseaseSchema(id=1, name="Early Blight", severity="Medium")

    return MLResponseSchema(
        success=True,
        prediction_id=prediction_id,
        prediction=PredictionDataSchema(
            crop=crop_data,
            disease=disease_data,
            confidence=conf,
        ),
        model=ModelMetadataSchema(
            name="Phytivra-ML-FastAPI",
            version="1.0.0",
        ),
    )


@app.post("/agentic-ai/follow-up", response_model=FollowUpResponseSchema)
async def get_follow_up_questions(payload: FollowUpRequestSchema):
    """
    Agentic AI fallback service for generating diagnostic questions when ML confidence is low.
    """
    is_hindi = payload.language.lower() == "hi"
    questions = DEFAULT_QUESTIONS_HI if is_hindi else DEFAULT_QUESTIONS_EN

    return FollowUpResponseSchema(
        success=True,
        status="needs_questions",
        prediction_id=payload.prediction_id,
        questions=questions,
    )


@app.post("/agentic-ai/recommendation")
async def generate_recommendation(payload: RecommendationRequestSchema):
    """
    Agentic AI fallback service for reconciling user answers and generating verified recommendation.
    """
    is_hindi = payload.language.lower() == "hi"
    kb = PESTICIDE_KNOWLEDGE_BASE["early_blight"]

    summary_text = (
        "टमाटर की अगेती झुलसा (अर्ली ब्लाइट) बीमारी के लक्षण पाए गए हैं। नीचे अनुशंसित कीटनाशक एवं सावधानियां दी गई हैं।"
        if is_hindi
        else "Early Blight has been identified on Tomato. Apply the approved fungicide and preventive cultural practices listed below."
    )

    return {
        "success": True,
        "status": "completed",
        "prediction_id": payload.prediction_id,
        "diagnosis": {
            "crop": kb["crop"],
            "disease": kb["disease"],
            "confidence": 0.88,
            "source": "ml_plus_agentic_reasoning",
        },
        "recommendation": {
            "available": True,
            "summary": summary_text,
            "actions": [
                "Remove and safely burn severely infected lower leaves.",
                "Avoid overhead irrigation to minimize leaf moisture.",
                "Ensure proper row-to-row spacing for cross ventilation."
            ],
            "pesticides": kb["pesticides"],
        },
        "pesticides": kb["pesticides"],
        "precautions": kb["precautions"],
        "sources": kb["sources"],
    }


class VoiceQueryRequest(BaseModel):
    query: str
    language: str = "en"
    crop: Optional[str] = None
    prediction_id: Optional[str] = None


class VoiceQueryResponse(BaseModel):
    success: bool = True
    query: str
    language: str
    detected_crop: Optional[str] = None
    detected_disease: Optional[str] = None
    reply_text: str
    spoken_text: str
    action_items: List[str] = []
    pesticides: List[Dict[str, Any]] = []
    precautions: List[str] = []
    sources: List[Dict[str, Any]] = []


@app.post("/voice/chat", response_model=VoiceQueryResponse)
async def voice_chat_assistant(payload: VoiceQueryRequest):
    """
    Voice-driven agricultural advisor and chatbot.
    Parses symptoms spoken or typed by the farmer and returns structured diagnosis,
    advisory text, audio TTS speech text, and verified pesticide management.
    """
    query_lower = payload.query.lower()
    is_hi = payload.language.lower() == "hi" or any(ord(c) > 128 for c in payload.query)
    lang = "hi" if is_hi else "en"

    kb = PESTICIDE_KNOWLEDGE_BASE["early_blight"]

    # Match common agricultural conditions
    if any(k in query_lower for k in ["yellow", "पील", "blight", "झुलसा", "धब्बे", "spot", "target"]):
        crop = "Tomato"
        disease = "Early Blight"
        reply_en = (
            "Based on the symptoms of yellow spots and concentric leaf markings, your tomato crop is affected by Early Blight (Alternaria solani). "
            "We recommend applying Mancozeb 63% + Carbendazim 12% WP (Saaf) at 2g per liter of water."
        )
        spoken_en = "Your tomato plants show signs of Early Blight. Apply Saaf fungicide at 2 grams per liter, and avoid wetting leaves during watering."
        
        reply_hi = (
            "पत्तियों पर पीले धब्बे और छल्लों के आधार पर आपके टमाटर में अगेती झुलसा (अर्ली ब्लाइट) के लक्षण हैं। "
            "इसके उपचार हेतु साफ (मैनकोजेब 63% + कार्बेन्डाजिम 12% WP) 2 ग्राम प्रति लीटर पानी में मिलाकर छिड़काव करें।"
        )
        spoken_hi = "टमाटर में अगेती झुलसा रोग के लक्षण हैं। साफ फफूंदनाशक 2 ग्राम प्रति लीटर पानी में मिलाकर छिड़कें और सूखी धूप में छिड़काव करें।"

        return VoiceQueryResponse(
            success=True,
            query=payload.query,
            language=lang,
            detected_crop=crop,
            detected_disease=disease,
            reply_text=reply_hi if is_hi else reply_en,
            spoken_text=spoken_hi if is_hi else spoken_en,
            action_items=[
                "पत्तियों के निचले प्रभावित हिस्सों को काटकर नष्ट करें।" if is_hi else "Prune and destroy infected lower foliage.",
                "ड्रिप या जड़ों के पास सिंचाई करें, फव्वारा सिंचाई से बचें।" if is_hi else "Use drip irrigation; avoid overhead watering.",
                "7 से 10 दिनों के अंतराल पर दोबारा छिड़काव करें।" if is_hi else "Repeat foliar spray after 7-10 days if symptoms persist."
            ],
            pesticides=kb["pesticides"],
            precautions=kb["precautions"],
            sources=kb["sources"],
        )

    elif any(k in query_lower for k in ["powder", "white", "सफेद", "चूर्णिल", "mildew"]):
        crop = "Vegetable / Crop"
        disease = "Powdery Mildew"
        reply_en = (
            "White powdery patches on leaves indicate Powdery Mildew. Spray Wettable Sulfur 80% WDG at 2 to 3 grams per liter or Hexaconazole 5% SC at 1 ml per liter."
        )
        spoken_en = "White patches indicate Powdery Mildew. Use Wettable Sulfur 2 grams per liter."
        reply_hi = (
            "पत्तियों पर सफेद पाउडर जैसे धब्बे चूर्णिल आसिता (पाउडरी मिल्ड्यू) रोग का संकेत हैं। इसके लिए घुलनशील गंधक (सल्फर 80% WDG) 2 ग्राम प्रति लीटर पानी में छिड़कें।"
        )
        spoken_hi = "पत्तियों पर सफेद फफूंद के लिए घुलनशील सल्फर का छिड़काव करें।"

        return VoiceQueryResponse(
            success=True,
            query=payload.query,
            language=lang,
            detected_crop=crop,
            detected_disease=disease,
            reply_text=reply_hi if is_hi else reply_en,
            spoken_text=spoken_hi if is_hi else spoken_en,
            action_items=[
                "खेत में हवा का आवागमन सुनिश्चित करें।" if is_hi else "Ensure adequate plant spacing for aeration.",
                "सुबह या शाम के समय छिड़काव करें।" if is_hi else "Apply treatment early morning or late afternoon."
            ],
            pesticides=[
                {
                    "id": 10,
                    "name": "Sulfex / Wettable Sulfur 80% WDG",
                    "company_name": "Excel Crop Care",
                    "active_ingredient": "Sulfur 80% WDG",
                    "dosage": "2-3 grams per liter of water",
                    "spray_method": "Foliar spray",
                    "packing_size": "500g, 1kg",
                    "price_range": "₹150 - ₹220 per 500g",
                    "precautions": "Do not apply during peak afternoon sun or temperature exceeding 35°C.",
                    "source_type": "official",
                    "source_url": "https://cibrc.gov.in"
                }
            ],
            precautions=["Wear eye protection during mixing.", "Do not mix with mineral oil sprays."],
            sources=[{"title": "CIBRC Official Register", "url": "https://cibrc.gov.in", "source_type": "government", "verified": True}]
        )

    else:
        # General agricultural assistance query
        reply_en = (
            f"Thank you for reaching out. We analyzed your query: '{payload.query}'. For precise disease diagnosis, "
            "we recommend uploading a clear close-up photograph of the affected crop leaf using the Camera Scan feature."
        )
        spoken_en = "For accurate diagnosis, please take a clear photo of the leaf using the diagnosis scanner."
        reply_hi = (
            f"आपके प्रश्न '{payload.query}' को प्राप्त किया गया। सटीक रोग पहचान के लिए, कृपया कैमरा स्कैन फीचर का उपयोग करके प्रभावित पत्ती की स्पष्ट फोटो अपलोड करें।"
        )
        spoken_hi = "सटीक जांच के लिए कृपया कैमरे से पत्ती की साफ फोटो खींचकर अपलोड करें।"

        return VoiceQueryResponse(
            success=True,
            query=payload.query,
            language=lang,
            detected_crop=payload.crop or "Field Crop",
            detected_disease="Under Investigation",
            reply_text=reply_hi if is_hi else reply_en,
            spoken_text=spoken_hi if is_hi else spoken_en,
            action_items=[
                "पत्ती की स्पष्ट फोटो लें।" if is_hi else "Take a clear leaf photo in good light.",
                "आस-पास के अन्य पौधों में संक्रमण की जांच करें।" if is_hi else "Check neighboring plants for signs of spread."
            ],
            pesticides=[],
            precautions=["Consult a local agricultural extension officer for unverified symptoms."],
            sources=[{"title": "Kisan Call Centre Advisory", "url": "https://farmer.gov.in", "source_type": "official", "verified": True}]
        )


@app.post("/voice/transcribe")
async def transcribe_voice(
    audio: Optional[UploadFile] = File(None),
    simulated_speech: Optional[str] = Form(None),
    language: str = Form("en"),
):
    """
    Speech-to-text transcription service for farmer voice input.
    """
    if simulated_speech and simulated_speech.strip():
        text = simulated_speech.strip()
    elif language.lower() == "hi":
        text = "टमाटर की पत्तियों पर पीले और भूरे धब्बे दिखाई दे रहे हैं"
    else:
        text = "Yellow and brown concentric spots are visible on tomato leaves"

    return {
        "success": True,
        "transcript": text,
        "language": language,
        "confidence": 0.96,
    }


@app.get("/voice/suggestions")
def get_voice_suggestions(language: str = Query("en")):
    """
    Returns curated, high-frequency voice search prompts for farmers.
    """
    is_hi = language.lower() == "hi"
    if is_hi:
        return {
            "language": "hi",
            "suggestions": [
                "टमाटर की पत्तियों पर पीले धब्बे क्यों हैं?",
                "अर्ली ब्लाइट की सबसे असरदार दवा कौन सी है?",
                "पत्तियों पर सफेद पाउडर जैसा क्या है?",
                "साफ फफूंदनाशक का सही डोज कितना है?",
                "क्या इस दवा के बाद तुरंत फसल तोड़ सकते हैं?"
            ]
        }
    return {
        "language": "en",
        "suggestions": [
            "What causes yellow spots with rings on tomato leaves?",
            "What is the best pesticide for Early Blight?",
            "White powder on leaves treatment",
            "What is the recommended dosage for Saaf fungicide?",
            "How many days to wait before harvesting after spray?"
        ]
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="127.0.0.1", port=8001, reload=True)
