import os
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS
import tensorflow as tf
from PIL import Image
import io
import json
import os

app = Flask(__name__)
CORS(app)

# Load the CNN model
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "ml", "pepper_disease_classifier_final.keras")


model = tf.keras.models.load_model(MODEL_PATH)

# Disease class mappings - CORRECTED BASED ON USER TESTING
DISEASE_CLASSES = {
    0: {
        'name': 'footrot',
        'description': 'Footrot disease affects the foot of the plant causing tissue decay.',
        'treatment': 'Remove affected plant parts, improve soil drainage, apply fungicide.',
        'severity': 'High',
        'prevention': 'Avoid waterlogging, maintain proper drainage, practice crop rotation.'
    },
    1: {
        'name': 'Pollu_Disease',
        'description': 'Pollu disease causes yellowing and wilting of leaves and stems.',
        'treatment': 'Remove infected plants, apply systemic fungicides, ensure good ventilation.',
        'severity': 'High',
        'prevention': 'Use disease-resistant varieties, avoid overhead irrigation.'
    },
    2: {
        'name': 'Slow-Decline',
        'description': 'Slow-decline is a progressive disease causing gradual plant deterioration.',
        'treatment': 'Prune affected branches, apply copper-based fungicides, improve plant nutrition.',
        'severity': 'Medium',
        'prevention': 'Maintain plant vigor, ensure proper fertilization, monitor regularly.'
    },
    3: {
        'name': 'healthy',
        'description': 'The leaves appear healthy with no visible signs of disease.',
        'treatment': 'Continue with regular maintenance and monitoring.',
        'severity': 'None',
        'prevention': 'Maintain regular monitoring and good farming practices.'
    },
    4: {
           'name': 'Leaf-Blight',
           'description': 'Leaf-blight is a fungal disease that causes brown or black spots on leaves, leading to drying and premature leaf drop.',
           'treatment': 'Remove infected leaves, apply recommended fungicides, and avoid overhead watering.',
           'severity': 'High',
           'prevention': 'Ensure good air circulation, avoid excess moisture, use disease-free planting material, and inspect plants regularly.'
       },
    5: {
           'name': 'Yellow-Mottle',
           'description': 'Yellow mottle is a viral disease that causes irregular yellow patches on leaves, reducing photosynthesis and weakening the plant.',
           'treatment': 'Remove and destroy infected plants to prevent spread, control insect vectors such as aphids and whiteflies, and disinfect tools after use.',
           'severity': 'High',
           'prevention': 'Use virus-free planting material, manage insect populations, keep the field clean, and monitor plants frequently for early symptoms.'
       }
}

def preprocess_image(image_data):
    """Preprocess image for model prediction"""
    try:
        # Read image from bytes
        image = Image.open(io.BytesIO(image_data))

        # Convert to RGB (3 channels) to match model input
        if image.mode != 'RGB':
            image = image.convert('RGB')

        # Resize to model's expected input size (adjust based on your model)
        image = image.resize((224, 224))

        # Convert to array and normalize
        image_array = np.array(image) / 255.0

        # Add batch dimension if not present
        if len(image_array.shape) == 3:
            image_array = np.expand_dims(image_array, axis=0)

        return image_array.astype(np.float32)
    except Exception as e:
        raise ValueError(f"Image preprocessing failed: {str(e)}")

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'message': 'Disease Detection API is running'}), 200

@app.route('/api/detect-disease', methods=['POST'])
def detect_disease():
    """
    Detect disease from uploaded image
    Expected: multipart/form-data with 'image' field
    """
    try:
        # Check if image file is present
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400

        file = request.files['image']

        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400

        # Read image data
        image_data = file.read()

        # Preprocess image
        processed_image = preprocess_image(image_data)

        # Make prediction
        predictions = model.predict(processed_image, verbose=0)

        # Get the predicted class and confidence
        predicted_class = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_class])

        # DEBUG: Print to Flask console for troubleshooting
        print(f"\n{'='*60}")
        print(f"PREDICTION DEBUG INFO")
        print(f"{'='*60}")
        print(f"Predicted class index: {predicted_class}")
        print(f"Confidence: {confidence:.4f}")
        print(f"All predictions: {predictions[0]}")
        for i, pred in enumerate(predictions[0]):
            print(f"  Index {i}: {pred:.4f}")
        print(f"{'='*60}\n")

        # Get disease information
        disease_info = DISEASE_CLASSES.get(predicted_class, {
            'name': 'Unknown',
            'description': 'Unable to classify the disease.',
            'treatment': 'Consult with a plant pathologist.',
            'severity': 'Unknown'
        })

        # Prepare response
        response = {
            'success': True,
            'disease': disease_info['name'],
            'confidence': round(confidence * 100, 2),
            'description': disease_info.get('description', ''),
            'treatment': disease_info.get('treatment', ''),
            'severity': disease_info.get('severity', ''),
            'prevention': disease_info.get('prevention', ''),
            'all_predictions': {
                DISEASE_CLASSES.get(i, {'name': 'Unknown'})['name']: float(predictions[0][i])
                for i in range(len(predictions[0]))
            }
        }

        return jsonify(response), 200

    except ValueError as ve:
        return jsonify({'error': str(ve)}), 400
    except Exception as e:
        return jsonify({'error': f'Disease detection failed: {str(e)}'}), 500

@app.route('/api/disease-info/<disease_name>', methods=['GET'])
def get_disease_info(disease_name):
    """Get detailed information about a disease"""
    try:
        for disease_id, disease_info in DISEASE_CLASSES.items():
            if disease_info['name'].lower() == disease_name.lower():
                return jsonify(disease_info), 200

        return jsonify({'error': 'Disease not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)

