@echo off
title LegalEase Web Server
cd /d "%~dp0"

echo ===================================================
echo             LegalEase Web Interface
echo ===================================================
echo.

:: Check for Node.js
where npm >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [OK] Node.js and npm detected.
    
    echo Installing dependencies...
    call npm install
    
    echo Starting Vite local web server...
    :: Open browser and start dev server
    start "" "http://localhost:8080"
    call npm run dev
    
    goto end
)

echo [ERROR] npm was not found in your PATH.
echo Please install Node.js to run the Vite development server.
echo.
pause

:end
