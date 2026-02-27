from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import pandas as pd

# Load trained model and encoders
model = joblib.load("pepper_price_model.pkl")
le_district = joblib.load("district_encoder.pkl")
le_type = joblib.load("type_encoder.pkl")
le_grade = joblib.load("grade_encoder.pkl")

app = FastAPI(title="Pepper Price Prediction API")


# Request Body Schema
class PredictionRequest(BaseModel):
    district: str
    pepper_type: str
    grade: str
    year: int
    month: int
    week: int

# API Endpoint for weekly price prediction
@app.post("/predictlocalprice")
def predict_price(data: PredictionRequest):

    try:
        # Encode categorical features
        district_encoded = le_district.transform([data.district])[0]
        type_encoded = le_type.transform([data.pepper_type])[0]
        grade_encoded = le_grade.transform([data.grade])[0]

        # Create dataframe
        input_df = pd.DataFrame([[
            district_encoded,
            type_encoded,
            grade_encoded,
            data.year,
            data.month,
            data.week
        ]], columns=[
            "district",
            "pepper_type",
            "grade",
            "year",
            "month",
            "week"
        ])

        # Predict
        prediction = model.predict(input_df)[0]

        return {
            "predicted_price_LKR_per_kg": round(float(prediction), 2)
        }

    except Exception as e:
        return {"error": str(e)}