"""
Cry classifier — v2: Logistic Regression + Cross-Validation.

v1 (MLP) overfit qildi: minority klasslar uchun F1 = 0.
Sabab: 5 ta asl burping sample'dan 105 ta augmented → model yodlab oldi.

v2 yondashuv:
  1. Soddaroq model — Logistic Regression (transfer learning gold standard)
  2. Stratified 5-fold CV — kichik test setdan ishonchli metrika
  3. Mean pooling — 1024-dim (2048 emas), kamroq overfit
  4. Augmentation har fold'da train fold'iga, val fold'i toza qoladi
"""
import os
import sys
import json
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
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import (
    classification_report, confusion_matrix, f1_score,
    accuracy_score, balanced_accuracy_score
)
from sklearn.utils.class_weight import compute_class_weight
from audiomentations import (
    Compose, PitchShift, TimeStretch, AddGaussianNoise, Gain
)
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
import joblib

ROOT = Path(__file__).resolve().parent.parent
REPORTS = ROOT / 'reports'
MODELS = ROOT / 'models'
MODELS.mkdir(exist_ok=True)
CLASSES = ['hungry', 'tired', 'discomfort', 'burping', 'belly_pain']
LABEL_MAP = {c: i for i, c in enumerate(CLASSES)}
SR = 16000
SEED = 42
N_FOLDS = 5

# Augmentation multipliers (train fold only)
AUG_MULT = {
    'hungry': 0,       # downsample to ~80/fold
    'tired': 5,
    'discomfort': 4,
    'burping': 15,
    'belly_pain': 8,
}
HUNGRY_TARGET_PER_FOLD = 80

np.random.seed(SEED)


def load_yamnet():
    print('YAMNet yuklanmoqda...')
    return hub.load('https://tfhub.dev/google/yamnet/1')


def fix_length(y, target_samples):
    if len(y) >= target_samples:
        return y[:target_samples]
    return np.pad(y, (0, target_samples - len(y)))


def load_audio(path):
    y, _ = librosa.load(path, sr=SR, mono=True)
    return fix_length(y, SR * 7)


def extract_embedding(model, audio):
    """Mean pooling only — 1024-dim."""
    waveform = tf.constant(audio, dtype=tf.float32)
    _, embeddings, _ = model(waveform)
    return embeddings.numpy().mean(axis=0)


def build_augmenter():
    return Compose([
        PitchShift(min_semitones=-2, max_semitones=2, p=0.5),
        TimeStretch(min_rate=0.9, max_rate=1.1,
                    leave_length_unchanged=False, p=0.5),
        Gain(min_gain_db=-6, max_gain_db=6, p=0.4),
        AddGaussianNoise(min_amplitude=0.001, max_amplitude=0.01, p=0.3),
    ])


def featurize(df, model, augmenter=None, augment=False):
    """DataFrame → (X, y). augment=True bo'lsa train fold uchun."""
    X, y = [], []
    for _, row in df.iterrows():
        cls = row['class']
        label = LABEL_MAP[cls]
        audio = load_audio(row['path'])

        # Original
        X.append(extract_embedding(model, audio))
        y.append(label)

        if augment and augmenter is not None:
            n_aug = AUG_MULT.get(cls, 0)
            for _ in range(n_aug):
                aug_audio = augmenter(samples=audio, sample_rate=SR)
                aug_audio = fix_length(aug_audio, SR * 7)
                X.append(extract_embedding(model, aug_audio))
                y.append(label)
    return np.array(X, dtype=np.float32), np.array(y, dtype=np.int32)


def downsample_hungry(df, target):
    parts = []
    for cls in CLASSES:
        sub = df[df['class'] == cls]
        if cls == 'hungry' and len(sub) > target:
            sub = sub.sample(target, random_state=SEED)
        parts.append(sub)
    return pd.concat(parts).reset_index(drop=True)


def main():
    print('━' * 60)
    print('  Cry Classifier — v2 (LogReg + CV)')
    print('━' * 60)

    df = pd.read_csv(REPORTS / 'clean_dataset.csv').reset_index(drop=True)
    print(f'\nToza dataset: {len(df)} sample')
    for cls in CLASSES:
        print(f'  {cls:12s} {(df["class"]==cls).sum():3d}')

    # YAMNet bir marta yuklaymiz
    model = load_yamnet()
    augmenter = build_augmenter()

    y_full = df['class'].map(LABEL_MAP).values
    skf = StratifiedKFold(n_splits=N_FOLDS, shuffle=True, random_state=SEED)

    fold_metrics = []
    all_y_true = []
    all_y_pred = []

    print(f'\n━ {N_FOLDS}-fold Cross-Validation ━\n')
    for fold_idx, (train_idx, val_idx) in enumerate(skf.split(df, y_full), 1):
        t0 = time.time()
        train_df = df.iloc[train_idx].copy()
        val_df   = df.iloc[val_idx].copy()

        # Downsample hungry on train side only
        train_df = downsample_hungry(train_df, HUNGRY_TARGET_PER_FOLD)

        # Extract
        X_train, y_train = featurize(train_df, model,
                                       augmenter=augmenter, augment=True)
        X_val, y_val = featurize(val_df, model, augment=False)

        # Class weights for train
        weights = compute_class_weight('balanced',
                                        classes=np.arange(5), y=y_train)
        cw = {i: w for i, w in enumerate(weights)}

        # Pipeline: scale + LogReg
        clf = Pipeline([
            ('scaler', StandardScaler()),
            ('lr', LogisticRegression(
                C=0.5,                # stronger regularization
                max_iter=2000,
                class_weight=cw,
                solver='lbfgs',
                multi_class='multinomial',
                random_state=SEED,
            )),
        ])
        clf.fit(X_train, y_train)

        y_pred = clf.predict(X_val)

        acc     = accuracy_score(y_val, y_pred)
        bal_acc = balanced_accuracy_score(y_val, y_pred)
        f1_m    = f1_score(y_val, y_pred, average='macro')

        fold_metrics.append({
            'fold': fold_idx,
            'n_train': len(X_train),
            'n_val': len(X_val),
            'accuracy': acc,
            'balanced_accuracy': bal_acc,
            'f1_macro': f1_m,
        })

        all_y_true.extend(y_val.tolist())
        all_y_pred.extend(y_pred.tolist())

        print(f'  Fold {fold_idx}/{N_FOLDS}  '
              f'train={len(X_train):4d}  val={len(X_val):3d}  '
              f'acc={acc:.3f}  bal_acc={bal_acc:.3f}  '
              f'f1_macro={f1_m:.3f}  ({time.time()-t0:.0f}s)')

    # Aggregate
    print('\n━ CV Aggregate Results ━')
    metrics_df = pd.DataFrame(fold_metrics)
    print(metrics_df.to_string(index=False))

    means = metrics_df[['accuracy', 'balanced_accuracy', 'f1_macro']].mean()
    stds = metrics_df[['accuracy', 'balanced_accuracy', 'f1_macro']].std()
    print(f'\n  Accuracy:           {means["accuracy"]:.3f} ± {stds["accuracy"]:.3f}')
    print(f'  Balanced Accuracy:  {means["balanced_accuracy"]:.3f} ± {stds["balanced_accuracy"]:.3f}')
    print(f'  F1 (macro):         {means["f1_macro"]:.3f} ± {stds["f1_macro"]:.3f}')

    # Aggregated confusion matrix
    y_true_all = np.array(all_y_true)
    y_pred_all = np.array(all_y_pred)
    print('\n  Aggregated classification report:')
    print(classification_report(y_true_all, y_pred_all,
                                  target_names=CLASSES, digits=3))

    # Confusion matrix
    cm = confusion_matrix(y_true_all, y_pred_all)
    cm_norm = cm.astype(float) / cm.sum(axis=1, keepdims=True)
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Purples',
                xticklabels=CLASSES, yticklabels=CLASSES, ax=axes[0])
    axes[0].set_title('Confusion Matrix (counts) — CV aggregate')
    axes[0].set_xlabel('Predicted'); axes[0].set_ylabel('True')
    sns.heatmap(cm_norm, annot=True, fmt='.2f', cmap='Purples',
                xticklabels=CLASSES, yticklabels=CLASSES, ax=axes[1],
                vmin=0, vmax=1)
    axes[1].set_title('Confusion Matrix (normalized) — CV aggregate')
    axes[1].set_xlabel('Predicted'); axes[1].set_ylabel('True')
    plt.tight_layout()
    plt.savefig(REPORTS / '07_cv_confusion.png', bbox_inches='tight')
    plt.close()
    print('  saved → reports/07_cv_confusion.png')

    # Final model on all data (for export)
    print('\n━ Final model trained on full data ━')
    df_full = downsample_hungry(df, HUNGRY_TARGET_PER_FOLD * 4)  # ~320 hungry
    X_full, y_full_train = featurize(df_full, model,
                                       augmenter=augmenter, augment=True)
    weights = compute_class_weight('balanced',
                                    classes=np.arange(5), y=y_full_train)
    cw = {i: w for i, w in enumerate(weights)}
    final = Pipeline([
        ('scaler', StandardScaler()),
        ('lr', LogisticRegression(C=0.5, max_iter=2000, class_weight=cw,
                                    solver='lbfgs',
                                    multi_class='multinomial',
                                    random_state=SEED)),
    ])
    final.fit(X_full, y_full_train)

    joblib.dump(final, MODELS / 'cry_classifier_lr.joblib')
    print(f'  saved → models/cry_classifier_lr.joblib')

    # Save metrics
    summary = {
        'cv_folds': N_FOLDS,
        'mean': {
            'accuracy': float(means['accuracy']),
            'balanced_accuracy': float(means['balanced_accuracy']),
            'f1_macro': float(means['f1_macro']),
        },
        'std': {
            'accuracy': float(stds['accuracy']),
            'balanced_accuracy': float(stds['balanced_accuracy']),
            'f1_macro': float(stds['f1_macro']),
        },
        'per_fold': fold_metrics,
    }
    with open(REPORTS / 'cv_metrics.json', 'w') as f:
        json.dump(summary, f, indent=2)
    print(f'  saved → reports/cv_metrics.json')

    print('\n' + '━' * 60)
    ba = means['balanced_accuracy']
    if ba >= 0.5:
        print(f'  ✅ Yaxshi: Balanced Accuracy = {ba:.3f}')
    elif ba >= 0.35:
        print(f'  ⚠️  O\'rtacha: Balanced Accuracy = {ba:.3f}')
    else:
        print(f'  ❌ Past: Balanced Accuracy = {ba:.3f}')
    print('━' * 60)


if __name__ == '__main__':
    main()
