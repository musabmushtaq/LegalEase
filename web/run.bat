@echo off
REM Start LegalEase Web Interface
REM This script starts a simple HTTP server to serve the web app

echo.
echo LegalEase Web Interface - Starting...
echo.
echo Prerequisites:
echo   - Backend API should be running on http://127.0.0.1:8000
echo   - MongoDB should be running
echo.

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Starting HTTP server using Python...
    echo Open browser to: http://localhost:8080
    echo Press Ctrl+C to stop
    echo.
    python -m http.server 8080
) else (
    echo Python not found in PATH
    echo.
    echo Alternative options:
    echo 1. Using Node.js: npx http-server -p 8080
    echo 2. Open index.html directly in browser (limited functionality)
    pause
)
