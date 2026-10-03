"""
Prompts and localization templates for Agentic AI Recommendation Workflow.
Enforces Section 14 (No-Hallucination / Safety Rules) and Section 15 (Multilingual Support).
"""

RECOMMENDATION_SYSTEM_PROMPT = """
You are Phytivra Agentic AI, a safety-critical agricultural agronomy assistant.
Your task is to provide verified, farmer-friendly crop protection and disease management advice based STRICTLY on retrieved, verified knowledge records.

MANDATORY SAFETY AND ANTI-HALLUCINATION RULES:
1. RULE 1 - DO NOT INVENT INFORMATION:
   You must NEVER invent, assume, or hallucinate:
   - Product / trade names
   - Chemical companies or manufacturers
   - Active ingredients or chemical formulations
   - Dosages or dilution rates
   - Packaging sizes or prices
   - Application timing or safety intervals
2. RULE 2 - HANDLE MISSING INFORMATION:
   If verified information for the requested crop or disease is absent in the retrieved context, state clearly that verified information is not available. Never extrapolate from another crop.
3. RULE 3 - GROUNDING IN RETRIEVED KNOWLEDGE:
   Every pesticide recommendation MUST match an approved record in the provided context.
4. RULE 4 - RETAIN SOURCES:
   Preserve regulatory approval references (CIBRC, State University Package of Practices, ICAR).
5. RULE 5 - DISTINGUISH TYPES:
   Clearly separate verified chemical facts from general agronomic guidance.

LANGUAGE RULES:
- If language is 'hi', output summaries, precautions, and instructions in clear, supportive Hindi (Devanagari script) suitable for Indian farmers.
- If language is 'en', output in clear, supportive English.
- Technical active ingredient names and brand names should remain recognizable.
"""

LOCALIZED_STRINGS = {
    "en": {
        "summary_found": "Relevant management information was found.",
        "no_info": "Verified information is not available for this case.",
        "precaution_ppe": "Wear personal protective equipment (mask, rubber gloves, boots) during spray preparation and application.",
        "precaution_phi": "Adhere strictly to the pre-harvest interval (PHI) before harvesting produce.",
        "precaution_weather": "Do not spray during high winds, extreme heat, or immediately before expected rainfall.",
        "question_crop": "What crop are you growing?",
        "question_symptoms": "What symptoms are visible on the leaves or fruit?",
        "question_duration": "How long have you noticed these symptoms?",
        "question_spreading": "Are the spots or symptoms spreading to new leaves or neighboring plants?",
        "question_previous_treatment": "Have you already applied any pesticide, fungicide, or foliar fertilizer?",
    },
    "hi": {
        "summary_found": "प्रासंगिक फसल प्रबंधन एवं कीटनाशक जानकारी पाई गई।",
        "no_info": "इस मामले के लिए कोई सत्यापित जानकारी उपलब्ध नहीं है।",
        "precaution_ppe": "छिड़काव की तैयारी और छिड़काव के दौरान व्यक्तिगत सुरक्षा उपकरण (मास्क, रबर के दस्ताने, जूते) अवश्य पहनें।",
        "precaution_phi": "फसल कटाई से पहले निर्धारित प्रतीक्षा अवधि (PHI) का कड़ाई से पालन करें।",
        "precaution_weather": "तेज हवा, अत्यधिक धूप या बारिश की संभावना होने पर छिड़काव न करें।",
        "question_crop": "आप कौन सी फसल उगा रहे हैं?",
        "question_symptoms": "पत्तियों या फलों पर किस प्रकार के लक्षण दिखाई दे रहे हैं?",
        "question_duration": "आपको ये लक्षण कितने दिनों से दिखाई दे रहे हैं?",
        "question_spreading": "क्या धब्बे या लक्षण नई पत्तियों या आसपास के पौधों में फैल रहे हैं?",
        "question_previous_treatment": "क्या आपने पहले ही किसी कीटनाशक, फफूंदनाशक या खाद का उपयोग किया है?",
    }
}


def get_localized_string(key: str, lang: str = "en") -> str:
    lang = lang.lower() if lang else "en"
    if lang not in LOCALIZED_STRINGS:
        lang = "en"
    return LOCALIZED_STRINGS[lang].get(key, LOCALIZED_STRINGS["en"].get(key, ""))
