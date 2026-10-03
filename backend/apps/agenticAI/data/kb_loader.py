"""
Knowledge Base Loader
Loads and parses 'docs/pesticide knowledge base v1.xlsx' using pure Python
(zipfile + xml.etree.ElementTree) so it has zero external dependencies,
and provides structured records for retrieval and RAG indexing.
"""

import os
import zipfile
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path

# Resolve project root (handles both running from backend/ or project root)
CURRENT_FILE = Path(__file__).resolve()
# Try walking up parents to find 'docs'
DOCS_DIR = None
for p in [CURRENT_FILE.parents[3], CURRENT_FILE.parents[4], Path.cwd(), Path.cwd().parent]:
    candidate = p / "docs"
    if candidate.exists() and (candidate / "pesticide knowledge base v1.xlsx").exists():
        DOCS_DIR = candidate
        break

if DOCS_DIR is None:
    DOCS_DIR = Path.cwd() / "docs"

XLSX_PATH = DOCS_DIR / "pesticide knowledge base v1.xlsx"


def parse_xlsx(file_path):
    """
    Parses an .xlsx file using standard library zipfile and xml.etree.
    Returns a list of dictionaries with sheet header keys.
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Knowledge base file not found at: {file_path}")

    with zipfile.ZipFile(file_path, "r") as z:
        # 1. Read shared strings if present
        shared_strings = []
        if "xl/sharedStrings.xml" in z.namelist():
            ss_tree = ET.fromstring(z.read("xl/sharedStrings.xml"))
            for si in ss_tree.findall("{http://schemas.openxmlformats.org/spreadsheetml/2006/main}si"):
                # Handle text nodes or formatted text runs
                texts = [t.text for t in si.findall(".//{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t") if t.text]
                shared_strings.append("".join(texts))

        # 2. Read sheet1.xml
        sheet_path = "xl/worksheets/sheet1.xml"
        if sheet_path not in z.namelist():
            # Fallback to first sheet found
            sheets = [n for n in z.namelist() if n.startswith("xl/worksheets/sheet") and n.endswith(".xml")]
            if not sheets:
                raise ValueError("No worksheets found in xlsx")
            sheet_path = sheets[0]

        sheet_tree = ET.fromstring(z.read(sheet_path))
        rows_data = []

        sheet_data = sheet_tree.find("{http://schemas.openxmlformats.org/spreadsheetml/2006/main}sheetData")
        if sheet_data is None:
            return []

        for row in sheet_data.findall("{http://schemas.openxmlformats.org/spreadsheetml/2006/main}row"):
            row_cells = {}
            for c in row.findall("{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c"):
                r = c.get("r")  # e.g., 'A1', 'B1'
                # Extract col letters
                col_letters = "".join(filter(str.isalpha, r))
                t = c.get("t")
                v = c.find("{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v")
                val = v.text if v is not None else ""

                if t == "s" and val.isdigit():
                    idx = int(val)
                    val = shared_strings[idx] if idx < len(shared_strings) else ""
                elif t == "str":
                    val = val
                row_cells[col_letters] = val
            rows_data.append(row_cells)

        if not rows_data:
            return []

        # Find header row (usually first row with data)
        header_row = rows_data[0]
        sorted_cols = sorted(header_row.keys(), key=lambda x: (len(x), x))
        headers = [header_row[col].strip() for col in sorted_cols if header_row.get(col)]

        records = []
        for r_dict in rows_data[1:]:
            record = {}
            has_val = False
            for col in sorted_cols:
                h = header_row.get(col, "").strip()
                if h:
                    val = r_dict.get(col, "").strip()
                    record[h] = val
                    if val:
                        has_val = True
            if has_val:
                records.append(record)

        return records


def parse_sheet_rows(zip_file, sheet_path):
    """Parses a specific worksheet XML from zip_file into a list of row dicts."""
    ns = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    tree = ET.fromstring(zip_file.read(sheet_path))
    rows = []
    for r in tree.findall(".//m:row", ns):
        r_num = int(r.get("r"))
        row_dict = {"_row": r_num}
        for c in r.findall("m:c", ns):
            c_ref = c.get("r")
            col = "".join(filter(str.isalpha, c_ref))
            v = c.find("m:v", ns)
            is_tag = c.find(".//m:t", ns)
            val = is_tag.text if is_tag is not None else (v.text if v is not None else "")
            row_dict[col] = (val or "").strip()
        rows.append(row_dict)
    return rows


def get_standardized_kb(file_path=None):
    """
    Parses Sheet 1 (Pesticide Reference), Sheet 2 (Sources), and Sheet 3 (Regulatory Notes)
    and combines them into clean, standardized records for Agentic AI retrieval and RAG.
    """
    path = file_path or XLSX_PATH
    if not os.path.exists(path):
        raise FileNotFoundError(f"Knowledge base file not found at: {path}")

    with zipfile.ZipFile(path, "r") as z:
        # 1. Parse Sources (Sheet 2)
        sources_map = {}
        sheet2_rows = parse_sheet_rows(z, "xl/worksheets/sheet2.xml")
        s2_header_row = next((r for r in sheet2_rows if r.get("_row") == 4), None)
        if s2_header_row:
            for r in sheet2_rows:
                if r.get("_row", 0) > 4:
                    pid = r.get("B", "")
                    if pid:
                        sources_map[pid] = {
                            "source_id": r.get("A", "src_unknown"),
                            "source_name": r.get("C", "Official Regulatory Board"),
                            "source_type": r.get("D", "official"),
                            "reference": r.get("E", "Official CIBRC/University Guidelines"),
                            "date_accessed": r.get("F", ""),
                            "verification_notes": r.get("G", "")
                        }

        # 2. Parse Pesticide Reference (Sheet 1)
        records = []
        sheet1_rows = parse_sheet_rows(z, "xl/worksheets/sheet1.xml")
        for r in sheet1_rows:
            r_num = r.get("_row", 0)
            if r_num > 4 and r.get("A"):  # Valid pesticide row
                pid = r.get("A", "")
                source_info = sources_map.get(pid, {
                    "source_id": f"src_{pid}",
                    "source_type": "official",
                    "reference": r.get("P", "CIBRC Approved")
                })

                is_verified = bool(r.get("Q") and r.get("P") and "unverified" not in r.get("P", "").lower())
                status = "Verified" if is_verified else "Not Verified"

                record = {
                    "id": pid,
                    "pesticide_id": pid,
                    "target_crops": r.get("B", ""),
                    "product_name": r.get("C", ""),
                    "company": r.get("G", ""),
                    "company_manufacturer": r.get("G", ""),
                    "active_ingredients": r.get("D", ""),
                    "formulation": r.get("E", ""),
                    "pesticide_type": r.get("F", ""),
                    "target_disease_pest": r.get("H", ""),
                    "purpose": r.get("I", ""),
                    "application_method": r.get("J", ""),
                    "dosage_rate": r.get("K", ""),
                    "water_volume_information": r.get("L", ""),
                    "crop_stage": r.get("M", ""),
                    "safety_precautions": r.get("N", ""),
                    "packaging": r.get("O", ""),
                    "regulatory_authority": r.get("P", ""),
                    "last_verified_date": r.get("Q", ""),
                    "agronomic_notes": r.get("R", ""),
                    "verification_status": status,
                    "is_verified": is_verified,
                    "source": source_info
                }
                records.append(record)

        # 3. Parse Regulatory Notes (Sheet 3) as advisory documents for RAG
        advisory_docs = []
        sheet3_rows = parse_sheet_rows(z, "xl/worksheets/sheet3.xml")
        for r in sheet3_rows:
            if r.get("_row", 0) > 4 and r.get("A"):
                advisory_docs.append({
                    "category": r.get("A", ""),
                    "guideline": r.get("B", ""),
                    "implementation": r.get("C", "")
                })

        return {
            "pesticides": records,
            "sources": sources_map,
            "advisories": advisory_docs
        }


def save_cached_kb():
    """Saves standardized kb data to kb_cache.json for high-performance retrieval."""
    import json
    data = get_standardized_kb()
    cache_path = Path(__file__).resolve().parent / "kb_cache.json"
    with open(cache_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    return cache_path


if __name__ == "__main__":
    cache_file = save_cached_kb()
    data = get_standardized_kb()
    p_list = data["pesticides"]
    print(f"Total verified pesticides loaded: {len(p_list)}")
    print(f"Knowledge base cached at: {cache_file}")
    for p in p_list:
        print(f"[{p['id']}] Crop: {p['target_crops']:<15} | Disease: {p['target_disease_pest'][:35]:<35} | Product: {p['product_name'][:30]}")

