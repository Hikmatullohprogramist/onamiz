"""
Cry classifier v3 — 3-klass + MFCC + Ensemble.

Strategiya:
  1. 5 → 3 klass:
     - needs       : hungry + tired           (340 sample)
     - discomfort  : discomfort + burping     ( 31 sample)
     - pain        : belly_pain               ( 13 sample)
  2. Features: YAMNet (1024) + MFCC stats (78) → 1102-dim
  3. Ensemble: LogReg + RandomForest + SVM + GradientBoosting (soft voting)
  4. 5-fold stratified CV — kichik dataset uchun ishonchli metrika
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
import joblib
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import (
    RandomForestClassifier, GradientBoostingClassifier, VotingClassifier
)
from sklearn.svm import SVC
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import (
    classification_report, confusion_matrix,
    f1_score, accuracy_score, balanced_accuracy_score
)
from sklearn.utils.class_weight import compute_class_weight
from audiomentations import (
    Compose, PitchShift, TimeStretch, AddGaussianNoise, Gain
)
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

ROOT = Path(__file__).resolve().parent.parent
REPORTS = ROOT / 'reports'
MODELS = ROOT / 'models'
MODELS.mkdir(exist_ok=True)

# 5 → 3 klass mapping
CLASS_MAP_5_TO_3 = {
    'hungry':     'needs',
    'tired':      'needs',
    'discomfort': 'discomfort',
    'burping':    'discomfort',
    'belly_pain': 'pain',
}
CLASSES_3 = ['needs', 'discomfort', 'pain']
LABEL_MAP = {c: i for i, c in enumerate(CLASSES_3)}

SR = 16000
SEED = 42
N_FOLDS = 5

# Augmentation multiplier — kichik klasslar uchun
AUG_MULT = {
    'needs':      0,    # 340 → downsample if needed
    'discomfort': 5,    # 31 → ~186
    'pain':       10,   # 13 → ~143
}
NEEDS_TARGET = 150

np.random.seed(SEED)


# ─── Feature extraction ─────────────────────────────────────

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


def yamnet_embedding(model, audio):
    """1024-dim mean pooling."""
    waveform = tf.constant(audio, dtype=tf.float32)
    _, embeddings, _ = model(waveform)
    return embeddings.numpy().mean(axis=0)


def mfcc_features(audio, sr=SR):
    """
    Hand-crafted audio features:
      - MFCC (13) + delta + delta-delta = 39 per frame
      - Spectral centroid, bandwidth, rolloff, ZCR
      - RMS energy
    → mean+std over time → 78 + 10 = 88 dim
    """
    mfcc = librosa.feature.mfcc(y=audio, sr=sr, n_mfcc=13)
    delta = librosa.feature.delta(mfcc)
    delta2 = librosa.feature.delta(mfcc, order=2)
    mfcc_full = np.vstack([mfcc, delta, delta2])  # (39, T)

    spec_centroid = librosa.feature.spectral_centroid(y=audio, sr=sr)
    spec_bw       = librosa.feature.spectral_bandwidth(y=audio, sr=sr)
    spec_rolloff  = librosa.feature.spectral_rolloff(y=audio, sr=sr)
    zcr           = librosa.feature.zero_crossing_rate(audio)
    rms           = librosa.feature.rms(y=audio)
    extra = np.vstack([spec_centroid, spec_bw, spec_rolloff, zcr, rms])  # (5, T)

    # Mean + std over time
    feats = np.concatenate([
        mfcc_full.mean(axis=1), mfcc_full.std(axis=1),
        extra.mean(axis=1), extra.std(axis=1),
    ])
    return feats  # 78 + 10 = 88


def combined_features(model, audio):
    yam = yamnet_embedding(model, audio)
    mf = mfcc_features(audio)
    return np.concatenate([yam, mf])  # 1024 + 88 = 1112


def build_augmenter():
    return Compose([
        PitchShift(min_semitones=-2, max_semitones=2, p=0.5),
        TimeStretch(min_rate=0.9, max_rate=1.1,
                    leave_length_unchanged=False, p=0.5),
        Gain(min_gain_db=-6, max_gain_db=6, p=0.4),
        AddGaussianNoise(min_amplitude=0.001, max_amplitude=0.01, p=0.3),
    ])


# ─── Data prep ──────────────────────────────────────────────

def load_clean_dataset():
    df = pd.read_csv(REPORTS / 'clean_dataset.csv').reset_index(drop=True)
    df['class3'] = df['class'].map(CLASS_MAP_5_TO_3)
    return df


def downsample_majority(df, target):
    parts = []
    for cls in CLASSES_3:
        sub = df[df['class3'] == cls]
        if cls == 'needs' and len(sub) > target:
            sub = sub.sample(target, random_state=SEED)
        parts.append(sub)
    return pd.concat(parts).reset_index(drop=True)


def featurize_split(df, model, augmenter=None, augment=False, name='split'):
    X, y = [], []
    n_orig = len(df)
    n_aug_total = 0
    for _, row in df.iterrows():
        cls = row['class3']
        label = LABEL_MAP[cls]
        audio = load_audio(row['path'])

        X.append(combined_features(model, audio))
        y.append(label)

        if augment and augmenter is not None:
            n_aug = AUG_MULT.get(cls, 0)
            for _ in range(n_aug):
                aug_audio = augmenter(samples=audio, sample_rate=SR)
                aug_audio = fix_length(aug_audio, SR * 7)
                X.append(combined_features(model, aug_audio))
                y.append(label)
                n_aug_total += 1

    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.int32)
    print(f'  {name}: orig={n_orig} aug={n_aug_total} total={len(y)}  '
          f'dist={np.bincount(y, minlength=3).tolist()}')
    return X, y


# ─── Models ─────────────────────────────────────────────────

def build_ensemble(class_weight):
    """Soft-voting ensemble of 4 classifiers."""
    lr = Pipeline([
        ('scaler', StandardScaler()),
        ('clf', LogisticRegression(
            C=0.5, max_iter=2000, class_weight=class_weight,
            solver='lbfgs', multi_class='multinomial',
            random_state=SEED)),
    ])
    rf = RandomForestClassifier(
        n_estimators=200, max_depth=12,
        class_weight=class_weight, random_state=SEED,
        n_jobs=-1)
    svm = Pipeline([
        ('scaler', StandardScaler()),
        ('clf', SVC(C=1.0, kernel='rbf', probability=True,
                     class_weight=class_weight, random_state=SEED)),
    ])
    gb = GradientBoostingClassifier(
        n_estimators=150, max_depth=4,
        learning_rate=0.05, random_state=SEED)

    return VotingClassifier(
        estimators=[('lr', lr), ('rf', rf), ('svm', svm), ('gb', gb)],
        voting='soft',
        weights=[1.0, 1.2, 1.0, 1.5],  # GB ko'p marta yaxshi
        n_jobs=-1,
    )


# ─── Main ───────────────────────────────────────────────────

def main():
    print('━' * 60)
    print('  Cry Classifier v3 — 3-class + MFCC + Ensemble')
    print('━' * 60)

    df = load_clean_dataset()
    print(f'\n5 → 3 klass mapping:')
    for c5, c3 in CLASS_MAP_5_TO_3.items():
        print(f'  {c5:12s} → {c3}')

    print('\n3-klass balansi:')
    for cls in CLASSES_3:
        n = (df['class3'] == cls).sum()
        print(f'  {cls:12s}  {n:3d}')

    model = load_yamnet()
    augmenter = build_augmenter()

    y_full = df['class3'].map(LABEL_MAP).values
    skf = StratifiedKFold(n_splits=N_FOLDS, shuffle=True, random_state=SEED)

    fold_metrics = []
    all_y_true = []
    all_y_pred = []
    all_y_proba = []

    print(f'\n━ {N_FOLDS}-fold Cross-Validation ━\n')
    for fold_idx, (train_idx, val_idx) in enumerate(skf.split(df, y_full), 1):
        t0 = time.time()
        train_df = df.iloc[train_idx].copy()
        val_df   = df.iloc[val_idx].copy()

        # Downsample needs
        train_df = downsample_majority(train_df, NEEDS_TARGET)

        # Featurize
        print(f'\n--- Fold {fold_idx}/{N_FOLDS} ---')
        X_train, y_train = featurize_split(
            train_df, model, augmenter=augmenter, augment=True, name='train')
        X_val, y_val = featurize_split(
            val_df, model, augment=False, name='val')

        weights = compute_class_weight('balanced',
                                        classes=np.arange(3), y=y_train)
        cw = {i: w for i, w in enumerate(weights)}

        clf = build_ensemble(class_weight=cw)
        clf.fit(X_train, y_train)

        y_pred = clf.predict(X_val)
        y_proba = clf.predict_proba(X_val)

        acc     = accuracy_score(y_val, y_pred)
        bal_acc = balanced_accuracy_score(y_val, y_pred)
        f1_m    = f1_score(y_val, y_pred, average='macro')

        fold_metrics.append({
            'fold': fold_idx,
            'accuracy': acc,
            'balanced_accuracy': bal_acc,
            'f1_macro': f1_m,
        })

        all_y_true.extend(y_val.tolist())
        all_y_pred.extend(y_pred.tolist())
        all_y_proba.append(y_proba)

        print(f'  Fold {fold_idx}/{N_FOLDS}  acc={acc:.3f}  '
              f'bal_acc={bal_acc:.3f}  f1_macro={f1_m:.3f}  '
              f'({time.time()-t0:.0f}s)')

    # Aggregate
    print('\n━ CV Aggregate Results ━')
    metrics_df = pd.DataFrame(fold_metrics)
    print(metrics_df.to_string(index=False))

    means = metrics_df[['accuracy', 'balanced_accuracy', 'f1_macro']].mean()
    stds  = metrics_df[['accuracy', 'balanced_accuracy', 'f1_macro']].std()
    print(f'\n  Accuracy:           {means["accuracy"]:.3f} ± {stds["accuracy"]:.3f}')
    print(f'  Balanced Accuracy:  {means["balanced_accuracy"]:.3f} ± {stds["balanced_accuracy"]:.3f}')
    print(f'  F1 (macro):         {means["f1_macro"]:.3f} ± {stds["f1_macro"]:.3f}')

    print('\n  Aggregated Classification Report:')
    print(classification_report(all_y_true, all_y_pred,
                                  target_names=CLASSES_3, digits=3))

    # Confusion matrix
    cm = confusion_matrix(all_y_true, all_y_pred)
    cm_norm = cm.astype(float) / cm.sum(axis=1, keepdims=True)
    fig, axes = plt.subplots(1, 2, figsize=(12, 5))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Purples',
                xticklabels=CLASSES_3, yticklabels=CLASSES_3, ax=axes[0])
    axes[0].set_title('Confusion (counts) — v3 CV aggregate')
    axes[0].set_xlabel('Predicted'); axes[0].set_ylabel('True')
    sns.heatmap(cm_norm, annot=True, fmt='.2f', cmap='Purples',
                xticklabels=CLASSES_3, yticklabels=CLASSES_3, ax=axes[1],
                vmin=0, vmax=1)
    axes[1].set_title('Confusion (normalized) — v3 CV aggregate')
    axes[1].set_xlabel('Predicted'); axes[1].set_ylabel('True')
    plt.tight_layout()
    plt.savefig(REPORTS / '08_v3_confusion.png', bbox_inches='tight')
    plt.close()
    print('  saved → reports/08_v3_confusion.png')

    # Final model on all data
    print('\n━ Final model on full data ━')
    df_full = downsample_majority(df, NEEDS_TARGET * 2)
    X_full, y_full_train = featurize_split(
        df_full, model, augmenter=augmenter, augment=True, name='final')
    weights = compute_class_weight('balanced',
                                    classes=np.arange(3), y=y_full_train)
    cw = {i: w for i, w in enumerate(weights)}
    final = build_ensemble(class_weight=cw)
    final.fit(X_full, y_full_train)

    joblib.dump(final, MODELS / 'cry_classifier_v3.joblib')
    print(f'  saved → models/cry_classifier_v3.joblib')

    summary = {
        'version': 'v3',
        'classes': CLASSES_3,
        'class_mapping': CLASS_MAP_5_TO_3,
        'features': 'YAMNet(1024) + MFCC(78) + spectral(10) = 1112',
        'model': 'Ensemble: LogReg + RandomForest + SVM + GradientBoosting',
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
    with open(REPORTS / 'v3_metrics.json', 'w') as f:
        json.dump(summary, f, indent=2)

    print('\n' + '━' * 60)
    ba = means['balanced_accuracy']
    target = 0.60
    if ba >= target:
        print(f'  ✅ Maqsadga erishildi: Balanced Accuracy = {ba:.3f} (target {target})')
    elif ba >= 0.40:
        print(f'  ⚠️  Yaxshilanish bor: BA = {ba:.3f} (target {target})')
    else:
        print(f'  ❌ Hali ham past: BA = {ba:.3f}')
    print('━' * 60)


if __name__ == '__main__':
    main()
