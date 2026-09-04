"""
합성 CGM 데이터를 /record API로 순서대로 재생(seed)하는 스크립트

[목적]
  1단계 공용 모델은 원래대로 폴백 규칙 기반 데이터로 두고,
  2/3/4단계(개인화)를 실제로 확인하기 위해, 합성 CGM 데이터의
  "식사 이벤트"들을 실제 사용자가 기록을 남긴 것처럼 서버에 순서대로 보냅니다.

[전략]
  - carbs > 0인 시점(식사)마다 하나의 기록으로 변환
  - 사용자 1명당 이벤트가 38~41건뿐이라 100건(4단계)을 못 채우므로,
    10명의 이벤트를 시간순으로 합쳐서 하나의 테스트 user_id에게 몰아서 보냄
  - DB의 get_user_records()가 created_at(서버 저장 시각) 순으로 정렬하므로,
    "보내는 순서"가 곧 "시간 순서"가 되도록 미리 정렬 후 순차 전송

[사용법]
  python3 seed_records.py --base-url http://localhost:8000 --user-id seed_demo
  (EC2에서 직접 돌리면 --base-url http://localhost:8000 그대로 두면 됩니다)
"""

import argparse
import time
import sys
from datetime import timedelta

import pandas as pd
import requests

STAGE2_MIN, STAGE3_MIN, STAGE4_MIN = 3, 30, 100


def find_glucose_after(df_user, base_ts, minutes):
    target = base_ts + timedelta(minutes=minutes)
    window = df_user[
        (df_user["timestamp"] >= target - timedelta(minutes=5)) &
        (df_user["timestamp"] <= target + timedelta(minutes=5))
    ]
    if window.empty:
        return None
    closest = window.iloc[(window["timestamp"] - target).abs().argsort()[:1]]
    val = closest["glucose"].values[0]
    return None if pd.isna(val) else float(val)


def map_exercise_level(value):
    try:
        v = float(value)
        if v == 0:
            return 0
        elif v < 0.6:
            return 1
        else:
            return 2
    except (ValueError, TypeError):
        return 0


def build_events(csv_path):
    df = pd.read_csv(csv_path, parse_dates=["timestamp"])
    events = []

    for uid in df["user_id"].unique():
        du = df[df["user_id"] == uid].sort_values("timestamp").reset_index(drop=True)
        meals = du[du["carbs"] > 0]

        for _, row in meals.iterrows():
            base_ts = row["timestamp"]
            a30 = find_glucose_after(du, base_ts, 30)
            a60 = find_glucose_after(du, base_ts, 60)
            a120 = find_glucose_after(du, base_ts, 120)
            if a30 is None and a60 is None:
                continue
            if pd.isna(row["glucose"]):
                continue

            carbs_g = float(row["carbs"])
            med_val = str(row["medication_other"]).strip().lower()

            events.append({
                "timestamp": base_ts,
                "drink": {
                    "name": f"식사 (탄수화물 {carbs_g:.0f}g)",
                    "sugar_g": round(carbs_g * 0.5, 1),
                    "carbs_g": carbs_g,
                    "fat_g": 0.0,
                },
                "current_glucose": float(row["glucose"]),
                "meal_status": 1,  # 식사 시점이므로 1시간 이내로 고정
                "exercise_level": map_exercise_level(row["exercise_intensity"]),
                "insulin_taken": bool(float(row["insulin_bolus"]) > 0),
                "medication_taken": med_val not in ("none", "", "nan"),
                "measured_at": base_ts.isoformat(),
                "actual_glucose_30m": a30,
                "actual_glucose_60m": a60,
                "actual_glucose_120m": a120,
            })

    events.sort(key=lambda e: e["timestamp"])
    return events


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default="data/synthetic_glucose_dataset.csv")
    ap.add_argument("--base-url", default="http://localhost:8000")
    ap.add_argument("--user-id", default="seed_demo")
    ap.add_argument("--delay", type=float, default=0.05, help="요청 간 대기시간(초)")
    args = ap.parse_args()

    events = build_events(args.csv)
    print(f"총 {len(events)}건의 식사 이벤트를 '{args.user_id}' 사용자로 전송합니다.\n")

    last_stage = None
    for i, ev in enumerate(events, 1):
        payload = {
            "user_id": args.user_id,
            "predict_request": {
                "user_id": args.user_id,
                "drink": ev["drink"],
                "current_glucose": ev["current_glucose"],
                "meal_status": ev["meal_status"],
                "exercise_level": ev["exercise_level"],
                "insulin_taken": ev["insulin_taken"],
                "medication_taken": ev["medication_taken"],
                "measured_at": ev["measured_at"],
            },
            "actual_glucose_30m": ev["actual_glucose_30m"],
            "actual_glucose_60m": ev["actual_glucose_60m"],
            "actual_glucose_120m": ev["actual_glucose_120m"],
        }

        try:
            r = requests.post(f"{args.base_url}/record", json=payload, timeout=30)
            r.raise_for_status()
            data = r.json()
        except Exception as e:
            print(f"[{i}] 실패: {e}")
            continue

        stage = data.get("model_stage")
        count = data.get("user_record_count")

        if stage != last_stage:
            print(f"  >>> [{count}건째] 단계 전환: {last_stage} -> {stage} ({data.get('message')})")
            last_stage = stage
        elif i % 20 == 0:
            print(f"  [{count}건째] 현재 단계 {stage}")

        time.sleep(args.delay)

    print(f"\n완료. 최종 {len(events)}건 전송, 최종 단계: {last_stage}")


if __name__ == "__main__":
    main()
