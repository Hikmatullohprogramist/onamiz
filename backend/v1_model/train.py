"""
V1 — Homiladorlik & Homila xavfi modelini o'qitish

Ikkala modelni ham 3 ta algoritm (RandomForest, XGBoost, LightGBM) bilan sinaydi
va 5-fold cross-validation bo'yicha eng yaxshisini tanlab saqlaydi.

Foydalanish:
    python train.py
"""

import json
import os
from pathlib import Path

import joblib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from lightgbm import LGBMClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
)
from sklearn.model_selection import StratifiedKFold, cross_val_score, train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from xgboost import XGBClassifier

# Yo'llar
ROOT = Path(__file__).parent
DATA_DIR = ROOT / "data"
MODELS_DIR = ROOT / "models"
REPORTS_DIR = ROOT / "reports"
MODELS_DIR.mkdir(exist_ok=True)
REPORTS_DIR.mkdir(exist_ok=True)

RANDOM_STATE = 42


def get_candidate_models():
    """3 ta nomzod model — eng yaxshisini cross-validation orqali tanlaymiz."""
    return {
        "RandomForest": RandomForestClassifier(
            n_estimators=300, random_state=RANDOM_STATE, n_jobs=-1
        ),
        "XGBoost": XGBClassifier(
            n_estimators=300,
            max_depth=6,
            learning_rate=0.1,
            random_state=RANDOM_STATE,
            eval_metric="mlogloss",
            n_jobs=-1,
        ),
        "LightGBM": LGBMClassifier(
            n_estimators=300,
            max_depth=6,
            learning_rate=0.1,
            random_state=RANDOM_STATE,
            n_jobs=-1,
            verbose=-1,
        ),
    }


def evaluate_and_select(X, y, model_name_prefix):
    """Har bir nomzod modelni cross-validation bilan baholaydi va eng yaxshisini qaytaradi."""
    print(f"\n{'=' * 60}")
    print(f"  {model_name_prefix} — eng yaxshi modelni tanlash")
    print(f"{'=' * 60}")

    candidates = get_candidate_models()
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=RANDOM_STATE)

    scores = {}
    for name, model in candidates.items():
        cv_scores = cross_val_score(model, X, y, cv=cv, scoring="f1_macro", n_jobs=-1)
        scores[name] = {
            "mean_f1": float(cv_scores.mean()),
            "std_f1": float(cv_scores.std()),
        }
        print(f"  {name:15s}  F1 (macro) = {cv_scores.mean():.4f}  (±{cv_scores.std():.4f})")

    best_name = max(scores, key=lambda k: scores[k]["mean_f1"])
    print(f"\n  Eng yaxshi: {best_name}  (F1={scores[best_name]['mean_f1']:.4f})")

    return best_name, candidates[best_name], scores


def save_confusion_matrix(y_true, y_pred, labels, title, path):
    """Confusion matrix grafigini saqlaydi."""
    cm = confusion_matrix(y_true, y_pred)
    plt.figure(figsize=(7, 5))
    sns.heatmap(
        cm,
        annot=True,
        fmt="d",
        cmap="Blues",
        xticklabels=labels,
        yticklabels=labels,
    )
    plt.title(title)
    plt.xlabel("Bashorat")
    plt.ylabel("Haqiqiy")
    plt.tight_layout()
    plt.savefig(path, dpi=120)
    plt.close()


# ============================================================
# 1-MODEL: Maternal Health Risk
# ============================================================
def train_maternal_risk():
    csv_path = DATA_DIR / "Maternal Health Risk Data Set.csv"
    if not csv_path.exists():
        print(f"[X] Topilmadi: {csv_path}")
        print("    Yuklang: https://www.kaggle.com/datasets/csafrit2/maternal-health-risk-data")
        return None

    df = pd.read_csv(csv_path)
    print(f"\n[Maternal] dataset: {df.shape}, classes: {df['RiskLevel'].unique()}")

    y_raw = df["RiskLevel"]
    X = df.drop(columns=["RiskLevel"])

    le = LabelEncoder()
    y = le.fit_transform(y_raw)
    class_labels = list(le.classes_)  # ['high risk', 'low risk', 'mid risk']

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    best_name, best_model, scores = evaluate_and_select(X_scaled, y, "Maternal Risk")

    # Train/test split — yakuniy baholash uchun
    X_tr, X_te, y_tr, y_te = train_test_split(
        X_scaled, y, test_size=0.2, stratify=y, random_state=RANDOM_STATE
    )
    best_model.fit(X_tr, y_tr)
    y_pred = best_model.predict(X_te)

    acc = accuracy_score(y_te, y_pred)
    f1 = f1_score(y_te, y_pred, average="macro")
    print(f"\n  Test accuracy: {acc:.4f}")
    print(f"  Test F1-macro: {f1:.4f}")
    print("\n" + classification_report(y_te, y_pred, target_names=class_labels))

    # Saqlash
    artifact = {
        "model": best_model,
        "scaler": scaler,
        "label_encoder": le,
        "feature_names": list(X.columns),
        "class_labels": class_labels,
        "best_model_name": best_name,
        "test_accuracy": float(acc),
        "test_f1_macro": float(f1),
    }
    joblib.dump(artifact, MODELS_DIR / "maternal_risk.joblib")

    save_confusion_matrix(
        y_te, y_pred, class_labels,
        f"Maternal Risk — {best_name} (Acc={acc:.3f})",
        REPORTS_DIR / "maternal_risk_cm.png",
    )

    with open(REPORTS_DIR / "maternal_risk_report.json", "w") as f:
        json.dump(
            {
                "best_model": best_name,
                "test_accuracy": float(acc),
                "test_f1_macro": float(f1),
                "cv_scores": scores,
                "feature_names": list(X.columns),
                "class_labels": class_labels,
            },
            f,
            indent=2,
        )

    print(f"  -> saqlandi: models/maternal_risk.joblib")
    return artifact


# ============================================================
# 2-MODEL: Fetal Health (CTG)
# ============================================================
def train_fetal_health():
    csv_path = DATA_DIR / "fetal_health.csv"
    if not csv_path.exists():
        print(f"[X] Topilmadi: {csv_path}")
        print("    Yuklang: https://www.kaggle.com/datasets/andrewmvd/fetal-health-classification")
        return None

    df = pd.read_csv(csv_path)
    print(f"\n[Fetal] dataset: {df.shape}")

    # Target: 1=Normal, 2=Suspect, 3=Pathological
    y = df["fetal_health"].astype(int).values - 1  # 0, 1, 2
    X = df.drop(columns=["fetal_health"])

    class_labels = ["Normal", "Suspect", "Pathological"]

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    best_name, best_model, scores = evaluate_and_select(X_scaled, y, "Fetal Health")

    X_tr, X_te, y_tr, y_te = train_test_split(
        X_scaled, y, test_size=0.2, stratify=y, random_state=RANDOM_STATE
    )
    best_model.fit(X_tr, y_tr)
    y_pred = best_model.predict(X_te)

    acc = accuracy_score(y_te, y_pred)
    f1 = f1_score(y_te, y_pred, average="macro")
    print(f"\n  Test accuracy: {acc:.4f}")
    print(f"  Test F1-macro: {f1:.4f}")
    print("\n" + classification_report(y_te, y_pred, target_names=class_labels))

    artifact = {
        "model": best_model,
        "scaler": scaler,
        "feature_names": list(X.columns),
        "class_labels": class_labels,
        "best_model_name": best_name,
        "test_accuracy": float(acc),
        "test_f1_macro": float(f1),
    }
    joblib.dump(artifact, MODELS_DIR / "fetal_health.joblib")

    save_confusion_matrix(
        y_te, y_pred, class_labels,
        f"Fetal Health — {best_name} (Acc={acc:.3f})",
        REPORTS_DIR / "fetal_health_cm.png",
    )

    with open(REPORTS_DIR / "fetal_health_report.json", "w") as f:
        json.dump(
            {
                "best_model": best_name,
                "test_accuracy": float(acc),
                "test_f1_macro": float(f1),
                "cv_scores": scores,
                "feature_names": list(X.columns),
                "class_labels": class_labels,
            },
            f,
            indent=2,
        )

    print(f"  -> saqlandi: models/fetal_health.joblib")
    return artifact


if __name__ == "__main__":
    print("=" * 60)
    print("  V1 MODEL TRAINING — Homiladorlik & Homila xavfi")
    print("=" * 60)

    train_maternal_risk()
    train_fetal_health()

    print("\n" + "=" * 60)
    print("  TUGADI — endi `python predict.py` ni sinab ko'ring")
    print("=" * 60)
