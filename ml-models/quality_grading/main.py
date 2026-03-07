from fastapi import FastAPI, UploadFile, File, HTTPException
import numpy as np
import cv2

from inference import run_9_images, validate_single_image

app = FastAPI(title="Pepper Quality Inference API")

EXPECTED = [
    "bottom_full","bottom_half","bottom_close",
    "middle_full","middle_half","middle_close",
    "top_full","top_half","top_close"
]

def read_imagefile_to_bgr(file_bytes: bytes):
    nparr = np.frombuffer(file_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    return img

@app.get("/")
def home():
    return {"message": "Pepper Quality API Running"}

@app.post("/infer/quality")
async def infer_quality(
    bottom_full: UploadFile = File(...),
    bottom_half: UploadFile = File(...),
    bottom_close: UploadFile = File(...),
    middle_full: UploadFile = File(...),
    middle_half: UploadFile = File(...),
    middle_close: UploadFile = File(...),
    top_full: UploadFile = File(...),
    top_half: UploadFile = File(...),
    top_close: UploadFile = File(...),
    texture_first: bool = True
):
    files = {
        "bottom_full": bottom_full, "bottom_half": bottom_half, "bottom_close": bottom_close,
        "middle_full": middle_full, "middle_half": middle_half, "middle_close": middle_close,
        "top_full": top_full, "top_half": top_half, "top_close": top_close
    }

    images = {}
    for k, f in files.items():
        data = await f.read()
        img = read_imagefile_to_bgr(data)
        if img is None:
            raise HTTPException(400, f"Invalid image for {k}")
        images[k] = img

    result = run_9_images(images, texture_first=texture_first)
    return result

@app.post("/infer/validate")
async def validate_image(file: UploadFile = File(...)):
    data = await file.read()
    img = read_imagefile_to_bgr(data)
    if img is None:
        raise HTTPException(400, "Invalid image")

    verdict = validate_single_image(img)
    # verdict example: {"ok": True/False, "pepper_count": 32, "total_objects": 40, "reason": "..."}
    if not verdict["ok"]:
        raise HTTPException(400, verdict["reason"])

    return verdict