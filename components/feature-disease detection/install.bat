@echo off
REM Disease Detection Backend Installation Script

echo ===================================
echo CNN Disease Detection Setup
echo ===================================
echo.

cd /d "F:\madara new\components\feature-disease detection"

echo Installing Python dependencies...
echo.

pip install --upgrade pip
pip install Flask==3.0.0
pip install Flask-CORS==4.0.0
pip install tensorflow==2.18.0
pip install Pillow==10.1.0
pip install numpy==1.26.0
pip install python-dotenv==1.0.0

echo.
echo ===================================
echo Installation Complete!
echo ===================================
echo.
echo Next steps:
echo 1. Run: python app.py
echo 2. Flask will start on http://0.0.0.0:5001
echo 3. Open another terminal for Flutter app
echo.
pause

