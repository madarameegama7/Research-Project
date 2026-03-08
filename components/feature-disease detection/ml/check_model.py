import tensorflow as tf
import numpy as np

# Load your model
model = tf.keras.models.load_model('./ml/pepper_disease_classifier_final.keras')

# Print model summary
print("="*60)
print("MODEL SUMMARY")
print("="*60)
model.summary()

print("\n" + "="*60)
print("INPUT LAYER DETAILS")
print("="*60)

# Get input shape
input_shape = model.input_shape
print(f"Input shape: {input_shape}")
print(f"Expected batch size: {input_shape[0]}")
print(f"Expected height: {input_shape[1]}")
print(f"Expected width: {input_shape[2]}")
print(f"Expected channels: {input_shape[3]}")

print("\n" + "="*60)
print("OUTPUT LAYER DETAILS")
print("="*60)

output_shape = model.output_shape
print(f"Output shape: {output_shape}")
print(f"Number of classes: {output_shape[1]}")

print("\n" + "="*60)
print("TEST WITH DUMMY DATA")
print("="*60)

# Test with RGB (3 channels)
try:
    test_input_rgb = np.random.rand(1, 224, 224, 3).astype(np.float32)
    print(f"Testing with RGB (3 channels): {test_input_rgb.shape}")
    output = model.predict(test_input_rgb)
    print(f"✅ RGB (3 channels) works! Output shape: {output.shape}")
except Exception as e:
    print(f"❌ RGB (3 channels) failed: {e}")

# Test with RGBA (4 channels)
try:
    test_input_rgba = np.random.rand(1, 224, 224, 4).astype(np.float32)
    print(f"\nTesting with RGBA (4 channels): {test_input_rgba.shape}")
    output = model.predict(test_input_rgba)
    print(f"✅ RGBA (4 channels) works! Output shape: {output.shape}")
except Exception as e:
    print(f"❌ RGBA (4 channels) failed: {e}")

print("\n" + "="*60)
print("RECOMMENDATION")
print("="*60)

if input_shape[3] == 3:
    print("✅ Use RGB (3 channels)")
elif input_shape[3] == 4:
    print("✅ Use RGBA (4 channels)")
else:
    print(f"⚠️  Unexpected channel count: {input_shape[3]}")

