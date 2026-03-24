@echo off
REM LegalEase Database - Initialization Script
REM Creates MongoDB indexes using Python and Motor

setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ===============================================
echo    LegalEase Database - Initialization
echo ===============================================
echo.

REM Check/create virtual environment
if not exist ".venv\" (
    echo Setting up Python virtual environment...
    python -m venv .venv
    if errorlevel 1 (
        echo ERROR: Failed to create virtual environment
        pause
        exit /b 1
    )
)

REM Activate venv
call .venv\Scripts\activate.bat

REM Install Motor (minimal requirement)
python -m pip install motor -q 2>nul
if errorlevel 1 (
    echo ERROR: Failed to install Motor
    pause
    exit /b 1
)

REM Run initialization
echo.
echo Creating database indexes...
echo.
python init_db.py

if errorlevel 1 (
    echo.
    echo ✗ Database initialization failed
    echo.
    pause
    exit /b 1
)

pause
echo [3/3] Initializing database...

pause

