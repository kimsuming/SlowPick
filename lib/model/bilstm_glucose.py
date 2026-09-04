"""
Bi-LSTM 혈당 시계열 예측 - 교수님 요청 과제

[이 코드가 하는 일]
  캐글 CGM(연속혈당측정) 데이터로 시계열 예측 모델을 만들고,
  Bi-LSTM / 단방향 LSTM / 학습 없는 기준선을 공정하게 비교합니다.

[준비물]
  pip install tensorflow scikit-learn pandas numpy

  주의: TensorFlow는 파이썬 3.14를 아직 지원하지 않습니다.
        파이썬 3.12 또는 3.11 환경에서 실행하세요. (확인: python --version)

[실행]
  python bilstm_glucose.py

[윈도우에서 한글이 깨지면]
  터미널에서 아래를 먼저 실행하세요.
      chcp 65001
  * 모델을 여러 번 학습하므로 5~15분 걸립니다.

[반드시 이해하고 넘어갈 것]
  1) 시간 기반 분할  - 시계열은 무작위로 섞어 나누면 안 됩니다.
                      미래로 과거를 맞히는 반칙(데이터 누수)이 됩니다.
  2) 정규화 기준     - 평균/표준편차는 "학습 데이터만" 보고 계산합니다.
  3) persistence     - "직전 값을 그대로 답한다"는 기준선.
                      시계열에서 이걸 못 이기면 모델은 의미가 없습니다.
  4) 여러 번 반복    - 신경망은 시작값이 랜덤이라 실행마다 결과가 달라집니다.
                      한 번 돌린 결과로 우열을 단정하면 안 됩니다.
                      그래서 시드를 바꿔가며 3번 학습하고 평균을 봅니다.
"""

import sys
# -- 윈도우 터미널에서 한글이 깨지는 것을 막습니다 --
# 콘솔 코드페이지가 UTF-8이 아니어도 출력이 깨지지 않게 강제로 맞춥니다.
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass   # 파이썬 3.6 이하 등에서는 그냥 넘어갑니다

import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"   # TF 경고 메시지 숨기기

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

# -- 설정 ------------------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV = os.path.join(BASE_DIR, "data", "synthetic_glucose_dataset.csv")  

SEQ   = 24         # 과거 몇 개의 관측을 보고 예측할 것인가
HZ    = 12         # 몇 스텝 뒤를 예측할 것인가
SEEDS = [0, 42, 777]   # 반복 실행에 쓸 랜덤 시드
FEATS = ["glucose", "carbs", "insulin_bolus",
         "insulin_basal", "exercise_steps", "heart_rate"]

# -- 1) 데이터 읽고 시계열 순서로 정렬 ---------------
df = pd.read_csv(CSV, parse_dates=["timestamp"]).sort_values(["user_id", "timestamp"])
print(f"전체 데이터: {df.shape}, 사용자 {df.user_id.nunique()}명")

gap = df.groupby("user_id")["timestamp"].diff().dt.total_seconds() / 60
print(f"관측 간격(분) 최빈값: {gap.mode().values[:3]}")

# -- 2) 시퀀스 만들기 (슬라이딩 윈도우) --------------
Xs, ys, us = [], [], []
for uid, g in df.groupby("user_id"):
    g = g.reset_index(drop=True)
    g["glucose"] = g["glucose"].interpolate(limit_direction="both")   # <- 이 줄 추가
    arr = g[FEATS].fillna(0).values.astype("float32")
    gl  = g["glucose"].values.astype("float32")
    for i in range(len(g) - SEQ - HZ):
        Xs.append(arr[i:i + SEQ])
        ys.append(gl[i + SEQ + HZ - 1])
        us.append(uid)

X, y, us = np.array(Xs), np.array(ys), np.array(us)
print(f"시퀀스: X={X.shape} (샘플수, 타임스텝, 특성수), y={y.shape}")

# -- 3) 시간 기반 분할 (누수 방지의 핵심) ------------
tr_idx, te_idx = [], []
for uid in np.unique(us):
    idx = np.where(us == uid)[0]
    cut = int(len(idx) * 0.8)
    tr_idx += list(idx[:cut])   # 앞 80% = 과거
    te_idx += list(idx[cut:])   # 뒤 20% = 미래
tr_idx, te_idx = np.array(tr_idx), np.array(te_idx)
Xtr, ytr, Xte, yte = X[tr_idx], y[tr_idx], X[te_idx], y[te_idx]
print(f"학습 {len(tr_idx)}건 / 테스트 {len(te_idx)}건 (시간 기반 분할)\n")

# -- 4) 정규화 (학습 데이터 기준으로만!) --------------
mu = Xtr.reshape(-1, X.shape[2]).mean(0)
sd = Xtr.reshape(-1, X.shape[2]).std(0) + 1e-6
Xtr_n, Xte_n = (Xtr - mu) / sd, (Xte - mu) / sd


def metrics(pred):
    return (mean_absolute_error(yte, pred),
            np.sqrt(mean_squared_error(yte, pred)),
            r2_score(yte, pred))


# -- 5) 기준선 먼저 (이게 없으면 점수를 해석할 수 없다) --
print("=" * 70)
print("[기준선] 학습을 전혀 하지 않은 방법들")
mae_pers, rmse_pers, r2_pers = metrics(Xte[:, -1, 0])   # 직전 값 그대로
mae_mean, rmse_mean, r2_mean = metrics(np.full(len(yte), ytr.mean()))
print(f"  직전 값 그대로 (persistence)     MAE {mae_pers:6.2f} | "
      f"RMSE {rmse_pers:6.2f} | R2 {r2_pers:6.3f}")
print(f"  무조건 전체 평균                 MAE {mae_mean:6.2f} | "
      f"RMSE {rmse_mean:6.2f} | R2 {r2_mean:6.3f}")


# -- 6) 딥러닝 모델 (시드를 바꿔가며 여러 번) ----------
def build(bidirectional: bool):
    L = tf.keras.layers
    # Bidirectional로 감싸면 양방향, 안 감싸면 단방향
    core = L.Bidirectional(L.LSTM(64)) if bidirectional else L.LSTM(64)
    return tf.keras.Sequential([
        L.Input(shape=X.shape[1:]),
        core,
        L.Dropout(0.2),                     # 과적합 방지
        L.Dense(32, activation="relu"),
        L.Dense(1),                         # 최종 예측값 1개
    ])


def train_once(bidirectional: bool, seed: int):
    """시드를 고정해서 한 번 학습하고 MAE를 반환"""
    tf.keras.backend.clear_session()        # 이전 모델 흔적 지우기
    tf.random.set_seed(seed)
    np.random.seed(seed)
    model = build(bidirectional)
    model.compile(optimizer="adam", loss="mse")
    model.fit(Xtr_n, ytr, epochs=12, batch_size=64, verbose=0, validation_split=0.1)
    return mean_absolute_error(yte, model.predict(Xte_n, verbose=0).ravel()), model


print(f"\n[딥러닝 모델] 시드 {SEEDS} 로 각각 학습 (시간이 걸립니다)")
print(f"  {'시드':<8}{'LSTM':>10}{'Bi-LSTM':>12}")
print("  " + "-" * 30)

lstm_scores, bilstm_scores, n_params = [], [], {}
for s in SEEDS:
    m1, mdl1 = train_once(False, s)
    m2, mdl2 = train_once(True, s)
    lstm_scores.append(m1)
    bilstm_scores.append(m2)
    n_params = {"LSTM": mdl1.count_params(), "Bi-LSTM": mdl2.count_params()}
    print(f"  {s:<8}{m1:>10.2f}{m2:>12.2f}")

l_mean, l_std = np.mean(lstm_scores), np.std(lstm_scores)
b_mean, b_std = np.mean(bilstm_scores), np.std(bilstm_scores)
print("  " + "-" * 30)
print(f"  {'평균':<8}{l_mean:>10.2f}{b_mean:>12.2f}")
print(f"  {'편차':<8}{l_std:>10.2f}{b_std:>12.2f}")
print(f"\n  파라미터 수: LSTM {n_params['LSTM']:,} / Bi-LSTM {n_params['Bi-LSTM']:,}")


# -- 7) 결론 --------------------------------------
print("\n" + "=" * 70)
print("[결론]")
print(f"  persistence(기준선)  MAE {mae_pers:.2f}")
print(f"  LSTM    평균         MAE {l_mean:.2f}  (실행마다 {min(lstm_scores):.2f}~{max(lstm_scores):.2f})")
print(f"  Bi-LSTM 평균         MAE {b_mean:.2f}  (실행마다 {min(bilstm_scores):.2f}~{max(bilstm_scores):.2f})")
print()
if min(l_mean, b_mean) > mae_pers:
    print(f"  -> 딥러닝 두 모델 모두 기준선(persistence)을 넘지 못했습니다.")
    print(f"     혈당이 천천히 변해서 '직전 값 그대로'가 이미 강력하기 때문입니다.")
else:
    print(f"  -> 딥러닝이 기준선을 넘었습니다.")
print()
print(f"  주의: LSTM은 실행마다 편차가 {l_std:.2f}로 큽니다.")
print(f"        한 번 돌린 결과로 'A가 B보다 낫다'고 단정하면 안 되는 이유입니다.")
