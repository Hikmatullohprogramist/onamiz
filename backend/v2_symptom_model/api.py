"""
Onamiz v4 — FastAPI server
Barcha endpointlar:
  GET  /              — status
  POST /predict       — asosiy bashorat (39 feature)
  POST /predict/quick — tez bashorat (faqat muhim simptomlar)
  GET  /risks         — barcha 42 xavf ro'yxati
  GET  /questions/{trimester} — trimestga mos savollar

Ishga tushirish:
  uvicorn api:app --reload --port 8001
yoki
  python api.py
"""

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
import json
from pathlib import Path
from predict import predict_symptom_risk

app = FastAPI(
    title="Onamiz API",
    description="Homiladorlik xavfini aniqlash — v4 (42 xavf, 39 feature)",
    version="4.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

ROOT = Path(__file__).parent


# ─── Schemalar ───────────────────────────────────────────────

class SymptomInput(BaseModel):
    # Asosiy
    trimester: str = Field(..., description="T1 | T2 | T3")
    age: int = Field(..., ge=14, le=55)
    gestational_week: int = Field(..., ge=1, le=45)

    # 1-trimest
    vaginal_bleeding: int    = Field(0, ge=0, le=2)
    one_sided_pain: int      = Field(0, ge=0, le=1)
    nausea_severity: int     = Field(0, ge=0, le=4)
    urinary_burning: int     = Field(0, ge=0, le=1)
    fever: int               = Field(0, ge=0, le=2)
    dizziness: int           = Field(0, ge=0, le=2)
    prev_miscarriage: int    = Field(0, ge=0, le=2)
    thyroid_symptoms: int    = Field(0, ge=0, le=3)
    rh_checked: int          = Field(1, ge=0, le=1)

    # 2-trimest
    headache_severity: int   = Field(0, ge=0, le=2)
    visual_disturbance: int  = Field(0, ge=0, le=1)
    edema_level: int         = Field(0, ge=0, le=3)
    fetal_movement: int      = Field(0, ge=0, le=2)
    epigastric_pain: int     = Field(0, ge=0, le=2)
    sudden_weight_gain: int  = Field(0, ge=0, le=1)
    fluid_leaking: int       = Field(0, ge=0, le=1)
    painless_bleeding: int   = Field(0, ge=0, le=2)
    fasting_glucose: int     = Field(0, ge=0, le=3)
    cervix_short: int        = Field(0, ge=0, le=1)
    belly_very_large: int    = Field(0, ge=0, le=1)

    # 3-trimest
    fetal_movement_t3: int   = Field(0, ge=0, le=2)
    contractions: int        = Field(0, ge=0, le=2)
    bleeding_with_pain: int  = Field(0, ge=0, le=1)
    shortness_of_breath: int = Field(0, ge=0, le=2)
    itching_palms_soles: int = Field(0, ge=0, le=3)
    post_term: int           = Field(0, ge=0, le=2)

    # Vital
    systolic_bp: float       = Field(120.0, ge=60, le=250)
    diastolic_bp: float      = Field(80.0, ge=40, le=160)
    heart_rate: float        = Field(80.0, ge=40, le=200)

    # O'zbekiston xususiy
    anemia_level: int        = Field(0, ge=0, le=3)
    iron_supplement: int     = Field(0, ge=0, le=1)
    parity: int              = Field(0, ge=0, le=2)
    prenatal_visits: int     = Field(0, ge=0, le=2)
    nutrition_poor: int      = Field(0, ge=0, le=1)
    rural: int               = Field(0, ge=0, le=1)
    pph_history: int         = Field(0, ge=0, le=1)

    # Til
    lang: str                = Field("uz", description="uz | ru | en")


class QuickInput(BaseModel):
    """
    Kunlik tekshiruv — trimestga mos savollar javoblari.
    Barcha trimest-xususiy maydonlar ixtiyoriy (default 0).
    """
    trimester: str
    age: int          = Field(..., ge=14, le=55)
    gestational_week: int = Field(..., ge=1, le=45)

    # Vital (default normal qiymatlar)
    systolic_bp: float  = Field(120.0, ge=60, le=250)
    diastolic_bp: float = Field(80.0,  ge=40, le=160)
    heart_rate: float   = Field(80.0,  ge=40, le=200)

    # ── T1 savollar ──────────────────────────────────────────
    vaginal_bleeding:  int = Field(0, ge=0, le=2)   # qon ketish
    one_sided_pain:    int = Field(0, ge=0, le=1)   # ektopik xavf
    nausea_severity:   int = Field(0, ge=0, le=4)   # hyperemesis
    dizziness:         int = Field(0, ge=0, le=3)   # anemiya
    fever:             int = Field(0, ge=0, le=2)   # infeksiya
    urinary_burning:   int = Field(0, ge=0, le=1)   # UTI

    # ── T2 savollar ──────────────────────────────────────────
    headache_severity:  int = Field(0, ge=0, le=2)  # preeklampsia
    visual_disturbance: int = Field(0, ge=0, le=1)  # eklampsiya
    edema_level:        int = Field(0, ge=0, le=3)  # shish
    fetal_movement:     int = Field(0, ge=0, le=2)  # fetal distress
    painless_bleeding:  int = Field(0, ge=0, le=2)  # plasenta previa
    sudden_weight_gain: int = Field(0, ge=0, le=1)  # preeklampsia

    # ── T3 savollar ──────────────────────────────────────────
    fetal_movement_t3:   int = Field(0, ge=0, le=2) # gipoksiya
    contractions:        int = Field(0, ge=0, le=2) # erta tug'ruq
    bleeding_with_pain:  int = Field(0, ge=0, le=1) # plasenta ajralishi
    itching_palms_soles: int = Field(0, ge=0, le=3) # jigar xolestazi
    shortness_of_breath: int = Field(0, ge=0, le=2) # o'pka shishi

    # ── Profil (onboarding dan keladigan ma'lumotlar) ─────────
    anemia_level:   int = Field(0, ge=0, le=3)
    parity:         int = Field(0, ge=0, le=2)
    rural:          int = Field(0, ge=0, le=1)

    lang: str = Field("uz", description="uz | ru | en")


# ─── Trimest encoder ─────────────────────────────────────────
TRIMESTER_ENC = {"T1": 0, "T2": 1, "T3": 2}


def _to_features(data: dict) -> dict:
    """Pydantic dict → model uchun feature dict"""
    trimester_enc = TRIMESTER_ENC.get(data.get("trimester", "T2"), 1)
    data["trimester_enc"] = trimester_enc
    return data


# ─── Endpointlar ─────────────────────────────────────────────

@app.get("/")
def root():
    return {
        "name": "Onamiz API",
        "version": "4.0.0",
        "risks": 42,
        "features": 39,
        "endpoints": {
            "POST /predict":        "To'liq bashorat (39 feature)",
            "POST /predict/quick":  "Tez bashorat (asosiy simptomlar)",
            "GET  /risks":          "Barcha 42 xavf ro'yxati",
            "GET  /questions/{t}":  "Trimest savollari",
            "GET  /health":         "Server holati",
        }
    }


@app.get("/health")
def health():
    try:
        from predict import _load
        art = _load()
        return {
            "status": "ok",
            "model": art.get("best_model_name"),
            "accuracy": round(art.get("test_accuracy", 0) * 100, 2),
            "version": art.get("version"),
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


@app.post("/predict")
def predict(payload: SymptomInput):
    try:
        features = _to_features(payload.model_dump())
        lang     = features.pop("lang", "uz")
        trimester = features.pop("trimester", "T2")
        return predict_symptom_risk(features, lang=lang)
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/predict/quick")
def predict_quick(payload: QuickInput):
    """
    Kunlik tekshiruv bashorati.
    Trimestga mos barcha savollar javoblari qabul qilinadi.
    Berilmagan maydonlar avtomatik 0 deb hisoblanadi.
    """
    try:
        features   = _to_features(payload.model_dump())
        lang       = features.pop("lang", "uz")
        features.pop("trimester", None)   # trimester_enc allaqachon qo'shildi
        return predict_symptom_risk(features, lang=lang)
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/risks")
def get_risks():
    """Barcha 42 xavf ro'yxati trimest bo'yicha"""
    return {
        "total": 42,
        "T1": [
            "Ektopik homila", "Spontan abort", "Hyperemesis gravidarum",
            "UTI / Pielonefrit", "Infeksiya / Sepsis", "Anemiya",
            "Takroriy abort xavfi", "Tireoid kasalligi", "Rh mos kelmaslik",
            "Erta homiladorlik asoratlari", "STI xavfi"
        ],
        "T2": [
            "Preeklampsia", "Og'ir preeklampsia", "HELLP sindrom",
            "Fetal distress", "PPROM", "Gestatsion diabet",
            "Suyuqlik ushlanishi", "Plasenta qoplag'i",
            "Bachadon bo'yni zaiflik", "Ko'p suv (polihidramnios)"
        ],
        "T3": [
            "Eklampsiya", "Homila gipoksiyasi", "Muddatidan oldin tug'ruq",
            "Plasenta ajralishi", "O'pka shishi", "IUGR",
            "Jigar xolestazi (ICP)", "Ko'p suv", "42+ hafta (post-term)",
            "GDM nazorat", "Plasenta qoplag'i T3"
        ],
        "PP": [
            "Postpartum depressiya (EPDS <10)",
            "Og'ir postpartum depressiya (EPDS 13+)",
            "O'ziga zarar yetkazish xavfi"
        ],
        "uzbekistan": [
            "Anemiya (kamqonlik)", "Obstetrik qon ketish",
            "Ko'p homiladorlik xavfi", "Tibbiy xizmatga yetish muammosi",
            "Oziqlanish yetishmovchiligi", "STI xavfi (o'smirlarda)",
        ]
    }


@app.get("/questions/{trimester}")
def get_questions(
    trimester: str,
    lang: str = Query("uz", description="uz | ru | en")
):
    """Trimestga mos savollarni qaytaradi"""
    json_path = ROOT / "data" / "pregnancy_risks.json"
    if not json_path.exists():
        raise HTTPException(status_code=404, detail="pregnancy_risks.json topilmadi")

    with open(json_path, encoding="utf-8") as f:
        data = json.load(f)

    t = trimester.upper()
    if t not in data.get("symptom_questions", {}):
        raise HTTPException(status_code=404, detail=f"Trimest topilmadi: {trimester}")

    questions = data["symptom_questions"][t]
    return {
        "trimester": t,
        "count": len(questions),
        "questions": questions,
        "push_schedule": [
            s for s in data.get("push_schedule", {}).get(t, [])
        ]
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
