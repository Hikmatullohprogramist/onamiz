"""
Data preparation pipeline.

Bosqichlar:
  1. Toza datasetni yuklash (cry_score >= 0.15)
  2. Stratified train/val/test split (70/15/15) — augmentation faqat train'ga
  3. Audio augmentation (pitch, time, gain, noise) — kichik klasslar uchun
  4. YAMNet embeddings extract qilish (Mean + Max concat → 2048-dim)
  5. data/embeddings/{train,val,test}.npz ga saqlash

Bir marta yurib, train.py keyin embeddings'ni darhol yuklab oladi.
"""
import os
import sys
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
from sklearn.model_selection import train_test_split
from audiomentations import (
    Compose, PitchShift, TimeStretch, AddGaussianNoise, Gain
)

ROOT = Path(__file__).resolve().parent.parent
REPORTS = ROOT / 'reports'
EMB_DIR = ROOT / 'data' / 'embeddings'
EMB_DIR.mkdir(parents=True, exist_ok=True)

CLASSES = ['hungry', 'tired', 'discomfort', 'burping', 'belly_pain']
LABEL_MAP = {c: i for i, c in enumerate(CLASSES)}

# Target: train set'da har klass uchun shu sondagi sample
TARGET_PER_CLASS = 200

SR = 16000
SEED = 42
np.random.seed(SEED)


def load_clean_dataset():
    df = pd.read_csv(REPORTS / 'clean_dataset.csv')
    print(f'Toza dataset: {len(df)} ta sample')
    for cls in CLASSES:
        n = (df['class'] == cls).sum()
        print(f'  {cls:12s} {n:3d}')
    return df


def stratified_split(df):
    """Test 15%, val 15%, train 70% — stratified by class."""
    train_val, test = train_test_split(
        df, test_size=0.15, random_state=SEED,
        stratify=df['class'])
    # val 15% of total = 0.15 / 0.85 of train_val
    train, val = train_test_split(
        train_val, test_size=0.15 / 0.85, random_state=SEED,
        stratify=train_val['class'])
    print('\nSplit:')
    for name, sub in [('train', train), ('val', val), ('test', test)]:
        counts = sub['class'].value_counts().reindex(CLASSES).fillna(0).astype(int)
        print(f'  {name:6s} ({len(sub):3d}):  ' +
              '  '.join(f'{c}={counts[c]}' for c in CLASSES))
    return train, val, test


def build_augmenter():
    return Compose([
        PitchShift(min_semitones=-2, max_semitones=2, p=0.5),
        TimeStretch(min_rate=0.9, max_rate=1.1,
                    leave_length_unchanged=False, p=0.5),
        Gain(min_gain_db=-6, max_gain_db=6, p=0.4),
        AddGaussianNoise(min_amplitude=0.001, max_amplitude=0.01, p=0.3),
    ])


def load_yamnet():
    print('\nYAMNet yuklanmoqda...')
    return hub.load('https://tfhub.dev/google/yamnet/1')


def extract_embedding(model, audio):
    """Audio (numpy, 16kHz mono) → 2048-dim feature (mean+max concat)."""
    waveform = tf.constant(audio, dtype=tf.float32)
    _, embeddings, _ = model(waveform)
    emb = embeddings.numpy()  # (N_frames, 1024)
    mean_emb = emb.mean(axis=0)
    max_emb = emb.max(axis=0)
    return np.concatenate([mean_emb, max_emb])  # (2048,)


def fix_length(y, target_samples):
    """Trim/pad audio to fixed length."""
    if len(y) >= target_samples:
        return y[:target_samples]
    return np.pad(y, (0, target_samples - len(y)))


def load_audio(path):
    y, _ = librosa.load(path, sr=SR, mono=True)
    return fix_length(y, SR * 7)  # 7 sekund


def process_split(name, df, model, augmenter=None):
    """
    Embeddings extract qiladi.
    augmenter is not None bo'lsa, har sample uchun augmented variantlar yaratiladi.
    """
    print(f'\n━ {name.upper()} ({len(df)} sample) ━')

    X, y = [], []
    # Class-specific augmentation multipliers (only for train)
    aug_mult = {
        'hungry': 0,       # no aug, just downsample (handled separately)
        'tired': 7,
        'discomfort': 6,
        'burping': 20,     # extreme — only 7 samples baseline
        'belly_pain': 10,
    }

    t0 = time.time()
    sample_idx = 0
    for _, row in df.iterrows():
        cls = row['class']
        label = LABEL_MAP[cls]
        try:
            audio = load_audio(row['path'])
        except Exception as e:
            print(f'  ⚠️  skip {row["name"]}: {e}')
            continue

        # Original
        emb = extract_embedding(model, audio)
        X.append(emb)
        y.append(label)
        sample_idx += 1

        # Augmented (only for train)
        if augmenter is not None:
            n_aug = aug_mult.get(cls, 0)
            for _ in range(n_aug):
                aug_audio = augmenter(samples=audio, sample_rate=SR)
                aug_audio = fix_length(aug_audio, SR * 7)
                aug_emb = extract_embedding(model, aug_audio)
                X.append(aug_emb)
                y.append(label)
                sample_idx += 1

        if sample_idx % 50 == 0:
            print(f'  [{sample_idx:4d}]  elapsed {time.time()-t0:.0f}s')

    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.int32)
    print(f'  Final: X.shape={X.shape}  y.shape={y.shape}')

    # Klass balansi
    print('  Klass balansi:')
    for i, cls in enumerate(CLASSES):
        n = (y == i).sum()
        print(f'    {cls:12s} {n:4d}')

    out = EMB_DIR / f'{name}.npz'
    np.savez_compressed(out, X=X, y=y, classes=np.array(CLASSES))
    size_mb = out.stat().st_size / 1024 / 1024
    print(f'  saved → {out.relative_to(ROOT)}  ({size_mb:.2f} MB)')
    return X, y


def downsample_majority(df, target=TARGET_PER_CLASS):
    """hungry juda ko'p — train set'da TARGET ga tushiramiz."""
    parts = []
    for cls in CLASSES:
        sub = df[df['class'] == cls]
        if cls == 'hungry' and len(sub) > target:
            sub = sub.sample(target, random_state=SEED)
        parts.append(sub)
    return pd.concat(parts).reset_index(drop=True)


def main():
    print('━' * 60)
    print('  Data Preparation Pipeline')
    print('━' * 60)

    df = load_clean_dataset()
    train_df, val_df, test_df = stratified_split(df)

    # hungry'ni train set'da kamaytirish
    train_df = downsample_majority(train_df, target=TARGET_PER_CLASS)
    print(f'\nTrain (downsampled): {len(train_df)} ta')

    model = load_yamnet()
    augmenter = build_augmenter()

    process_split('train', train_df, model, augmenter=augmenter)
    process_split('val',   val_df,   model, augmenter=None)
    process_split('test',  test_df,  model, augmenter=None)

    # Class mapping ham saqlanadi
    np.save(EMB_DIR / 'class_names.npy', np.array(CLASSES))

    print('\n' + '━' * 60)
    print('  ✅ Data prep tugadi. train.py uchun tayyor.')
    print('━' * 60)


if __name__ == '__main__':
    main()
