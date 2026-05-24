# Onamiz — Cry Classification Model (v3)

Chaqaloq yig'isini 5 ta sababga ko'ra klassifikatsiya qiluvchi on-device model.

## Klasslar

| Klass | Ma'no |
|-------|-------|
| `hungry` | Och |
| `tired` | Charchagan / uxlagisi kelmoqda |
| `discomfort` | Noqulay (taglik, harorat, kiyim) |
| `burping` | Kekirish kerak |
| `belly_pain` | Qorin og'rig'i / gaz |

## Arxitektura

```
Audio (3s, 16kHz mono)
   ↓
Mel-spectrogram (128 mels)
   ↓
YAMNet (frozen) → 1024-dim embedding
   ↓
Dense(256) + Dropout(0.4)
   ↓
Dense(128) + Dropout(0.3)
   ↓
Dense(5, softmax)
```

**Output:** TFLite (~5-10MB) — Flutter app ichida ishlaydi.

## Dataset

- **Donate-a-Cry Corpus** (~457 sample, 5 klass)
- Manba: https://github.com/gveres/donateacry-corpus
- **Diqqat:** Imbalanced — `hungry` ~80%

## Sozlash

```bash
# Virtual environment
python -m venv .venv
source .venv/bin/activate

# Dependencies
pip install -r requirements.txt

# Dataset (GitHub'dan)
git clone https://github.com/gveres/donateacry-corpus.git data/donateacry-corpus
```

## Roadmap

- [x] Loyiha strukturasi
- [ ] Dataset klonlash + EDA
- [ ] Baseline model (YAMNet + MLP)
- [ ] Augmentation + class weights
- [ ] TFLite konvertatsiya
- [ ] Flutter integratsiya

## Litsenziya

Akademik tadqiqot va shaxsiy foydalanish uchun. Tashxis vositasi emas.
