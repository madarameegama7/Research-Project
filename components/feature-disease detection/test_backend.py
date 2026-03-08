#!/usr/bin/env python3
"""
Test the Flask disease detection backend
"""
import requests
import json
import time

BASE_URL = 'http://localhost:5001'

def test_health():
    """Test health endpoint"""
    print("\n1️⃣  Testing health check...")
    try:
        response = requests.get(f'{BASE_URL}/health', timeout=5)
        if response.status_code == 200:
            print("   ✅ Backend is RUNNING")
            print(f"   Response: {response.json()}")
            return True
        else:
            print(f"   ❌ Unexpected status: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("   ❌ Cannot connect to backend!")
        print("   Make sure START_SERVER.bat is running")
        return False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

def test_with_image(image_path):
    """Test disease detection with an image"""
    print(f"\n2️⃣  Testing disease detection with: {image_path}")
    try:
        with open(image_path, 'rb') as f:
            files = {'image': f}
            response = requests.post(f'{BASE_URL}/api/detect-disease', files=files, timeout=120)

            if response.status_code == 200:
                result = response.json()
                print(f"   ✅ Disease detected!")
                print(f"   Disease: {result.get('disease')}")
                print(f"   Confidence: {result.get('confidence')}%")
                print(f"   Severity: {result.get('severity')}")
                return True
            else:
                print(f"   ❌ Error {response.status_code}: {response.text}")
                return False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

if __name__ == '__main__':
    print("="*60)
    print("Disease Detection Backend Test")
    print("="*60)

    # Check if backend is running
    backend_ok = test_health()

    if not backend_ok:
        print("\n" + "="*60)
        print("SOLUTION:")
        print("="*60)
        print("Run: START_SERVER.bat")
        print("Then try this script again")
        exit(1)

    # Optionally test with an image
    print("\n" + "="*60)
    print("Backend is working correctly! ✅")
    print("="*60)
    print("\nYou can now use the mobile app to capture images")

