"""
Onamiz v3 — Cry Detection API.

Endpoints:
  GET  /health           — server status
  POST /cry/detect       — audio fayl yuboriladi, baby_cry detection

Ishga tushirish:
  uvicorn api:app --reload --port 8002

Honest scope:
  Bu API faqat YIG'I aniqlanganini tasdiqlaydi (binary).
  Sababini bashorat qilmaydi — chunki yetarli ma'lumot yo'q.
  UI tomonida foydalanuvchiga 5 ta umumiy sabab tarbiyaviy ko'rsatiladi.
"""
import os
import io
import tempfile
import csv
from pathlib import Path
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
import warnings
warnings.filterwarnings('ignore')

import numpy as np
import librosa
import tensorflow as tf
import tensorflow_hub as hub
import joblib


def _mfcc_features(audio, sr=16000):
    """V3 model uchun hand-crafted features (78+10 = 88-dim)."""
    mfcc = librosa.feature.mfcc(y=audio, sr=sr, n_mfcc=13)
    delta = librosa.feature.delta(mfcc)
    delta2 = librosa.feature.delta(mfcc, order=2)
    mfcc_full = np.vstack([mfcc, delta, delta2])

    spec_centroid = librosa.feature.spectral_centroid(y=audio, sr=sr)
    spec_bw       = librosa.feature.spectral_bandwidth(y=audio, sr=sr)
    spec_rolloff  = librosa.feature.spectral_rolloff(y=audio, sr=sr)
    zcr           = librosa.feature.zero_crossing_rate(audio)
    rms           = librosa.feature.rms(y=audio)
    extra = np.vstack([spec_centroid, spec_bw, spec_rolloff, zcr, rms])

    return np.concatenate([
        mfcc_full.mean(axis=1), mfcc_full.std(axis=1),
        extra.mean(axis=1), extra.std(axis=1),
    ])
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware

ROOT = Path(__file__).parent
SR = 16000

# Confidence thresholds (cry-related klasslar yig'indisi bo'yicha)
CRY_THRESHOLD = 0.20   # past — yig'i emas
HIGH_CONFIDENCE = 0.50  # yuqori ishonch

# v3: 3-klass ensemble (needs / discomfort / pain)
# v2 legacy: 5-klass LogReg (~22% balanced accuracy)
CLASS_NAMES_V3 = ['needs', 'discomfort', 'pain']
CLASSIFIER_V3_PATH = ROOT / 'models' / 'cry_classifier_v3.joblib'
CLASS_NAMES_V2 = ['hungry', 'tired', 'discomfort', 'burping', 'belly_pain']
CLASSIFIER_V2_PATH = ROOT / 'models' / 'cry_classifier_lr.joblib'

app = FastAPI(
    title='Onamiz Cry Detection API',
    description='YAMNet asosida chaqaloq yig\'isini aniqlash (binary detection)',
    version='3.0.0',
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_methods=['*'],
    allow_headers=['*'],
)

# ─── Model lazy load ─────────────────────────────────────
_yamnet = None
_cry_indices = None
_classifier = None


def get_yamnet():
    global _yamnet, _cry_indices
    if _yamnet is None:
        print('YAMNet yuklanmoqda...')
        _yamnet = hub.load('https://tfhub.dev/google/yamnet/1')
        class_map_path = _yamnet.class_map_path().numpy().decode('utf-8')
        cry_idx = {}
        with tf.io.gfile.GFile(class_map_path) as f:
            reader = csv.DictReader(f)
            for i, row in enumerate(reader):
                name = row['display_name'].lower()
                if any(t in name for t in ['baby cry', 'crying',
                                            'whimper', 'infant cry']):
                    cry_idx[row['display_name']] = i
        _cry_indices = cry_idx
        print(f'✓ YAMNet tayyor. Cry klasslari: {list(cry_idx.keys())}')
    return _yamnet, _cry_indices


def get_classifier():
    """V3 (3-klass ensemble) ni afzal ko'rib, mavjud bo'lmasa v2 (5-klass LR)."""
    global _classifier
    if _classifier is None:
        if CLASSIFIER_V3_PATH.exists():
            print(f'Classifier yuklanmoqda (v3): {CLASSIFIER_V3_PATH.name}')
            _classifier = {
                'pipeline': joblib.load(CLASSIFIER_V3_PATH),
                'classes': CLASS_NAMES_V3,
                'version': 'v3',
                'features': 'yamnet+mfcc',
            }
            print('✓ V3 classifier tayyor (3 klass ensemble)')
        elif CLASSIFIER_V2_PATH.exists():
            print(f'Classifier yuklanmoqda (v2): {CLASSIFIER_V2_PATH.name}')
            _classifier = {
                'pipeline': joblib.load(CLASSIFIER_V2_PATH),
                'classes': CLASS_NAMES_V2,
                'version': 'v2',
                'features': 'yamnet_only',
            }
            print('✓ V2 classifier tayyor (5 klass LogReg, ~22%)')
    return _classifier


# ─── Endpoints ──────────────────────────────────────────

@app.get('/')
def root():
    return {
        'name': 'Onamiz Cry Detection API',
        'version': '3.0.0',
        'scope': 'binary cry detection (yig\'i aniqlash)',
        'note': "Sababi bashorat qilinmaydi — UI'da tarbiyaviy ma'lumot ko'rsatiladi",
        'endpoints': {
            'GET /health':        'Server status',
            'POST /cry/detect':   'Audio fayl → cry detection',
        },
    }


@app.get('/health')
def health():
    try:
        get_yamnet()
        return {'status': 'ok', 'model': 'yamnet'}
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


@app.post('/cry/detect')
async def detect_cry(audio: UploadFile = File(...)):
    """
    Audio fayl qabul qiladi (m4a/wav/mp3), YAMNet bilan baby_cry tekshiradi.

    Response:
      {
        "is_cry": bool,
        "confidence": float (0.0-1.0),
        "level": "high" | "medium" | "low",
        "duration_sec": float,
        "top_class": str,
      }
    """
    model, cry_idx = get_yamnet()

    # Audio'ni vaqtinchalik faylga yozish
    ext = Path(audio.filename or 'audio').suffix or '.m4a'
    with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as tmp:
        content = await audio.read()
        tmp.write(content)
        tmp_path = tmp.name

    try:
        # librosa istalgan format'ni o'qiy oladi (ffmpeg orqali)
        try:
            y, _ = librosa.load(tmp_path, sr=SR, mono=True)
        except Exception as e:
            raise HTTPException(
                status_code=400,
                detail=f"Audio o'qib bo'lmadi: {e}",
            )

        duration = len(y) / SR
        if duration < 0.5:
            raise HTTPException(
                status_code=400,
                detail='Audio juda qisqa (< 0.5s)',
            )

        # YAMNet inference
        waveform = tf.constant(y, dtype=tf.float32)
        scores, embeddings, _ = model(waveform)
        mean_scores = scores.numpy().mean(axis=0)
        mean_emb = embeddings.numpy().mean(axis=0)  # 1024-dim

        # Cry confidence — barcha cry klasslarning yig'indisi
        # (Baby cry + Crying, sobbing + Whimper + Infant cry)
        # 1.0 dan yuqori ham bo'lishi mumkin (multilabel kabi)
        cry_confidences = {name: float(mean_scores[i])
                            for name, i in cry_idx.items()}
        max_cry_class = max(cry_confidences, key=cry_confidences.get)
        cry_score = min(1.0, sum(cry_confidences.values()))

        # Eng yuqori klass (debugging uchun)
        top_idx = int(mean_scores.argmax())
        class_map_path = model.class_map_path().numpy().decode('utf-8')
        with tf.io.gfile.GFile(class_map_path) as f:
            reader = csv.DictReader(f)
            class_names = [row['display_name'] for row in reader]
        top_class = class_names[top_idx]

        is_cry = cry_score >= CRY_THRESHOLD
        if cry_score >= HIGH_CONFIDENCE:
            level = 'high'
        elif cry_score >= CRY_THRESHOLD:
            level = 'medium'
        else:
            level = 'low'

        # ─── Sabab predictions (TAXMINIY) ──────────
        predictions = None
        predictions_version = None
        if is_cry:
            clf_info = get_classifier()
            if clf_info is not None:
                pipeline = clf_info['pipeline']
                classes = clf_info['classes']
                version = clf_info['version']

                # V3 — YAMNet + MFCC
                if clf_info['features'] == 'yamnet+mfcc':
                    mfcc = _mfcc_features(y, SR)
                    feat = np.concatenate([mean_emb, mfcc]).reshape(1, -1)
                else:
                    feat = mean_emb.reshape(1, -1)

                probs = pipeline.predict_proba(feat)[0]
                predictions = {
                    name: round(float(p), 4)
                    for name, p in zip(classes, probs)
                }
                predictions_version = version

        # Disclaimer matni model versiyasiga qarab
        pred_note = None
        if predictions:
            if predictions_version == 'v3':
                pred_note = ('Taxminiy natija — 3 klass ensemble model. '
                              'Tibbiy tashxis o\'rnini bosa olmaydi.')
            else:
                pred_note = ('Taxminiy natija — model aniqligi cheklangan. '
                              'Tibbiy tashxis sifatida ishlatmang.')

        return {
            'is_cry': is_cry,
            'confidence': round(cry_score, 3),
            'level': level,
            'duration_sec': round(duration, 2),
            'top_class': top_class,
            'matched_cry_class': max_cry_class,
            'predictions': predictions,
            'predictions_version': predictions_version,
            'predictions_note': pred_note,
        }

    finally:
        try:
            os.remove(tmp_path)
        except Exception:
            pass


if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host='0.0.0.0', port=8002)
