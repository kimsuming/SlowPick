"""
데이터베이스 레이어
SQLite (개발) / PostgreSQL (운영) 추상화
사용자 기록 저장 및 개인화 모델 학습용 데이터 제공
"""

import sqlite3
import json
import uuid
import logging
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Tuple

logger = logging.getLogger(__name__)

DB_PATH = Path("data/glucose.db")


class Database:
    def __init__(self, db_path: str = str(DB_PATH)):
        DB_PATH.parent.mkdir(exist_ok=True)
        self.db_path = db_path
        self._init_db()

    def _get_conn(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self):
        with self._get_conn() as conn:
            conn.executescript("""
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

                CREATE INDEX IF NOT EXISTS idx_user_id
                    ON glucose_records(user_id);

                CREATE INDEX IF NOT EXISTS idx_user_created
                    ON glucose_records(user_id, created_at);
            """)
        logger.info("DB 초기화 완료")

    # ──────────────────────────────────────────
    # 기록 저장
    # ──────────────────────────────────────────

    def save_record(self, req) -> str:
        """RecordRequest 저장 후 record_id 반환"""
        record_id = str(uuid.uuid4())
        pr = req.predict_request

        with self._get_conn() as conn:
            conn.execute("""
                INSERT INTO glucose_records (
                    id, user_id, drink_name,
                    sugar_g, carbs_g, fat_g,
                    current_glucose, meal_status, exercise_level,
                    insulin_taken, medication_taken, measured_at,
                    actual_glucose_30m, actual_glucose_60m, actual_glucose_120m
                ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            """, (
                record_id,
                req.user_id,
                pr.drink.name,
                pr.drink.sugar_g,
                pr.drink.carbs_g,
                pr.drink.fat_g,
                pr.current_glucose,
                int(pr.meal_status),
                int(pr.exercise_level),
                int(pr.insulin_taken),
                int(pr.medication_taken),
                pr.measured_at.isoformat() if pr.measured_at else datetime.now().isoformat(),
                req.actual_glucose_30m,
                req.actual_glucose_60m,
                req.actual_glucose_120m,
            ))
        return record_id

    # ──────────────────────────────────────────
    # 조회
    # ──────────────────────────────────────────

    def get_user_record_count(self, user_id: str) -> int:
        with self._get_conn() as conn:
            row = conn.execute(
                "SELECT COUNT(*) as cnt FROM glucose_records WHERE user_id = ?",
                (user_id,)
            ).fetchone()
        return row["cnt"] if row else 0

    def get_user_records(self, user_id: str, limit: Optional[int] = None) -> List[dict]:
        """시간순 정렬된 사용자 기록 반환"""
        sql = "SELECT * FROM glucose_records WHERE user_id = ? ORDER BY created_at ASC"
        params = [user_id]
        if limit:
            sql += " LIMIT ?"
            params.append(limit)

        with self._get_conn() as conn:
            rows = conn.execute(sql, params).fetchall()
        return [dict(row) for row in rows]

    def get_user_avg_delta(self, user_id: str) -> Optional[float]:
        """사용자 평균 혈당 상승량 (60분 기준)"""
        with self._get_conn() as conn:
            row = conn.execute("""
                SELECT AVG(actual_glucose_60m - current_glucose) as avg_delta
                FROM glucose_records
                WHERE user_id = ?
                  AND actual_glucose_60m IS NOT NULL
            """, (user_id,)).fetchone()
        val = row["avg_delta"] if row else None
        return round(val, 2) if val is not None else None

    def get_user_bias(self, user_id: str) -> Tuple[float, float, float]:
        """
        공용 모델 예측값과 실측값 간 평균 편차 계산
        2단계 보정에 사용
        """
        records = self.get_user_records(user_id)
        biases_30, biases_60, biases_120 = [], [], []

        for r in records:
            base = r["current_glucose"]
            if r.get("actual_glucose_30m") is not None:
                biases_30.append(r["actual_glucose_30m"] - base)
            if r.get("actual_glucose_60m") is not None:
                biases_60.append(r["actual_glucose_60m"] - base)
            if r.get("actual_glucose_120m") is not None:
                biases_120.append(r["actual_glucose_120m"] - base)

        def safe_mean(lst):
            return float(sum(lst) / len(lst)) if lst else 0.0

        return safe_mean(biases_30), safe_mean(biases_60), safe_mean(biases_120)
