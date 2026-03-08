from fastapi import APIRouter, File, UploadFile
import numpy as np
import joblib
import cv2
import shap
from xgboost import XGBRegressor
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.applications.efficientnet import preprocess_input
from pathlib import Path

router = APIRouter()

# ------------------------------
# Paths
# ------------------------------
BASE_DIR = Path(__file__).resolve().parent

XGB_MODEL_PATH = BASE_DIR / "xgb_model.json"
PCA_PATH = BASE_DIR / "pca.pkl"
SCALER_PATH = BASE_DIR / "scaler.pkl"

# ------------------------------
# Load trained models
# ------------------------------
xgb_model = XGBRegressor()
xgb_model.load_model(str(XGB_MODEL_PATH))

pca = joblib.load(PCA_PATH)
scaler = joblib.load(SCALER_PATH)

effnet = EfficientNetB0(
    weights="imagenet", include_top=False, input_shape=(224, 224, 3), pooling="avg"
)

# Create SHAP explainer
explainer = shap.Explainer(xgb_model)

# Feature names
feature_names = [f"pca_{i}" for i in range(pca.n_components_)] + [
    "soil_moisture",
    "temperature",
    "moisture_temp_ratio",
    "moisture_squared",
    "temp_squared",
]


# ------------------------------
# Generate SHAP explanation
# ------------------------------
def get_shap_values(X):
    shap_values = explainer(X)
    values = shap_values.values[0]

    explanation = {}
    for name, val in zip(feature_names, values):
        explanation[name] = float(val)

    return explanation


# ------------------------------
# Generate farmer-friendly insights
# ------------------------------
def generate_farmer_insights(shap_values, soil, temp):
    insights = []

    soil_impact = shap_values.get("soil_moisture", 0)
    temp_impact = shap_values.get("temperature", 0)

    if soil_impact > 0:
        insights.append("Soil moisture is positively influencing crop yield.")
    else:
        insights.append("Low soil moisture may reduce crop yield. Consider irrigation.")

    if temp_impact > 0:
        insights.append("Current temperature conditions support good crop growth.")
    else:
        insights.append("Temperature conditions may not be optimal for crop growth.")

    if soil < 40:
        insights.append(
            "Soil moisture is quite low. Increasing irrigation may improve yield."
        )

    if temp > 35:
        insights.append("High temperature detected. Crop stress may reduce yield.")

    if soil > 70:
        insights.append(
            "Soil moisture levels are high which may support strong plant growth."
        )

    return insights


# Prediction Endpoint
@router.post("/predict")
async def predict_yield(file: UploadFile = File(...), soil: float = 0, temp: float = 0):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)

    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        return {"error": "Invalid image file"}

    img = cv2.resize(img, (224, 224))
    img = preprocess_input(img)

    # CNN feature extraction
    img_feat = effnet.predict(np.expand_dims(img, axis=0), verbose=0)

    # PCA reduction
    img_feat_reduced = pca.transform(img_feat)

    # Feature engineering
    moisture_temp_ratio = soil / (temp + 1)
    moisture_squared = soil**2
    temp_squared = temp**2

    tab = np.array([[soil, temp, moisture_temp_ratio, moisture_squared, temp_squared]])

    # Scale tabular data
    tab_scaled = scaler.transform(tab)

    # Combine features
    X = np.concatenate([img_feat_reduced, tab_scaled], axis=1)

    # Prediction
    prediction = xgb_model.predict(X)[0]

    # SHAP explanation
    shap_values = get_shap_values(X)

    # Farmer insights
    insights = generate_farmer_insights(shap_values, soil, temp)

    return {
        "predicted_yield": float(prediction),
        "insights": insights,
        "top_factors": {
            "soil_moisture_impact": shap_values.get("soil_moisture", 0),
            "temperature_impact": shap_values.get("temperature", 0),
        },
    }
