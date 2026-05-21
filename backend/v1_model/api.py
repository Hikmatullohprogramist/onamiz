"""
V1 — FastAPI server

Modellarni REST API orqali ishlatish uchun.
Ishga tushirish:
    uvicorn api:app --reload
yoki
    python api.py

Swagger UI:  http://localhost:8000/docs
"""

from typing import Dict

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from predict import predict_fetal_health, predict_maternal_risk

app = FastAPI(
    title="Onalik & Homila Xavfini Aniqlash API",
    description="V1 — Homiladorlik va homila uchun ML asosidagi xavf bashorati",
    version="1.0.0",
)


class MaternalInput(BaseModel):
    Age: int = Field(..., ge=10, le=70, description="Yosh (10-70)")
    SystolicBP: int = Field(..., ge=60, le=250, description="Sistolik qon bosimi")
    DiastolicBP: int = Field(..., ge=40, le=160, description="Diastolik qon bosimi")
    BS: float = Field(..., ge=4, le=20, description="Qon shakari (mmol/L)")
    BodyTemp: float = Field(..., ge=95, le=105, description="Tana harorati (°F)")
    HeartRate: int = Field(..., ge=40, le=160, description="Yurak urishi (BPM)")


class FetalInput(BaseModel):
    """22 ta CTG feature. Maydon nomlari datasetdagidek bo'lishi kerak."""

    features: Dict[str, float]


@app.get("/")
def root():
    return {
        "name": "Maternal & Fetal Risk API",
        "version": "1.0.0",
        "endpoints": ["/predict/maternal", "/predict/fetal"],
    }


@app.post("/predict/maternal")
def maternal(payload: MaternalInput):
    try:
        return predict_maternal_risk(payload.model_dump())
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/predict/fetal")
def fetal(payload: FetalInput):
    try:
        return predict_fetal_health(payload.features)
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
