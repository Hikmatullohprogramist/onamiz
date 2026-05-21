# Claude Code uchun prompt

Quyidagi promptni Claude Code'ga to'g'ridan-to'g'ri yuborib, v1 modelni ishga tushiring.

---

## PROMPT (nusxa olib, Claude Code'ga jo'nating):

Salom! Men homiladorlar va chaqaloqlar uchun xavfni erta aniqlovchi AI ilova qilyapman. Sizga v1 ML pipeline'ni tayyorlab keldim. Quyidagilarni qiling:

### 1-qadam: Loyihani tekshiring
- `README.md` ni o'qing
- `train.py`, `predict.py`, `api.py` fayllarini tushuning
- `requirements.txt` da qaysi paketlar borligini ko'ring

### 2-qadam: Muhitni tayyorlang
```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 3-qadam: Datasetlarni tekshiring
`data/` papkasida quyidagi 2 ta CSV bo'lishi kerak:
- `Maternal Health Risk Data Set.csv` — https://www.kaggle.com/datasets/csafrit2/maternal-health-risk-data
- `fetal_health.csv` — https://www.kaggle.com/datasets/andrewmvd/fetal-health-classification

Agar yo'q bo'lsa, menga ayting — qo'lda yuklayman.

### 4-qadam: Modellarni o'qiting
```bash
python train.py
```
Skript 3 ta algoritm (RandomForest, XGBoost, LightGBM) ni cross-validation bilan sinaydi va eng yaxshisini saqlaydi. Kutiladigan natija: 90%+ aniqlik.

### 5-qadam: Bashoratni tekshiring
```bash
python predict.py
```
Demo natija ko'rsatadi — agar `low/mid/high` ehtimollar bilan natija chiqsa, model ishlayapti.

### 6-qadam: API serverni sinab ko'ring
```bash
python api.py
```
Brauzerda `http://localhost:8000/docs` ni oching va `/predict/maternal` endpointini Swagger UI orqali sinang.

### 7-qadam: Yaxshilashlar qo'shing
V1 ishga tushgandan keyin quyidagilarni qo'shing (har biri alohida task):

**A. SHAP explainability** — har bir bashorat qaysi feature'ga bog'liq ekanini ko'rsatish. Tibbiy AI uchun majburiy. `predict.py` ga `explain=True` parametri qo'shing.

**B. ONNX eksport** — `train.py` oxirida modelni `.onnx` formatda ham saqlash. Bu TensorFlow Lite va Core ML orqali mobil ilovada ishlatish uchun kerak.

**C. Lokalizatsiya** — `predict.py` da `MATERNAL_RECOMMENDATIONS` va `FETAL_RECOMMENDATIONS` ni `i18n/` papkasidagi JSON fayllarga ko'chiring. O'zbek, rus, ingliz tillarini qo'shing.

**D. Logging** — `loguru` qo'shing va har bir bashoratni anonim tarzda yozing (model yaxshilash uchun keyinchalik kerak bo'ladi).

**E. Docker** — `Dockerfile` va `docker-compose.yml` qo'shing — production deployment uchun.

**F. Test'lar** — `pytest` ostida `tests/test_predict.py` yozing. Ekstremal qiymatlar (juda yuqori BP, juda past harorat) bilan modelni sinang.

**G. Validation chegaralari** — `api.py` da Pydantic schemalarini kengaytiring. Tibbiy jihatdan mantiqsiz qiymatlarda (masalan, 300/200 qon bosimi) avtomatik 400 xato qaytarsin.

### Qo'shimcha so'rovlar (keyingi sprint uchun):
- Postpartum depressiya skriningi (EPDS anketasi asosida) moduli qo'shish
- Chaqaloq o'sish percentillari (WHO Z-score) modulini qo'shish  
- Chaqaloq yig'isi tahlili (Donate-a-Cry corpus bilan TensorFlow modeli)

Boshlang. Birinchi 4 qadamni bajaring, natijalarni menga ko'rsating, keyin yaxshilashlarga o'taman.

---

## Maslahatlar

- Claude Code'ga ushbu loyihani `git init` qilib, GitHub'ga private repo qilib joylang
- `.env` faylida hech qanday secret saqlamang (hozircha kerak emas, lekin keyinchalik DB credentials uchun)
- Har bir o'qitishdan keyin `reports/` papkasidagi confusion matrix grafiklarini ko'rib chiqing
