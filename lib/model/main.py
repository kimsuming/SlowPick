"""
혈당 예측 AI - FastAPI 서버
음료 섭취 후 혈당 변화를 예측하는 ML 기반 API
"""


from chat_router import chat_router
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import logging

from schemas import PredictRequest, PredictResponse, RecordRequest, RecordResponse, UserStats
from model_manager import ModelManager
from database import Database

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

db = Database()
model_manager = ModelManager(db)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("서버 시작: 공용 모델 로드 중...")
    model_manager.load_or_train_shared_model()
    logger.info("공용 모델 로드 완료")
    yield
    logger.info("서버 종료")


app = FastAPI(
    title="혈당 예측 AI API",
    description="음료 섭취 후 예상 혈당 변화를 반환하는 ML 기반 API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 챗봇 출입구를 /chat 경로로 등록합니다.
app.include_router(chat_router, prefix="/chat")


@app.get("/")
def root():
    return {"status": "ok", "message": "혈당 예측 AI 서버 정상 동작 중"}


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
        result = model_manager.predict(req)
        return result
    except Exception as e:
        logger.error(f"예측 오류: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/record", response_model=RecordResponse)
def record(req: RecordRequest):
    """
    실제 혈당 측정값 기록 (모델 학습용)

    섭취 후 실제 혈당을 기록하면 개인화 모델 학습에 사용됩니다.
    3건 이상 누적 시 편차 보정, 30건 이상 시 개인 모델 학습 시작.
    """
    try:
        record_id = db.save_record(req)
        user_record_count = db.get_user_record_count(req.user_id)

        # 데이터 충분하면 개인 모델 재학습 트리거
        model_manager.maybe_retrain_user_model(req.user_id, user_record_count)

        stage = model_manager.get_model_stage(user_record_count)
        return RecordResponse(
            record_id=record_id,
            user_record_count=user_record_count,
            model_stage=stage,
            message=f"기록 완료. 현재 {user_record_count}건 누적 ({stage})",
        )
    except Exception as e:
        logger.error(f"기록 오류: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/users/{user_id}/stats", response_model=UserStats)
def user_stats(user_id: str):
    """사용자 누적 데이터 현황 및 모델 단계 조회"""
    count = db.get_user_record_count(user_id)
    stage = model_manager.get_model_stage(count)
    avg_delta = db.get_user_avg_delta(user_id)
    return UserStats(
        user_id=user_id,
        record_count=count,
        model_stage=stage,
        avg_glucose_delta=avg_delta,
    )


from fastapi import Header, HTTPException

ADMIN_TOKEN = "123456"


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