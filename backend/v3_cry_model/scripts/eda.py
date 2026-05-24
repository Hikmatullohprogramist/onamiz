"""
Dataset EDA — statistika va vizualizatsiya.
Natijalar: reports/ papkasiga saqlanadi.
"""
import os
import sys
from pathlib import Path
from collections import Counter

import numpy as np
import pandas as pd
import librosa
import librosa.display
import matplotlib
matplotlib.use('Agg')  # headless
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.utils.class_weight import compute_class_weight

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / 'data' / 'donateacry-corpus' / 'donateacry_corpus_cleaned_and_updated_data'
REPORTS = ROOT / 'reports'
REPORTS.mkdir(exist_ok=True)

CLASSES = ['hungry', 'tired', 'discomfort', 'burping', 'belly_pain']
COLORS = {'hungry': '#D86080', 'tired': '#7B3FB0',
          'discomfort': '#FF9F40', 'burping': '#4CAF50',
          'belly_pain': '#E91E63'}

sns.set_style('whitegrid')
plt.rcParams['figure.dpi'] = 100


def collect_files():
    rows = []
    for cls in CLASSES:
        for f in sorted((DATA_DIR / cls).glob('*.wav')):
            rows.append({'class': cls, 'path': str(f),
                         'size_kb': f.stat().st_size / 1024})
    return pd.DataFrame(rows)


def audio_stats(path):
    y, sr = librosa.load(path, sr=None)
    return pd.Series({
        'duration': len(y) / sr,
        'sample_rate': sr,
        'rms': float(np.sqrt(np.mean(y ** 2))),
        'max_amp': float(np.max(np.abs(y))),
    })


def plot_class_balance(df):
    counts = df['class'].value_counts().reindex(CLASSES)
    fig, ax = plt.subplots(figsize=(9, 4.5))
    bars = ax.bar(counts.index, counts.values,
                  color=[COLORS[c] for c in counts.index])
    for bar, count in zip(bars, counts.values):
        ax.text(bar.get_x() + bar.get_width() / 2,
                bar.get_height() + 5, f'{count}',
                ha='center', fontweight='bold', fontsize=11)
    ax.set_title('Donate-a-Cry — Klass balansi',
                 fontsize=14, fontweight='bold')
    ax.set_ylabel('Sample soni')
    plt.tight_layout()
    out = REPORTS / '01_class_balance.png'
    plt.savefig(out, bbox_inches='tight')
    plt.close()
    print(f'  saved → {out.relative_to(ROOT)}')


def plot_duration_rms(df):
    fig, axes = plt.subplots(1, 2, figsize=(14, 4.5))
    for cls in CLASSES:
        sub = df[df['class'] == cls]
        axes[0].hist(sub['duration'], bins=15, alpha=0.55,
                     label=cls, color=COLORS[cls])
    axes[0].set_xlabel('Davomiylik (sekund)')
    axes[0].set_ylabel('Sample soni')
    axes[0].set_title('Audio davomiyligi taqsimoti')
    axes[0].legend()

    sns.boxplot(data=df, x='class', y='rms', ax=axes[1],
                order=CLASSES,
                palette=[COLORS[c] for c in CLASSES])
    axes[1].set_title("RMS energiya — klass bo'yicha")
    axes[1].set_ylabel('RMS')
    axes[1].set_xlabel('')
    plt.tight_layout()
    out = REPORTS / '02_duration_rms.png'
    plt.savefig(out, bbox_inches='tight')
    plt.close()
    print(f'  saved → {out.relative_to(ROOT)}')


def plot_spectrograms(df):
    fig, axes = plt.subplots(5, 1, figsize=(12, 14))
    for ax, cls in zip(axes, CLASSES):
        sample = df[df['class'] == cls].iloc[0]
        y, sr = librosa.load(sample['path'], sr=16000)
        mel = librosa.feature.melspectrogram(y=y, sr=sr,
                                              n_mels=128, fmax=8000)
        mel_db = librosa.power_to_db(mel, ref=np.max)
        librosa.display.specshow(mel_db, sr=sr, x_axis='time',
                                  y_axis='mel', ax=ax, fmax=8000)
        ax.set_title(f'{cls}  —  {sample["duration"]:.1f}s',
                     fontweight='bold', loc='left')
    plt.tight_layout()
    out = REPORTS / '03_spectrograms.png'
    plt.savefig(out, bbox_inches='tight')
    plt.close()
    print(f'  saved → {out.relative_to(ROOT)}')


def main():
    print('━' * 60)
    print('  Onamiz Cry Classifier — EDA')
    print('━' * 60)

    print(f'\nDataset:  {DATA_DIR}')
    df = collect_files()
    print(f'Jami:     {len(df)} ta audio fayl\n')

    # Class balance
    counts = df['class'].value_counts().reindex(CLASSES)
    pct = (counts / counts.sum() * 100).round(1)
    print('Klass balansi:')
    print('─' * 40)
    for cls in CLASSES:
        bar = '█' * int(pct[cls] / 2)
        print(f'  {cls:12s} │ {counts[cls]:4d}  ({pct[cls]:5.1f}%)  {bar}')
    print('─' * 40)
    print(f'\n⚠️  Ratio: hungry / burping = '
          f'{counts["hungry"] / counts["burping"]:.1f}x')

    # Audio stats
    print('\nAudio statistikalarni hisoblayapman... ', end='', flush=True)
    stats = df['path'].apply(audio_stats)
    df = pd.concat([df, stats], axis=1)
    print('✓')

    print('\nSample rate distribution:')
    for sr, cnt in df['sample_rate'].value_counts().items():
        print(f'  {int(sr)} Hz  →  {cnt} ta fayl')

    print("\nDavomiylik klass bo'yicha (sek):")
    dur = df.groupby('class')['duration'].agg(
        ['mean', 'min', 'max', 'std']).round(2)
    dur = dur.reindex(CLASSES)
    print(dur.to_string())

    # Class weights
    print('\nClass weights (balanced):')
    weights = compute_class_weight('balanced',
                                    classes=np.array(CLASSES),
                                    y=df['class'].values)
    for cls, w in zip(CLASSES, weights):
        print(f'  {cls:12s}  →  weight = {w:.2f}')

    # Augmentation plan
    print('\nAugmentation rejasi (target = 100 sample/klass):')
    for cls in CLASSES:
        cur = counts[cls]
        need = max(0, 100 - cur)
        mult = round(100 / cur, 1) if cur else 0
        if cur < 100:
            print(f'  {cls:12s}  +{need:3d} ta kerak  ({mult}x aug)')
        else:
            print(f'  {cls:12s}  yetarli (downsample yoki keep)')

    # Visualizations
    print('\nGrafiklarni saqlayapman...')
    plot_class_balance(df)
    plot_duration_rms(df)
    plot_spectrograms(df)

    # Save summary CSV
    summary = pd.DataFrame({'count': counts, 'pct': pct,
                            'class_weight': weights.round(3)})
    summary.to_csv(REPORTS / 'summary.csv')
    print(f'  saved → reports/summary.csv')

    print('\n' + '━' * 60)
    print('  ✅ EDA tugadi. reports/ papkasini ko\'ring.')
    print('━' * 60)


if __name__ == '__main__':
    main()
