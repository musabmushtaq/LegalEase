@echo off
REM LegalEase Database Initialization Script
REM Run this ONCE to set up MongoDB collections and indexes

setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ===============================================
echo    LegalEase Database - Initialization
echo ===============================================
echo.

REM ============================================================================
REM 1. CREATE VIRTUAL ENVIRONMENT IF NEEDED
REM ============================================================================
echo [1/3] Checking Python virtual environment...
if exist ".venv\" (
    echo     ✓ Virtual environment found
) else (
    echo     Creating virtual environment...
    python -m venv .venv
    if errorlevel 1 (
        echo     ERROR: Failed to create virtual environment
        pause
        exit /b 1
    )
    echo     ✓ Virtual environment created
)

REM ============================================================================
REM 2. ACTIVATE VENV & INSTALL DEPENDENCIES
REM ============================================================================
echo.
echo [2/3] Installing dependencies...
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo     ERROR: Failed to activate virtual environment
    pause
    exit /b 1
)

python -c "import motor, pydantic_settings, python_dotenv" 2>NUL
if errorlevel 1 (
    echo     Installing from requirements.txt...
    pip install -r requirements.txt -q
    if errorlevel 1 (
        echo     ERROR: Failed to install dependencies
        pause
        exit /b 1
    )
    echo     ✓ Dependencies installed
) else (
    echo     ✓ Dependencies already installed
)

REM ============================================================================
REM 3. RUN INITIALIZATION SCRIPT
REM ============================================================================
echo.
echo [3/3] Initializing database...
echo.

python init_db.py

if errorlevel 1 (
    echo.
    echo ✗ Database initialization failed!
    echo.
    pause
    exit /b 1
)

echo.
echo ===============================================
echo    ✓ Database initialized successfully!
echo ===============================================
echo.
echo     Your database is ready to use.
echo.
echo     NEXT STEPS:
echo     1. Close this window
echo     2. Run api/run.bat to start the API server
echo.
pause
