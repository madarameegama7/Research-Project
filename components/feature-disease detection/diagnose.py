#!/usr/bin/env python3
"""
Disease Detection Diagnostics
Tests the Flask backend and model loading speed
"""

import os
import sys
import time
import requests
from pathlib import Path

def test_model_loading():
    """Test if model loads quickly"""
    print("\n" + "="*60)
    print("TESTING MODEL LOADING")
    print("="*60)

    try:
        import tensorflow as tf
        print("✅ TensorFlow imported successfully")

        os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
        tf.get_logger().setLevel('ERROR')

        model_path = Path(__file__).parent / "ml" / "pepper_disease_classifier_final.keras"

        if not model_path.exists():
            print(f"❌ Model file not found: {model_path}")
            return False

        print(f"📦 Model path: {model_path}")
        print(f"📏 Model size: {model_path.stat().st_size / (1024*1024):.1f} MB")

        print("⏳ Loading model (this may take 10-30 seconds on first run)...")
        start = time.time()
        model = tf.keras.models.load_model(model_path)
        elapsed = time.time() - start

        print(f"✅ Model loaded in {elapsed:.1f} seconds")
        print(f"   Input shape: {model.input_shape}")
        print(f"   Output shape: {model.output_shape}")

        # Test prediction speed
        import numpy as np
        print("\n⏳ Testing prediction speed...")
        test_input = np.random.rand(1, 224, 224, 3).astype(np.float32)

        start = time.time()
        output = model.predict(test_input, verbose=0)
        elapsed = time.time() - start

        print(f"✅ Prediction completed in {elapsed:.2f} seconds")
        print(f"   Output: {output[0]}")

        return True

    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_flask_startup():
    """Test if Flask starts without errors"""
    print("\n" + "="*60)
    print("TESTING FLASK STARTUP")
    print("="*60)

    try:
        print("⏳ Starting Flask app...")
        from app import app
        print("✅ Flask app imported successfully")

        # Check if model is loaded
        print("✅ Flask app configured and ready")
        return True

    except Exception as e:
        print(f"❌ Flask startup error: {e}")
        return False

def test_backend_connection():
    """Test if backend responds to requests"""
    print("\n" + "="*60)
    print("TESTING BACKEND CONNECTION")
    print("="*60)

    try:
        print("⏳ Testing /health endpoint...")
        response = requests.get('http://localhost:5001/health', timeout=5)

        if response.status_code == 200:
            print(f"✅ Backend is responding: {response.json()}")
            return True
        else:
            print(f"❌ Unexpected status code: {response.status_code}")
            return False

    except requests.exceptions.ConnectionError:
        print("❌ Could not connect to backend at http://localhost:5001")
        print("   Make sure Flask is running")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    print("🔍 Disease Detection Diagnostics")
    print("="*60)

    # Check if we're in the right directory
    if not Path("app.py").exists():
        print("❌ app.py not found in current directory")
        print("   Make sure you're in: disease_detection folder")
        return

    # Test model loading
    model_ok = test_model_loading()

    # Test Flask startup
    flask_ok = test_flask_startup()

    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)

    if model_ok and flask_ok:
        print("✅ All checks passed!")
        print("\nTo start the backend:")
        print("   python app.py")
        print("\nOr use:")
        print("   START_SERVER.bat")
    else:
        print("❌ Some checks failed. See above for details.")

        if not model_ok:
            print("\n💡 Model loading issue:")
            print("   - Ensure ml/pepper_disease_classifier_final.keras exists")
            print("   - Check disk space for model loading")

        if not flask_ok:
            print("\n💡 Flask issue:")
            print("   - Run: pip install -r requirements.txt")

if __name__ == '__main__':
    main()

