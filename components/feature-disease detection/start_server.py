#!/usr/bin/env python3
"""
Disease Detection ML Backend Starter
This script starts the Flask server and provides helpful information
"""

import os
import sys
import subprocess
import time
from pathlib import Path

def print_header(text):
    """Print formatted header"""
    print("\n" + "="*50)
    print(f"  {text}")
    print("="*50 + "\n")

def check_python():
    """Check Python version"""
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print(f"❌ Python 3.8+ required. Found: {version.major}.{version.minor}")
        return False
    print(f"✅ Python {version.major}.{version.minor}.{version.micro} found")
    return True

def check_dependencies():
    """Check if required packages are installed"""
    required = ['flask', 'flask_cors', 'tensorflow', 'PIL', 'numpy']
    missing = []

    for package in required:
        try:
            __import__(package)
            print(f"✅ {package}")
        except ImportError:
            print(f"❌ {package} (missing)")
            missing.append(package)

    if missing:
        print(f"\n⚠️  Missing packages: {', '.join(missing)}")
        print("\nInstalling missing packages...")
        try:
            subprocess.run([sys.executable, '-m', 'pip', 'install', '-r', 'requirements.txt'], check=True)
            print("✅ Packages installed successfully!")
            return True
        except subprocess.CalledProcessError:
            print("❌ Failed to install packages")
            return False

    return True

def check_model_file():
    """Check if model file exists"""
    model_path = Path(__file__).parent / "ml" / "pepper_disease_classifier_final.keras"
    if model_path.exists():
        size_mb = model_path.stat().st_size / (1024 * 1024)
        print(f"✅ Model file found ({size_mb:.1f} MB)")
        return True
    else:
        print(f"❌ Model file not found at: {model_path}")
        return False

def main():
    os.system('cls' if os.name == 'nt' else 'clear')

    print_header("Disease Detection ML Backend")

    print("Checking system requirements...\n")

    if not check_python():
        sys.exit(1)

    print("\nChecking dependencies...\n")
    if not check_dependencies():
        sys.exit(1)

    print("\nChecking model file...\n")
    if not check_model_file():
        sys.exit(1)

    print_header("Starting Flask Server")

    print("📡 Server Configuration:")
    print("   • Host: 0.0.0.0 (all interfaces)")
    print("   • Port: 5001")
    print("   • API Endpoint: http://YOUR_IP:5001/api")
    print("\n🔗 Quick Links:")
    print("   • Health Check: http://localhost:5001/health")
    print("   • Detect Disease: http://localhost:5001/api/detect-disease (POST)")

    print("\n📱 Mobile App Configuration:")
    print("   • Change IP in disease_detection_service.dart")
    print("   • Android Emulator: 10.0.2.2:5001")
    print("   • Physical Phone: YOUR_COMPUTER_IP:5001")

    print("\n⏹️  Press Ctrl+C to stop the server\n")
    print("="*50 + "\n")

    try:
        # Import and run Flask app
        from app import app

        print("✅ Starting Flask application...\n")
        app.run(debug=True, host='0.0.0.0', port=5001)

    except KeyboardInterrupt:
        print_header("Server Stopped")
        print("👋 Flask server has been shut down gracefully")
    except Exception as e:
        print(f"\n❌ Error starting server: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()

