"""
GlucoBench_benchmark_dataset.csv → glucose.db 변환 스크립트

변환 전략:
- carbs > 0인 행(식사 시점)을 기준으로 레코드 생성
- 해당 시점 기준 30분/60분/120분 후 glucose값을 찾아서 actual로 사용
- sugar_g는 carbs * 0.5로 추정 (없는 경우)
- fat_g는 0으로 채움
- exercise_level: none=0, low=1, medium/high=2
- insulin_taken: insulin_bolus > 0이면 1
- medication_taken: medication_other != 'none'이면 1

사용법:
    python3 convert_glucobench.py
"""

import sqlite3
import uuid
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# ── 경로 설정 ──
CSV_PATH  = "GlucoBench_benchmark_dataset.csv"
DB_PATH   = "lib/model/data/glucose_with_glucobench.db"   # 실제 프로젝트 경로

# ── exercise_intensity → exercise_level 변환 ──
EXERCISE_MAP = {
    "none":   0,
    "low":    1,
    "medium": 2,
    "high":   2,
}

def find_glucose_after(df_user, base_ts, minutes):
    """base_ts 기준으로 ±5분 범위 내 가장 가까운 glucose값 반환"""
    target = base_ts + timedelta(minutes=minutes)
    window = df_user[
        (df_user["timestamp"] >= target - timedelta(minutes=5)) &
        (df_user["timestamp"] <= target + timedelta(minutes=5))
    ]
    if window.empty:
        return None
    # 가장 가까운 시점의 glucose 반환
    closest = window.iloc[(window["timestamp"] - target).abs().argsort()[:1]]
    return float(closest["glucose"].values[0])


def convert():
    df = pd.read_csv(CSV_PATH)
    df["timestamp"] = pd.to_datetime(df["timestamp"])

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # 테이블 없으면 생성
    cur.executescript("""
        CREATE TABLE IF NOT EXISTS glucose_records (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            drink_name TEXT,
            sugar_g REAL,
            carbs_g REAL,
            fat_g REAL,
            current_glucose REAL NOT NULL,
            meal_status INTEGER,
            exercise_level INTEGER,
            insulin_taken INTEGER,
            medication_taken INTEGER,
            measured_at TEXT,
            actual_glucose_30m REAL,
            actual_glucose_60m REAL,
            actual_glucose_120m REAL,
            created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE INDEX IF NOT EXISTS idx_user_id ON glucose_records(user_id);
    """)

    inserted = 0
    skipped  = 0

    for user_id in df["user_id"].unique():
        df_user = df[df["user_id"] == user_id].sort_values("timestamp").reset_index(drop=True)

        # carbs > 0인 행만 (식사/음료 섭취 시점)
        meal_rows = df_user[df_user["carbs"] > 0]

        for _, row in meal_rows.iterrows():
            base_ts = row["timestamp"]

            actual_30  = find_glucose_after(df_user, base_ts, 30)
            actual_60  = find_glucose_after(df_user, base_ts, 60)
            actual_120 = find_glucose_after(df_user, base_ts, 120)

            # 30분/60분 후 값이 둘 다 없으면 스킵
            if actual_30 is None and actual_60 is None:
                skipped += 1
                continue

            carbs_g        = float(row["carbs"])
            sugar_g        = round(carbs_g * 0.5, 1)   # 추정값
            fat_g          = 0.0
            current_glucose = float(row["glucose"])
            exercise_level = EXERCISE_MAP.get(str(row["exercise_intensity"]).lower(), 0)
            insulin_taken  = 1 if float(row["insulin_bolus"]) > 0 else 0
            medication_taken = 0 if str(row["medication_other"]).strip().lower() == "none" else 1
            meal_status    = 1  # 식사 시점이므로 1시간 이내로 고정
            measured_at    = base_ts.isoformat()
            drink_name     = f"식사 (탄수화물 {carbs_g}g)"

            cur.execute("""
                INSERT OR IGNORE INTO glucose_records (
                    id, user_id, drink_name,
                    sugar_g, carbs_g, fat_g,
                    current_glucose, meal_status, exercise_level,
                    insulin_taken, medication_taken, measured_at,
                    actual_glucose_30m, actual_glucose_60m, actual_glucose_120m
                ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            """, (
                str(uuid.uuid4()), user_id, drink_name,
                sugar_g, carbs_g, fat_g,
                current_glucose, meal_status, exercise_level,
                insulin_taken, medication_taken, measured_at,
                actual_30, actual_60, actual_120,
            ))
            inserted += 1

    conn.commit()

    # 결과 확인
    cur.execute("SELECT user_id, COUNT(*) FROM glucose_records GROUP BY user_id")
    rows = cur.fetchall()
    conn.close()

    print(f"✅ 삽입 완료: {inserted}건 / 스킵: {skipped}건")
    print()
    print("[ 유저별 누적 건수 ]")
    for r in rows:
        print(f"  {r[0]}: {r[1]}건")


if __name__ == "__main__":
    convert()
