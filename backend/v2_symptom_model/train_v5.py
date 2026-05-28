"""
Onamiz v5 — Yaxshilangan model trening
Maqsad: 89.9% → 95%+

Yaxshilanishlar:
1. Ko'proq data: 5000 → 12000 namuna
2. Feature engineering: interaksiya featurelar
3. Optuna HPO: LightGBM optimal parametrlar
4. Stacking ensemble: LightGBM + XGBoost + RandomForest
5. Borderline-SMOTE: qiyin misollar ko'proq
"""

import warnings
warnings.filterwarnings("ignore")
import os
os.environ["PYTHONWARNINGS"] = "ignore"

import numpy as np
import pandas as pd
import joblib
from pathlib import Path
from sklearn.model_selection import train_test_split, StratifiedKFold, cross_val_score
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier, StackingClassifier, GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, f1_score, classification_report
from imblearn.over_sampling import SMOTE, BorderlineSMOTE
from xgboost import XGBClassifier
from lightgbm import LGBMClassifier

RANDOM_STATE = 42
np.random.seed(RANDOM_STATE)

ROOT       = Path(__file__).parent
MODEL_PATH = ROOT / "models" / "onamiz_v5.joblib"
MODEL_PATH.parent.mkdir(exist_ok=True)

FEATURE_COLS = [
    "trimester_enc", "age", "gestational_week",
    "vaginal_bleeding", "one_sided_pain", "nausea_severity",
    "urinary_burning", "fever", "dizziness", "prev_miscarriage",
    "thyroid_symptoms", "rh_checked",
    "headache_severity", "visual_disturbance", "edema_level",
    "fetal_movement", "epigastric_pain", "sudden_weight_gain",
    "fluid_leaking", "painless_bleeding", "fasting_glucose",
    "cervix_short", "belly_very_large",
    "fetal_movement_t3", "contractions", "bleeding_with_pain",
    "shortness_of_breath", "itching_palms_soles", "post_term",
    "systolic_bp", "diastolic_bp", "heart_rate",
    "anemia_level", "iron_supplement", "parity",
    "prenatal_visits", "nutrition_poor", "rural", "pph_history",
]

# ─── Interaksiya featurelar ────────────────────────────────────
INTERACTION_COLS = [
    "bp_score",            # sistolika + diastolika kombinatsiyasi
    "preeclampsia_index",  # qon bosimi * bosh og'riq * ko'z buzilishi
    "anemia_risk_idx",     # anemiya + dizziness + heart_rate
    "movement_alert",      # fetal_movement + fetal_movement_t3
    "emergency_flag",      # emergency belgilar yig'indisi
    "trimester_age_risk",  # yosh + trimester kombinatsiyasi
    "uzbek_risk_idx",      # o'zbekiston xususiy xavf indeksi
    "icp_index",           # itching_palms_soles og'irlashtirilgan
    "gdm_index",           # fasting_glucose + belly_very_large
]

ALL_COLS = FEATURE_COLS + INTERACTION_COLS


def _compute_score(r: dict) -> int:
    """Xavf ballini hisoblash (v4 bilan bir xil)."""
    s = 0
    if r.get("vaginal_bleeding") == 2:    s += 10
    if r.get("one_sided_pain") == 1:      s += 10
    if r.get("visual_disturbance") == 1:  s += 10
    if r.get("fetal_movement") == 2:      s += 10
    if r.get("fluid_leaking") == 1:       s += 10
    if r.get("bleeding_with_pain") == 1:  s += 10
    if r.get("fetal_movement_t3") == 2:   s += 10
    if r.get("painless_bleeding") == 2:   s += 10
    if r.get("headache_severity") == 2:   s += 5
    if r.get("epigastric_pain") == 2:     s += 5
    if r.get("contractions") == 2:        s += 5
    bp = r.get("systolic_bp", 120)
    db = r.get("diastolic_bp", 80)
    if bp >= 160:                          s += 5
    if bp >= 140:                          s += 4
    if db >= 90:                           s += 4
    if r.get("fever") == 2:              s += 4
    if r.get("nausea_severity") == 4:    s += 4
    if r.get("shortness_of_breath") == 2: s += 4
    if r.get("anemia_level") == 3:       s += 4
    if r.get("itching_palms_soles") == 3: s += 4
    if r.get("post_term") == 2:          s += 4
    if r.get("fasting_glucose") == 2:    s += 4
    if r.get("cervix_short") == 1:       s += 4
    if r.get("pph_history") == 1 and r.get("parity", 0) >= 1: s += 3
    if r.get("vaginal_bleeding") == 1:   s += 3
    if r.get("nausea_severity") == 3:    s += 3
    if r.get("urinary_burning") == 1:    s += 3
    if r.get("dizziness") == 2:          s += 3
    if r.get("fetal_movement") == 1:     s += 3
    if r.get("fetal_movement_t3") == 1:  s += 3
    if r.get("edema_level") == 3:        s += 3
    if r.get("painless_bleeding") == 1:  s += 3
    if r.get("anemia_level") == 2:       s += 2
    if r.get("headache_severity") == 1:  s += 2
    if r.get("edema_level") == 2:        s += 2
    if r.get("sudden_weight_gain") == 1: s += 2
    if r.get("prev_miscarriage") == 2:   s += 2
    if r.get("fever") == 1:             s += 2
    if r.get("contractions") == 1:      s += 2
    if r.get("epigastric_pain") == 1:   s += 2
    if r.get("shortness_of_breath") == 1: s += 2
    if r.get("pph_history") == 1:       s += 2
    if r.get("thyroid_symptoms", 0) >= 2: s += 2
    if r.get("fasting_glucose") == 1:   s += 2
    if r.get("belly_very_large") == 1:  s += 2
    if r.get("itching_palms_soles") == 2: s += 2
    if r.get("post_term") == 1:         s += 2
    age = r.get("age", 25)
    if age < 18:                          s += 2
    if age > 40:                          s += 1
    if r.get("parity", 0) >= 2:         s += 1
    if r.get("rural") == 1 and r.get("prenatal_visits") == 0: s += 2
    if r.get("iron_supplement") == 0 and r.get("anemia_level", 0) >= 1: s += 1
    if r.get("nutrition_poor") == 1:    s += 1
    if r.get("prev_miscarriage") == 1:  s += 1
    if r.get("anemia_level") == 1:      s += 1
    if r.get("prenatal_visits") == 0:   s += 1
    if r.get("rh_checked") == 0:        s += 1
    if r.get("thyroid_symptoms") == 1:  s += 1
    if r.get("itching_palms_soles") == 1: s += 1
    if r.get("fasting_glucose") == 3:   s += 1
    return s


def _add_interactions(df: pd.DataFrame) -> pd.DataFrame:
    """Interaksiya featurelarni qo'shish."""
    df = df.copy()

    df["bp_score"] = (
        (df["systolic_bp"] - 120).clip(lower=0) / 10
        + (df["diastolic_bp"] - 80).clip(lower=0) / 5
    ).round(2)

    df["preeclampsia_index"] = (
        df["headache_severity"] * df["visual_disturbance"]
        + (df["systolic_bp"] >= 140).astype(int) * 2
        + (df["systolic_bp"] >= 160).astype(int) * 3
        + df["edema_level"] * 0.5
    ).round(2)

    df["anemia_risk_idx"] = (
        df["anemia_level"] * 2
        + df["dizziness"]
        + ((df["heart_rate"] - 90).clip(lower=0) / 10)
    ).round(2)

    df["movement_alert"] = (
        df["fetal_movement"].replace({0: 0, 1: 1, 2: 3})
        + df["fetal_movement_t3"].replace({0: 0, 1: 1, 2: 3})
    )

    df["emergency_flag"] = (
        (df["vaginal_bleeding"] == 2).astype(int)
        + (df["one_sided_pain"] == 1).astype(int)
        + (df["visual_disturbance"] == 1).astype(int)
        + (df["fetal_movement"] == 2).astype(int)
        + (df["fluid_leaking"] == 1).astype(int)
        + (df["bleeding_with_pain"] == 1).astype(int)
        + (df["fetal_movement_t3"] == 2).astype(int)
        + (df["painless_bleeding"] == 2).astype(int)
    )

    age = df["age"]
    df["trimester_age_risk"] = (
        ((age < 18) | (age > 40)).astype(int)
        + df["trimester_enc"] * 0.3
        + df["prev_miscarriage"] * 0.5
    ).round(2)

    df["uzbek_risk_idx"] = (
        df["anemia_level"]
        + df["rural"]
        + (df["prenatal_visits"] == 0).astype(int) * 2
        + df["nutrition_poor"]
        + df["pph_history"]
        + (df["iron_supplement"] == 0).astype(int) * df["anemia_level"]
    )

    df["icp_index"] = (
        df["itching_palms_soles"] * df["trimester_enc"]
    )

    df["gdm_index"] = (
        df["fasting_glucose"] + df["belly_very_large"]
    )

    return df


def _score_to_risk(s: int) -> str:
    if s >= 10:  return "emergency"
    if s >= 6:   return "high"
    if s >= 3:   return "medium"
    return "low"


def generate_dataset(n: int, uzbek_ratio: float = 0.4, seed_offset: int = 0) -> pd.DataFrame:
    """Global + O'zbekiston aralash dataset generatsiya."""
    np.random.seed(RANDOM_STATE + seed_offset)
    n_uzbek  = int(n * uzbek_ratio)
    n_global = n - n_uzbek

    records = []

    for source in [("global", n_global), ("uzbekistan", n_uzbek)]:
        src_name, count = source
        is_uz = src_name == "uzbekistan"

        for _ in range(count):
            trimester = np.random.choice(["T1","T2","T3"], p=[0.35,0.35,0.30])
            trim_enc  = {"T1":0,"T2":1,"T3":2}[trimester]

            if is_uz:
                age = int(np.clip(np.random.normal(22, 7), 15, 44))
            else:
                age = np.random.randint(16, 45)

            week = {
                "T1": np.random.randint(4, 13),
                "T2": np.random.randint(13, 27),
                "T3": np.random.randint(27, 42),
            }[trimester]

            # O'zbekiston xususiy taqsimotlar
            if is_uz:
                anemia_level    = np.random.choice([0,1,2,3], p=[0.26,0.35,0.28,0.11] if age<19 else [0.40,0.35,0.20,0.05])
                rural           = np.random.choice([0,1], p=[0.35,0.65])
                parity          = np.random.choice([0,1,2], p=[0.25,0.35,0.40] if rural else [0.45,0.40,0.15])
                prenatal_visits = np.random.choice([0,1,2], p=[0.25,0.45,0.30] if rural else [0.05,0.30,0.65])
                nutrition_poor  = np.random.choice([0,1], p=[0.55,0.45])
                pph_history     = np.random.choice([0,1], p=[0.82,0.18] if parity>=2 else [0.93,0.07])
                iron_supplement = np.random.choice([0,1], p=[0.65,0.35])
                rh_checked      = np.random.choice([0,1], p=[0.30,0.70])
            else:
                anemia_level    = np.random.choice([0,1,2,3], p=[0.60,0.25,0.12,0.03])
                rural           = np.random.choice([0,1], p=[0.60,0.40])
                parity          = np.random.choice([0,1,2], p=[0.40,0.40,0.20])
                prenatal_visits = np.random.choice([0,1,2], p=[0.10,0.40,0.50])
                nutrition_poor  = np.random.choice([0,1], p=[0.75,0.25])
                pph_history     = np.random.choice([0,1], p=[0.92,0.08])
                iron_supplement = np.random.choice([0,1], p=[0.50,0.50])
                rh_checked      = np.random.choice([0,1], p=[0.15,0.85])

            vaginal_bleeding    = np.random.choice([0,1,2], p=[0.80,0.15,0.05])
            one_sided_pain      = np.random.choice([0,1],   p=[0.93,0.07])
            nausea_severity     = np.random.choice([0,1,2,3,4], p=[0.20,0.30,0.30,0.15,0.05])
            urinary_burning     = np.random.choice([0,1],   p=[0.85,0.15])
            fever               = np.random.choice([0,1,2], p=[0.85,0.10,0.05])
            dizziness           = np.random.choice([0,1,2], p=[0.70,0.20,0.10] if anemia_level < 2 else [0.30,0.40,0.30])
            prev_miscarriage    = np.random.choice([0,1,2], p=[0.75,0.15,0.10])
            thyroid_symptoms    = np.random.choice([0,1,2,3], p=[0.88,0.06,0.04,0.02])
            headache_severity   = np.random.choice([0,1,2], p=[0.70,0.20,0.10])
            visual_disturbance  = np.random.choice([0,1],   p=[0.95,0.05])
            edema_level         = np.random.choice([0,1,2,3], p=[0.55,0.25,0.15,0.05])
            fetal_movement      = np.random.choice([0,1,2], p=[0.80,0.15,0.05])
            epigastric_pain     = np.random.choice([0,1,2], p=[0.80,0.15,0.05])
            sudden_weight_gain  = np.random.choice([0,1],   p=[0.90,0.10])
            fluid_leaking       = np.random.choice([0,1],   p=[0.97,0.03])
            painless_bleeding   = np.random.choice([0,1,2], p=[0.93,0.05,0.02])
            fasting_glucose     = np.random.choice([0,1,2,3], p=[0.72,0.12,0.04,0.12])
            cervix_short        = np.random.choice([0,1],   p=[0.98,0.02])
            belly_very_large    = np.random.choice([0,1],   p=[0.97,0.03])
            fetal_movement_t3   = np.random.choice([0,1,2], p=[0.78,0.17,0.05])
            contractions        = np.random.choice([0,1,2], p=[0.75,0.17,0.08])
            bleeding_with_pain  = np.random.choice([0,1],   p=[0.97,0.03])
            shortness_of_breath = np.random.choice([0,1,2], p=[0.75,0.20,0.05])
            itching_palms_soles = np.random.choice([0,1,2,3], p=[0.88,0.06,0.04,0.02])
            post_term           = np.random.choice([0,1,2], p=[0.87,0.10,0.03])

            systolic_bp  = round(float(np.clip(np.random.normal(115, 15), 80, 200)), 1)
            diastolic_bp = round(float(np.clip(np.random.normal(75, 10), 50, 130)), 1)
            heart_rate   = round(float(np.clip(np.random.normal(82 + anemia_level*3, 12), 50, 160)), 1)

            r = dict(
                trimester_enc=trim_enc, age=age, gestational_week=week,
                vaginal_bleeding=vaginal_bleeding, one_sided_pain=one_sided_pain,
                nausea_severity=nausea_severity, urinary_burning=urinary_burning,
                fever=fever, dizziness=dizziness, prev_miscarriage=prev_miscarriage,
                thyroid_symptoms=thyroid_symptoms, rh_checked=rh_checked,
                headache_severity=headache_severity, visual_disturbance=visual_disturbance,
                edema_level=edema_level, fetal_movement=fetal_movement,
                epigastric_pain=epigastric_pain, sudden_weight_gain=sudden_weight_gain,
                fluid_leaking=fluid_leaking, painless_bleeding=painless_bleeding,
                fasting_glucose=fasting_glucose, cervix_short=cervix_short,
                belly_very_large=belly_very_large, fetal_movement_t3=fetal_movement_t3,
                contractions=contractions, bleeding_with_pain=bleeding_with_pain,
                shortness_of_breath=shortness_of_breath,
                itching_palms_soles=itching_palms_soles, post_term=post_term,
                systolic_bp=systolic_bp, diastolic_bp=diastolic_bp, heart_rate=heart_rate,
                anemia_level=anemia_level, iron_supplement=iron_supplement,
                parity=parity, prenatal_visits=prenatal_visits,
                nutrition_poor=nutrition_poor, rural=rural, pph_history=pph_history,
                source=src_name,
            )
            s = _compute_score(r)
            r["risk_level"] = _score_to_risk(s)
            records.append(r)

    df = pd.DataFrame(records)
    return df.sample(frac=1, random_state=RANDOM_STATE).reset_index(drop=True)


def add_borderline_cases(df: pd.DataFrame, n_each: int = 200) -> pd.DataFrame:
    """
    Chegara holatlari (s=3,6,10 atrofida) — model uchun qiyin namunalar.
    Bu modelning chegara hududlarini yaxshi o'rganishiga yordam beradi.
    """
    np.random.seed(RANDOM_STATE + 99)
    extras = []

    base = {c: 0 for c in FEATURE_COLS}
    base.update({"systolic_bp": 120.0, "diastolic_bp": 80.0, "heart_rate": 82.0,
                 "age": 28, "gestational_week": 20, "trimester_enc": 1})

    # s=3 atrofida → low/medium chegara
    for _ in range(n_each):
        r = base.copy()
        r["nausea_severity"]  = np.random.choice([2, 3])        # +3 yoki +3
        r["dizziness"]        = np.random.choice([0, 1, 2])
        r["anemia_level"]     = np.random.choice([0, 1, 2])
        r["systolic_bp"]      = float(np.random.choice([110, 115, 118, 122, 125]))
        s = _compute_score(r)
        r["risk_level"]       = _score_to_risk(s)
        r["source"]           = "borderline"
        extras.append(r)

    # s=6 atrofida → medium/high chegara
    for _ in range(n_each):
        r = base.copy()
        r["headache_severity"]  = np.random.choice([1, 2])       # +2 yoki +5
        r["edema_level"]        = np.random.choice([1, 2, 3])
        r["anemia_level"]       = np.random.choice([1, 2])
        r["systolic_bp"]        = float(np.random.normal(135, 10))
        r["diastolic_bp"]       = float(np.random.normal(85, 8))
        s = _compute_score(r)
        r["risk_level"]         = _score_to_risk(s)
        r["source"]             = "borderline"
        extras.append(r)

    # s=10 atrofida → high/emergency chegara
    for _ in range(n_each):
        r = base.copy()
        # Bitta emergency belgisi yoki ikkita high
        choice = np.random.choice(["single_emerg", "double_high", "near_emerg"])
        if choice == "single_emerg":
            col = np.random.choice(["vaginal_bleeding", "fetal_movement", "fetal_movement_t3"])
            r[col] = 2
        elif choice == "double_high":
            r["headache_severity"] = 2   # +5
            r["epigastric_pain"]   = 2   # +5 → s=10
        else:
            r["systolic_bp"]       = float(np.random.normal(158, 6))
            r["headache_severity"] = np.random.choice([1, 2])
        s = _compute_score(r)
        r["risk_level"] = _score_to_risk(s)
        r["source"]     = "borderline"
        extras.append(r)

    df_extra = pd.DataFrame(extras)
    return pd.concat([df, df_extra], ignore_index=True)


def build_features(df: pd.DataFrame):
    """Feature cols + interaksiya cols."""
    df2 = _add_interactions(df)
    return df2[ALL_COLS]


def train():
    print("=" * 60)
    print("  ONAMIZ v5 — MODEL TRENING")
    print("=" * 60)

    # 1. Data
    print("\n[1/5] Dataset generatsiya...")
    df = generate_dataset(12000, uzbek_ratio=0.40)
    df = add_borderline_cases(df, n_each=300)
    print(f"  Jami: {len(df)} namuna")
    print(f"  Taqsimot: {df['risk_level'].value_counts().to_dict()}")

    # 2. Preprocessing
    print("\n[2/5] Preprocessing...")
    le_y   = LabelEncoder()
    df["risk_enc"] = le_y.fit_transform(df["risk_level"])
    print(f"  Sinflar: {dict(enumerate(le_y.classes_))}")

    X = build_features(df)
    y = df["risk_enc"]

    scaler = StandardScaler()
    X_sc   = scaler.fit_transform(X)

    # BorderlineSMOTE — chegara misollar ko'proq
    try:
        smote = BorderlineSMOTE(random_state=RANDOM_STATE, k_neighbors=5)
        X_bal, y_bal = smote.fit_resample(X_sc, y)
        print(f"  BorderlineSMOTE: {len(X_bal)} namuna")
    except Exception:
        smote = SMOTE(random_state=RANDOM_STATE)
        X_bal, y_bal = smote.fit_resample(X_sc, y)
        print(f"  SMOTE: {len(X_bal)} namuna")

    X_tr, X_te, y_tr, y_te = train_test_split(
        X_bal, y_bal, test_size=0.2, stratify=y_bal, random_state=RANDOM_STATE
    )
    print(f"  Train: {len(X_tr)} | Test: {len(X_te)}")

    # 3. Optuna HPO
    print("\n[3/5] Optuna bilan LightGBM tuning...")
    best_lgb = _optuna_lgb(X_tr, y_tr)

    # 4. Barcha modellarni o'qitish
    print("\n[4/5] Stacking ensemble o'qitish...")
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=RANDOM_STATE)

    models = {
        "LightGBM_tuned": best_lgb,
        "XGBoost": XGBClassifier(
            n_estimators=400, max_depth=7, learning_rate=0.08,
            subsample=0.85, colsample_bytree=0.85,
            eval_metric="mlogloss", random_state=RANDOM_STATE, n_jobs=-1,
        ),
        "RandomForest": RandomForestClassifier(
            n_estimators=400, max_depth=12, min_samples_leaf=2,
            random_state=RANDOM_STATE, n_jobs=-1,
        ),
    }

    results = {}
    for name, m in models.items():
        sc = cross_val_score(m, X_tr, y_tr, cv=cv, scoring="accuracy", n_jobs=-1)
        results[name] = sc.mean()
        print(f"  {name:20s}  CV acc={sc.mean():.4f} ±{sc.std():.4f}")

    # Stacking
    estimators = [(n, m) for n, m in models.items()]
    stacking = StackingClassifier(
        estimators=estimators,
        final_estimator=LogisticRegression(max_iter=1000, C=5.0),
        cv=5,
        n_jobs=-1,
    )
    sc_stk = cross_val_score(stacking, X_tr, y_tr, cv=cv, scoring="accuracy", n_jobs=-1)
    results["Stacking"] = sc_stk.mean()
    print(f"  {'Stacking':20s}  CV acc={sc_stk.mean():.4f} ±{sc_stk.std():.4f}")

    # Eng yaxshi model
    best_name = max(results, key=results.get)
    print(f"\n  Tanlangan: {best_name}")

    if best_name == "Stacking":
        final_model = stacking
    else:
        final_model = models[best_name]

    final_model.fit(X_tr, y_tr)

    # 5. Baholash
    print("\n[5/5] Test natijalar...")
    y_pred = final_model.predict(X_te)
    acc = accuracy_score(y_te, y_pred)
    f1  = f1_score(y_te, y_pred, average="macro")
    print(f"\n  Test Accuracy : {acc:.4f}  ({acc:.1%})")
    print(f"  Test F1-macro : {f1:.4f}")
    print(f"\n  V4 bilan taqqoslash:")
    print(f"    V4 accuracy  : 89.9%")
    print(f"    V5 accuracy  : {acc:.1%}")
    print(f"    Yaxshilanish : +{(acc - 0.899)*100:.1f}pp")
    print(f"\n{classification_report(y_te, y_pred, target_names=le_y.classes_)}")

    # Saqlash
    artifact = {
        "model":           final_model,
        "scaler":          scaler,
        "label_encoder":   le_y,
        "trimester_encoder": LabelEncoder().fit(["T1","T2","T3"]),
        "feature_names":   list(ALL_COLS),
        "base_features":   list(FEATURE_COLS),
        "interaction_features": list(INTERACTION_COLS),
        "class_labels":    list(le_y.classes_),
        "best_model_name": best_name,
        "test_accuracy":   float(acc),
        "test_f1_macro":   float(f1),
        "version":         "v5",
        "total_risks":     42,
        "dataset":         {"total": len(df)},
        "improvements":    [
            "12000+ namuna (v4: 5000)",
            "9 ta interaksiya feature",
            "BorderlineSMOTE",
            "Optuna HPO",
            "Stacking ensemble",
        ],
        "sources": [
            "WHO ANC 2016", "ACOG 2023", "FIGO 2022",
            "SMFM Consult #53 (ICP)", "WHO/IADPSG 2013 (GDM)",
            "ATA Guidelines 2017 (Thyroid)",
            "Andijan Maternal Mortality Study 2025",
        ],
    }

    joblib.dump(artifact, MODEL_PATH)
    print(f"\n✅ Model saqlandi: {MODEL_PATH}")
    print(f"   Hajmi: {MODEL_PATH.stat().st_size / 1024:.0f} KB")

    return artifact


def _optuna_lgb(X_tr, y_tr):
    """Optuna bilan LightGBM optimal parametrlar topish."""
    try:
        import optuna
        optuna.logging.set_verbosity(optuna.logging.WARNING)
    except ImportError:
        print("  optuna topilmadi, default parametrlar ishlatiladi")
        return LGBMClassifier(
            n_estimators=500, max_depth=7, learning_rate=0.05,
            num_leaves=63, subsample=0.85, colsample_bytree=0.85,
            min_child_samples=10, reg_alpha=0.1, reg_lambda=0.1,
            random_state=RANDOM_STATE, n_jobs=-1, verbose=-1,
        )

    cv = StratifiedKFold(n_splits=3, shuffle=True, random_state=RANDOM_STATE)

    def objective(trial):
        params = {
            "n_estimators":       trial.suggest_int("n_estimators", 200, 800),
            "max_depth":          trial.suggest_int("max_depth", 4, 10),
            "learning_rate":      trial.suggest_float("learning_rate", 0.01, 0.2, log=True),
            "num_leaves":         trial.suggest_int("num_leaves", 20, 128),
            "subsample":          trial.suggest_float("subsample", 0.6, 1.0),
            "colsample_bytree":   trial.suggest_float("colsample_bytree", 0.6, 1.0),
            "min_child_samples":  trial.suggest_int("min_child_samples", 5, 50),
            "reg_alpha":          trial.suggest_float("reg_alpha", 0.0, 1.0),
            "reg_lambda":         trial.suggest_float("reg_lambda", 0.0, 1.0),
            "random_state":       RANDOM_STATE,
            "n_jobs":             -1,
            "verbose":            -1,
        }
        m = LGBMClassifier(**params)
        sc = cross_val_score(m, X_tr, y_tr, cv=cv, scoring="accuracy", n_jobs=-1)
        return sc.mean()

    study = optuna.create_study(direction="maximize")
    study.optimize(objective, n_trials=40, show_progress_bar=False)

    best = study.best_params
    best.update({"random_state": RANDOM_STATE, "n_jobs": -1, "verbose": -1})
    print(f"  Optuna best CV: {study.best_value:.4f}")
    print(f"  Best params: n_est={best['n_estimators']}, depth={best['max_depth']}, lr={best['learning_rate']:.4f}")

    return LGBMClassifier(**best)


if __name__ == "__main__":
    train()
