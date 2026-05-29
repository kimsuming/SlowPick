"""
모델 매니저
사용자 데이터 수에 따라 4단계 모델을 선택/학습/예측
"""

import os
import pickle
import logging
import numpy as np
from datetime import datetime
from typing import Optional, Tuple
from pathlib import Path

from sklearn.ensemble import RandomForestRegressor
from sklearn.multioutput import MultiOutputRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline

from schemas import PredictRequest, PredictResponse, GlucoseCurve, RiskLevel
from features import extract_features, build_lstm_sequence, generate_synthetic_data

logger = logging.getLogger(__name__)

MODEL_DIR = Path("models")
MODEL_DIR.mkdir(exist_ok=True)

SHARED_MODEL_PATH = MODEL_DIR / "shared_model.pkl"

# 단계 임계값
STAGE2_MIN = 3
STAGE3_MIN = 30
STAGE4_MIN = 100


class ModelManager:
    def __init__(self, db):
        self.db = db
        self.shared_model: Optional[Pipeline] = None

    # ──────────────────────────────────────────
    # 모델 단계 판별
    # ──────────────────────────────────────────

    def get_model_stage(self, record_count: int) -> int:
        if record_count >= STAGE4_MIN:
            return 4
        if record_count >= STAGE3_MIN:
            return 3
        if record_count >= STAGE2_MIN:
            return 2
        return 1

    def get_stage_label(self, stage: int) -> str:
        return {
            1: "공용 RandomForest",
            2: "공용 RF + 개인 편차 보정",
            3: "개인 전용 RandomForest",
            4: "개인 LSTM (시계열)",
        }[stage]

    # ──────────────────────────────────────────
    # 공용 모델 로드 / 학습
    # ──────────────────────────────────────────

    def load_or_train_shared_model(self):
        if SHARED_MODEL_PATH.exists():
            with open(SHARED_MODEL_PATH, "rb") as f:
                self.shared_model = pickle.load(f)
            logger.info("공용 모델 로드 완료")
        else:
            logger.info("공용 모델 없음 → 합성 데이터로 초기 학습")
            self.train_shared_model()

    def train_shared_model(self):
        logger.info("공용 모델 학습 시작...")
        X, y30, y60, y120 = generate_synthetic_data(n_samples=2000)
        Y = np.column_stack([y30, y60, y120])

        self.shared_model = Pipeline([
            ("scaler", StandardScaler()),
            ("rf", MultiOutputRegressor(
                RandomForestRegressor(
                    n_estimators=200,
                    max_depth=10,
                    min_samples_leaf=5,
                    random_state=42,
                    n_jobs=-1,
                )
            )),
        ])
        self.shared_model.fit(X, Y)

        with open(SHARED_MODEL_PATH, "wb") as f:
            pickle.dump(self.shared_model, f)
        logger.info("공용 모델 학습 완료 및 저장")

    # ──────────────────────────────────────────
    # 개인 모델 학습 트리거
    # ──────────────────────────────────────────

    def maybe_retrain_user_model(self, user_id: str, record_count: int):
        stage = self.get_model_stage(record_count)

        # 30건 이상: 개인 RF 학습
        if stage >= 3:
            self._train_user_rf(user_id)

        # 100건 이상: LSTM 학습
        if stage >= 4:
            self._train_user_lstm(user_id)

    def _train_user_rf(self, user_id: str):
        records = self.db.get_user_records(user_id)
        if len(records) < STAGE3_MIN:
            return

        logger.info(f"[{user_id}] 개인 RF 학습 시작 ({len(records)}건)")
        X_list, y30_list, y60_list, y120_list = [], [], [], []

        for r in records:
            if r.get("actual_glucose_60m") is None:
                continue
            feat = extract_features(
                r["current_glucose"], r["sugar_g"], r["carbs_g"], r["fat_g"],
                r["meal_status"], r["exercise_level"],
                r["insulin_taken"], r["medication_taken"],
                datetime.fromisoformat(r["measured_at"])
            )
            X_list.append(feat[0])
            base = r["current_glucose"]
            y30_list.append(r.get("actual_glucose_30m", base) - base)
            y60_list.append(r.get("actual_glucose_60m", base) - base)
            y120_list.append(r.get("actual_glucose_120m", base) - base)

        if len(X_list) < STAGE3_MIN:
            return

        X = np.array(X_list)
        Y = np.column_stack([y30_list, y60_list, y120_list])

        model = Pipeline([
            ("scaler", StandardScaler()),
            ("rf", MultiOutputRegressor(
                RandomForestRegressor(n_estimators=100, max_depth=8, random_state=42)
            )),
        ])
        model.fit(X, Y)

        path = MODEL_DIR / f"user_{user_id}_rf.pkl"
        with open(path, "wb") as f:
            pickle.dump(model, f)
        logger.info(f"[{user_id}] 개인 RF 저장 완료")

    def _train_user_lstm(self, user_id: str):
        """
        LSTM 학습 (TensorFlow/Keras 선택적 의존성)
        설치되지 않은 경우 RF 3단계로 폴백
        """
        try:
            import tensorflow as tf
        except ImportError:
            logger.warning("TensorFlow 미설치 → LSTM 학습 스킵, RF 사용")
            return

        records = self.db.get_user_records(user_id)
        if len(records) < STAGE4_MIN:
            return

        logger.info(f"[{user_id}] LSTM 학습 시작 ({len(records)}건)")
        SEQ_LEN = 10
        X_seqs, Y_list = [], []

        for i in range(len(records) - SEQ_LEN):
            seq_records = records[i:i + SEQ_LEN]
            target = records[i + SEQ_LEN]
            if target.get("actual_glucose_60m") is None:
                continue

            seq = build_lstm_sequence(seq_records, seq_len=SEQ_LEN)
            X_seqs.append(seq[0])

            base = target["current_glucose"]
            y30 = target.get("actual_glucose_30m", base) - base
            y60 = target.get("actual_glucose_60m", base) - base
            y120 = target.get("actual_glucose_120m", base) - base
            Y_list.append([y30, y60, y120])

        if len(X_seqs) < 20:
            return

        X_seq = np.array(X_seqs)   # (N, SEQ_LEN, n_features)
        Y_arr = np.array(Y_list)   # (N, 3)

        n_features = X_seq.shape[2]
        model = tf.keras.Sequential([
            tf.keras.layers.LSTM(64, input_shape=(SEQ_LEN, n_features), return_sequences=True),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.LSTM(32),
            tf.keras.layers.Dense(16, activation="relu"),
            tf.keras.layers.Dense(3),
        ])
        model.compile(optimizer="adam", loss="mse")
        model.fit(X_seq, Y_arr, epochs=30, batch_size=16, verbose=0)

        path = MODEL_DIR / f"user_{user_id}_lstm"
        model.save(str(path))
        logger.info(f"[{user_id}] LSTM 저장 완료")

    # ──────────────────────────────────────────
    # 메인 예측 로직
    # ──────────────────────────────────────────

    def predict(self, req: PredictRequest) -> PredictResponse:
        record_count = self.db.get_user_record_count(req.user_id)
        stage = self.get_model_stage(record_count)

        if stage == 4:
            deltas = self._predict_lstm(req) or self._predict_rf(req, stage)
        elif stage == 3:
            deltas = self._predict_rf(req, stage)
        elif stage == 2:
            deltas = self._predict_with_bias_correction(req)
        else:
            deltas = self._predict_shared(req)

        measured_at = req.measured_at or datetime.now()
        feat = extract_features(
            req.current_glucose, req.drink.sugar_g, req.drink.carbs_g,
            req.drink.fat_g, req.meal_status, req.exercise_level,
            req.insulin_taken, req.medication_taken, measured_at
        )

        d30, d60, d120 = deltas
        base = req.current_glucose

        g30 = round(base + d30, 1)
        g60 = round(base + d60, 1)
        g120 = round(base + d120, 1)
        delta_max = round(max(d30, d60, d120), 1)

        curve = self._build_curve(base, d30, d60, d120)
        risk = self._assess_risk(g60)
        coaching = self._generate_coaching(req, delta_max, risk["label"])

        return PredictResponse(
            user_id=req.user_id,
            drink_name=req.drink.name,
            current_glucose=base,
            predicted_glucose_30m=g30,
            predicted_glucose_60m=g60,
            predicted_glucose_120m=g120,
            delta_glucose=delta_max,
            glucose_curve=curve,
            risk=RiskLevel(**risk),
            model_stage=stage,
            model_stage_label=self.get_stage_label(stage),
            is_personalized=(stage >= 3),
            accuracy_warning=(
                "초기 예측 단계입니다. 실제 측정값을 기록할수록 정확도가 향상됩니다."
                if stage <= 2 else None
            ),
            coaching_drink_alt=coaching["drink_alt"],
            coaching_action=coaching["action"],
        )

    # ──────────────────────────────────────────
    # 단계별 예측 구현
    # ──────────────────────────────────────────

    def _predict_shared(self, req: PredictRequest) -> Tuple[float, float, float]:
        """1단계: 공용 RF 예측"""
        measured_at = req.measured_at or datetime.now()
        feat = extract_features(
            req.current_glucose, req.drink.sugar_g, req.drink.carbs_g,
            req.drink.fat_g, req.meal_status, req.exercise_level,
            req.insulin_taken, req.medication_taken, measured_at
        )
        pred = self.shared_model.predict(feat)[0]
        return float(pred[0]), float(pred[1]), float(pred[2])

    def _predict_with_bias_correction(self, req: PredictRequest) -> Tuple[float, float, float]:
        """2단계: 공용 RF + 개인 평균 편차 보정"""
        d30, d60, d120 = self._predict_shared(req)
        bias30, bias60, bias120 = self.db.get_user_bias(req.user_id)
        return d30 + bias30, d60 + bias60, d120 + bias120

    def _predict_rf(self, req: PredictRequest, stage: int) -> Tuple[float, float, float]:
        """3단계: 개인 전용 RF"""
        path = MODEL_DIR / f"user_{req.user_id}_rf.pkl"
        if not path.exists():
            logger.warning(f"개인 RF 없음 → 공용 모델 폴백 ({req.user_id})")
            return self._predict_shared(req)

        with open(path, "rb") as f:
            model = pickle.load(f)

        measured_at = req.measured_at or datetime.now()
        feat = extract_features(
            req.current_glucose, req.drink.sugar_g, req.drink.carbs_g,
            req.drink.fat_g, req.meal_status, req.exercise_level,
            req.insulin_taken, req.medication_taken, measured_at
        )
        pred = model.predict(feat)[0]
        return float(pred[0]), float(pred[1]), float(pred[2])

    def _predict_lstm(self, req: PredictRequest) -> Optional[Tuple[float, float, float]]:
        """4단계: LSTM 시계열 예측"""
        try:
            import tensorflow as tf
        except ImportError:
            return None

        path = MODEL_DIR / f"user_{req.user_id}_lstm"
        if not path.exists():
            return None

        try:
            model = tf.keras.models.load_model(str(path))
            records = self.db.get_user_records(req.user_id, limit=10)
            seq = build_lstm_sequence(records, seq_len=10)
            pred = model.predict(seq, verbose=0)[0]
            return float(pred[0]), float(pred[1]), float(pred[2])
        except Exception as e:
            logger.error(f"LSTM 예측 실패: {e}")
            return None

    # ──────────────────────────────────────────
    # 헬퍼
    # ──────────────────────────────────────────

    def _build_curve(self, base, d30, d60, d120) -> GlucoseCurve:
        """0~120분 혈당 곡선 생성 (6포인트 보간)"""
        times = [0, 30, 60, 90, 120]
        # 90분은 60분과 120분의 중간값 사용
        d90 = (d60 + d120) / 2
        values = [
            round(base, 1),
            round(base + d30, 1),
            round(base + d60, 1),
            round(base + d90, 1),
            round(base + d120, 1),
        ]
        return GlucoseCurve(time_minutes=times, predicted_glucose=values)

    def _assess_risk(self, predicted_60m: float) -> dict:
        if predicted_60m < 140:
            return {
                "label": "낮음",
                "color": "#27ae60",
                "description": "정상 범위 예상. 문제없이 섭취 가능합니다.",
            }
        elif predicted_60m < 180:
            return {
                "label": "보통",
                "color": "#e67e22",
                "description": "식후 혈당 경계 수준. 섭취량 조절을 권장합니다.",
            }
        else:
            return {
                "label": "높음",
                "color": "#c0392b",
                "description": "혈당이 크게 오를 수 있습니다. 대체 음료를 권장합니다.",
            }

    def _generate_coaching(self, req: PredictRequest, delta_max: float, risk_label: str) -> dict:
        """규칙 기반 코칭 메시지 생성"""
        drink_alt = None
        action = None

        sugar = req.drink.sugar_g

        if risk_label == "높음":
            if sugar > 20:
                drink_alt = f"당류 0g 무설탕 버전 또는 아메리카노로 대체 시 혈당 상승을 크게 줄일 수 있습니다."
            else:
                drink_alt = "저GI 음료(두유, 무가당 차류)로 대체를 권장합니다."
            action = "섭취 후 15분 가벼운 걷기를 하면 혈당 상승을 약 15~20% 완화할 수 있습니다."

        elif risk_label == "보통":
            if req.meal_status == 0:  # 공복
                drink_alt = "공복 섭취 대신 식사와 함께 드시면 혈당 상승 속도가 완만해집니다."
            else:
                drink_alt = f"당류를 {max(0, sugar - 10):.0f}g 이하 제품으로 선택하면 혈당 안정에 도움됩니다."
            action = "식후 혈당이 높은 경우 인슐린 또는 약 복용 타이밍을 의료진과 상담하세요."

        else:  # 낮음
            drink_alt = "현재 선택하신 음료는 혈당에 큰 영향을 주지 않아 안전합니다."
            action = "현재 상태를 유지하세요. 정기적인 혈당 측정을 권장합니다."

        return {"drink_alt": drink_alt, "action": action}
