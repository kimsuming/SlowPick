"""
혈당 예측 AI - FastAPI 서버
음료 섭취 후 혈당 변화를 예측하는 ML 기반 API
"""

from chat_router import chat_router
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
# FastAPI 앱을 직접 실행하기 위한 ASGI 서버입니다.
import uvicorn
import logging

# 요청/응답 데이터의 형태(스키마)를 정의한 Pydantic 모델들을 가져옵니다
from schemas import PredictRequest, PredictResponse, RecordRequest, RecordResponse, UserStats
# 4단계 개인화 모델 로직을 담당하는 클래스를 가져옵니다.
from model_manager import ModelManager
# SQLite 데이터베이스 접근을 담당하는 클래스를 가져옵니다.
from database import Database

# 로그 출력 레벨을 INFO로 설정하여 기본 로깅을 구성합니다.
logging.basicConfig(level=logging.INFO)
# 현재 모듈 이름으로 로거 인스턴스를 생성합니다.
logger = logging.getLogger(__name__)

# 데이터베이스 인스턴스를 전역으로 생성합니다.
db = Database()
# 데이터베이스 인스턴스를 주입하여 모델 매니저를 전역으로 생성합니다.
model_manager = ModelManager(db)


# FastAPI 앱의 시작/종료 생명주기를 관리하는 함수입니다.
@asynccontextmanager
async def lifespan(app: FastAPI):
    # 서버가 시작될 때 로그를 남깁니다.
    logger.info("서버 시작: 공용 모델 로드 중...")
    # 저장된 공용 모델이 있으면 불러오고, 없으면 새로 학습시킵니다.
    model_manager.load_or_train_shared_model()
    # 모델 로드가 끝났음을 로그로 남깁니다.
    logger.info("공용 모델 로드 완료")
    # yield 이전 코드는 시작 시, 이후 코드는 종료 시 실행됩니다.
    yield
    # 서버가 종료될 때 로그를 남깁니다.
    logger.info("서버 종료")


# FastAPI 애플리케이션 인스턴스를 생성하고 기본 메타데이터와 lifespan을 설정합니다.
app = FastAPI(
    title="혈당 예측 AI API",
    description="음료 섭취 후 예상 혈당 변화를 반환하는 ML 기반 API",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS 미들웨어를 등록하여 모든 출처(origin), 메서드, 헤더의 요청을 허용합니다.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 챗봇 출입구를 /chat 경로로 등록합니다.
app.include_router(chat_router, prefix="/chat")

# 서버 상태 확인용 루트 엔드포인트입니다.
@app.get("/")
def root():
    return {"status": "ok", "message": "혈당 예측 AI 서버 정상 동작 중"}

# 혈당 예측을 수행하는 POST 엔드포인트입니다.
@app.post("/predict", response_model=PredictResponse)
def predict(req: PredictRequest):
    """
    혈당 예측 엔드포인트

    - 사용자 데이터 수에 따라 자동으로 모델 단계 선택
    - 1단계(~2건): 공용 RandomForest
    - 2단계(3~29건): 공용 RF + 개인 편차 보정
    - 3단계(30~99건): 개인 전용 RandomForest
    - 4단계(100건+): LSTM 시계열 모델
    """
    try:
        # 모델 매니저에게 요청 데이터를 넘겨 실제 예측을 수행시킵니다.
        result = model_manager.predict(req)
        # 예측 결과를 그대로 응답으로 반환합니다.
        return result
    except Exception as e:
        logger.error(f"예측 오류: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# 실제 혈당 측정값을 기록하는 POST 엔드포인트입니다.
@app.post("/record", response_model=RecordResponse)
def record(req: RecordRequest):
    """
    실제 혈당 측정값 기록 (모델 학습용)

    섭취 후 실제 혈당을 기록하면 개인화 모델 학습에 사용됩니다.
    3건 이상 누적 시 편차 보정, 30건 이상 시 개인 모델 학습 시작.
    """
    try:
        # 요청받은 기록을 데이터베이스에 저장하고, 생성된 레코드 ID를 받습니다.
        record_id = db.save_record(req)
         # 해당 사용자의 누적 기록 건수를 조회합니다.
        user_record_count = db.get_user_record_count(req.user_id)

        # 데이터 충분하면 개인 모델 재학습 트리거
        # (내부적으로 3건/30건/100건 기준을 확인하여 필요 시 재학습을 시작합니다.)
        model_manager.maybe_retrain_user_model(req.user_id, user_record_count)

        # 현재 누적 건수에 해당하는 모델 단계를 계산합니다.
        stage = model_manager.get_model_stage(user_record_count)
        # 기록 결과, 누적 건수, 현재 모델 단계를 담아 응답을 반환합니다.
        return RecordResponse(
            record_id=record_id,
            user_record_count=user_record_count,
            model_stage=stage,
            message=f"기록 완료. 현재 {user_record_count}건 누적 ({stage})",
        )
    except Exception as e:
        logger.error(f"기록 오류: {e}")
        raise HTTPException(status_code=500, detail=str(e))

 # 특정 사용자의 누적 데이터 현황과 모델 단계를 조회하는 GET 엔드포인트입니다.
@app.get("/users/{user_id}/stats", response_model=UserStats)
def user_stats(user_id: str):
    """사용자 누적 데이터 현황 및 모델 단계 조회"""
    # 해당 사용자의 총 기록 건수를 조회합니다.
    count = db.get_user_record_count(user_id)
    # 건수에 따른 현재 모델 단계를 계산합니다.
    stage = model_manager.get_model_stage(count)
    # 해당 사용자의 평균 혈당 변화량을 조회합니다.
    avg_delta = db.get_user_avg_delta(user_id)
    # 사용자 ID, 기록 건수, 모델 단계, 평균 혈당 변화량을 담아 응답을 반환합니다.
    return UserStats(
        user_id=user_id,
        record_count=count,
        model_stage=stage,
        avg_glucose_delta=avg_delta,
    )


from fastapi import Header, HTTPException

ADMIN_TOKEN = "123456"

# 공용 모델을 수동으로 재학습시키는 관리자 전용 POST 엔드포인트입니다.
@app.post("/admin/retrain-shared")
def retrain_shared(x_admin_token: str = Header(None)):
    if x_admin_token != ADMIN_TOKEN:
        raise HTTPException(status_code=403, detail="관리자 권한 필요")

    model_manager.train_shared_model()

    return {
        "status": "ok",
        "message": "공용 모델 재학습 완료"
    }


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)