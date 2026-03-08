import tensorflow as tf
import numpy as np
import os
from PIL import Image
import io

# Get the script directory
script_dir = os.path.dirname(os.path.abspath(__file__))

# Build absolute path to model
model_path = os.path.join(script_dir, 'ml', 'pepper_disease_classifier_final.keras')
print(f"Loading model from: {model_path}")

model = tf.keras.models.load_model(model_path)

print("\n" + "="*60)
print("MODEL INPUT/OUTPUT INFO")
print("="*60)
print(f"Input shape: {model.input_shape}")
print(f"Output shape: {model.output_shape}")
print(f"Number of classes: {model.output_shape[1]}")

# Get model weights and layer info
print("\n" + "="*60)
print("FIRST LAYER INFO")
print("="*60)
first_layer = model.layers[0]
print(f"First layer name: {first_layer.name}")
print(f"First layer type: {type(first_layer)}")

print("\n" + "="*60)
print("HOW TO FIND CORRECT CLASS ORDER")
print("="*60)
print("""
The model has 6 output classes. Currently mapped as:
  Index 0: healthy
  Index 1: footrot
  Index 2: Pollu_Disease
  Index 3: Slow-Decline
  Index 4: leaf blight
  Index 5: yellow_mottle

TO VERIFY THIS IS CORRECT:
1. Take a photo of a HEALTHY leaf
2. Note which disease it shows (e.g., "shows as footrot")
3. That tells us the actual class order

EXAMPLE:
- If healthy leaf shows as "Index 1 footrot" → healthy is actually index 1, not 0
- Then the correct order is: Index 0=?, Index 1=healthy, ...

INSTRUCTIONS:
1. Test with healthy leaf image
2. Look at Flask output: "Predicted class: X"
3. Tell me what X is and what disease name it showed
4. We can then fix the mapping!
""")

print("\n" + "="*60)
print("CURRENT MAPPING IN app.py")
print("="*60)
print("""
0: healthy
1: footrot
2: Pollu_Disease
3: Slow-Decline
4: leaf blight
5: yellow_mottle

IS THIS CORRECT? Test to find out!
""")

