"""
Pydantic 스키마 정의
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from enum import IntEnum
from datetime import datetime


class MealStatus(IntEnum):
    FASTING = 0       # 공복
    WITHIN_1H = 1     # 1시간 이내 식사
    WITHIN_2H = 2     # 2시간 이내 식사


class ExerciseLevel(IntEnum):
    NONE = 0          # 운동 없음
    LIGHT = 1         # 가벼운 운동
    INTENSE = 2       # 강한 운동


class DrinkInfo(BaseModel):
    name: str = Field(..., description="음료 이름")
    sugar_g: float = Field(..., ge=0, description="당류 (g)")
    carbs_g: float = Field(..., ge=0, description="탄수화물 (g)")
    fat_g: float = Field(0.0, ge=0, description="지방 (g) - 높을수록 혈당 상승 둔화")
    volume_ml: Optional[float] = Field(None, ge=0, description="용량 (ml)")


class PredictRequest(BaseModel):
    user_id: str = Field(..., description="사용자 ID")

    # 음료 정보
    drink: DrinkInfo

    # 실시간 사용자 입력
    current_glucose: float = Field(..., ge=40, le=400, description="현재 혈당 (mg/dL)")
    meal_status: MealStatus = Field(..., description="마지막 식사 상태")
    exercise_level: ExerciseLevel = Field(..., description="운동 여부")
    insulin_taken: bool = Field(False, description="인슐린 투여 여부")
    medication_taken: bool = Field(False, description="당뇨 약 복용 여부")
    measured_at: Optional[datetime] = Field(None, description="측정 시간 (없으면 현재 시각)")

    @field_validator("measured_at", mode="before")
    @classmethod
    def set_measured_at(cls, v):
        return v or datetime.now()

    model_config = {"use_enum_values": True}


class GlucoseCurve(BaseModel):
    time_minutes: List[int] = Field(..., description="시간축 (분)")
    predicted_glucose: List[float] = Field(..., description="예측 혈당 (mg/dL)")


class RiskLevel(BaseModel):
    label: str = Field(..., description="낮음 / 보통 / 높음")
    color: str = Field(..., description="UI 색상 코드")
    description: str = Field(..., description="위험도 설명")


class PredictResponse(BaseModel):
    user_id: str
    drink_name: str

    # 핵심 예측값
    current_glucose: float = Field(..., description="섭취 전 혈당 (mg/dL)")
    predicted_glucose_30m: float = Field(..., description="30분 후 예측 혈당")
    predicted_glucose_60m: float = Field(..., description="60분 후 예측 혈당")
    predicted_glucose_120m: float = Field(..., description="120분 후 예측 혈당")
    delta_glucose: float = Field(..., description="최대 혈당 상승량 (Δ mg/dL)")

    # 시계열 곡선
    glucose_curve: GlucoseCurve

    # 위험도
    risk: RiskLevel

    # 모델 메타
    model_stage: int = Field(..., description="사용된 모델 단계 (1~4)")
    model_stage_label: str = Field(..., description="모델 단계 설명")
    is_personalized: bool = Field(..., description="개인화 모델 여부")
    accuracy_warning: Optional[str] = Field(None, description="정확도 경고 문구")

    # 코칭
    coaching_drink_alt: Optional[str] = Field(None, description="음료 대체 추천")
    coaching_action: Optional[str] = Field(None, description="행동 추천")


class RecordRequest(BaseModel):
    """실제 측정값 기록 (모델 학습용)"""
    user_id: str
    predict_request: PredictRequest
    actual_glucose_30m: Optional[float] = Field(None, ge=40, le=400, description="30분 후 실측값")
    actual_glucose_60m: Optional[float] = Field(None, ge=40, le=400, description="60분 후 실측값")
    actual_glucose_120m: Optional[float] = Field(None, ge=40, le=400, description="120분 후 실측값")


class RecordResponse(BaseModel):
    record_id: str
    user_record_count: int
    model_stage: int
    message: str


class UserStats(BaseModel):
    user_id: str
    record_count: int
    model_stage: int
    avg_glucose_delta: Optional[float] = Field(None, description="평균 혈당 상승량")
