@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ===============================================
echo    LegalEase App - Build and Run
echo ===============================================
echo.

powershell -NoProfile -Command "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null } | Select-Object -First 1).IPv4Address.IPAddress" > temp_ip.txt
set /p IP=<temp_ip.txt
del temp_ip.txt

if "!IP!"=="" (
    echo ERROR: Could not detect IP address.
    pause
    exit /b 1
)

:done
echo Detected IP: !IP!
echo.

flutter run --dart-define=API_BASE_URL=http://!IP!:8000

pause
endlocal
