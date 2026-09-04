"""
가상(합성) CGM 혈당 데이터 생성기

[왜 필요한가]
  캐글에서 받은 "GlucoBench_benchmark_dataset.csv"는 식사를 해도 혈당이
  평균 1.7밖에 안 오르는 등 비현실적으로 밋밋했습니다 (persistence baseline이
  압도적으로 유리한 구조). 이 스크립트는 실제 생리학적 원리를 반영해서
  "식사 후 진짜로 오르고, 인슐린을 맞으면 내려가는" 혈당 곡선을 만듭니다.

[반영한 생리학 원리]
  1) 하루주기 리듬(circadian) - 새벽에 코르티솔 때문에 혈당이 오르는
     "새벽 현상(dawn phenomenon)"을 반영
  2) 식사 반응 - 탄수화물 섭취 후 45~75분 뒤 피크, 이후 서서히 감소
     (감마 분포 형태의 흡수 곡선)
  3) 인슐린 효과 - 볼러스 인슐린은 15분 지연 후 3~4시간에 걸쳐 혈당을 낮춤
  4) 운동 효과 - 운동은 혈당을 일시적으로 떨어뜨림
  5) 개인차 - 당뇨 유형(정상/전당뇨/2형/1형)에 따라 기준 혈당, 변동성,
     인슐린 민감도가 다름
  6) 센서 노이즈 - CGM 센서 특유의 미세한 잡음 + 가끔 결측치

[출력]
  기존 GlucoBench_benchmark_dataset.csv와 같은 컬럼 구조로
  synthetic_glucose_dataset.csv 를 생성합니다.
"""

import numpy as np
import pandas as pd

RNG = np.random.default_rng(42)

N_USERS = 10
N_DAYS = 14
INTERVAL_MIN = 5
STEPS_PER_DAY = 24 * 60 // INTERVAL_MIN

DIABETES_PROFILES = {
    # type: (기준 혈당 평균, 기준 변동폭, 인슐린 민감도, carb_ratio, hbA1c 범위)
    "normal":       dict(base=95,  base_sd=8,  ins_sens=55, carb_ratio=12, hba1c=(4.8, 5.6), weight=0.35),
    "prediabetic":  dict(base=108, base_sd=10, ins_sens=45, carb_ratio=11, hba1c=(5.7, 6.4), weight=0.25),
    "type2":        dict(base=135, base_sd=18, ins_sens=35, carb_ratio=9,  hba1c=(6.5, 8.5), weight=0.25),
    "type1":        dict(base=140, base_sd=28, ins_sens=42, carb_ratio=10, hba1c=(6.5, 9.0), weight=0.15),
}

MEAL_TIMES = {"breakfast": 7.5, "lunch": 12.5, "dinner": 18.5}
DEVICES = ["Dexcom_G6", "Libre_2", "Medtronic_670G"]
REGIONS = [("USA", "America/New_York"), ("USA", "America/Los_Angeles"), ("UK", "Europe/London")]


def meal_response_kernel(length_steps, peak_step, magnitude):
    """감마 분포 형태의 식후 혈당 반응 곡선 (빠르게 올랐다가 서서히 내려옴)."""
    t = np.arange(length_steps)
    shape, scale = 3.0, peak_step / 3.0
    kernel = (t ** (shape - 1)) * np.exp(-t / scale)
    kernel = kernel / kernel.max() * magnitude
    return kernel


def insulin_response_kernel(length_steps, magnitude):
    """15분 지연 후 서서히 혈당을 낮추는 인슐린 효과 곡선."""
    t = np.arange(length_steps)
    delay = 3  # 15분 = 3 스텝
    shifted = np.clip(t - delay, 0, None)
    shape, scale = 2.2, 12.0
    kernel = (shifted ** (shape - 1)) * np.exp(-shifted / scale)
    kernel = kernel / kernel.max() * magnitude
    return -kernel


def build_user(uid, day0):
    profile_type = RNG.choice(list(DIABETES_PROFILES), p=[v["weight"] for v in DIABETES_PROFILES.values()])
    prof = DIABETES_PROFILES[profile_type]
    device = RNG.choice(DEVICES)
    region, tz = REGIONS[RNG.integers(len(REGIONS))]
    sex = RNG.choice(["M", "F"])
    age = int(RNG.integers(19, 71))
    weight = round(float(RNG.normal(75, 15)), 1)
    hba1c = round(float(RNG.uniform(*prof["hba1c"])), 1)
    ins_sens = round(float(RNG.normal(prof["ins_sens"], 4)), 1)
    carb_ratio = round(float(RNG.normal(prof["carb_ratio"], 1)), 1)

    n_steps = N_DAYS * STEPS_PER_DAY
    timestamps = pd.date_range(day0, periods=n_steps, freq=f"{INTERVAL_MIN}min")

    # 1) 하루주기 리듬 + 새벽 현상 베이스라인
    hours = np.asarray(timestamps.hour + timestamps.minute / 60, dtype=float)
    circadian = 6 * np.sin((hours - 5) / 24 * 2 * np.pi)          # 완만한 일중 변동
    dawn = 10 * np.exp(-((hours - 6) ** 2) / (2 * 1.5 ** 2))       # 새벽 5~7시경 상승
    base_drift = np.cumsum(RNG.normal(0, 0.3, n_steps))            # 느린 랜덤워크(개인 컨디션 변화)
    base_drift -= base_drift.mean()
    baseline = prof["base"] + circadian + dawn + base_drift

    glucose = np.asarray(baseline, dtype=float).copy()

    carbs = np.zeros(n_steps)
    insulin_bolus = np.zeros(n_steps)
    insulin_basal = np.full(n_steps, round(float(RNG.uniform(0.5, 1.5)), 2)) if profile_type in ("type1", "type2") else np.zeros(n_steps)
    meal_type = np.array(["none"] * n_steps, dtype=object)
    exercise_steps = np.zeros(n_steps)
    exercise_intensity = np.zeros(n_steps)
    heart_rate = RNG.normal(70, 6, n_steps)
    stress_level = np.clip(RNG.normal(3, 1.5, n_steps), 0, 10)

    RESP_LEN = 36   # 3시간치 반응 곡선

    for day in range(N_DAYS):
        day_start = day * STEPS_PER_DAY
        for meal, hour in MEAL_TIMES.items():
            if RNG.random() < 0.95:  # 가끔 끼니를 거름
                jitter = RNG.normal(0, 20)  # 분 단위 지터
                step = day_start + int((hour * 60 + jitter) / INTERVAL_MIN)
                if step < 0 or step >= n_steps:
                    continue
                carb_amt = max(5, RNG.normal(55 if meal != "breakfast" else 45, 18))
                carbs[step] = round(carb_amt, 1)
                meal_type[step] = meal

                # 식후 혈당 상승 (탄수화물량 / 인슐린저항 반영)
                rise_magnitude = carb_amt * (55 / ins_sens) * 0.9
                peak_step = int(RNG.uniform(9, 15))  # 45~75분
                kernel = meal_response_kernel(RESP_LEN, peak_step, rise_magnitude)
                end = min(n_steps, step + RESP_LEN)
                glucose[step:end] += kernel[: end - step]

                # 볼러스 인슐린 (당뇨인 경우 식사에 맞춰 투여)
                if profile_type in ("type1", "type2") or RNG.random() < 0.3:
                    bolus = round(carb_amt / carb_ratio, 1)
                    insulin_bolus[step] = bolus
                    ins_kernel = insulin_response_kernel(RESP_LEN, bolus * (55 / ins_sens) * 3.2)
                    glucose[step:end] += ins_kernel[: end - step]

        # 하루 1~2회 랜덤 운동
        for _ in range(RNG.integers(0, 3)):
            hour = RNG.uniform(6, 21)
            step = day_start + int(hour * 60 / INTERVAL_MIN)
            if step < 0 or step >= n_steps:
                continue
            dur = int(RNG.integers(4, 9))  # 20~45분
            intensity = RNG.uniform(0.3, 1.0)
            end = min(n_steps, step + dur)
            exercise_steps[step:end] += RNG.integers(80, 220, end - step) * intensity
            exercise_intensity[step:end] = round(float(intensity), 2)
            heart_rate[step:end] += intensity * RNG.uniform(20, 45)
            # 운동은 혈당을 서서히 낮춤 (운동 후 지속)
            ex_kernel = -intensity * 8 * np.exp(-np.arange(RESP_LEN) / 15.0)
            e2 = min(n_steps, step + RESP_LEN)
            glucose[step:e2] += ex_kernel[: e2 - step]

    # 기초 인슐린의 완만한 억제 효과 (2형/1형만)
    if profile_type in ("type1", "type2"):
        glucose -= insulin_basal[0] * 6

    # 센서 노이즈
    glucose += RNG.normal(0, 2.5, n_steps)
    glucose = np.clip(glucose, 55, 380)

    # 결측치 (센서 신호 끊김) - 실제 CGM처럼 짧은 구간이 통째로 빠짐
    quality_flag = np.ones(n_steps, dtype=int)
    n_dropouts = RNG.integers(2, 6)
    for _ in range(n_dropouts):
        start = RNG.integers(0, n_steps - 10)
        length = RNG.integers(2, 8)
        quality_flag[start:start + length] = 0

    sleep_hours = (hours >= 23) | (hours < 7)
    sleep_stage = np.where(sleep_hours,
                            RNG.choice(["light", "deep", "REM"], n_steps),
                            "awake")

    df = pd.DataFrame({
        "user_id": f"U{uid:03d}",
        "timestamp": timestamps,
        "glucose": np.round(glucose, 1),
        "cgm_quality_flag": quality_flag,
        "insulin_bolus": insulin_bolus,
        "insulin_basal": insulin_basal,
        "carbs": carbs,
        "meal_type": meal_type,
        "exercise_steps": np.round(exercise_steps).astype(int),
        "exercise_intensity": np.round(exercise_intensity, 2),
        "heart_rate": np.round(np.clip(heart_rate, 45, 190), 1),
        "skin_temp": np.round(RNG.normal(33.5, 0.6, n_steps), 1),
        "gsr": np.round(np.clip(RNG.normal(4, 1.5, n_steps) + stress_level * 0.3, 0.5, None), 2),
        "sleep_stage": sleep_stage,
        "medication_other": "",
        "stress_level": np.round(stress_level, 1),
        "alcohol": 0,
        "notes": "",
        "device_id": device,
        "hbA1c": hba1c,
        "age": age,
        "sex": sex,
        "weight": weight,
        "carb_ratio": carb_ratio,
        "insulin_sensitivity": ins_sens,
        "timezone": tz,
        "region": region,
        "diabetes_type": profile_type,  # 원본엔 없던 참고용 컬럼(검증에 유용)
    })

    # 결측 구간은 glucose 등을 NaN 처리 (실제 센서 끊김처럼)
    mask = df["cgm_quality_flag"] == 0
    df.loc[mask, ["glucose"]] = np.nan

    return df


def add_lag_features(df):
    df = df.sort_values(["user_id", "timestamp"]).reset_index(drop=True)
    g = df.groupby("user_id")["glucose"]
    df["glucose_lag_1"] = g.shift(1)
    df["glucose_lag_3"] = g.shift(3)
    df["glucose_lag_6"] = g.shift(6)
    df["glucose_roll_mean_1h"] = (
        df.groupby("user_id")["glucose"]
        .transform(lambda s: s.rolling(12, min_periods=1).mean())
    )
    return df


def main():
    day0 = pd.Timestamp("2024-09-01")
    frames = [build_user(uid, day0) for uid in range(1, N_USERS + 1)]
    df = pd.concat(frames, ignore_index=True)
    df = add_lag_features(df)

    out_path = "/mnt/user-data/outputs/synthetic_glucose_dataset.csv"
    df.to_csv(out_path, index=False)

    print(f"생성 완료: {df.shape}")
    print(df.groupby("user_id")["diabetes_type"].first())
    print()
    print("=== 사용자별 glucose 통계 ===")
    print(df.groupby("user_id")["glucose"].agg(["mean", "std", "min", "max"]).round(1))
    print()

    # 식사 후 상승폭 검증
    rises = []
    for uid, g in df.groupby("user_id"):
        g = g.reset_index(drop=True)
        meal_idx = g.index[g["carbs"] > 0].tolist()
        for i in meal_idx:
            base = g.loc[i, "glucose"]
            future = g.loc[i:i + 12, "glucose"]
            if len(future) > 1 and not pd.isna(base):
                valid = future.dropna()
                if len(valid) > 1:
                    rises.append(valid.max() - base)
    rises = np.array(rises)
    print(f"식사 이벤트 {len(rises)}건 / 식후 1시간 내 최대 상승폭 평균: {np.nanmean(rises):.1f}, 중앙값: {np.nanmedian(rises):.1f}")
    print(f"10 이상 상승 비율: {(rises >= 10).mean() * 100:.1f}% | 30 이상 상승 비율: {(rises >= 30).mean() * 100:.1f}%")

    return out_path


if __name__ == "__main__":
    main()
