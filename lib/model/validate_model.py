"""
모델 밸리데이션(검증) 스크립트

교수님이 요청하신 "밸리데이션 값"을 뽑는 코드입니다.
현재 모델(RandomForest)이 얼마나 정확한지를 숫자로 측정합니다.

[실행 방법]
  1) model 폴더(또는 glucose_server 폴더)에 이 파일을 넣습니다
     - features.py 가 같은 폴더에 있어야 합니다
  2) 필요한 라이브러리:  pip install scikit-learn numpy
  3) python validate_model.py

[윈도우에서 그래도 한글이 깨지면]
  터미널에서 아래를 먼저 한 번 실행하세요.
      chcp 65001

[이 코드가 하는 일]
  1. 합성 데이터 2000건을 만든다
  2. 학습용 80% / 시험용 20% 로 나눈다  <- 핵심!
  3. 학습용으로만 모델을 학습시킨다
  4. 모델이 한 번도 못 본 시험용으로 점수를 매긴다
  5. 기준선(baseline)과 비교한다
"""

import sys

# --- 윈도우 터미널에서 한글이 깨지는 것을 막습니다 ----------
# 맥/리눅스 터미널은 기본이 UTF-8이라 문제가 없지만,
# 윈도우 콘솔은 cp949 같은 옛 코드페이지를 쓰는 경우가 많아 깨질 수 있습니다.
# 아래 두 줄이 출력 인코딩을 UTF-8로 맞춰줍니다.
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass   # 아주 오래된 파이썬에서는 그냥 넘어갑니다

import numpy as np
from sklearn.model_selection import train_test_split, KFold, cross_val_score
from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.dummy import DummyRegressor
from sklearn.multioutput import MultiOutputRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

from features import generate_synthetic_data, FEATURE_NAMES

np.random.seed(42)   # 매번 같은 결과가 나오도록 고정

# --- 1) 데이터 준비 -----------------------------------------
X, y30, y60, y120 = generate_synthetic_data(n_samples=2000)
Y = np.column_stack([y30, y60, y120])   # 30분/60분/120분 정답을 한 묶음으로
print(f"데이터: 입력 {X.shape}, 정답 {Y.shape}")

# --- 2) 학습용 / 시험용 나누기 (가장 중요!) -----------------
# 왜 나누나: 배운 문제로 시험 보면 당연히 잘 맞습니다.
#           처음 보는 문제로 시험을 봐야 진짜 실력을 알 수 있습니다.
X_tr, X_te, Y_tr, Y_te = train_test_split(X, Y, test_size=0.2, random_state=42)
print(f"학습 {X_tr.shape[0]}건 / 시험 {X_te.shape[0]}건\n")


def make_rf():
    """지금 서버가 쓰는 것과 똑같은 설정의 RandomForest"""
    return Pipeline([
        ("scaler", StandardScaler()),
        ("rf", MultiOutputRegressor(RandomForestRegressor(
            n_estimators=200, max_depth=10, min_samples_leaf=5,
            random_state=42, n_jobs=-1)))
    ])


def evaluate(name, model):
    """모델을 학습시키고 세 가지 지표로 점수를 매긴다"""
    model.fit(X_tr, Y_tr)                 # 학습용으로만 배운다
    P_tr = model.predict(X_tr)            # 배운 문제 (참고용)
    P_te = model.predict(X_te)            # 처음 보는 문제 (진짜 점수)

    print(f"[{name}]")
    maes = []
    for i, h in enumerate(["30분", "60분", "120분"]):
        mae  = mean_absolute_error(Y_te[:, i], P_te[:, i])        # 평균 몇 mg/dL 틀리나
        rmse = np.sqrt(mean_squared_error(Y_te[:, i], P_te[:, i]))# 큰 실수에 민감한 오차
        r2   = r2_score(Y_te[:, i], P_te[:, i])                   # 1에 가까울수록 좋음
        mae_tr = mean_absolute_error(Y_tr[:, i], P_tr[:, i])      # 배운 문제 점수
        print(f"  {h:>5} | MAE {mae:6.2f} | RMSE {rmse:6.2f} | R2 {r2:6.3f} "
              f"| (학습 MAE {mae_tr:5.2f})")
        maes.append(mae)
    avg = float(np.mean(maes))
    print(f"  평균 MAE: {avg:.2f}\n")
    return avg


# --- 3) 세 모델 비교 ----------------------------------------
print("=" * 62)
mae_rf   = evaluate("RandomForest (현재 우리 모델)", make_rf())
mae_lin  = evaluate("선형회귀 (기준선 1)", MultiOutputRegressor(LinearRegression()))
mae_mean = evaluate("무조건 평균 (기준선 2 = 최저선)",
                    MultiOutputRegressor(DummyRegressor(strategy="mean")))

print("=" * 62)
print(f"평균 예측 대비 개선율 : RF {(1-mae_rf/mae_mean)*100:.1f}%  "
      f"/ 선형회귀 {(1-mae_lin/mae_mean)*100:.1f}%")
print(f"RF가 선형회귀보다 나은 정도 : {(1-mae_rf/mae_lin)*100:.1f}%\n")

# --- 4) 교차검증 (한 번 나눈 게 운이 좋았나 확인) -----------
print("[5-Fold 교차검증 - 60분 예측]")
rf1 = Pipeline([("s", StandardScaler()),
                ("rf", RandomForestRegressor(n_estimators=200, max_depth=10,
                                             min_samples_leaf=5, random_state=42, n_jobs=-1))])
scores = -cross_val_score(rf1, X, y60, cv=KFold(5, shuffle=True, random_state=42),
                          scoring="neg_mean_absolute_error")
print(f"  각 폴드 MAE: {np.round(scores, 2)}")
print(f"  평균 {scores.mean():.2f} (표준편차 {scores.std():.2f})\n")

# --- 5) 어떤 입력이 예측에 중요했나 -------------------------
rf1.fit(X, y60)
imp = rf1.named_steps["rf"].feature_importances_
print("[특성 중요도 상위 6개 - 60분 예측]")
for i in np.argsort(imp)[::-1][:6]:
    print(f"  {FEATURE_NAMES[i]:<18} {imp[i]*100:5.1f}%")
