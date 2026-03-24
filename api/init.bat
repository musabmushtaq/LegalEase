@echo off
REM LegalEase API - Initialization Script
REM Run this ONCE to set up Python venv and install dependencies

setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ===============================================
echo    LegalEase API - Initialization
echo ===============================================
echo.

REM Create virtual environment if needed
echo [1/2] Setting up Python virtual environment...
if exist ".venv\" (
    echo     ✓ Virtual environment already exists
) else (
    python -m venv .venv
    if errorlevel 1 (
        echo     ERROR: Failed to create virtual environment
        pause
        exit /b 1
    )
    echo     ✓ Virtual environment created
)

REM Activate and install requirements
echo.
echo [2/2] Installing dependencies...
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo     ERROR: Failed to activate virtual environment
    pause
    exit /b 1
)

pip install -r requirements.txt -q
if errorlevel 1 (
    echo     ERROR: Failed to install dependencies
    pause
    exit /b 1
)
echo     ✓ Dependencies installed

REM Create .env if needed
if not exist ".env" (
    if exist ".env.example" (
        copy .env.example .env >NUL
        echo     ✓ .env file created
    )
)

echo.
echo ===============================================
echo    ✓ API initialization complete!
echo ===============================================
echo.
echo     Now run: run.bat to start the server
echo.
pause
