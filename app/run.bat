@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ===============================================
echo    LegalEase App - Build and Run
echo ===============================================
echo.

for /f "delims=" %%A in ('ipconfig ^| find /I "IPv4"') do (
    set "LINE=%%A"
    set "IP=!LINE:*: =!"
    goto :done
)

:done
echo Detected IP: !IP!
echo.

flutter run --dart-define=API_BASE_URL=http://!IP!:8000

pause
endlocal
