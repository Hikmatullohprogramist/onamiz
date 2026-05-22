"""
Onamiz v4 — Simptom asosida xavf bashorati
42 ta xavf, 39 ta feature
"""

from pathlib import Path
from typing import Dict, Any
import joblib
import numpy as np
import pandas as pd

ROOT       = Path(__file__).parent
MODEL_PATH = ROOT / "models" / "onamiz_v4.joblib"

_cache: Dict[str, Any] = {}


def _load():
    if "model" not in _cache:
        if not MODEL_PATH.exists():
            raise FileNotFoundError(
                f"Model topilmadi: {MODEL_PATH}\n"
                "Colab dan onamiz_v4.joblib yuklab, models/ papkasiga joylashtiring."
            )
        _cache["model"] = joblib.load(MODEL_PATH)
    return _cache["model"]


# ─── Tavsiyalar ──────────────────────────────────────────────
RECOMMENDATIONS = {
    "yashil": {
        "uz": "Ko'rsatkichlar normal. Navbatdagi rejali ko'rikka boring.",
        "ru": "Показатели в норме. Продолжайте плановые визиты.",
        "en": "All looks normal. Continue with your scheduled checkups.",
    },
    "sariq": {
        "uz": "Ba'zi belgilar diqqat talab qiladi. Bu hafta shifokoringizni ko'ring.",
        "ru": "Некоторые симптомы требуют внимания. Обратитесь к врачу на этой неделе.",
        "en": "Some symptoms need attention. See your doctor this week.",
    },
    "qizil": {
        "uz": "Muhim belgilar aniqlandi. BUGUN shifokorga boring.",
        "ru": "Обнаружены важные симптомы. Обратитесь к врачу СЕГОДНЯ.",
        "en": "Important symptoms detected. See a doctor TODAY.",
    },
    "favqulodda": {
        "uz": "TEZKOR! Hoziroq tez yordamga murojaat qiling yoki kasalxonaga boring.",
        "ru": "СРОЧНО! Немедленно вызовите скорую помощь или обратитесь в больницу.",
        "en": "EMERGENCY! Call an ambulance immediately or go to the hospital now.",
    },
}

RISK_MAP = {
    "emergency": "favqulodda",
    "high":      "qizil",
    "medium":    "sariq",
    "low":       "yashil",
}

COLOR_MAP = {
    "favqulodda": "#FF0000",
    "qizil":      "#FF4444",
    "sariq":      "#FFA500",
    "yashil":     "#4CAF50",
}


def predict_symptom_risk(features: Dict[str, Any], lang: str = "uz") -> Dict[str, Any]:
    """
    Foydalanuvchi simptomlaridan xavf darajasini aniqlaydi.

    Args:
        features: 39 ta feature (noma'lum qiymatlar 0 qabul qilinadi)
        lang: 'uz' | 'ru' | 'en'

    Returns:
        {
          "risk_level": "sariq",
          "color": "#FFA500",
          "emoji": "🟡",
          "recommendation": "...",
          "probabilities": {"low": 0.1, "medium": 0.6, ...},
          "predicted_class": "medium",
          "model_accuracy": 0.899,
          "triggered_risks": [...]
        }
    """
    art          = _load()
    feature_cols = art["feature_names"]
    scaler       = art["scaler"]
    model        = art["model"]
    le_y         = art["label_encoder"]

    # Noma'lum featurelar 0
    row = {col: features.get(col, 0) for col in feature_cols}
    X    = pd.DataFrame([row], columns=feature_cols)
    X_sc = scaler.transform(X)

    probs     = model.predict_proba(X_sc)[0]
    pred_idx  = int(np.argmax(probs))
    pred_cls  = le_y.classes_[pred_idx]          # 'emergency'|'high'|'medium'|'low'
    risk_uz   = RISK_MAP[pred_cls]               # 'favqulodda'|'qizil'|'sariq'|'yashil'

    emoji_map = {
        "favqulodda": "🚨",
        "qizil":      "🔴",
        "sariq":      "🟡",
        "yashil":     "🟢",
    }

    # Qaysi xavflar trigger bo'ldi
    triggered = _detect_triggered_risks(features)

    return {
        "risk_level":     risk_uz,
        "color":          COLOR_MAP[risk_uz],
        "emoji":          emoji_map[risk_uz],
        "recommendation": RECOMMENDATIONS[risk_uz].get(lang, RECOMMENDATIONS[risk_uz]["uz"]),
        "probabilities":  {cls: round(float(p), 4) for cls, p in zip(le_y.classes_, probs)},
        "predicted_class": pred_cls,
        "model_accuracy": round(art.get("test_accuracy", 0), 4),
        "triggered_risks": triggered,
        "version": art.get("version", "v4"),
    }


def _detect_triggered_risks(f: Dict) -> list:
    """Qaysi simptomlar xavf signali berdi."""
    triggered = []
    checks = [
        (f.get("vaginal_bleeding", 0) == 2,     "Ko'p qon ketish"),
        (f.get("one_sided_pain", 0) == 1,        "Bir tomonlama qorin og'rig'i (ektopik xavf)"),
        (f.get("visual_disturbance", 0) == 1,    "Ko'z oldida uchish (eklampsiya xavfi)"),
        (f.get("fetal_movement", 0) == 2,        "Homila harakati yo'q"),
        (f.get("fluid_leaking", 0) == 1,         "Qin suvi oqishi (PPROM)"),
        (f.get("bleeding_with_pain", 0) == 1,    "Qorin og'rig'i bilan qon ketish"),
        (f.get("fetal_movement_t3", 0) == 2,     "3-trimestda homila harakatsiz"),
        (f.get("painless_bleeding", 0) == 2,     "Og'riqsiz qon ketish (plasenta previa)"),
        (f.get("itching_palms_soles", 0) >= 2,   "Kaft/oyoq qichishi (jigar xolestazi)"),
        (f.get("post_term", 0) == 2,             "42+ hafta (muddati o'tgan)"),
        (f.get("fasting_glucose", 0) >= 2,       "Qon shakari yuqori (gestatsion diabet)"),
        (f.get("headache_severity", 0) == 2,     "Kuchli bosh og'rig'i"),
        (f.get("systolic_bp", 0) >= 140,         "Qon bosimi yuqori (≥140)"),
        (f.get("anemia_level", 0) >= 3,          "Og'ir anemiya"),
        (f.get("cervix_short", 0) == 1,          "Bachadon bo'yni qisqa (<25mm)"),
    ]
    for condition, name in checks:
        if condition:
            triggered.append(name)
    return triggered


# ─── Demo ────────────────────────────────────────────────────
if __name__ == "__main__":
    cases = [
        ("✅ Sog'lom (T2)", {
            "trimester_enc": 1, "age": 28, "gestational_week": 18,
            "systolic_bp": 115, "diastolic_bp": 75, "heart_rate": 80,
        }),
        ("🟡 Bosh og'riq + shish", {
            "trimester_enc": 1, "age": 32, "gestational_week": 24,
            "headache_severity": 2, "edema_level": 2,
            "systolic_bp": 145, "diastolic_bp": 95, "heart_rate": 90,
        }),
        ("🔴 ICP — kaft qichishi", {
            "trimester_enc": 2, "age": 29, "gestational_week": 33,
            "itching_palms_soles": 3,
            "systolic_bp": 116, "diastolic_bp": 74, "heart_rate": 82,
        }),
        ("🚨 Eklampsiya xavfi", {
            "trimester_enc": 2, "age": 35, "gestational_week": 34,
            "visual_disturbance": 1, "headache_severity": 2,
            "systolic_bp": 165, "diastolic_bp": 112, "heart_rate": 102,
        }),
    ]

    print("=" * 60)
    print("  ONAMIZ v4 — DEMO")
    print("=" * 60)
    for name, inp in cases:
        r = predict_symptom_risk(inp)
        print(f"\n{name}")
        print(f"  {r['emoji']} {r['risk_level'].upper()} — {r['recommendation']}")
        print(f"  Ehtimollar: {r['probabilities']}")
        if r["triggered_risks"]:
            print(f"  Xavf signallari: {', '.join(r['triggered_risks'])}")
