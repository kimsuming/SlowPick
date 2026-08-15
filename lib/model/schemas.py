"""
Pydantic 스키마 정의
"""

# Pydantic의 기본 모델 클래스, 필드 검증 도구, 커스텀 검증 데코레이터를 가져옵니다.
from pydantic import BaseModel, Field, field_validator
# 선택적 타입(Optional)과 리스트 타입(List)을 위한 typing 모듈입니다.
from typing import Optional, List
# 정수 기반의 열거형(Enum)을 만들기 위한 클래스입니다.
from enum import IntEnum
# 시간 정보를 다루기 위한 datetime 클래스입니다.
from datetime import datetime

# 마지막 식사로부터 얼마나 시간이 지났는지를 나타내는 열거형입니다.
# IntEnum이라 정수처럼도 쓸 수 있고, 이름으로도 접근할 수 있습니다.
class MealStatus(IntEnum):
    FASTING = 0       # 공복
    WITHIN_1H = 1     # 1시간 이내 식사
    WITHIN_2H = 2     # 2시간 이내 식사

# 운동 강도를 나타내는 열거형입니다.
class ExerciseLevel(IntEnum):
    NONE = 0          # 운동 없음
    LIGHT = 1         # 가벼운 운동
    INTENSE = 2       # 강한 운동

# 음료 한 잔에 대한 영양 정보를 담는 데이터 모델입니다.
class DrinkInfo(BaseModel):
    name: str = Field(..., description="음료 이름")
    sugar_g: float = Field(..., ge=0, description="당류 (g)")
    carbs_g: float = Field(..., ge=0, description="탄수화물 (g)")
    fat_g: float = Field(0.0, ge=0, description="지방 (g) - 높을수록 혈당 상승 둔화")
    volume_ml: Optional[float] = Field(None, ge=0, description="용량 (ml)")

# 혈당 예측 요청 시 클라이언트가 서버로 보내는 데이터 형태입니다.
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
    # 측정 시간, 값이 없으면 아래 검증 함수에서 현재 시각으로 자동 채워짐
    measured_at: Optional[datetime] = Field(None, description="측정 시간 (없으면 현재 시각)")

    # measured_at 필드가 채워지기 "전(before)"에 실행되는 커스텀 검증 함수입니다.
    @field_validator("measured_at", mode="before")
    @classmethod
    def set_measured_at(cls, v):
        # 값이 들어오면(v) 그 값을 그대로 쓰고, 값이 없으면(None이나 빈 값) 현재 시각으로 대체합니다.
        return v or datetime.now()

    model_config = {"use_enum_values": True}


# 시간에 따른 예측 혈당 곡선을 나타내는 모델입니다.
class GlucoseCurve(BaseModel):
    time_minutes: List[int] = Field(..., description="시간축 (분)")
    predicted_glucose: List[float] = Field(..., description="예측 혈당 (mg/dL)")


# 위험도 정보를 담는 모델입니다. (UI에 표시할 라벨, 색상, 설명)
class RiskLevel(BaseModel):
    label: str = Field(..., description="낮음 / 보통 / 높음")
    color: str = Field(..., description="UI 색상 코드")
    description: str = Field(..., description="위험도 설명")


# 혈당 예측 결과를 클라이언트에게 돌려줄 때 사용하는 응답 데이터 형태입니다.
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
    # 위에서 정의한 GlucoseCurve 모델을 그대로 중첩하여, 그래프를 그릴 수 있는 전체 데이터를 담음
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


# 실제 측정값을 기록할 때 클라이언트가 서버로 보내는 요청 데이터 형태입니다.
class RecordRequest(BaseModel):
    """실제 측정값 기록 (모델 학습용)"""
    user_id: str
    predict_request: PredictRequest
    actual_glucose_30m: Optional[float] = Field(None, ge=40, le=400, description="30분 후 실측값")
    actual_glucose_60m: Optional[float] = Field(None, ge=40, le=400, description="60분 후 실측값")
    actual_glucose_120m: Optional[float] = Field(None, ge=40, le=400, description="120분 후 실측값")


# 기록 저장이 완료된 후 클라이언트에게 돌려주는 응답 데이터 형태입니다.
class RecordResponse(BaseModel):
    record_id: str
    user_record_count: int
    model_stage: int
    message: str


# 사용자의 누적 데이터 현황을 조회할 때 응답하는 데이터 형태입니다.
class UserStats(BaseModel):
    user_id: str
    record_count: int
    model_stage: int
    avg_glucose_delta: Optional[float] = Field(None, description="평균 혈당 상승량")
