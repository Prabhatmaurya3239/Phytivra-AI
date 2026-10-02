"""
Database Cleanup Script
Removes all old/dummy data that was present before the new dataset seeding.
Leaves ONLY the verified records from 'docs/pesticide knowledge base v1.xlsx'.
"""

import os
import sys
import django
from pathlib import Path

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

# The 15 verified IDs
VERIFIED_P_IDS = [f"P{i:03d}" for i in range(1, 16)]


def cleanup():
    print("=" * 60)
    print("REMOVING OLD / DUMMY DATA FROM DATABASE")
    print("=" * 60)

    # 1. Identify old pesticides (not in P001-P015)
    old_pesticides = Pesticide.objects.exclude(pesticide_id__in=VERIFIED_P_IDS)
    old_p_count = old_pesticides.count()
    old_p_names = list(old_pesticides.values_list("name", "company_name"))
    print(f"Found {old_p_count} old/dummy pesticides:")
    for name, comp in old_p_names:
        print(f"  - {name} ({comp})")

    # 2. Get list of verified crop names from kb
    kb_data = get_standardized_kb()
    verified_crops = set()
    for item in kb_data.get("pesticides", []):
        c_name = item["target_crops"].split("(")[0].strip()
        verified_crops.add(c_name.lower())

    old_crops = Crop.objects.exclude(name__iregex=r"^(" + "|".join([c for c in verified_crops]) + r")$")
    old_c_count = old_crops.count()
    old_c_names = list(old_crops.values_list("name", flat=True))
    print(f"\nFound {old_c_count} old/dummy crops:")
    for name in old_c_names:
        print(f"  - {name}")

    # 3. Clean up recommendations associated with old items
    old_recs = Recommendation.objects.filter(pesticide__in=old_pesticides)
    old_r_count = old_recs.count()
    old_recs.delete()
    print(f"\nDeleted {old_r_count} old recommendations linked to dummy pesticides.")

    # 4. Clean up old diseases associated with old crops or without verified pesticides
    old_diseases = Disease.objects.filter(crop__in=old_crops)
    old_d_count = old_diseases.count()
    old_diseases.delete()
    print(f"Deleted {old_d_count} old diseases linked to dummy crops.")

    # 5. Delete old crops and old pesticides
    old_crops.delete()
    print(f"Deleted {old_c_count} old crops.")

    old_pesticides.delete()
    print(f"Deleted {old_p_count} old pesticides.")

    # 6. Verify final clean counts
    print("\n" + "=" * 60)
    print("CLEANUP COMPLETED - CURRENT DATABASE COUNTS:")
    print(f"  Verified Pesticides (P001-P015): {Pesticide.objects.count()}")
    print(f"  Verified Crops:                  {Crop.objects.count()}")
    print(f"  Verified Diseases:               {Disease.objects.count()}")
    print(f"  Verified Recommendations:        {Recommendation.objects.count()}")
    print("=" * 60)


if __name__ == "__main__":
    cleanup()
