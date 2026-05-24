"""
YAMNet sanity check.

YAMNet — Google'ning AudioSet'da train qilingan modeli (521 audio klass).
Bu skript:
  1. YAMNet'ni TF Hub'dan yuklaydi
  2. Bizning datasetimizdan har klassdan 3 ta sample oladi
  3. YAMNet'ni ishga tushiradi, top-5 klassni ko'rsatadi
  4. 'baby_cry' / 'crying' confidence darajasini tekshiradi

Maqsad: YAMNet bizning audio'larda yig'i ekanligini aniqlay oladimi?
Agar javob 'ha' bo'lsa, transfer learning'da kuchli vositamiz bor.
"""
import os
import sys
from pathlib import Path
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
import warnings
warnings.filterwarnings('ignore')

import numpy as np
import librosa
import tensorflow as tf
import tensorflow_hub as hub
import csv

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / 'data' / 'donateacry-corpus' / 'donateacry_corpus_cleaned_and_updated_data'
CLASSES = ['hungry', 'tired', 'discomfort', 'burping', 'belly_pain']

YAMNET_URL = 'https://tfhub.dev/google/yamnet/1'


def load_yamnet():
    print('YAMNet yuklanmoqda... (birinchi marta ~10MB)')
    model = hub.load(YAMNET_URL)
    class_map_path = model.class_map_path().numpy().decode('utf-8')
    class_names = []
    with tf.io.gfile.GFile(class_map_path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            class_names.append(row['display_name'])
    print(f'✓ YAMNet tayyor. {len(class_names)} ta AudioSet klass mavjud.\n')
    return model, class_names


def run_yamnet(model, audio_path):
    y, sr = librosa.load(audio_path, sr=16000, mono=True)
    waveform = tf.constant(y, dtype=tf.float32)
    scores, embeddings, spectrogram = model(waveform)
    scores_np = scores.numpy()
    mean_scores = scores_np.mean(axis=0)
    return mean_scores, embeddings.numpy()


def get_cry_indices(class_names):
    cry_terms = ['baby cry', 'baby cry, infant cry', 'crying',
                 'crying, sobbing', 'infant cry', 'whimper']
    indices = {}
    for i, name in enumerate(class_names):
        lname = name.lower()
        for term in cry_terms:
            if term in lname:
                indices[name] = i
                break
    return indices


def main():
    model, class_names = load_yamnet()

    cry_idx = get_cry_indices(class_names)
    print('🔍 Cry-related AudioSet klasslari:')
    for name, idx in cry_idx.items():
        print(f'  [{idx}]  {name}')
    print()

    print('━' * 70)
    print('  Har klassdan 3 ta sample → YAMNet top-5')
    print('━' * 70)

    total_baby_cry_conf = []
    total_any_cry_conf = []

    for cls in CLASSES:
        files = sorted((DATA_DIR / cls).glob('*.wav'))[:3]
        print(f'\n▌ {cls.upper()}')
        for f in files:
            mean_scores, embeddings = run_yamnet(model, str(f))
            top5 = np.argsort(mean_scores)[::-1][:5]

            # 'Baby cry' specific
            baby_cry_score = mean_scores[cry_idx.get('Baby cry, infant cry', 0)]
            any_cry_score = max(mean_scores[i] for i in cry_idx.values())
            total_baby_cry_conf.append(baby_cry_score)
            total_any_cry_conf.append(any_cry_score)

            print(f'  {f.name[:38]}…')
            print(f'    Embedding shape: {embeddings.shape}')
            for rank, idx in enumerate(top5, 1):
                marker = ' 👶' if idx in cry_idx.values() else ''
                print(f'    #{rank}  {class_names[idx]:35s}  '
                      f'{mean_scores[idx]:.3f}{marker}')

    print('\n' + '━' * 70)
    print('  📊 Statistik xulosa (15 ta sample)')
    print('━' * 70)
    bc = np.array(total_baby_cry_conf)
    ac = np.array(total_any_cry_conf)
    print(f"  'Baby cry, infant cry' confidence:")
    print(f'      mean = {bc.mean():.3f}   min = {bc.min():.3f}   '
          f'max = {bc.max():.3f}')
    print(f"  Eng kuchli cry klass (har 6 dan biri):")
    print(f'      mean = {ac.mean():.3f}   min = {ac.min():.3f}   '
          f'max = {ac.max():.3f}')

    print('\n  ✅ Xulosa:')
    if bc.mean() > 0.3:
        print('    YAMNet bizning audio\'larni yig\'i deb yaxshi aniqlaydi.')
        print('    Transfer learning uchun mukammal feature extractor.')
    elif ac.mean() > 0.3:
        print('    YAMNet umumiy "crying" ni aniqlaydi (baby_cry emas).')
        print('    Embedding\'lar baribir foydali.')
    else:
        print('    ⚠️  YAMNet confidence past — embedding sifati shubhali.')

    print(f'\n  Embedding dimension: 1024')
    print(f'  Audio sekundiga: ~2 ta embedding (har 0.48s)')
    print(f'  → Klassifikatsiya uchun: mean pooling yoki LSTM')


if __name__ == '__main__':
    main()
