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
                    menu_id INTEGER,
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
            # 기존 DB에 menu_id 컬럼이 없을 수 있으므로 안전하게 추가 시도
            try:
                conn.execute("ALTER TABLE glucose_records ADD COLUMN menu_id INTEGER")
            except sqlite3.OperationalError:
                pass  # 이미 존재함
        logger.info("DB 초기화 완료")

    # ──────────────────────────────────────────
    # 기록 저장
    # ──────────────────────────────────────────

    def _resolve_nutrition(self, req) -> Tuple[str, float, float, float]:
        """
        클라이언트(Flutter)가 메뉴 선택 화면에서 이미 갖고 있던 당류(sugar_g)를
        RecordRequest에 실어 보낸 값을 그대로 사용한다.
        carbs_g/fat_g는 메뉴 데이터에 애초에 없으므로, carbs_g는 sugar_g로 근사하고
        fat_g는 0으로 둔다 (기존 example.dart 프로토타입과 동일한 근사 방식).
        """
        drink_name = getattr(req, "drink_name", None) or (
            f"메뉴#{req.menu_id}" if getattr(req, "menu_id", None) else "음료 미지정"
        )
        sugar_g = getattr(req, "sugar_g", None) or 0.0
        carbs_g = sugar_g  # 근사치
        fat_g = 0.0
        return (drink_name, sugar_g, carbs_g, fat_g)

    def save_record(self, req) -> str:
        """
        followup_offset_minutes가 지정된 경우: "N분 후 실측값" 업데이트로 보고,
        새 행을 만들지 않고 이 사용자의 가장 최근 기록 중 그 칸이 아직 비어있는
        기록을 찾아 값을 채운다. 시간 계산 없이, 사용자가 누른 칩(30/60/120)을
        그대로 신뢰한다.

        그 외의 경우: 평범한 새 스냅샷을 저장한다.
        """
        offset = getattr(req, "followup_offset_minutes", None)
        if offset in (30, 60, 120):
            return self._apply_followup(req.user_id, offset, req.current_glucose)

        record_id = str(uuid.uuid4())
        drink_name, sugar_g, carbs_g, fat_g = self._resolve_nutrition(req)
        measured_at = req.measured_at or datetime.now()
        meal_status = int(req.meal_status) if req.meal_status is not None else 0
        exercise_level = int(req.exercise_level) if req.exercise_level is not None else 0

        with self._get_conn() as conn:
            conn.execute("""
                INSERT INTO glucose_records (
                    id, user_id, drink_name, menu_id,
                    sugar_g, carbs_g, fat_g,
                    current_glucose, meal_status, exercise_level,
                    insulin_taken, medication_taken, measured_at,
                    actual_glucose_30m, actual_glucose_60m, actual_glucose_120m
                ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
            """, (
                record_id,
                req.user_id,
                drink_name,
                req.menu_id,
                sugar_g,
                carbs_g,
                fat_g,
                req.current_glucose,
                meal_status,
                exercise_level,
                int(req.insulin_taken),
                int(req.medication_taken),
                measured_at.isoformat(),
                None, None, None,
            ))

        return record_id

    def _apply_followup(self, user_id: str, offset_minutes: int, actual_glucose: float) -> str:
        """
        이 사용자의 가장 최근 기록 중 actual_glucose_{offset}m이 아직 비어있는
        기록을 찾아 값을 채운다. 시간차 계산 없음 - 사용자가 지정한 offset을 그대로 믿는다.
        업데이트된 기록의 id를 반환 (없으면 새 id를 그냥 반환).
        """
        column = f"actual_glucose_{offset_minutes}m"
        with self._get_conn() as conn:
            row = conn.execute(f"""
                SELECT id FROM glucose_records
                WHERE user_id = ? AND {column} IS NULL
                ORDER BY measured_at DESC
                LIMIT 1
            """, (user_id,)).fetchone()

            if row is None:
                logger.warning(f"[{user_id}] followup({offset_minutes}분) 대상 기록 없음 - 무시")
                return str(uuid.uuid4())

            conn.execute(
                f"UPDATE glucose_records SET {column} = ? WHERE id = ?",
                (actual_glucose, row["id"]),
            )
            return row["id"]

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
        """사용자 평균 혈당 상승량 (60분 값 우선, 없으면 30분 → 120분 순으로 대체)"""
        with self._get_conn() as conn:
            row = conn.execute("""
                SELECT AVG(
                    COALESCE(actual_glucose_60m, actual_glucose_30m, actual_glucose_120m)
                    - current_glucose
                ) as avg_delta
                FROM glucose_records
                WHERE user_id = ?
                  AND (actual_glucose_30m IS NOT NULL
                       OR actual_glucose_60m IS NOT NULL
                       OR actual_glucose_120m IS NOT NULL)
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