"""
특성 엔지니어링 모듈
입력 데이터를 ML 모델용 수치 벡터로 변환
"""

import numpy as np
from datetime import datetime
from typing import Dict, Any


FEATURE_NAMES = [
    "current_glucose",
    "sugar_g",
    "carbs_g",
    "fat_g",
    "net_carbs",           # carbs - fat_dampen 효과 반영
    "gi_proxy",            # sugar/carbs 비율로 GI 근사
    "meal_status",
    "exercise_level",
    "insulin_taken",
    "medication_taken",
    "hour_sin",            # 시간대 순환 인코딩
    "hour_cos",
    "is_morning_peak",     # 새벽/아침 혈당 상승 효과
    "glucose_zone",        # 현재 혈당 구간 (정상/주의/위험)
]


def extract_features(
    current_glucose: float,
    sugar_g: float,
    carbs_g: float,
    fat_g: float,
    meal_status: int,
    exercise_level: int,
    insulin_taken: bool,
    medication_taken: bool,
    measured_at: datetime,
) -> np.ndarray:
    """
    원시 입력값 → 특성 벡터 변환

    Returns:
        shape (1, len(FEATURE_NAMES)) numpy array
    """
    hour = measured_at.hour

    # 지방이 많으면 탄수화물 흡수 둔화 (fat damping)
    fat_damping = 1.0 - min(fat_g * 0.02, 0.35)
    net_carbs = carbs_g * fat_damping

    # 당 비율 → GI 프록시 (당/탄수화물 비율이 높을수록 빠른 상승)
    gi_proxy = sugar_g / (carbs_g + 1e-6)

    # 시간대 순환 인코딩 (자정 연속성 보장)
    hour_sin = np.sin(2 * np.pi * hour / 24)
    hour_cos = np.cos(2 * np.pi * hour / 24)

    # 새벽 현상 (dawn phenomenon): 오전 4~9시 인슐린 저항성↑
    is_morning_peak = 1 if 4 <= hour <= 9 else 0

    # 현재 혈당 구간
    if current_glucose < 100:
        glucose_zone = 0   # 정상
    elif current_glucose < 140:
        glucose_zone = 1   # 주의
    elif current_glucose < 180:
        glucose_zone = 2   # 높음
    else:
        glucose_zone = 3   # 위험

    features = np.array([
        current_glucose,
        sugar_g,
        carbs_g,
        fat_g,
        net_carbs,
        gi_proxy,
        float(meal_status),
        float(exercise_level),
        float(insulin_taken),
        float(medication_taken),
        hour_sin,
        hour_cos,
        float(is_morning_peak),
        float(glucose_zone),
    ]).reshape(1, -1)

    return features


def build_lstm_sequence(records: list, seq_len: int = 10) -> np.ndarray:
    """
    최근 N개 기록 → LSTM 시퀀스 변환

    Args:
        records: DB에서 가져온 최근 기록 리스트 (시간순)
        seq_len: 시퀀스 길이

    Returns:
        shape (1, seq_len, n_features) numpy array
    """
    sequences = []
    for r in records[-seq_len:]:
        feat = extract_features(
            current_glucose=r["current_glucose"],
            sugar_g=r["sugar_g"],
            carbs_g=r["carbs_g"],
            fat_g=r["fat_g"],
            meal_status=r["meal_status"],
            exercise_level=r["exercise_level"],
            insulin_taken=r["insulin_taken"],
            medication_taken=r["medication_taken"],
            measured_at=datetime.fromisoformat(r["measured_at"]),
        )
        sequences.append(feat[0])

    # 시퀀스가 seq_len보다 짧으면 패딩
    while len(sequences) < seq_len:
        sequences.insert(0, sequences[0])

    return np.array(sequences).reshape(1, seq_len, -1)


def generate_synthetic_data(n_samples: int = 2000) -> tuple:
    """
    공용 모델 초기 학습용 합성 데이터 생성
    실제 당뇨 연구 기반 파라미터 사용

    Returns:
        X: feature matrix, y_30: 30분 delta, y_60: 60분 delta, y_120: 120분 delta
    """
    rng = np.random.default_rng(42)
    X_list, y30_list, y60_list, y120_list = [], [], [], []

    for _ in range(n_samples):
        current_glucose = rng.uniform(70, 250)
        sugar_g = rng.uniform(0, 60)
        carbs_g = sugar_g + rng.uniform(0, 30)
        fat_g = rng.uniform(0, 20)
        meal_status = rng.integers(0, 3)
        exercise_level = rng.integers(0, 3)
        insulin_taken = rng.choice([0, 1], p=[0.7, 0.3])
        medication_taken = rng.choice([0, 1], p=[0.65, 0.35])
        hour = rng.integers(0, 24)
        measured_at = datetime.now().replace(hour=int(hour), minute=0)

        feat = extract_features(
            current_glucose, sugar_g, carbs_g, fat_g,
            int(meal_status), int(exercise_level),
            bool(insulin_taken), bool(medication_taken), measured_at
        )

        # 생리학적 규칙 기반 delta 생성
        base_rise = sugar_g * 0.9 + carbs_g * 0.25
        fat_dampen = 1.0 - min(fat_g * 0.02, 0.35)
        meal_factor = [1.3, 1.0, 0.8][int(meal_status)]
        exercise_factor = [1.0, 0.75, 0.55][int(exercise_level)]
        insulin_factor = 0.5 if insulin_taken else 1.0
        med_factor = 0.7 if medication_taken else 1.0
        morning_factor = 1.15 if 4 <= hour <= 9 else 1.0
        high_glucose_factor = 0.8 if current_glucose > 160 else 1.0

        delta_max = (
            base_rise * fat_dampen * meal_factor *
            exercise_factor * insulin_factor * med_factor *
            morning_factor * high_glucose_factor
        )

        # 시간별 곡선 형태 (30m=0.6peak, 60m=1.0peak, 120m=0.65)
        delta_30 = delta_max * 0.6 + rng.normal(0, 3)
        delta_60 = delta_max * 1.0 + rng.normal(0, 4)
        delta_120 = delta_max * 0.65 + rng.normal(0, 5)

        X_list.append(feat[0])
        y30_list.append(delta_30)
        y60_list.append(delta_60)
        y120_list.append(delta_120)

    return (
        np.array(X_list),
        np.array(y30_list),
        np.array(y60_list),
        np.array(y120_list),
    )
