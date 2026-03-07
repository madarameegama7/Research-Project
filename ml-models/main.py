from fastapi import FastAPI
from price_prediction.local_price.router import router as price_router
from quality_grading.router import router as quality_router
from yield_prediction.router import router as yield_router

app = FastAPI(title="Ceylon Pepper ML Models API")

app.include_router(price_router, tags=["Price Prediction"])
app.include_router(quality_router, tags=["Quality Grading"])
app.include_router(yield_router, tags=["Yield Prediction"])

