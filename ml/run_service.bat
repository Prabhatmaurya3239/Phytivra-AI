@echo off
echo ========================================================
echo Starting Phytivra-AI ML & Agentic AI FastAPI Service
echo Running on http://127.0.0.1:8001 (Swagger docs at /docs)
echo ========================================================
cd /d "%~dp0.."
call .\venv\Scripts\activate
uvicorn ml.app:app --host 127.0.0.1 --port 8001 --reload
pause
