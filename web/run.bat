@echo off
title LegalEase Web Server
cd /d "%~dp0"

echo ===================================================
echo             LegalEase Web Interface
echo ===================================================
echo.

:: Port to host the web app
set PORT=8080

:: Find Python executable
where python >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [OK] Python detected.
    echo Starting local web server on http://localhost:%PORT% ...
    
    :: Open browser after a 1 second delay
    start "" "http://localhost:%PORT%"
    
    :: Start python http.server
    python -m http.server %PORT%
    goto end
)

:: Find Node.js / npx as fallback
where npx >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [OK] Node.js/npx detected.
    echo Starting local web server on http://localhost:%PORT% ...
    
    :: Open browser after a 1 second delay
    start "" "http://localhost:%PORT%"
    
    :: Start server using npx
    npx -y http-server -p %PORT%
    goto end
)

echo [ERROR] Neither Python nor Node.js/npx was found in your PATH.
echo Please install Python or Node.js to host the ES module files correctly, or run a local web server of your choice.
echo.
pause

:end
