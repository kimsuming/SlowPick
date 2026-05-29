# 혈당 예측 AI — FastAPI 서버

음료 섭취 후 혈당 변화를 예측하는 ML 기반 REST API.

## 파일 구조

```
glucose_predictor/
├── main.py            # FastAPI 앱, 라우터
├── schemas.py         # Pydantic 입출력 스키마
├── features.py        # 특성 엔지니어링 (수치 변환, 합성 데이터)
├── model_manager.py   # 4단계 모델 선택 / 학습 / 예측
├── database.py        # SQLite DB (사용자 기록 저장)
├── requirements.txt
└── models/            # 학습된 모델 파일 저장 (자동 생성)
    ├── shared_model.pkl
    ├── user_{id}_rf.pkl
    └── user_{id}_lstm/
```

## 실행

```bash
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Swagger UI: http://localhost:8000/docs

---

## API 엔드포인트

### POST `/predict` — 혈당 예측

**요청 예시**
```json
{
  "user_id": "user_001",
  "drink": {
    "name": "콜라 355ml",
    "sugar_g": 39,
    "carbs_g": 39,
    "fat_g": 0
  },
  "current_glucose": 105,
  "meal_status": 1,
  "exercise_level": 0,
  "insulin_taken": false,
  "medication_taken": false
}
```

**응답 예시**
```json
{
  "user_id": "user_001",
  "drink_name": "콜라 355ml",
  "current_glucose": 105,
  "predicted_glucose_30m": 131.2,
  "predicted_glucose_60m": 148.7,
  "predicted_glucose_120m": 138.4,
  "delta_glucose": 43.7,
  "glucose_curve": {
    "time_minutes": [0, 30, 60, 90, 120],
    "predicted_glucose": [105, 131.2, 148.7, 143.5, 138.4]
  },
  "risk": {
    "label": "보통",
    "color": "#e67e22",
    "description": "식후 혈당 경계 수준. 섭취량 조절을 권장합니다."
  },
  "model_stage": 1,
  "model_stage_label": "공용 RandomForest",
  "is_personalized": false,
  "accuracy_warning": "초기 예측 단계입니다. 실제 측정값을 기록할수록 정확도가 향상됩니다.",
  "coaching_drink_alt": "저GI 음료(두유, 무가당 차류)로 대체를 권장합니다.",
  "coaching_action": "섭취 후 15분 가벼운 걷기를 하면 혈당 상승을 약 15~20% 완화할 수 있습니다."
}
```

---

### POST `/record` — 실제 측정값 기록 (모델 학습용)

```json
{
  "user_id": "user_001",
  "predict_request": { /* 위 predict 요청과 동일 */ },
  "actual_glucose_30m": 128,
  "actual_glucose_60m": 145,
  "actual_glucose_120m": 135
}
```

---

### GET `/users/{user_id}/stats` — 사용자 현황

```json
{
  "user_id": "user_001",
  "record_count": 12,
  "model_stage": 2,
  "avg_glucose_delta": 38.5
}
```

---

## 모델 단계

| 단계 | 조건 | 모델 | 설명 |
|------|------|------|------|
| 1 | 0~2건 | 공용 RandomForest | 합성 데이터 2000건으로 사전 학습 |
| 2 | 3~29건 | 공용 RF + 편차 보정 | 개인 평균 오차를 예측값에 가산 |
| 3 | 30~99건 | 개인 전용 RF | 개인 데이터만으로 재학습 |
| 4 | 100건+ | 개인 LSTM | 시계열 흐름 반영 (TensorFlow 필요) |

---

## 특성 목록 (14개)

| 특성 | 설명 |
|------|------|
| current_glucose | 현재 혈당 |
| sugar_g / carbs_g / fat_g | 음료 영양 성분 |
| net_carbs | 지방 감쇠 적용 탄수화물 |
| gi_proxy | 당/탄수화물 비율 (GI 근사) |
| meal_status | 공복(0) / 1시간(1) / 2시간(2) |
| exercise_level | 없음(0) / 가벼운(1) / 강한(2) |
| insulin_taken / medication_taken | 인슐린/약 복용 여부 |
| hour_sin / hour_cos | 시간대 순환 인코딩 |
| is_morning_peak | 새벽 현상 플래그 (04~09시) |
| glucose_zone | 현재 혈당 구간 (0~3) |

---

## LSTM 활성화 (4단계)

```bash
pip install tensorflow
```

100건 이상 기록 시 `/record` 호출 때 자동으로 LSTM 학습이 트리거됩니다.
