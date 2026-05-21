"""
V1 — Bashorat (inference) modulasi

O'qitilgan modellarni yuklab, foydalanuvchining ma'lumotlariga foiz-asosida
xavf darajasini qaytaradi.

Natija formati:
    {
        "probabilities": {"low": 0.12, "mid": 0.65, "high": 0.23},
        "predicted_class": "mid",
        "risk_level": "sariq",       # yashil / sariq / qizil
        "recommendation": "..."      # foydalanuvchi uchun maslahat
    }
"""

from pathlib import Path
from typing import Dict, Any

import joblib
import numpy as np
import pandas as pd

ROOT = Path(__file__).parent
MODELS_DIR = ROOT / "models"

# Kesh — har so'rovda diskdan o'qimaslik uchun
_model_cache: Dict[str, Any] = {}


def _load_model(name: str):
    if name not in _model_cache:
        path = MODELS_DIR / f"{name}.joblib"
        if not path.exists():
            raise FileNotFoundError(
                f"Model topilmadi: {path}. Avval `python train.py` ni ishga tushiring."
            )
        _model_cache[name] = joblib.load(path)
    return _model_cache[name]


def _map_to_traffic_light(predicted_class: str, probabilities: Dict[str, float]) -> str:
    """Bashoratni yashil/sariq/qizil tizimga aylantiradi."""
    cls = predicted_class.lower()
    if "high" in cls or "pathological" in cls:
        return "qizil"
    if "mid" in cls or "suspect" in cls:
        return "sariq"
    return "yashil"


# ============================================================
# Maternal Risk (homiladorlik xavfi)
# ============================================================
MATERNAL_RECOMMENDATIONS = {
    "yashil": "Ko'rsatkichlar normal. Rejali ko'riklarga davom eting.",
    "sariq": "Ba'zi ko'rsatkichlar diqqat talab qiladi. Shifokoringiz bilan maslahatlashing.",
    "qizil": "Yuqori xavf aniqlandi. Iloji boricha tezroq shifokorga murojaat qiling.",
}


def predict_maternal_risk(features: Dict[str, float]) -> Dict[str, Any]:
    """
    Args:
        features: {
            "Age": int, "SystolicBP": int, "DiastolicBP": int,
            "BS": float, "BodyTemp": float, "HeartRate": int
        }
    """
    art = _load_model("maternal_risk")
    feature_names = art["feature_names"]

    missing = [f for f in feature_names if f not in features]
    if missing:
        raise ValueError(f"Yetishmayotgan featurelar: {missing}")

    X = pd.DataFrame([[features[f] for f in feature_names]], columns=feature_names)
    X_scaled = art["scaler"].transform(X)
    probs = art["model"].predict_proba(X_scaled)[0]

    le = art["label_encoder"]
    raw_classes = le.classes_  # ['high risk', 'low risk', 'mid risk']

    # Probabilities ni qulay nomlar bilan qaytaramiz
    prob_dict = {}
    for cls_name, p in zip(raw_classes, probs):
        key = cls_name.replace(" risk", "").strip().lower()  # high/mid/low
        prob_dict[key] = float(round(p, 4))

    pred_idx = int(np.argmax(probs))
    predicted_class = raw_classes[pred_idx]
    traffic = _map_to_traffic_light(predicted_class, prob_dict)

    return {
        "probabilities": prob_dict,
        "predicted_class": predicted_class,
        "risk_level": traffic,
        "recommendation": MATERNAL_RECOMMENDATIONS[traffic],
        "model": art["best_model_name"],
        "model_accuracy": art["test_accuracy"],
    }


# ============================================================
# Fetal Health (homila xavfi)
# ============================================================
FETAL_RECOMMENDATIONS = {
    "yashil": "Homila holati normal. Kuzatuvni davom ettiring.",
    "sariq": "Shubhali signallar bor. Qo'shimcha tekshiruv tavsiya etiladi.",
    "qizil": "Patologik signallar aniqlandi. Tezkor tibbiy aralashuv kerak.",
}


def predict_fetal_health(features: Dict[str, float]) -> Dict[str, Any]:
    """22 ta CTG feature qabul qiladi."""
    art = _load_model("fetal_health")
    feature_names = art["feature_names"]

    missing = [f for f in feature_names if f not in features]
    if missing:
        raise ValueError(f"Yetishmayotgan featurelar: {missing}")

    X = pd.DataFrame([[features[f] for f in feature_names]], columns=feature_names)
    X_scaled = art["scaler"].transform(X)
    probs = art["model"].predict_proba(X_scaled)[0]

    class_labels = art["class_labels"]  # ['Normal', 'Suspect', 'Pathological']
    prob_dict = {
        label.lower(): float(round(p, 4)) for label, p in zip(class_labels, probs)
    }

    pred_idx = int(np.argmax(probs))
    predicted_class = class_labels[pred_idx]
    traffic = _map_to_traffic_light(predicted_class, prob_dict)

    return {
        "probabilities": prob_dict,
        "predicted_class": predicted_class,
        "risk_level": traffic,
        "recommendation": FETAL_RECOMMENDATIONS[traffic],
        "model": art["best_model_name"],
        "model_accuracy": art["test_accuracy"],
    }


# ============================================================
# Demo
# ============================================================
if __name__ == "__main__":
    print("\n=== Maternal Risk demo ===")
    result = predict_maternal_risk(
        {
            "Age": 28,
            "SystolicBP": 130,
            "DiastolicBP": 85,
            "BS": 7.5,
            "BodyTemp": 98.0,
            "HeartRate": 78,
        }
    )
    print(result)

    print("\n=== Fetal Health demo ===")
    # Misol uchun "Normal" namuna (test'dan)
    fetal_example = {
        "baseline value": 120,
        "accelerations": 0.0,
        "fetal_movement": 0.0,
        "uterine_contractions": 0.0,
        "light_decelerations": 0.0,
        "severe_decelerations": 0.0,
        "prolongued_decelerations": 0.0,
        "abnormal_short_term_variability": 73.0,
        "mean_value_of_short_term_variability": 0.5,
        "percentage_of_time_with_abnormal_long_term_variability": 43.0,
        "mean_value_of_long_term_variability": 2.4,
        "histogram_width": 64.0,
        "histogram_min": 62.0,
        "histogram_max": 126.0,
        "histogram_number_of_peaks": 2.0,
        "histogram_number_of_zeroes": 0.0,
        "histogram_mode": 120.0,
        "histogram_mean": 137.0,
        "histogram_median": 121.0,
        "histogram_variance": 73.0,
        "histogram_tendency": 1.0,
    }
    try:
        result = predict_fetal_health(fetal_example)
        print(result)
    except ValueError as e:
        print(f"Misol nuqsonli: {e}")
