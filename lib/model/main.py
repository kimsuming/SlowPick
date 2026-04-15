import pandas as pd
import numpy as np
from fastapi import FastAPI
from pydantic import BaseModel
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor

app = FastAPI()

# -----------------------------
# 1. 데이터 생성 + 모델 학습
# -----------------------------
def generate_dummy_data(samples=1000):
    np.random.seed(42)

    sugar_g = np.random.uniform(0, 50, samples)
    is_exercise = np.random.randint(0, 2, samples)
    current_glucose = np.random.uniform(70, 150, samples)
    is_insulin = np.random.randint(0, 2, samples)
    is_medication = np.random.randint(0, 2, samples)

    target_glucose = (
        current_glucose
        + (sugar_g * 2.5)
        - (is_exercise * 25)
        - (is_insulin * 45)
        - (is_medication * 15)
        + np.random.normal(0, 10, samples)
    )

    df = pd.DataFrame({
        'sugar_g': sugar_g,
        'is_exercise': is_exercise,
        'current_glucose': current_glucose,
        'is_insulin': is_insulin,
        'is_medication': is_medication,
        'target_glucose': target_glucose
    })

    return df


data = generate_dummy_data()

X = data[['sugar_g', 'is_exercise', 'current_glucose', 'is_insulin', 'is_medication']]
y = data['target_glucose']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model = RandomForestRegressor(n_estimators=100, random_state=42)
model.fit(X_train, y_train)


# -----------------------------
# 2. 요청 데이터 구조 정의
# -----------------------------
class GlucoseRequest(BaseModel):
    sugar_g: float
    is_exercise: bool
    current_glucose: float
    is_insulin: bool
    is_medication: bool


# -----------------------------
# 3. API 엔드포인트
# -----------------------------
@app.get("/")
def root():
    return {"message": "Glucose Prediction API is running"}


@app.post("/predict")
def predict_glucose(data: GlucoseRequest):
    input_df = pd.DataFrame([[
        data.sugar_g,
        int(data.is_exercise),
        data.current_glucose,
        int(data.is_insulin),
        int(data.is_medication)
    ]], columns=[
        'sugar_g',
        'is_exercise',
        'current_glucose',
        'is_insulin',
        'is_medication'
    ])

    prediction = model.predict(input_df)[0]

    return {
        "prediction": round(prediction, 2)
    }