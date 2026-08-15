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



# 랜덤포레스트 회귀 모델입니다.
from sklearn.ensemble import RandomForestRegressor
# 출력값이 여러 개(30분/60분/120분 혈당 변화)일 때, 각각을 별도로 예측하도록 감싸주는 래퍼입니다.
from sklearn.multioutput import MultiOutputRegressor
# 입력 특성들의 스케일(단위/범위)을 표준화(평균 0, 분산 1)해주는 전처리 도구입니다.
from sklearn.preprocessing import StandardScaler
# 전처리와 모델을 하나로 묶어서, "전처리 → 학습/예측"을 한 번에 처리할 수 있게 해주는 도구입니다.
from sklearn.pipeline import Pipeline

# main.py 등에서 쓰는 요청/응답 스키마들을 가져옵니다.
from schemas import PredictRequest, PredictResponse, GlucoseCurve, RiskLevel
# 앞서 살펴본 특성 엔지니어링 함수들을 가져옵니다.
from features import extract_features, build_lstm_sequence, generate_synthetic_data

logger = logging.getLogger(__name__)


# 학습된 모델 파일들을 저장할 디렉토리입니다.
MODEL_DIR = Path("models")
# 디렉토리가 없으면 새로 만듭니다. (exist_ok=True → 이미 있어도 에러 안 남)
MODEL_DIR.mkdir(exist_ok=True)

# 공용(모든 사용자 공통) 모델이 저장될 파일 경로입니다.
SHARED_MODEL_PATH = MODEL_DIR / "shared_model.pkl"

# 단계 임계값
# 사용자 누적 기록 건수에 따라 몇 단계 모델을 쓸지 결정하는 기준값들입니다.
STAGE2_MIN = 3
STAGE3_MIN = 30
STAGE4_MIN = 100

# 모델의 선택/학습/예측 전체를 총괄하는 클래스입니다.
class ModelManager:
    def __init__(self, db):
        # 데이터베이스 접근 객체를 저장해둡니다. (기록 조회, 저장 등에 사용)
        self.db = db
        # 공용 모델을 담아둘 변수. 처음엔 아직 로드되지 않았으므로 None입니다.
        self.shared_model: Optional[Pipeline] = None

    # ──────────────────────────────────────────
    # 모델 단계 판별
    # ──────────────────────────────────────────

    def get_model_stage(self, record_count: int) -> int:
        if record_count >= STAGE4_MIN: # 4단계: 100건 이상 (개인 LSTM)
            return 4
        if record_count >= STAGE3_MIN: # 3단계: 30~99건 (개인 전용 RF)
            return 3
        if record_count >= STAGE2_MIN: # 2단계: 3~29건 (공용 모델 + 편차 보정)
            return 2
        return 1 # 1단계: 0~2건 (공용 모델)


    # 모델의 선택/학습/예측 전체를 총괄하는 클래스입니다.
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


    # 서버 시작 시 호출됨 (main.py의 lifespan에서 호출).
    # 저장된 공용 모델 파일이 있으면 불러오고, 없으면 새로 학습시킵니다.
    def load_or_train_shared_model(self):
        if SHARED_MODEL_PATH.exists():
            with open(SHARED_MODEL_PATH, "rb") as f:
                self.shared_model = pickle.load(f)
            logger.info("공용 모델 로드 완료")
        else:
            logger.info("공용 모델 없음 → 합성 데이터로 초기 학습")
            self.train_shared_model()


    # GlucoBench(실제 연구용 혈당 데이터셋)를 학습 데이터로 활용하기 위한 내부 함수입니다.
    def _load_glucobench_data(self):
        """
        GlucoBench DB에서 공용 모델 학습용 데이터 로드.
        DB가 없거나 데이터가 부족하면 None 반환 → 합성 데이터로 폴백.
        """
        import sqlite3
        from pathlib import Path

        db_path = Path("data/glucose.db")
        # DB 파일 자체가 없으면 바로 포기하고 None 반환 (합성 데이터 사용하라는 신호)
        if not db_path.exists():
            return None

        try:
            conn = sqlite3.connect(str(db_path))
            conn.row_factory = sqlite3.Row
            rows = conn.execute("""
                SELECT * FROM glucose_records
                WHERE actual_glucose_60m IS NOT NULL
                  AND user_id LIKE 'U%'
            """).fetchall()
            conn.close()
        except Exception as e:
            logger.warning(f"GlucoBench DB 로드 실패: {e}")
            return None

        if len(rows) < 50:
            logger.info(f"GlucoBench 데이터 부족 ({len(rows)}건) → 합성 데이터 사용")
            return None

        X_list, y30_list, y60_list, y120_list = [], [], [], []
        for r in rows:
            try:
                feat = extract_features(
                    r["current_glucose"], r["sugar_g"], r["carbs_g"], r["fat_g"],
                    r["meal_status"], r["exercise_level"],
                    bool(r["insulin_taken"]), bool(r["medication_taken"]),
                    datetime.fromisoformat(r["measured_at"])
                )
                base = r["current_glucose"]
                X_list.append(feat[0])
                y30_list.append((r["actual_glucose_30m"] or base) - base)
                y60_list.append(r["actual_glucose_60m"] - base)
                y120_list.append((r["actual_glucose_120m"] or base) - base)
            except Exception:
                continue

        if len(X_list) < 50:
            return None

        logger.info(f"GlucoBench 데이터 {len(X_list)}건 로드 완료")
        return (
            np.array(X_list),
            np.array(y30_list),
            np.array(y60_list),
            np.array(y120_list),
        )

    # 공용 모델을 실제로 학습시키는 함수입니다.
    def train_shared_model(self):
        logger.info("공용 모델 학습 시작...")

        # GlucoBench 실제 데이터 우선 시도, 없으면 합성 데이터 사용
        data = self._load_glucobench_data()
        if data is not None:
            X, y30, y60, y120 = data
            logger.info("실제 데이터(GlucoBench)로 공용 모델 학습")
        else:
            X, y30, y60, y120 = generate_synthetic_data(n_samples=2000)
            logger.info("합성 데이터로 공용 모델 학습")


        # 세 개의 정답값(30분/60분/120분 변화량)을 하나의 2차원 배열로 옆으로 붙입니다.
        # (다중 출력 회귀를 위해 필요한 형태)
        Y = np.column_stack([y30, y60, y120])

         # "표준화 → 랜덤포레스트(다중출력)"로 이어지는 파이프라인을 구성합니다.
        self.shared_model = Pipeline([
            ("scaler", StandardScaler()),
            ("rf", MultiOutputRegressor(
                RandomForestRegressor(
                    n_estimators=200,       # 트리 200개로 구성된 숲
                    max_depth=10,           # 트리 최대 깊이 제한 (과적합 방지)
                    min_samples_leaf=5,     # 리프 노드에 최소 5개 샘플 (과적합 방지)
                    random_state=42,        # 결과 재현을 위한 시드 고정
                    n_jobs=-1,              # 사용 가능한 모든 CPU 코어를 병렬로 사용
                )
            )),
        ])
        self.shared_model.fit(X, Y)
        
         # 학습된 모델을 파일로 저장해서, 다음번 서버 재시작 시 다시 학습할 필요 없게 함
        with open(SHARED_MODEL_PATH, "wb") as f:
            pickle.dump(self.shared_model, f)
        logger.info("공용 모델 학습 완료 및 저장")

    # ──────────────────────────────────────────
    # 개인 모델 학습 트리거
    # ──────────────────────────────────────────

    # 사용자가 새 기록을 남길 때마다 호출되어, 필요하면 개인화 모델 학습을 시작합니다.
    def maybe_retrain_user_model(self, user_id: str, record_count: int):
        stage = self.get_model_stage(record_count)

        # 30건 이상: 개인 RF 학습
        if stage >= 3:
            self._train_user_rf(user_id)

        # 100건 이상: LSTM 학습
        if stage >= 4:
            self._train_user_lstm(user_id)


    # 특정 사용자 전용 RandomForest 모델을 학습시키는 함수입니다. (3단계용)
    def _train_user_rf(self, user_id: str):
        # 해당 사용자의 모든 기록을 DB에서 가져옵니다.
        records = self.db.get_user_records(user_id)
        # 최소 기준(30건) 미달이면 학습하지 않고 조용히 종료
        if len(records) < STAGE3_MIN:
            return

        logger.info(f"[{user_id}] 개인 RF 학습 시작 ({len(records)}건)")
        X_list, y30_list, y60_list, y120_list = [], [], [], []

        for r in records:
            # 60분 실측값이 아직 없는 기록(예측만 하고 실측 안 한 경우)은 학습에서 제외
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

        # 공용 모델보다 트리 개수/깊이를 줄여 가벼운 개인 모델을 구성합니다.
        # (개인 데이터는 상대적으로 적기 때문에 너무 복잡한 모델은 과적합 위험)
        model = Pipeline([
            ("scaler", StandardScaler()),
            ("rf", MultiOutputRegressor(
                RandomForestRegressor(n_estimators=100, max_depth=8, random_state=42)
            )),
        ])
        model.fit(X, Y)

        # 사용자별로 파일명을 다르게 해서 저장 (user_아이디_rf.pkl)
        path = MODEL_DIR / f"user_{user_id}_rf.pkl"
        with open(path, "wb") as f:
            pickle.dump(model, f)
        logger.info(f"[{user_id}] 개인 RF 저장 완료")

    # 특정 사용자 전용 LSTM(시계열) 모델을 학습시키는 함수입니다. (4단계용)
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
        # 최소 기준(100건) 미달이면 학습하지 않음
        if len(records) < STAGE4_MIN:
            return

        logger.info(f"[{user_id}] LSTM 학습 시작 ({len(records)}건)")
        SEQ_LEN = 10 # LSTM에 넣을 시퀀스 길이 (최근 10건씩 묶어서 학습)
        X_seqs, Y_list = [], []

        # 슬라이딩 윈도우 방식: 연속된 10건을 입력으로, 그 다음 11번째 기록을 정답(target)으로 사용
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
        # LSTM 신경망 구조를 순서대로 쌓아서 정의합니다.
        model = tf.keras.Sequential([
            # 첫 번째 LSTM층: 64개 유닛, 다음 층에도 전체 시퀀스를 넘기기 위해 return_sequences=True
            tf.keras.layers.LSTM(64, input_shape=(SEQ_LEN, n_features), return_sequences=True),
            # 과적합 방지를 위해 20% 뉴런을 무작위로 끄는 Dropout층
            tf.keras.layers.Dropout(0.2),
            # 두 번째 LSTM층: 32개 유닛, 이번엔 마지막 결과만 넘김 (return_sequences 기본값 False)
            tf.keras.layers.LSTM(32),
            # 완전연결층(Dense): 16개 유닛, ReLU 활성화 함수
            tf.keras.layers.Dense(16, activation="relu"),
            # 출력층: 3개 값(30분/60분/120분 변화량)을 그대로 예측 (활성화 함수 없음 = 회귀)
            tf.keras.layers.Dense(3),
        ])
        model.compile(optimizer="adam", loss="mse")
        # 30번 반복 학습(epoch), 한 번에 16개씩(batch_size) 묶어서 학습, verbose=0으로 로그 출력 생략
        model.fit(X_seq, Y_arr, epochs=30, batch_size=16, verbose=0)

        path = MODEL_DIR / f"user_{user_id}_lstm"
        model.save(str(path))
        logger.info(f"[{user_id}] LSTM 저장 완료")

    # ──────────────────────────────────────────
    # 메인 예측 로직
    # ──────────────────────────────────────────

    # main.py의 /predict 엔드포인트에서 호출되는 핵심 함수입니다.
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

        # 측정 시각이 없으면 현재 시각 사용 (스키마의 field_validator에서도 처리되지만 이중 안전장치)
        measured_at = req.measured_at or datetime.now()
        # 아래에서는 실제로 사용하지 않지만, 특성 추출 과정을 한 번 더 거칩니다.
        # feat = extract_features(
        #     req.current_glucose, req.drink.sugar_g, req.drink.carbs_g,
        #     req.drink.fat_g, req.meal_status, req.exercise_level,
        #     req.insulin_taken, req.medication_taken, measured_at
        # )

        # 예측된 변화량(delta)들을 각각 이름 있는 변수로 풀어냅니다
        d30, d60, d120 = deltas
        base = req.current_glucose

        # 변화량을 섭취 전 혈당에 더해 실제 예측 혈당 수치를 계산 (소수점 첫째 자리 반올림)
        g30 = round(base + d30, 1)
        g60 = round(base + d60, 1)
        g120 = round(base + d120, 1)
        # 세 시점 중 가장 크게 오른 변화량을 "최대 상승폭"으로 기록
        delta_max = round(max(d30, d60, d120), 1)
        
        # 그래프용 곡선 데이터, 위험도 평가, 코칭 메시지를 각각 생성
        curve = self._build_curve(base, d30, d60, d120)
        risk = self._assess_risk(g60)
        coaching = self._generate_coaching(req, delta_max, risk["label"])

        # 지금까지 계산한 모든 값을 PredictResponse 스키마에 채워 반환
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

    # 1단계: 공용 모델로만 예측 (개인화 없음)
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

    # 2단계: 공용 모델 예측값에 "이 사용자만의 평균적 오차(편차)"를 더해 보정
    def _predict_with_bias_correction(self, req: PredictRequest) -> Tuple[float, float, float]:
        """2단계: 공용 RF + 개인 평균 편차 보정"""
        # 먼저 1단계와 동일하게 공용 모델로 예측
        d30, d60, d120 = self._predict_shared(req)
        # 이 사용자의 과거 기록에서, "공용 모델 예측 대비 실제값이 평균적으로 얼마나 벗어났는지" 조회
        bias30, bias60, bias120 = self.db.get_user_bias(req.user_id)
        # 공용 예측값에 개인 편차를 더해 보정된 값 반환
        return d30 + bias30, d60 + bias60, d120 + bias120

    # 3단계: 이 사용자만을 위해 따로 학습된 RandomForest 모델로 예측
    def _predict_rf(self, req: PredictRequest, stage: int) -> Tuple[float, float, float]:
        """3단계: 개인 전용 RF"""
        path = MODEL_DIR / f"user_{req.user_id}_rf.pkl"
        # 아직 개인 모델 파일이 없다면 (학습이 덜 되었거나 실패한 경우) 1단계 공용 모델로 대체(폴백)
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
    
    # 4단계: 최근 기록들의 흐름(시퀀스)을 반영하는 LSTM으로 예측
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
            # 이 사용자의 가장 최근 10건을 가져와 LSTM 입력 시퀀스로 변환
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

    # 0~120분 사이의 혈당 변화를 그래프로 그릴 수 있도록 5개 포인트로 구성된 곡선 데이터를 만듭니다.
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

    # 60분 후 예측 혈당 수치를 기준으로 위험도를 3단계(낮음/보통/높음)로 분류합니다.
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

    # 위험도와 사용자 상황(식사 여부, 당류량)에 따라 규칙 기반으로 코칭 문구를 생성합니다.
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