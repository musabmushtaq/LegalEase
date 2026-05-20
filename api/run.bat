@echo off
REM LegalEase API Runner Batch Script
REM Activates venv and starts the API with graceful shutdown support

cls
echo ================================
echo LegalEase API Runner
echo ================================
echo.

REM Activate virtual environment
call .\.venv\Scripts\activate.bat

REM Run the API
echo Starting API server...
echo Press Ctrl+C to gracefully shut down
echo.

python run.py

echo.
echo API server stopped.
pause
@echo off
REM LegalEase API - Run Script
REM Assumes init.bat has already been run

setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ===============================================
echo    LegalEase API - Server
echo ===============================================
echo.

REM Activate virtual environment
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo ERROR: Failed to activate virtual environment
    echo Make sure you've run init.bat first
    echo.
    pause
    exit /b 1
)

echo Starting API server...
echo.
echo ===============================================
echo     API URL: http://127.0.0.1:8000
echo     Docs:    http://127.0.0.1:8000/docs
echo     Health:  http://127.0.0.1:8000/health
echo.
echo     Press Ctrl+C to stop
echo ===============================================
echo.

REM Start the server
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload --reload-exclude=".venv" --reload-exclude="temp_*"

echo.
echo Server stopped
pause
