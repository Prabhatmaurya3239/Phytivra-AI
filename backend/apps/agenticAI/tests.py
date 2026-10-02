"""
Agentic AI Tests Entrypoint.
Supports both:
1. Django test runner: python manage.py test apps.agenticAI.tests
2. Direct execution: python tests.py
"""

import os
import sys
import unittest
from pathlib import Path

# Ensure backend directory is in sys.path
BACKEND_DIR = Path(__file__).resolve().parent.parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

try:
    from .tests.test_agentic_flow import TestAgenticAIWorkflow
    from .tests.test_api_endpoints import AgenticAIAPITests
except ImportError:
    from apps.agenticAI.tests.test_agentic_flow import TestAgenticAIWorkflow
    from apps.agenticAI.tests.test_api_endpoints import AgenticAIAPITests

__all__ = [
    "TestAgenticAIWorkflow",
    "AgenticAIAPITests",
]

if __name__ == "__main__":
    unittest.main()
