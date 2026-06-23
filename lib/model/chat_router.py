"""
SlowPick 챗봇 기능을 위한 FastAPI 라우터 예시 코드입니다.

전체 흐름은 다음과 같습니다.
1. 사용자가 채팅창에 질문을 입력하면 이 파일의 /chat 출입구로 요청이 들어옵니다.
2. 사용자의 최근 혈당 예측 기록과, 질문에 포함된 음료의 영양 정보를 데이터베이스에서 가져옵니다.
3. 가져온 정보를 정리하여 인공지능 언어모델에게 전달할 안내문(시스템 프롬프트)을 만듭니다.
4. 안내문과 사용자의 질문을 함께 인공지능 API로 보내고, 받은 답변을 그대로 앱으로 돌려줍니다.

기존 SlowPick의 main.py 또는 app.py 파일에서 이 라우터를 등록해야 사용할 수 있습니다.
예시: app.include_router(chat_router, prefix="/chat")
"""

import os
import sqlite3
import httpx
import pymysql
from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

chat_router = APIRouter()

# 환경변수에 Gemini API 키를 미리 등록해두어야 합니다.
# 예시(터미널에서): export GEMINI_API_KEY="발급받은키값"
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
GEMINI_MODEL = "gemini-2.5-flash"
GEMINI_API_URL = (
    f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"
)

# glucose.db 파일의 실제 위치에 맞게 경로를 수정해주세요.
GLUCOSE_DB_PATH = "data/glucose.db"

# 메뉴 정보가 저장된 RDS(MySQL) 데이터베이스 접속 정보입니다.
# slowpick-api/.env 파일에 있는 값과 동일합니다. (읽기 전용으로만 사용합니다)
MENU_DB_CONFIG = {
    "host": "slowpick-db.clqe0u26ihjp.ap-northeast-2.rds.amazonaws.com",
    "user": "admin",
    "password": "tmffhdnvlr123",
    "database": "slowpick",
}


class ChatRequest(BaseModel):
    user_id: str
    message: str
    menu_id: Optional[int] = None  # 사용자가 특정 음료에 대해 질문하는 경우 함께 전달


class ChatResponse(BaseModel):
    reply: str


def get_user_health_context(user_id: int) -> Optional[dict]:
    """
    사용자의 최근 혈당 기록을 glucose.db에서 가져오는 함수입니다.

    glucose_records 표에서 해당 사용자의 가장 최근 기록 5개를 가져와서,
    측정 당시 혈당의 평균과 최근 경향을 정리합니다.

    아직 기록이 하나도 없는 사용자라면 None을 반환합니다.
    """
    conn = sqlite3.connect(GLUCOSE_DB_PATH)
    cur = conn.cursor()
    cur.execute(
        """
        SELECT current_glucose, meal_status, measured_at
        FROM glucose_records
        WHERE user_id = ?
        ORDER BY measured_at DESC
        LIMIT 5
        """,
        (str(user_id),),
    )
    rows = cur.fetchall()
    conn.close()

    if not rows:
        return None

    glucose_values = [row[0] for row in rows if row[0] is not None]
    if not glucose_values:
        return None

    average_glucose = sum(glucose_values) / len(glucose_values)
    most_recent_glucose = glucose_values[0]

    # 정상 식후 혈당 기준(약 140)과 비교하여 간단한 경향을 만듭니다.
    if average_glucose >= 180:
        trend = "최근 혈당이 다소 높게 유지되고 있는 편"
    elif average_glucose >= 140:
        trend = "최근 혈당이 평균보다 약간 높은 편"
    elif average_glucose <= 70:
        trend = "최근 혈당이 다소 낮게 측정되는 편"
    else:
        trend = "최근 혈당이 안정적인 범위에 있는 편"

    return {
        "recent_average_glucose": round(average_glucose, 1),
        "most_recent_glucose": most_recent_glucose,
        "recent_trend": trend,
        "record_count": len(rows),
    }


def get_menu_info(menu_id: Optional[int]) -> Optional[dict]:
    """
    음료(메뉴)의 영양 정보를 menus 표에서 가져오는 함수입니다.

    menus 표의 모든 컬럼(당류, 칼로리, 브랜드 등)을 그대로 가져오고,
    menu_allergies 표에서 알레르기 정보를 함께 가져옵니다.
    """
    if menu_id is None:
        return None

    conn = pymysql.connect(**MENU_DB_CONFIG, cursorclass=pymysql.cursors.DictCursor)
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT * FROM menus WHERE id = %s AND is_active = 1",
                (menu_id,),
            )
            menu = cur.fetchone()
            if not menu:
                return None

            cur.execute(
                "SELECT allergy_name FROM menu_allergies WHERE menu_id = %s",
                (menu_id,),
            )
            menu["allergies"] = [row["allergy_name"] for row in cur.fetchall()]

        return menu
    finally:
        conn.close()


def find_menu_id_by_name_in_message(message: str) -> Optional[int]:
    """
    사용자가 채팅 메시지에 메뉴 이름을 언급한 경우, 그 메뉴의 id를 찾아주는 함수입니다.

    띄어쓰기를 무시했을 때, 메뉴 이름 전체가 메시지에 포함되어 있는지 확인합니다.
    예: 메뉴 이름이 "이디야커피 아메리카노"이고, 메시지가
    "이디야커피아메리카노 마셔도 될까요?"여도 찾을 수 있습니다.

    여러 메뉴가 후보가 될 경우, 더 긴 이름이 일치하는 메뉴를 우선합니다.
    일치하는 메뉴가 없으면 None을 반환합니다.
    """
    conn = pymysql.connect(**MENU_DB_CONFIG, cursorclass=pymysql.cursors.DictCursor)
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, menu_name FROM menus WHERE is_active = 1"
            )
            rows = cur.fetchall()
    finally:
        conn.close()

    normalized_message = message.replace(" ", "")

    best_id: Optional[int] = None
    best_length = 0

    for row in rows:
        menu_name = row["menu_name"]
        if not menu_name:
            continue

        normalized_name = menu_name.replace(" ", "")
        if normalized_name and normalized_name in normalized_message:
            if len(normalized_name) > best_length:
                best_id = row["id"]
                best_length = len(normalized_name)

    return best_id


def build_system_prompt(health_context: Optional[dict], menu_info: Optional[dict]) -> str:
    """
    사용자의 건강 정보와 음료 정보를 정리하여,
    인공지능에게 전달할 안내문을 만드는 함수입니다.
    """
    prompt = (
        "당신은 SlowPick 앱의 건강 상담 챗봇입니다. "
        "사용자가 카페 음료와 혈당 관리에 관해 질문하면, "
        "아래 제공되는 사용자 정보를 참고하여 "
        "친근하고 이해하기 쉬운 말투로 답변하세요. "
        "의학적 진단을 내리지 말고, 참고용 안내라는 점을 자연스럽게 전달하세요. "
        "답변에는 마크다운 문법(별표 **, 샵 #, 목록 기호 - 등)을 절대 사용하지 말고, "
        "일반적인 문장으로만 답변하세요.\n\n"
    )

    if health_context:
        prompt += f"[사용자의 최근 혈당 정보]\n"
        prompt += f"- 최근 평균 혈당: {health_context['recent_average_glucose']}\n"
        prompt += f"- 가장 최근 측정값: {health_context['most_recent_glucose']}\n"
        prompt += f"- 경향: {health_context['recent_trend']}\n\n"
    else:
        prompt += (
            "[사용자의 최근 혈당 정보]\n"
            "아직 기록된 혈당 데이터가 없습니다. "
            "이 경우에는 일반적인 건강 정보 위주로 답변하고, "
            "혈당 기록을 입력하면 더 정확한 안내를 받을 수 있다고 안내해주세요.\n\n"
        )

    if menu_info:
        prompt += "[현재 질문 대상 음료 정보]\n"
        prompt += f"- 이름: {menu_info.get('menu_name')}\n"
        prompt += f"- 브랜드: {menu_info.get('brand_name')}\n"

        # 위에서 다룬 항목 외에, menus 표에 들어있는 나머지 정보(당류, 칼로리, 카페인 등)를
        # 컬럼 이름과 값 그대로 안내문에 추가합니다.
        excluded_keys = {"id", "menu_name", "brand_name", "is_active", "allergies"}
        for key, value in menu_info.items():
            if key in excluded_keys or value is None:
                continue
            prompt += f"- {key}: {value}\n"

        if menu_info.get("allergies"):
            prompt += f"- 알레르기 유발 성분: {', '.join(menu_info['allergies'])}\n"

        prompt += "\n"

    return prompt


async def call_gemini(system_prompt: str, user_message: str) -> str:
    """
    Gemini API를 호출하여 답변을 받아오는 함수입니다.
    503 오류(일시적 서버 과부하)가 발생하면 3초 기다렸다가 최대 3번까지 재시도합니다.
    """
    import asyncio

    if not GEMINI_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="GEMINI_API_KEY 환경변수가 설정되어 있지 않습니다.",
        )

    headers = {
        "x-goog-api-key": GEMINI_API_KEY,
        "content-type": "application/json",
    }

    body = {
        "system_instruction": {
            "parts": [{"text": system_prompt}]
        },
        "contents": [
            {
                "parts": [{"text": user_message}]
            }
        ],
    }

    max_retries = 3
    retry_delay = 3  # 초

    for attempt in range(max_retries):
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(GEMINI_API_URL, headers=headers, json=body)

        if response.status_code == 200:
            break

        # 503(일시적 과부하)이면 잠깐 기다렸다가 재시도합니다.
        if response.status_code == 503 and attempt < max_retries - 1:
            await asyncio.sleep(retry_delay)
            continue

        # 그 외 오류거나 재시도를 다 소진하면 오류를 냅니다.
        raise HTTPException(
            status_code=502,
            detail=f"인공지능 API 호출에 실패했습니다: {response.text}",
        )

    data = response.json()
    parts = data["candidates"][0]["content"]["parts"]
    text_parts = [part["text"] for part in parts if "text" in part]
    reply_text = "".join(text_parts)

    reply_text = reply_text.replace("**", "")

    return reply_text


@chat_router.post("/", response_model=ChatResponse)
async def chat_with_bot(request: ChatRequest):
    """
    채팅 출입구입니다. Flutter 앱에서 이 주소로 요청을 보냅니다.
    """
    health_context = get_user_health_context(request.user_id)

    # menu_id가 함께 전달되지 않았다면, 채팅 메시지 안에 메뉴 이름이
    # 직접 언급되어 있는지 찾아봅니다.
    menu_id = request.menu_id
    if menu_id is None:
        menu_id = find_menu_id_by_name_in_message(request.message)

    menu_info = get_menu_info(menu_id)

    system_prompt = build_system_prompt(health_context, menu_info)
    reply = await call_gemini(system_prompt, request.message)

    return ChatResponse(reply=reply)