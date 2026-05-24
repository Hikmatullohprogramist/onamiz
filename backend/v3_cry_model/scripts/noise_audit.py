"""
To'liq dataset YAMNet noise auditi.

Har bir audio uchun YAMNet'ning quyidagi klasslari uchun confidence olamiz:
  - Baby cry, infant cry
  - Crying, sobbing
  - Whimper
  - Speech (anti-signal)
  - Animal (anti-signal)

Past confidence → noise/outlier kandidati.
Natijalar reports/noise_audit.csv ga saqlanadi.
"""
import os
import sys
import csv
import time
from pathlib import Path
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
import warnings
warnings.filterwarnings('ignore')

import numpy as np
import pandas as pd
import librosa
import tensorflow as tf
import tensorflow_hub as hub
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / 'data' / 'donateacry-corpus' / 'donateacry_corpus_cleaned_and_updated_data'
REPORTS = ROOT / 'reports'
REPORTS.mkdir(exist_ok=True)
CLASSES = ['hungry', 'tired', 'discomfort', 'burping', 'belly_pain']

# Threshold: cry_score (cry-related klasslar yig'indisi)
CRY_THRESHOLD = 0.15

COLORS = {'hungry': '#D86080', 'tired': '#7B3FB0',
          'discomfort': '#FF9F40', 'burping': '#4CAF50',
          'belly_pain': '#E91E63'}


def load_yamnet():
    print('YAMNet yuklanmoqda...')
    model = hub.load('https://tfhub.dev/google/yamnet/1')
    class_map_path = model.class_map_path().numpy().decode('utf-8')
    class_names = []
    with tf.io.gfile.GFile(class_map_path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            class_names.append(row['display_name'])

    # Cry/noise indekslari
    cry_idx = {}
    noise_idx = {}
    for i, name in enumerate(class_names):
        ln = name.lower()
        if any(t in ln for t in ['baby cry', 'crying', 'whimper', 'infant cry']):
            cry_idx[name] = i
        if any(t in ln for t in ['speech', 'animal', 'cat', 'dog',
                                  'meow', 'bark', 'music', 'silence']):
            noise_idx[name] = i
    print(f'✓ YAMNet tayyor. {len(cry_idx)} cry klass, '
          f'{len(noise_idx)} kuzatuv klass.\n')
    return model, class_names, cry_idx, noise_idx


def score_audio(model, audio_path, cry_idx, noise_idx):
    y, sr = librosa.load(audio_path, sr=16000, mono=True)
    waveform = tf.constant(y, dtype=tf.float32)
    scores, _, _ = model(waveform)
    mean_scores = scores.numpy().mean(axis=0)

    # Eng yuqori klass
    top_idx = int(mean_scores.argmax())

    return {
        'cry_score': float(sum(mean_scores[i] for i in cry_idx.values())),
        'baby_cry':  float(mean_scores[cry_idx.get('Baby cry, infant cry', 0)]),
        'crying':    float(mean_scores[cry_idx.get('Crying, sobbing', 0)]),
        'whimper':   float(mean_scores[cry_idx.get('Whimper', 0)]),
        'speech':    float(mean_scores[noise_idx.get('Speech', 0)]),
        'top_class': 'Unknown',  # filled below
        'top_score': float(mean_scores[top_idx]),
        '_top_idx':  top_idx,
    }


def main():
    model, class_names, cry_idx, noise_idx = load_yamnet()

    # Hamma fayllarni yig'amiz
    rows = []
    for cls in CLASSES:
        for f in sorted((DATA_DIR / cls).glob('*.wav')):
            rows.append({'class': cls, 'path': str(f), 'name': f.name})

    total = len(rows)
    print(f'{total} ta fayl YAMNet bilan o\'tkaziladi...\n')

    t0 = time.time()
    for i, row in enumerate(rows):
        s = score_audio(model, row['path'], cry_idx, noise_idx)
        s['top_class'] = class_names[s.pop('_top_idx')]
        row.update(s)

        if (i + 1) % 50 == 0 or i == total - 1:
            elapsed = time.time() - t0
            eta = elapsed / (i + 1) * (total - i - 1)
            print(f'  [{i+1:3d}/{total}]  '
                  f'elapsed {elapsed:.0f}s  eta {eta:.0f}s')

    df = pd.DataFrame(rows)
    df.to_csv(REPORTS / 'noise_audit.csv', index=False)
    print(f'\n✓ Saqlandi: reports/noise_audit.csv')

    print('\n' + '━' * 70)
    print('  📊 Cry score klass bo\'yicha')
    print('━' * 70)
    stats = df.groupby('class')['cry_score'].agg(
        ['mean', 'median', 'min', 'max', 'std']).round(3)
    stats = stats.reindex(CLASSES)
    stats['low_n'] = df.groupby('class').apply(
        lambda g: (g['cry_score'] < CRY_THRESHOLD).sum()).reindex(CLASSES)
    stats['total'] = df.groupby('class').size().reindex(CLASSES)
    stats['noise_pct'] = (stats['low_n'] / stats['total'] * 100).round(1)
    print(stats.to_string())

    # Outlier ro'yxati
    print(f'\n  ⚠️  cry_score < {CRY_THRESHOLD} (noise/outlier):')
    outliers = df[df['cry_score'] < CRY_THRESHOLD].sort_values('cry_score')
    print(f'      Jami: {len(outliers)} ta fayl ({len(outliers)/total*100:.1f}%)')
    print('\n      Klass bo\'yicha:')
    for cls in CLASSES:
        n = (outliers['class'] == cls).sum()
        total_cls = (df['class'] == cls).sum()
        print(f'        {cls:12s}  {n:3d} / {total_cls:3d}  '
              f'({n/total_cls*100:.1f}%)')

    print('\n      Eng yomon 10 ta:')
    for _, row in outliers.head(10).iterrows():
        print(f'        {row["class"]:11s}  '
              f'cry={row["cry_score"]:.3f}  '
              f'top="{row["top_class"]}"  '
              f'{row["name"][:40]}…')

    # Vizualizatsiya
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    # 1) Distribution per class
    for cls in CLASSES:
        sub = df[df['class'] == cls]
        axes[0].hist(sub['cry_score'], bins=20, alpha=0.55,
                     label=cls, color=COLORS[cls])
    axes[0].axvline(CRY_THRESHOLD, color='red', linestyle='--',
                    label=f'threshold = {CRY_THRESHOLD}')
    axes[0].set_xlabel('Cry score (YAMNet)')
    axes[0].set_ylabel('Sample soni')
    axes[0].set_title('Cry score taqsimoti klass bo\'yicha')
    axes[0].legend(fontsize=9)

    # 2) Boxplot
    sns.boxplot(data=df, x='class', y='cry_score', ax=axes[1],
                order=CLASSES,
                palette=[COLORS[c] for c in CLASSES])
    axes[1].axhline(CRY_THRESHOLD, color='red', linestyle='--')
    axes[1].set_title('Cry score — boxplot')
    axes[1].set_xlabel('')

    plt.tight_layout()
    plt.savefig(REPORTS / '04_noise_audit.png', bbox_inches='tight')
    plt.close()
    print(f'\n  saved → reports/04_noise_audit.png')

    # Toza dataset ro'yxati
    clean = df[df['cry_score'] >= CRY_THRESHOLD]
    clean_summary = clean.groupby('class').size().reindex(CLASSES)
    print(f'\n  ✅ Toza dataset (cry_score >= {CRY_THRESHOLD}):')
    print(f'      Jami: {len(clean)} ta')
    for cls in CLASSES:
        before = (df['class'] == cls).sum()
        after = clean_summary[cls]
        print(f'        {cls:12s}  {before:3d} → {after:3d}  '
              f'(-{before-after})')

    clean.to_csv(REPORTS / 'clean_dataset.csv', index=False)
    print(f'\n  saved → reports/clean_dataset.csv')


if __name__ == '__main__':
    main()
