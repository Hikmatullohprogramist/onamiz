# V1 — Homiladorlik & Homila xavfini aniqlash AI modeli

Bu loyiha ikkita ML modelni o'qitadi va ishga tushiradi:

1. **Maternal Risk Model** — homiladorda 3 xavf darajasini bashorat qiladi (low / mid / high) — ona klinik ko'rsatkichlari asosida.
2. **Fetal Health Model** — homilada 3 holatni bashorat qiladi (Normal / Suspect / Pathological) — kardiotokografiya (CTG) ma'lumotlari asosida.

Har bir model **foizlarda ehtimollikni qaytaradi** (masalan: 12% low, 65% mid, 23% high) — bu sizning ilovangizdagi yashil/sariq/qizil tizim uchun mos.

---

## Tezda boshlash

### 1. Datasetlarni `data/` papkasiga joylang

Quyidagi 2 ta CSV faylni yuklang:

| Fayl nomi | Manba |
|---|---|
| `data/Maternal Health Risk Data Set.csv` | https://www.kaggle.com/datasets/csafrit2/maternal-health-risk-data |
| `data/fetal_health.csv` | https://www.kaggle.com/datasets/andrewmvd/fetal-health-classification |

### 2. Dependentslarni o'rnating

```bash
pip install -r requirements.txt
```

### 3. Ikkala modelni o'qiting

```bash
python train.py
```

Skript avtomatik:
- 3 ta algoritmni (RandomForest, XGBoost, LightGBM) sinaydi
- 5-fold cross-validation bilan eng yaxshisini tanlaydi
- Modellarni `models/` papkasiga saqlaydi
- `reports/` papkasiga aniqlik hisobotini chiqaradi

### 4. Bashorat qiling

```bash
python predict.py
```

Yoki kod ichida:

```python
from predict import predict_maternal_risk, predict_fetal_health

# Misol 1: ona ma'lumotlari
result = predict_maternal_risk({
    "Age": 28, "SystolicBP": 130, "DiastolicBP": 85,
    "BS": 7.5, "BodyTemp": 98, "HeartRate": 78
})
# {'low': 0.12, 'mid': 0.65, 'high': 0.23, 'predicted_class': 'mid', 'risk_level': 'sariq'}

# Misol 2: homila CTG ma'lumotlari
result = predict_fetal_health({...22 ta feature...})
```

### 5. (Ixtiyoriy) API serverni ishga tushiring

```bash
python api.py
# http://localhost:8000/docs — Swagger interfeysi
```

---

## Loyiha tarkibi

```
v1_model/
├── README.md
├── requirements.txt
├── train.py            # asosiy o'qitish skripti
├── predict.py          # inference wrapper
├── api.py              # FastAPI server
├── data/               # datasetlar (CSV)
├── models/             # o'qitilgan modellar (.joblib)
└── reports/            # aniqlik hisobotlari, confusion matrix
```

---

## Claude Code uchun keyingi qadamlar

V1 ishga tushgandan keyin quyidagilarni qo'shish kerak:

1. **ONNX eksporti** — TensorFlow Lite va Core ML uchun mobil ilovaga joylashtirish
2. **SHAP explainability** — har bir bashorat qaysi feature'ga bog'liq ekanini ko'rsatish (tibbiy AI uchun majburiy)
3. **Asosiy backend** — FastAPI + PostgreSQL bilan to'liq REST API
4. **Lokalizatsiya** — natijalarni o'zbek tilida chiqarish (tushuntirishlar bilan)
5. **Mahalliy ma'lumot yig'ish moduli** — foydalanuvchilardan anonim ma'lumot to'plash uchun pipeline
6. **Postpartum depressiya skriningi** (EPDS) — onaning ruhiy salomatligi moduli
7. **Chaqaloq yig'isi moduli** (v2) — Donate-a-Cry + Baby Chillanto datasetlari bilan
