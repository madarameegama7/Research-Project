@echo off
REM Disease Detection Backend Run Script

echo ===================================
echo Starting CNN Disease Detection API
echo ===================================
echo.
echo Starting Flask server...
echo Server will run on: http://0.0.0.0:5001
echo.
echo Endpoints:
echo   GET  http://localhost:5001/health
echo   POST http://localhost:5001/api/detect-disease
echo   GET  http://localhost:5001/api/disease-info/{name}
echo.
echo Press Ctrl+C to stop the server
echo ===================================
echo.

cd /d "F:\madara new\components\feature-disease detection"
python app.py

pause

