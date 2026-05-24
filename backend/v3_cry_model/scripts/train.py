"""
Cry classifier training.

Input:  data/embeddings/{train,val,test}.npz — 2048-dim features
Output: models/cry_classifier.h5 + reports/training_history.png + classification report

Arxitektura:
  Input (2048) → Dense(256, relu) → Dropout(0.4)
                → Dense(128, relu) → Dropout(0.3)
                → Dense(5, softmax)
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
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from sklearn.utils.class_weight import compute_class_weight
from sklearn.metrics import (
    classification_report, confusion_matrix, f1_score,
    accuracy_score, balanced_accuracy_score
)
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

ROOT = Path(__file__).resolve().parent.parent
EMB_DIR = ROOT / 'data' / 'embeddings'
MODELS = ROOT / 'models'
MODELS.mkdir(exist_ok=True)
REPORTS = ROOT / 'reports'

CLASSES = ['hungry', 'tired', 'discomfort', 'burping', 'belly_pain']
SEED = 42

np.random.seed(SEED)
tf.random.set_seed(SEED)


def load_split(name):
    data = np.load(EMB_DIR / f'{name}.npz')
    return data['X'], data['y']


def build_model(input_dim, n_classes):
    model = keras.Sequential([
        layers.Input(shape=(input_dim,)),
        layers.BatchNormalization(),
        layers.Dense(256, activation='relu',
                     kernel_regularizer=keras.regularizers.l2(1e-4)),
        layers.Dropout(0.4),
        layers.Dense(128, activation='relu',
                     kernel_regularizer=keras.regularizers.l2(1e-4)),
        layers.Dropout(0.3),
        layers.Dense(n_classes, activation='softmax'),
    ])
    return model


def plot_history(history, out_path):
    fig, axes = plt.subplots(1, 2, figsize=(13, 4))
    h = history.history

    axes[0].plot(h['loss'], label='train')
    axes[0].plot(h['val_loss'], label='val')
    axes[0].set_title('Loss')
    axes[0].set_xlabel('Epoch')
    axes[0].legend()
    axes[0].grid(alpha=0.3)

    axes[1].plot(h['accuracy'], label='train')
    axes[1].plot(h['val_accuracy'], label='val')
    axes[1].set_title('Accuracy')
    axes[1].set_xlabel('Epoch')
    axes[1].legend()
    axes[1].grid(alpha=0.3)

    plt.tight_layout()
    plt.savefig(out_path, bbox_inches='tight')
    plt.close()


def plot_confusion(y_true, y_pred, out_path):
    cm = confusion_matrix(y_true, y_pred)
    cm_norm = cm.astype(float) / cm.sum(axis=1, keepdims=True)

    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    sns.heatmap(cm, annot=True, fmt='d', cmap='Purples',
                xticklabels=CLASSES, yticklabels=CLASSES, ax=axes[0])
    axes[0].set_title('Confusion Matrix (counts)')
    axes[0].set_xlabel('Predicted'); axes[0].set_ylabel('True')

    sns.heatmap(cm_norm, annot=True, fmt='.2f', cmap='Purples',
                xticklabels=CLASSES, yticklabels=CLASSES, ax=axes[1],
                vmin=0, vmax=1)
    axes[1].set_title('Confusion Matrix (normalized per row)')
    axes[1].set_xlabel('Predicted'); axes[1].set_ylabel('True')

    plt.tight_layout()
    plt.savefig(out_path, bbox_inches='tight')
    plt.close()


def main():
    print('━' * 60)
    print('  Cry Classifier — Training')
    print('━' * 60)

    X_train, y_train = load_split('train')
    X_val,   y_val   = load_split('val')
    X_test,  y_test  = load_split('test')

    print(f'\nTrain:  {X_train.shape}   y dist:',
          np.bincount(y_train, minlength=5).tolist())
    print(f'Val:    {X_val.shape}   y dist:',
          np.bincount(y_val, minlength=5).tolist())
    print(f'Test:   {X_test.shape}   y dist:',
          np.bincount(y_test, minlength=5).tolist())

    # Class weights (train data uchun balanced)
    weights = compute_class_weight('balanced',
                                    classes=np.arange(5),
                                    y=y_train)
    class_weight = {i: w for i, w in enumerate(weights)}
    print('\nClass weights:')
    for cls, w in zip(CLASSES, weights):
        print(f'  {cls:12s}  {w:.3f}')

    # Model
    print('\nModel arxitekturasi:')
    model = build_model(input_dim=X_train.shape[1], n_classes=5)
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-3),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy'],
    )
    model.summary()

    callbacks = [
        keras.callbacks.EarlyStopping(
            monitor='val_loss', patience=15,
            restore_best_weights=True, verbose=1),
        keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss', factor=0.5, patience=7,
            min_lr=1e-6, verbose=1),
    ]

    print('\n━ Training boshlandi ━\n')
    t0 = time.time()
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=200,
        batch_size=32,
        class_weight=class_weight,
        callbacks=callbacks,
        verbose=2,
    )
    print(f'\n⏱  Training vaqti: {time.time()-t0:.1f}s')

    plot_history(history, REPORTS / '05_training_history.png')
    print('  saved → reports/05_training_history.png')

    # Evaluation
    print('\n━ Test Evaluation ━')
    y_pred_proba = model.predict(X_test, verbose=0)
    y_pred = y_pred_proba.argmax(axis=1)

    acc = accuracy_score(y_test, y_pred)
    bal_acc = balanced_accuracy_score(y_test, y_pred)
    f1_macro = f1_score(y_test, y_pred, average='macro')
    f1_weighted = f1_score(y_test, y_pred, average='weighted')

    print(f'\n  Accuracy:           {acc:.3f}')
    print(f'  Balanced Accuracy:  {bal_acc:.3f}')
    print(f'  F1 (macro):         {f1_macro:.3f}')
    print(f'  F1 (weighted):      {f1_weighted:.3f}')

    print('\n  Classification Report:')
    print(classification_report(y_test, y_pred,
                                  target_names=CLASSES, digits=3))

    plot_confusion(y_test, y_pred, REPORTS / '06_confusion_matrix.png')
    print('  saved → reports/06_confusion_matrix.png')

    # Save model
    model.save(MODELS / 'cry_classifier.h5')
    print(f'\n  saved → models/cry_classifier.h5')

    # Save metrics summary
    metrics = {
        'accuracy': float(acc),
        'balanced_accuracy': float(bal_acc),
        'f1_macro': float(f1_macro),
        'f1_weighted': float(f1_weighted),
        'per_class_f1': {
            CLASSES[i]: float(f1_score(y_test, y_pred,
                                       labels=[i], average='macro'))
            for i in range(5)
        },
        'epochs_trained': len(history.history['loss']),
    }
    with open(REPORTS / 'metrics.json', 'w') as f:
        json.dump(metrics, f, indent=2)
    print(f'  saved → reports/metrics.json')

    print('\n' + '━' * 60)
    if bal_acc >= 0.65:
        print(f'  ✅ Maqsadga erishildi: Balanced Accuracy = {bal_acc:.3f}')
    elif bal_acc >= 0.5:
        print(f'  ⚠️  O\'rtacha: Balanced Accuracy = {bal_acc:.3f}')
        print('     Hyperparameter tuning yoki ko\'proq aug kerak')
    else:
        print(f'  ❌ Past: Balanced Accuracy = {bal_acc:.3f}')
        print('     Arxitektura yoki ma\'lumotni qayta ko\'rib chiqish kerak')
    print('━' * 60)


if __name__ == '__main__':
    main()
