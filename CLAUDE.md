# SlowPick

당뇨·건강 관리 사용자를 위한 카페 음료 추천·검색 + 커뮤니티 앱.

---

## 기술 스택

| 영역 | 기술 |
|---|---|
| Frontend | Flutter (Dart), Amplify Flutter v2 |
| Auth | AWS Cognito (ID Token 방식) |
| Backend | Node.js + Express, EC2 (ap-northeast-2) |
| DB | MySQL 8, RDS |
| Storage | AWS S3 |
| 기타 | Firebase Core (초기화만, 인증 미사용) |

---

## AWS Cognito

```
User Pool ID     : us-east-1_C7QkE8emM
Client ID        : 4ren759pejiq73dufqp5vnbjfb
Identity Pool ID : us-east-1:0b6cfc46-0631-4820-a2c0-568c1fccc0f9
Region           : us-east-1
JWKS URL         : https://cognito-idp.us-east-1.amazonaws.com/us-east-1_C7QkE8emM/.well-known/jwks.json
```

- 로그인 식별자: **이메일** (username = email)
- 이메일 인증 필수 (가입 후 코드 확인)
- 닉네임: Cognito attribute `CognitoUserAttributeKey.nickname`
- 앱은 **ID Token** 을 Authorization 헤더로 전송, EC2가 JWKS로 검증
- `sub` (UUID) 가 RDS의 유저 식별 키 (`cognito_sub`)

---

## EC2 백엔드

```
Base URL  : http://3.34.7.133:3000
런타임    : Node.js (PM2 관리)
프레임워크: Express
```

### 파일 구조

```
src/
├── server.js            # 진입점, DB 연결 확인 후 listen
├── app.js               # Express 설정, 전역 에러 핸들러
├── config/
│   ├── db.js            # mysql2 connection pool (connectionLimit: 10)
│   └── cognito.js       # aws-jwt-verify, tokenUse: 'id'
├── middleware/
│   └── auth.js          # JWT 검증 → req.user = { sub, email, nickname }
└── routes/
    ├── index.js         # 라우터 통합
    ├── menus.js         # /api/menus
    ├── users.js         # /api/user/profile
    ├── allergens.js     # /api/allergens
    ├── posts.js         # /api/posts  (소통 게시판)
    ├── recipes.js       # /api/recipes (레시피 게시판)
    └── upload.js        # /api/upload/presign (S3 presigned URL)
```

### 핵심 규칙

- **모든 라우터에 `auth` 미들웨어 필수** — 없으면 인증 없이 접근 가능
- `req.user.sub` = Cognito sub → RDS `cognito_sub` FK 로 사용
- 에러는 `next(err)` → `app.js` 전역 핸들러가 500 반환
- 소프트 삭제 없음 — `posts`, `recipes`, `comments` 모두 `is_deleted` 컬럼 없음, 실제 DELETE 사용
- `posts`, `recipes`에 denormalized 카운터 컬럼 존재 (`like_count`, `dislike_count`, `comment_count` 등) — 투표/댓글 변경 시 반드시 UPDATE로 동기화
- `posts.js` 에서 `/comments/:id/like` 경로를 `/:id` 경로보다 **반드시 먼저** 등록

### .env 항목

```
PORT=3000
DB_HOST=<RDS 엔드포인트>
DB_PORT=3306
DB_USER=<유저명>
DB_PASSWORD=<패스워드>
DB_NAME=slowpick
COGNITO_USER_POOL_ID=us-east-1_C7QkE8emM
COGNITO_CLIENT_ID=4ren759pejiq73dufqp5vnbjfb
AWS_REGION=us-east-1
S3_BUCKET=<버킷 이름>
```

---

## API 엔드포인트

모든 엔드포인트는 `Authorization: Bearer <ID Token>` 필수.

### 메뉴 `/api/menus`

| 메서드 | 경로 | 설명 |
|---|---|---|
| GET | `/api/menus` | 목록 (`?search=&brands=&sort=`) — 응답에 `is_liked: bool` 포함 |
| GET | `/api/menus/recommended` | 추천 메뉴 10개 (RAND) — `is_liked` 포함 |
| GET | `/api/menus/names` | 메뉴명 목록 (자동완성용) |
| GET | `/api/menus/liked` | 내가 찜한 메뉴 목록 (`is_liked: true` 항상) |
| POST | `/api/menus/:id/like` | 찜 토글 → `{ liked: bool }` |

- 실제 컬럼명: `menu_name`, `brand_name` (`name`, `brand` 아님)
- `is_liked`: 로그인 유저 기준 찜 여부, MySQL EXISTS 서브쿼리로 실시간 계산
- **핫/아이스·사이즈 변형**: 같은 `(brand_name, menu_name)`을 가진 여러 행이 온도/사이즈만 다른
  같은 메뉴일 수 있다 (`menus.temperature`/`size_label`/`size_rank` 참고). 크롤러가 각 변형을
  독립된 행(별도 `doc_id`, 이미지, 영양정보)으로 저장하므로 **DB 레벨에서 부모-자식 FK는 없음** —
  프론트(`MenuService.groupVariants`)와 `menu_detail_screen.dart`가 `(brand_name, menu_name)`
  완전일치로 그룹핑해서 하나의 메뉴처럼 보여주고, 상세 화면에서 핫/아이스 토글 + 사이즈 선택(최대 3개)
  으로 전환한다. 디폴트는 [핫] + 가장 작은 `size_rank`. `/api/menus` 응답에 이 세 필드를 반드시
  포함시켜야 그룹핑이 동작한다.

### 유저 `/api/user`

| 메서드 | 경로 | 설명 |
|---|---|---|
| GET | `/api/user/profile` | 프로필 + 건강정보 + 알러지 조회 |
| PUT | `/api/user/profile` | 프로필 전체 저장 |

요청/응답 body:
```json
{
  "nickname": "string",
  "health": {
    "diabetes_type1": false, "diabetes_type2": false, "diabetes_pre": false,
    "dairy_edible": false, "dairy_inedible": false, "dairy_lactose_intolerant": false,
    "caffeine_edible": false, "caffeine_inedible": false,
    "risk_pregnant": false, "risk_hypertension": false, "risk_minor": false,
    "height_cm": 167.0, "weight_kg": 70.0, "target_weight_kg": 58.0
  },
  "allergies": ["키위", "땅콩"]
}
```

### 알러지 자동완성 `/api/allergens`

| 메서드 | 경로 | 설명 |
|---|---|---|
| GET | `/api/allergens` | `SELECT DISTINCT allergy_name FROM menu_allergies` |

### 소통 게시판 `/api/posts`

| 메서드 | 경로 | 설명 |
|---|---|---|
| GET | `/api/posts` | 목록 (`?page=&limit=&q=&sort=latest\|popular`) |
| POST | `/api/posts` | 글 작성 `{ title, content }` |
| GET | `/api/posts/:id` | 상세 + 조회수 +1 |
| DELETE | `/api/posts/:id` | 실제 삭제 (본인만) |
| POST | `/api/posts/:id/vote` | 추천·싫어요 토글 `{ type: 'like'\|'dislike' }` — posts.like_count/dislike_count 동기화 |
| POST | `/api/posts/:id/bookmark` | 북마크 토글 |
| GET | `/api/posts/:id/comments` | 댓글 목록 (2단계 계층) |
| POST | `/api/posts/:id/comments` | 댓글·답글 작성 `{ content, parent_id? }` — posts.comment_count 동기화 |
| POST | `/api/posts/comments/:id/like` | 댓글 좋아요 토글 — comments.like_count 동기화 |

### 레시피 게시판 `/api/recipes`

| 메서드 | 경로 | 설명 |
|---|---|---|
| GET | `/api/recipes` | 목록 (`?page=&limit=&q=&sort=latest\|popular&mine=true&liked=true`) |
| POST | `/api/recipes` | 작성 `{ title, content, thumbnail_url?, tags? }` |
| GET | `/api/recipes/:id` | 상세 + 조회수 +1 |
| DELETE | `/api/recipes/:id` | 실제 삭제 (본인만) |
| POST | `/api/recipes/:id/like` | 찜 토글 — recipes.like_count 동기화 |

### 이미지 업로드 `/api/upload`

| 메서드 | 경로 | 설명 |
|---|---|---|
| POST | `/api/upload/presign` | S3 presigned PUT URL 발급 `{ contentType }` |

업로드 흐름:
1. `POST /api/upload/presign` → `{ upload_url, public_url, key }` 수신
2. 앱이 `upload_url` 에 직접 `PUT` (Content-Type 헤더 필수)
3. `public_url` 을 게시글/레시피 body에 포함해서 저장

---

## RDS 스키마

DB: `slowpick` (MySQL 8 / RDS). `mysqldump --no-data` 기준 전체 테이블 구조.

### 유저

```sql
CREATE TABLE users (
  cognito_sub VARCHAR(36) NOT NULL,
  email VARCHAR(255) NOT NULL,
  nickname VARCHAR(50) DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (cognito_sub),
  UNIQUE KEY (email)
);

CREATE TABLE user_health_info (
  cognito_sub VARCHAR(36) NOT NULL,
  diabetes_type1 TINYINT(1) NOT NULL DEFAULT 0,
  diabetes_type2 TINYINT(1) NOT NULL DEFAULT 0,
  diabetes_pre TINYINT(1) NOT NULL DEFAULT 0,
  dairy_edible TINYINT(1) NOT NULL DEFAULT 0,
  dairy_inedible TINYINT(1) NOT NULL DEFAULT 0,
  dairy_lactose_intolerant TINYINT(1) NOT NULL DEFAULT 0,
  caffeine_edible TINYINT(1) NOT NULL DEFAULT 0,
  caffeine_inedible TINYINT(1) NOT NULL DEFAULT 0,
  risk_pregnant TINYINT(1) NOT NULL DEFAULT 0,
  risk_hypertension TINYINT(1) NOT NULL DEFAULT 0,
  risk_minor TINYINT(1) NOT NULL DEFAULT 0,
  height_cm DECIMAL(5,1) DEFAULT NULL,
  weight_kg DECIMAL(5,1) DEFAULT NULL,
  target_weight_kg DECIMAL(5,1) DEFAULT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (cognito_sub),
  FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE
);

CREATE TABLE user_allergies (
  id BIGINT NOT NULL AUTO_INCREMENT,
  cognito_sub VARCHAR(36) NOT NULL,
  allergen VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY (cognito_sub, allergen),
  FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE
);

CREATE TABLE user_note_titles (
  cognito_sub VARCHAR(36) NOT NULL,
  note_key VARCHAR(30) NOT NULL,
  title VARCHAR(50) NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (cognito_sub, note_key),
  FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE
);
```

### 메뉴

```sql
CREATE TABLE brands (
  id BIGINT NOT NULL AUTO_INCREMENT,
  brand_name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY (brand_name)
  -- menus.brand_name 은 문자열 컬럼일 뿐 FK 아님 (참조 무결성 없음)
);

CREATE TABLE menus (
  id BIGINT NOT NULL AUTO_INCREMENT,
  doc_id VARCHAR(255) NOT NULL,
  brand_name VARCHAR(100) NOT NULL,
  menu_name VARCHAR(255) NOT NULL,
  temperature ENUM('HOT','ICED') DEFAULT NULL,
  size_label VARCHAR(50) DEFAULT NULL,
  size_rank TINYINT DEFAULT NULL,
  category VARCHAR(100) DEFAULT NULL,
  description TEXT,
  size_standard VARCHAR(100) DEFAULT NULL,
  image_url TEXT,
  calories DECIMAL(6,1) DEFAULT NULL,
  sugar DECIMAL(6,1) DEFAULT NULL,
  protein DECIMAL(6,1) DEFAULT NULL,
  caffeine DECIMAL(6,1) DEFAULT NULL,
  saturated_fat DECIMAL(6,1) DEFAULT NULL,
  sodium DECIMAL(6,1) DEFAULT NULL,
  nutrition_json JSON DEFAULT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY (doc_id)
);

CREATE TABLE menu_allergies (
  id BIGINT NOT NULL AUTO_INCREMENT,
  menu_id BIGINT NOT NULL,
  allergy_name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY (menu_id, allergy_name),
  FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE CASCADE
);

CREATE TABLE menu_likes (
  menu_id BIGINT NOT NULL,
  cognito_sub VARCHAR(36) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (menu_id, cognito_sub),
  FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE CASCADE,
  FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE
);
```

### 소통 게시판

```sql
CREATE TABLE posts (
  id BIGINT NOT NULL AUTO_INCREMENT,
  cognito_sub VARCHAR(36) NOT NULL,
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  view_count INT NOT NULL DEFAULT 0,
  like_count INT NOT NULL DEFAULT 0,
  dislike_count INT NOT NULL DEFAULT 0,
  comment_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE
  -- is_deleted 없음 — 실제 DELETE 사용
);

CREATE TABLE post_votes (
  post_id BIGINT NOT NULL,
  cognito_sub VARCHAR(36) NOT NULL,
  type ENUM('like','dislike') NOT NULL,
  PRIMARY KEY (post_id, cognito_sub),
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE
);

CREATE TABLE post_bookmarks (
  post_id BIGINT NOT NULL,
  cognito_sub VARCHAR(36) NOT NULL,
  PRIMARY KEY (post_id, cognito_sub),
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE
);

CREATE TABLE comments (
  id BIGINT NOT NULL AUTO_INCREMENT,
  post_id BIGINT DEFAULT NULL,
  recipe_id BIGINT DEFAULT NULL,
  parent_id BIGINT DEFAULT NULL,
  cognito_sub VARCHAR(36) NOT NULL,
  content TEXT NOT NULL,
  like_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE
  -- post_id / recipe_id 중 하나만 사용 (소통+레시피 댓글 통합 테이블)
  -- parent_id NULL=댓글, 값 있음=답글
  -- post_id/recipe_id/parent_id 는 FK 제약 없음 (애플리케이션 레벨로 관리)
  -- is_deleted 없음 — 실제 DELETE 사용
);

CREATE TABLE comment_likes (
  comment_id BIGINT NOT NULL,
  cognito_sub VARCHAR(36) NOT NULL,
  PRIMARY KEY (comment_id, cognito_sub),
  FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
  FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE
);
```

### 레시피 게시판

```sql
CREATE TABLE recipes (
  id BIGINT NOT NULL AUTO_INCREMENT,
  cognito_sub VARCHAR(36) NOT NULL,
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  thumbnail_url VARCHAR(500) DEFAULT NULL,
  view_count INT NOT NULL DEFAULT 0,
  like_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE
  -- is_deleted 없음 — 실제 DELETE 사용
);

CREATE TABLE recipe_tags (
  recipe_id BIGINT NOT NULL,
  tag VARCHAR(50) NOT NULL,
  PRIMARY KEY (recipe_id, tag),
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
);

CREATE TABLE recipe_likes (
  recipe_id BIGINT NOT NULL,
  cognito_sub VARCHAR(36) NOT NULL,
  PRIMARY KEY (recipe_id, cognito_sub),
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
  FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE
);
```

### 혈당 기록

```sql
CREATE TABLE blood_sugar_records (
  id BIGINT NOT NULL AUTO_INCREMENT,
  cognito_sub VARCHAR(36) NOT NULL,
  menu_id BIGINT DEFAULT NULL,
  meal_timing ENUM('after_meal_2h','after_meal_1h','none') NOT NULL,
  medication TINYINT(1) NOT NULL,
  insulin TINYINT(1) NOT NULL DEFAULT 0,
  exercise ENUM('none','light','intense') NOT NULL,
  blood_sugar SMALLINT UNSIGNED NOT NULL,
  recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE,
  FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE SET NULL
  -- menu_id 는 메뉴 삭제와 무관하게 혈당 기록 이력을 보존하기 위해 SET NULL (다른 FK와 다름)
  -- meal_timing: after_meal_2h(식후 2시간) / after_meal_1h(식후 1시간) / none(해당없음)
  -- medication = 당뇨약 복용 여부, insulin = 인슐린 투여 여부 (별개 항목)
);

CREATE TABLE blood_sugar_followups (
  id BIGINT NOT NULL AUTO_INCREMENT,
  record_id BIGINT NOT NULL,
  offset_minutes TINYINT UNSIGNED NOT NULL,
  blood_sugar SMALLINT UNSIGNED NOT NULL,
  recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY (record_id, offset_minutes),
  FOREIGN KEY (record_id) REFERENCES blood_sugar_records(id) ON DELETE CASCADE
  -- 식후 30/60/120분 등 후속 혈당값. 한 기록당 같은 offset_minutes 중복 불가
);
```

### 카운터 동기화 규칙

denormalized 카운터는 관련 행 변경 시 반드시 UPDATE:

| 이벤트 | 업데이트 대상 |
|---|---|
| post_votes INSERT/DELETE | `posts.like_count` 또는 `posts.dislike_count` |
| post_bookmarks INSERT/DELETE | 카운터 없음 |
| comments INSERT | `posts.comment_count` +1 (recipes는 별도 카운터 없음) |
| comments DELETE | `posts.comment_count` -1 |
| comment_likes INSERT/DELETE | `comments.like_count` |
| recipe_likes INSERT/DELETE | `recipes.like_count` |
| menu_likes INSERT/DELETE | 카운터 없음 (menus 테이블 컬럼 없음 — EXISTS 서브쿼리로 실시간 계산) |

### FK 규칙

- 모든 유저 관련 테이블(`user_health_info`, `user_allergies`, `user_note_titles`, `posts`, `recipes`, `comments`, `blood_sugar_records`, `post_votes`, `post_bookmarks`, `comment_likes`, `recipe_likes`, `menu_likes`): `cognito_sub` → `users.cognito_sub`, `ON DELETE CASCADE`
- 게시글/레시피 관련 자식 테이블(`post_votes`, `post_bookmarks`, `comment_likes`, `recipe_tags`, `recipe_likes`, `menu_allergies`, `menu_likes`): 부모 PK → `ON DELETE CASCADE`
- `blood_sugar_records.menu_id` → `menus.id`, `ON DELETE SET NULL` (메뉴 삭제 시에도 혈당 기록 이력 보존, 유일한 SET NULL 케이스)
- `blood_sugar_followups.record_id` → `blood_sugar_records.id`, `ON DELETE CASCADE`
- **FK 제약이 없는 컬럼** (애플리케이션 레벨로만 관리, 쿼리 작성 시 주의):
  - `menus.brand_name` — `brands.brand_name` 을 참조하지 않는 단순 문자열
  - `comments.post_id` / `comments.recipe_id` / `comments.parent_id` — 참조 무결성 없음

---

## Flutter 서비스 레이어

```
lib/service/
├── auth_service.dart   # AuthService.instance (싱글톤)
│                       # signUp / confirmSignUp / signIn / signOut
│                       # fetchNickname / fetchIdToken
│                       # resetPassword / confirmResetPassword
├── api_client.dart     # ApiClient.instance (싱글톤)
│                       # 모든 요청에 JWT 자동 첨부
│                       # 401 → UnauthorizedException
│                       # get / post / put / delete
├── menu_service.dart   # MenuService (static)
│                       # fetchMenus / fetchRecommended / fetchMenuNames
│                       # groupVariants — 핫/아이스·사이즈 변형을 (brand_name, menu_name)
│                       # 기준으로 묶어 대표 변형 + variants 리스트로 반환
└── user_service.dart   # UserService (static)
                        # fetchProfile / saveProfile / fetchMenuAllergens
```

### ApiClient 패턴

```dart
// 모든 EC2 API 호출은 ApiClient 경유
final response = await ApiClient.instance.get('/api/posts');
final response = await ApiClient.instance.post('/api/posts', body: { ... });
```

### 인증 토큰 흐름

```
앱 로그인 (Amplify)
  → Cognito ID Token 발급
  → ApiClient._authHeaders() 에서 fetchIdToken() 호출
  → Authorization: Bearer <token> 헤더 자동 첨부
  → EC2 auth.js 미들웨어가 JWKS로 검증
  → req.user.sub 으로 RDS 조회
```

---

## 화면 → API 대응

| 화면 | 주요 API |
|---|---|
| login_screen | Cognito signIn |
| signup_screen | Cognito signUp → confirmSignUp |
| find_password_screen | Cognito resetPassword → confirmResetPassword |
| search.dart | GET /api/menus (파라미터 없이 전체 로드 후 클라이언트 필터) |
| myPage_input.dart | GET·PUT /api/user/profile, GET /api/allergens |
| community_screen | GET /api/posts |
| community_post | GET /api/posts/:id, GET /api/posts/:id/comments |
| community_write | POST /api/posts |
| community_recipe | GET /api/recipes |
| community_recipewrite | POST /api/upload/presign → PUT S3 → POST /api/recipes |
| menu_liked_screen | GET /api/menus/liked, POST /api/menus/:id/like |
| search.dart | GET /api/menus (is_liked 포함), POST /api/menus/:id/like |