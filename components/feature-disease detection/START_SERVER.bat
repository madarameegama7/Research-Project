@echo off
REM Disease Detection ML Backend Startup Script
REM This script starts the Flask server for disease detection

echo.
echo ============================================
echo  Disease Detection ML Backend
echo ============================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ from https://www.python.org/downloads/
    pause
    exit /b 1
)

echo [1/5] Python found:
python --version

REM Navigate to the disease detection component folder
cd /d "%~dp0"
echo [2/5] Current directory: %cd%

REM Check if requirements are installed
echo [3/5] Checking dependencies...
pip list | findstr /I "tensorflow flask flask-cors pillow" >nul
if errorlevel 1 (
    echo Installing required packages...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo ERROR: Failed to install requirements
        pause
        exit /b 1
    )
) else (
    echo Dependencies already installed
)

REM Check if model file exists
if not exist "ml\pepper_disease_classifier_final.keras" (
    echo ERROR: Model file not found at ml\pepper_disease_classifier_final.keras
    pause
    exit /b 1
)
echo [4/5] Model file found

echo [5/5] Running diagnostics...
python network_config.py

echo.
echo ============================================
echo  Starting Flask Server...
echo ============================================
echo.
echo The server will be available at:
echo   Local: http://localhost:5001
echo   Network: http://0.0.0.0:5001
echo.
echo Health check: http://localhost:5001/health
echo.
echo NOTE: First request may take 5-10 seconds (model loading)
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the Flask app
python app.py

pause

