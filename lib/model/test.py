import urllib.request   # 서버에 요청을 보내는 기본 도구
import json             # 데이터를 JSON 형식으로 바꾸는 도구

BASE = "http://localhost:8000"   # 서버 주소 (포트 다르면 숫자 바꾸기)
USER = "my_stage_test"           # 테스트할 사용자 이름

def post(path, data):
    # 서버에 데이터를 보내는(POST) 함수
    body = json.dumps(data).encode("utf-8")
    req = urllib.request.Request(BASE + path, data=body,
            headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=60) as res:
        return json.loads(res.read())

def get(path):
    # 서버에서 데이터를 가져오는(GET) 함수
    with urllib.request.urlopen(BASE + path, timeout=60) as res:
        return json.loads(res.read())
    

def record():
    # 실측 혈당 기록을 하나 남기는 함수 (기록 수를 늘리는 용도)
    return post("/record", {
        "user_id": USER,
        "predict_request": {
            "user_id": USER,
            "drink": {"name": "콜라", "sugar_g": 39, "carbs_g": 39, "fat_g": 0},
            "current_glucose": 105, "meal_status": 1, "exercise_level": 0,
            "insulin_taken": False, "medication_taken": False
        },
        "actual_glucose_30m": 130,   # TODO: 실제 잰 값처럼 아무 숫자
        "actual_glucose_60m": 145,   # TODO
        "actual_glucose_120m": 130   # TODO
    })

def predict():
    # 예측을 한 번 받아오는 함수
    return post("/predict", {
        "user_id": USER,
        "drink": {"name": "콜라", "sugar_g": 39, "carbs_g": 39, "fat_g": 0},
        "current_glucose": 105, "meal_status": 1, "exercise_level": 0,
        "insulin_taken": False, "medication_taken": False
    })


def show(count):
    # 지금 단계와 예측을 한 줄로 출력하는 함수
    p = predict()
    print(count, "건 →", p["model_stage"], p["model_stage_label"],
          "| 60분 예측", p["predicted_glucose_60m"])

# 기록 0건일 때 (1단계 예상)
show(0)

count = 0
for target in [3, 30, 100]:        # 이 세 문턱에서 단계를 확인할 거예요
    while count < target:          # target 건이 될 때까지
        record()                   # 기록을 하나 남기고
        count = count + 1          # 센 값을 1 늘린다
    show(count)                    # 그 시점의 단계를 출력