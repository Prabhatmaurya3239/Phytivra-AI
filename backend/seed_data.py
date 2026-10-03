"""
Database Seeder Script
Reads 'docs/pesticide knowledge base v1.xlsx' and populates the real Django database:
- apps.crops.models.Crop
- apps.pesticides.models.Pesticide
- apps.disease.models.Disease
- apps.recommendations.models.Recommendation
Replaces all dummy data with real, verified agricultural data.
"""

import os
import sys
import django
from pathlib import Path
from datetime import datetime

# Setup Django environment
BACKEND_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BACKEND_DIR))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from apps.crops.models import Crop
from apps.pesticides.models import Pesticide
from apps.disease.models import Disease
from apps.recommendations.models import Recommendation
from apps.agenticAI.data.kb_loader import get_standardized_kb

# Scientific names and descriptions for crops in the knowledge base
CROP_METADATA = {
    "Wheat": {
        "scientific_name": "Triticum aestivum",
        "description": "Wheat is a major cereal grain cultivated worldwide, primarily grown in the Rabi season across North India."
    },
    "Rice (Paddy)": {
        "scientific_name": "Oryza sativa",
        "description": "Rice is the primary staple food crop in India, extensively cultivated under lowland and irrigated conditions."
    },
    "Sugarcane": {
        "scientific_name": "Saccharum officinarum",
        "description": "Sugarcane is an important commercial cash crop used for sugar, jaggery, and bio-ethanol production."
    },
    "Mustard": {
        "scientific_name": "Brassica juncea",
        "description": "Mustard is an essential Rabi oilseed crop widely cultivated across North and Central India."
    },
    "Cotton": {
        "scientific_name": "Gossypium hirsutum",
        "description": "Cotton is the leading fiber cash crop in India, providing raw material for the textile industry."
    },
    "Tomato": {
        "scientific_name": "Solanum lycopersicum",
        "description": "Tomato is a vital vegetable crop grown widely across tropical and subtropical regions."
    },
    "Potato": {
        "scientific_name": "Solanum tuberosum",
        "description": "Potato is a major tuber food crop cultivated during the winter season in Indo-Gangetic plains."
    },
    "Onion": {
        "scientific_name": "Allium cepa",
        "description": "Onion is an indispensable commercial bulb vegetable crop grown across multiple crop seasons."
    },
    "Chili": {
        "scientific_name": "Capsicum annuum",
        "description": "Chili is an important spice and cash crop widely valued for pungency and oleoresin extraction."
    },
    "Brinjal (Eggplant)": {
        "scientific_name": "Solanum melongena",
        "description": "Brinjal is an important vegetable crop in India, consumed widely and cultivated year-round."
    },
    "Cauliflower & Cabbage": {
        "scientific_name": "Brassica oleracea",
        "description": "Cole crops cultivated widely for fresh market vegetable supply during autumn and winter."
    },
    "Mango": {
        "scientific_name": "Mangifera indica",
        "description": "Known as the King of Fruits, mango is India's premier horticultural fruit crop."
    },
    "Citrus (Kinnow / Mandarin)": {
        "scientific_name": "Citrus reticulata",
        "description": "Kinnow mandarin is a high-yielding citrus hybrid widely grown in Punjab, Haryana, and Rajasthan."
    },
    "Guava": {
        "scientific_name": "Psidium guajava",
        "description": "Guava is a hardy and prolific tropical fruit crop rich in Vitamin C and dietary fiber."
    },
    "Rose (Ornamental)": {
        "scientific_name": "Rosa indica",
        "description": "Rose is a premier commercial floriculture and ornamental flowering shrub."
    }
}


def parse_date(date_str):
    if not date_str:
        return None
    try:
        return datetime.strptime(date_str.strip(), "%Y-%m-%d").date()
    except Exception:
        return None


import re

def sanitize_url(val):
    if not val:
        return ""
    match = re.search(r"https?://[^\s]+", val)
    if match:
        return match.group(0).rstrip(";,./")
    return ""

def clean_first_name(product_names):
    """Extracts the first primary brand name for concise identification."""
    if not product_names:
        return "Generic"
    parts = product_names.split("/")
    return parts[0].strip()


def seed():
    print("=" * 60)
    print("SEEDING REAL PESTICIDE DATA FROM KNOWLEDGE BASE")
    print("=" * 60)

    kb_data = get_standardized_kb()
    pesticides_list = kb_data.get("pesticides", [])
    print(f"Loaded {len(pesticides_list)} records from 'pesticide knowledge base v1.xlsx'.\n")

    pesticides_created = 0
    crops_created = 0
    diseases_created = 0
    recommendations_created = 0

    for item in pesticides_list:
        pid = item["pesticide_id"]
        crop_raw = item["target_crops"]
        crop_clean_name = crop_raw.split("(")[0].strip()
        product_full = item["product_name"]
        first_brand = clean_first_name(product_full)
        company_full = item["company_manufacturer"]
        first_company = clean_first_name(company_full)

        # Ensure (name, company_name) uniqueness if same brand is used for multiple crops
        p_name = first_brand
        existing_dup = Pesticide.objects.filter(name=p_name, company_name=first_company).exclude(pesticide_id=pid).first()
        if existing_dup:
            p_name = f"{first_brand} ({crop_clean_name})"

        # 1. Create or update Pesticide in DB
        pesticide_defaults = {
            "name": p_name,
            "company_name": first_company,
            "product_name": product_full,
            "company_manufacturer": company_full,
            "active_ingredients": item.get("active_ingredients", ""),
            "formulation": item.get("formulation", ""),
            "pesticide_type": item.get("pesticide_type", ""),
            "target_crops": crop_raw,
            "target_disease_pest": item.get("target_disease_pest", ""),
            "purpose": item.get("purpose", ""),
            "application_method": item.get("application_method", ""),
            "dosage_rate": item.get("dosage_rate", ""),
            "dosage": item.get("dosage_rate", ""),
            "water_volume_information": item.get("water_volume_information", ""),
            "crop_stage": item.get("crop_stage", ""),
            "safety_precautions": item.get("safety_precautions", ""),
            "precautions": item.get("safety_precautions", ""),
            "packaging": item.get("packaging", ""),
            "packing_size": item.get("packaging", ""),
            "description": f"{item.get('purpose', '')}. Formulated as {item.get('formulation', '')}.",
            "source_url": sanitize_url(item.get("source", {}).get("reference", "")),
            "source_type": item.get("source", {}).get("source_type", "official"),
            "last_verified_date": parse_date(item.get("last_verified_date")),
            "notes": f"{item.get('agronomic_notes', '')} Ref: {item.get('source', {}).get('reference', '')}".strip(),
            "availability": True,
        }

        pesticide_obj, created_p = Pesticide.objects.update_or_create(
            pesticide_id=pid,
            defaults=pesticide_defaults
        )
        if created_p:
            pesticides_created += 1

        # 2. Create or find Crop in DB
        crop_clean_name = crop_raw.split("(")[0].strip()
        meta = CROP_METADATA.get(crop_raw, CROP_METADATA.get(crop_clean_name, {
            "scientific_name": f"{crop_clean_name} spp.",
            "description": f"{crop_clean_name} crop cultivated under Indian agro-climatic conditions."
        }))

        crop_obj = Crop.objects.filter(name__iexact=crop_clean_name).first()
        if not crop_obj:
            crop_obj = Crop.objects.filter(scientific_name__iexact=meta["scientific_name"]).first()

        created_c = False
        if not crop_obj:
            crop_obj = Crop.objects.create(
                name=crop_clean_name,
                scientific_name=meta["scientific_name"],
                description=meta["description"]
            )
            created_c = True
        else:
            # Update description if empty
            if not crop_obj.description:
                crop_obj.description = meta["description"]
                crop_obj.save()

        if created_c:
            crops_created += 1

        # 3. Create or find Disease for this Crop
        raw_diseases = item.get("target_disease_pest", "")
        primary_disease = raw_diseases.split("(")[0].split(",")[0].strip()

        disease_obj = Disease.objects.filter(crop=crop_obj, name__iexact=primary_disease).first()
        created_d = False
        if not disease_obj:
            disease_obj = Disease.objects.create(
                crop=crop_obj,
                name=primary_disease,
                symptoms=f"Symptoms associated with {raw_diseases}. Monitored under standard agricultural disease scout protocols.",
                causes=f"Pathogenic or insect vector origin affecting {crop_clean_name}.",
                description=f"Target disease/pest: {raw_diseases}. {item.get('purpose', '')}",
                severity="Medium",
            )
            created_d = True

        if created_d:
            diseases_created += 1

        disease_obj.recommended_pesticides.add(pesticide_obj)

        # 4. Create Recommendation linking Disease and Pesticide
        rec_obj, created_r = Recommendation.objects.update_or_create(
            disease=disease_obj,
            pesticide=pesticide_obj,
            defaults={
                "dosage": item.get("dosage_rate", ""),
                "notes": f"{item.get('agronomic_notes', '')} {item.get('purpose', '')}".strip()
            }
        )
        if created_r:
            recommendations_created += 1

        print(f"[*] [{pid}] {crop_clean_name:<12} | {primary_disease:<22} | {first_brand}")

    print("\n" + "=" * 60)
    print("SEEDING SUMMARY:")
    print(f"  Pesticides in DB:     {Pesticide.objects.count()} (New: {pesticides_created})")
    print(f"  Crops in DB:          {Crop.objects.count()} (New: {crops_created})")
    print(f"  Diseases in DB:       {Disease.objects.count()} (New: {diseases_created})")
    print(f"  Recommendations in DB: {Recommendation.objects.count()} (New: {recommendations_created})")
    print("=" * 60)


if __name__ == "__main__":
    seed()
