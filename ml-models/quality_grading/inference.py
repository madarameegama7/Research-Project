import cv2
import torch
import torch.nn as nn
import numpy as np
from PIL import Image
from collections import Counter
from ultralytics import YOLO
from torchvision import transforms, models

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

YOLO_PATH = "models/yolov8s_best.pt"
MOLD_CKPT = "models/mobilenetv3_mold_best.pt"
TEXT_CKPT = "models/mobilenetv3_texture_best.pt"

# ---------------- Load YOLO ----------------
yolo = YOLO(YOLO_PATH)
yolo_names = yolo.names

#---------------- Single image pipeline ----------------
def validate_single_image(image_bgr, conf=0.25, iou=0.5):
    """
    Returns:
      { ok: bool, pepper_count: int, total_objects: int, pepper_ratio: float, reason: str }
    """
    res = yolo(image_bgr, conf=conf, iou=iou, verbose=False)[0]

    pepper_count = 0
    total_objects = 0

    if res.boxes is not None and len(res.boxes) > 0:
        total_objects = len(res.boxes)
        for cls in res.boxes.cls:
            cls_name = yolo_names[int(cls)]
            if cls_name == "pepper_berry":
                pepper_count += 1

    pepper_ratio = (pepper_count / total_objects) if total_objects > 0 else 0.0

    # --- thresholds (tune these with your dataset) ---
    # If it's truly pepper-on-paper, pepper_berry should be detected many times.
    MIN_PEPPER = 8          # start with 8 (safe for close-up), tune later
    MIN_RATIO = 0.30        # at least 30% of detections should be pepper

    if pepper_count < MIN_PEPPER:
        return {
            "ok": False,
            "pepper_count": int(pepper_count),
            "total_objects": int(total_objects),
            "pepper_ratio": float(pepper_ratio),
            "reason": "This image does not look like a pepper sample photo. Please capture pepper on a clean white background."
        }

    if total_objects > 0 and pepper_ratio < MIN_RATIO:
        return {
            "ok": False,
            "pepper_count": int(pepper_count),
            "total_objects": int(total_objects),
            "pepper_ratio": float(pepper_ratio),
            "reason": "Pepper is not clearly visible. Please re-take the photo with better lighting and ensure pepper fills the frame."
        }

    return {
        "ok": True,
        "pepper_count": int(pepper_count),
        "total_objects": int(total_objects),
        "pepper_ratio": float(pepper_ratio),
        "reason": "ok"
    }

# ---------------- Load MobileNet checkpoints (same as your notebook) ----------------
def load_mobilenet_ckpt(ckpt_path: str):
    ckpt = torch.load(ckpt_path, map_location=DEVICE)
    class_to_idx = ckpt["class_to_idx"]
    idx_to_class = {v: k for k, v in class_to_idx.items()}

    model = models.mobilenet_v3_small(weights=None)
    in_features = model.classifier[3].in_features
    model.classifier[3] = nn.Linear(in_features, len(class_to_idx))
    model.load_state_dict(ckpt["model_state_dict"])
    model = model.to(DEVICE)
    model.eval()

    img_size = ckpt.get("img_size", 224)
    return model, idx_to_class, img_size

mold_model, mold_idx_to_class, IMG_SIZE = load_mobilenet_ckpt(MOLD_CKPT)
texture_model, texture_idx_to_class, _ = load_mobilenet_ckpt(TEXT_CKPT)

preprocess = transforms.Compose([
    transforms.Resize((IMG_SIZE, IMG_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize([0.485,0.456,0.406],[0.229,0.224,0.225]),
])

def pct(part: int, whole: int) -> float:
    return (part / whole * 100.0) if whole > 0 else 0.0

def predict_class(model, idx_to_class, crop_bgr) -> str:
    crop_rgb = cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB)
    pil = Image.fromarray(crop_rgb)
    x = preprocess(pil).unsqueeze(0).to(DEVICE)
    with torch.no_grad():
        logits = model(x)
        pred_idx = int(torch.argmax(logits, dim=1).item())
    return idx_to_class[pred_idx]

PCT_KEYS = ["adulterant_seed_pct","extraneous_matter_pct","mold_pct","abnormal_texture_pct","healthy_visual_pct"]

def avg_pct_dict(list_of_pct_dicts):
    avg = {}
    for k in PCT_KEYS:
        avg[k] = sum(d[k] for d in list_of_pct_dicts) / len(list_of_pct_dicts)
    return avg

def run_single_image_pipeline(image_bgr, conf=0.25, iou=0.5, texture_first: bool = True):
    # YOLO inference (using ndarray)
    res = yolo(image_bgr, conf=conf, iou=iou, verbose=False)[0]

    obj_counts = Counter()
    berry_crops = []

    if res.boxes is not None and len(res.boxes) > 0:
        for box, cls in zip(res.boxes.xyxy, res.boxes.cls):
            cls_name = yolo_names[int(cls)]
            obj_counts[cls_name] += 1

            if cls_name == "pepper_berry":
                x1, y1, x2, y2 = map(int, box.tolist())
                crop = image_bgr[y1:y2, x1:x2]
                if crop.size != 0:
                    berry_crops.append(crop)

    total_objects = sum(obj_counts.values())
    pepper_count = obj_counts.get("pepper_berry", 0)
    adulterant_count = obj_counts.get("adulterant_seed", 0)
    extraneous_count = obj_counts.get("extraneous_matter", 0)

    mold_count = 0
    abnormal_texture_count = 0

    for crop in berry_crops:
        if texture_first:
            tex_pred = predict_class(texture_model, texture_idx_to_class, crop)
            if tex_pred == "abnormal_texture":
                abnormal_texture_count += 1
                continue
            mold_pred = predict_class(mold_model, mold_idx_to_class, crop)
            if mold_pred == "mold":
                mold_count += 1
        else:
            mold_pred = predict_class(mold_model, mold_idx_to_class, crop)
            if mold_pred == "mold":
                mold_count += 1
                continue
            tex_pred = predict_class(texture_model, texture_idx_to_class, crop)
            if tex_pred == "abnormal_texture":
                abnormal_texture_count += 1

    healthy_visual_count = pepper_count - mold_count - abnormal_texture_count
    if healthy_visual_count < 0:
        healthy_visual_count = 0

    return {
        "adulterant_seed_pct": pct(adulterant_count, total_objects),
        "extraneous_matter_pct": pct(extraneous_count, total_objects),
        "mold_pct": pct(mold_count, pepper_count),
        "abnormal_texture_pct": pct(abnormal_texture_count, pepper_count),
        "healthy_visual_pct": pct(healthy_visual_count, pepper_count),
        "counts": {
            "total_objects": int(total_objects),
            "pepper_berry": int(pepper_count),
            "adulterant_seed": int(adulterant_count),
            "extraneous_matter": int(extraneous_count),
            "mold": int(mold_count),
            "abnormal_texture": int(abnormal_texture_count),
            "healthy_visual": int(healthy_visual_count),
        }
    }

def run_9_images(payload_images: dict, texture_first: bool = True):
    """
    payload_images keys:
      bottom_full, bottom_half, bottom_close,
      middle_full, middle_half, middle_close,
      top_full, top_half, top_close
    values: BGR numpy arrays
    """

    mapping = {
        "bottom": ["bottom_full","bottom_half","bottom_close"],
        "middle": ["middle_full","middle_half","middle_close"],
        "top": ["top_full","top_half","top_close"],
    }

    sample_avgs = {}
    sample_details = {}

    for sample, keys in mapping.items():
        per_image = []
        per_image_details = {}

        for k in keys:
            out = run_single_image_pipeline(payload_images[k], texture_first=texture_first)
            per_image.append({kk: out[kk] for kk in PCT_KEYS})
            per_image_details[k] = out

        sample_details[sample] = per_image_details
        sample_avgs[sample] = avg_pct_dict(per_image)

    final_avg = avg_pct_dict(list(sample_avgs.values()))

    return {
        "samples": sample_avgs,
        "final": final_avg,
        "details": sample_details,  # remove later if you want smaller response
        "meta": {
            "device": DEVICE,
            "texture_first": texture_first
        }
    }