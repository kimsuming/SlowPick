"""
glucose.db에 가상 혈당 기록 110건을 삽입하는 스크립트.
실제 프로젝트의 database.py를 그대로 재사용합니다.

사용법:
    python seed_data.py
"""

import sys
import os
import uuid
import random
import sqlite3
from datetime import datetime, timedelta

# ── DB 경로: 실제 프로젝트에서는 'data/glucose.db' 로 수정 ──
DB_PATH = "data/glucose.db"

# ── 테스트 대상 유저 ID ──
USER_ID = "user_test_001"

# ── 가상 음료 목록 (이름, 당류, 탄수화물, 지방) ──
DRINKS = [
    ("아메리카노",        0,  0,  0),
    ("카페라떼",          8, 10,  4),
    ("바닐라라떼",       30, 38,  5),
    ("초코프라푸치노",   48, 62,  8),
    ("콜라 355ml",        39, 39,  0),
    ("오렌지주스",        22, 26,  0),
    ("두유 (무가당)",      2,  5,  4),
    ("아이스티",          18, 20,  0),
    ("녹차라떼",          24, 30,  3),
    ("에너지 드링크",     27, 28,  0),
]

def seed(n: int = 110):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # 테이블이 없으면 생성
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

    base_time = datetime.now() - timedelta(days=n)

    inserted = 0
    for i in range(n):
        drink_name, sugar_g, carbs_g, fat_g = random.choice(DRINKS)

        current_glucose  = round(random.uniform(85, 160), 1)
        meal_status      = random.randint(0, 2)
        exercise_level   = random.choices([0, 1, 2], weights=[60, 30, 10])[0]
        insulin_taken    = random.choices([0, 1], weights=[80, 20])[0]
        medication_taken = random.choices([0, 1], weights=[75, 25])[0]
        measured_at      = (base_time + timedelta(hours=i * 5)).isoformat()

        # ── 생리학적 규칙으로 사후 혈당 계산 ──
        fat_dampen       = 1.0 - min(fat_g * 0.02, 0.35)
        meal_factor      = [1.3, 1.0, 0.8][meal_status]
        exercise_factor  = [1.0, 0.75, 0.55][exercise_level]
        insulin_factor   = 0.5 if insulin_taken else 1.0
        med_factor       = 0.7 if medication_taken else 1.0
        delta_max = (
            (sugar_g * 0.9 + carbs_g * 0.25)
            * fat_dampen * meal_factor
            * exercise_factor * insulin_factor * med_factor
        )

        actual_30  = round(current_glucose + delta_max * 0.6  + random.gauss(0, 3), 1)
        actual_60  = round(current_glucose + delta_max * 1.0  + random.gauss(0, 4), 1)
        actual_120 = round(current_glucose + delta_max * 0.65 + random.gauss(0, 5), 1)

        cur.execute("""
            INSERT INTO glucose_records (
                id, user_id, drink_name,
                sugar_g, carbs_g, fat_g,
                current_glucose, meal_status, exercise_level,
                insulin_taken, medication_taken, measured_at,
                actual_glucose_30m, actual_glucose_60m, actual_glucose_120m
            ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """, (
            str(uuid.uuid4()), USER_ID, drink_name,
            sugar_g, carbs_g, fat_g,
            current_glucose, meal_status, exercise_level,
            insulin_taken, medication_taken, measured_at,
            actual_30, actual_60, actual_120,
        ))
        inserted += 1

    conn.commit()

    # ── 결과 요약 출력 ──
    cur.execute("SELECT COUNT(*) FROM glucose_records WHERE user_id = ?", (USER_ID,))
    total = cur.fetchone()[0]

    cur.execute("""
        SELECT drink_name, current_glucose, actual_glucose_60m, measured_at
        FROM glucose_records
        WHERE user_id = ?
        ORDER BY measured_at DESC
        LIMIT 5
    """, (USER_ID,))
    samples = cur.fetchall()
    conn.close()

    print(f"✅ {inserted}건 삽입 완료 (유저: {USER_ID})")
    print(f"📦 DB 총 누적 건수: {total}건")
    print()
    print("[ 최근 5건 샘플 ]")
    print(f"{'음료':<20} {'현재혈당':>8} {'60분후':>8} {'측정시각'}")
    print("-" * 60)
    for row in samples:
        print(f"{row[0]:<20} {row[1]:>8.1f} {row[2]:>8.1f}  {row[3][:16]}")

    print()
    print(f"📁 DB 파일 위치: {os.path.abspath(DB_PATH)}")
    print("👉 실제 프로젝트에 적용하려면 DB_PATH를 'data/glucose.db'로 바꾸세요.")


if __name__ == "__main__":
    seed(110)
