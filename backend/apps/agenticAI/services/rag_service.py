"""
RAG Service (Prototype)
Implements Section 9 & 10 of Task 3:
- Distinguishes unstructured context (regulatory guidelines, agronomic notes, application advisory).
- Provides keyword/semantic context retrieval over approved documents.
- Supplies verified contextual knowledge to Agentic AI without inventing facts.
"""

import math
import re
from typing import List, Dict, Any
from pathlib import Path
import json

from apps.agenticAI.data.kb_loader import get_standardized_kb

CACHE_PATH = Path(__file__).resolve().parent.parent / "data" / "kb_cache.json"


class RAGService:
    def __init__(self):
        self._documents = []
        self._build_index()

    def _build_index(self):
        """Builds index of unstructured advisory documents from knowledge base."""
        data = None
        if CACHE_PATH.exists():
            try:
                with open(CACHE_PATH, "r", encoding="utf-8") as f:
                    data = json.load(f)
            except Exception:
                data = get_standardized_kb()
        else:
            data = get_standardized_kb()

        docs = []

        # 1. Unstructured regulatory and technical notes (Sheet 3)
        for adv in data.get("advisories", []):
            text = f"Category: {adv.get('category')}. Guideline: {adv.get('guideline')}. Implementation: {adv.get('implementation')}"
            docs.append({
                "doc_id": f"adv_{len(docs) + 1}",
                "type": "advisory",
                "title": adv.get("category", "General Agricultural Advisory"),
                "content": text,
                "tokens": self._tokenize(text)
            })

        # 2. Agronomic Notes & Resistance Management (Sheet 1)
        for p in data.get("pesticides", []):
            notes = p.get("agronomic_notes", "")
            safety = p.get("safety_precautions", "")
            purpose = p.get("purpose", "")
            if notes or safety:
                text = (
                    f"Crop: {p.get('target_crops')}. Disease: {p.get('target_disease_pest')}. "
                    f"Purpose: {purpose}. Agronomic Advisory: {notes}. Precautions: {safety}."
                )
                docs.append({
                    "doc_id": f"agronomy_{p.get('pesticide_id')}",
                    "type": "product_advisory",
                    "title": f"Advisory for {p.get('target_crops')} - {p.get('product_name')}",
                    "content": text,
                    "tokens": self._tokenize(text)
                })

        self._documents = docs

    def _tokenize(self, text: str) -> List[str]:
        return [w.lower() for w in re.findall(r"\b\w{3,}\b", text)]

    def retrieve(self, query: str, top_k: int = 3) -> List[Dict[str, Any]]:
        """
        Retrieves top-k relevant unstructured documents for the query using TF-IDF style scoring.
        """
        if not self._documents:
            self._build_index()

        q_tokens = self._tokenize(query)
        if not q_tokens:
            return self._documents[:top_k]

        scored_docs = []
        for doc in self._documents:
            doc_tokens = doc["tokens"]
            score = 0.0
            for qt in q_tokens:
                count = doc_tokens.count(qt)
                if count > 0:
                    score += (1 + math.log(count)) * (1.0 / (len(doc_tokens) ** 0.5 + 1.0))
            if score > 0:
                scored_docs.append((score, doc))

        scored_docs.sort(key=lambda x: x[0], reverse=True)
        return [doc for _, doc in scored_docs[:top_k]]
