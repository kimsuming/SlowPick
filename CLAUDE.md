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
| GET | `/api/menus` | 목록 (`?search=&brands=&sort=`) |
| GET | `/api/menus/recommended` | 추천 메뉴 10개 (RAND) |
| GET | `/api/menus/names` | 메뉴명 목록 (자동완성용) |

- 실제 컬럼명: `menu_name`, `brand_name` (`name`, `brand` 아님)

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

### 유저

```sql
users             -- cognito_sub VARCHAR(36) PK, email VARCHAR(255) UNI, nickname VARCHAR(50), created_at, updated_at
user_health_info  -- cognito_sub PK/FK, diabetes_type1/2/pre, dairy_edible/inedible/lactose_intolerant,
                  --   caffeine_edible/inedible, risk_pregnant/hypertension/minor (모두 tinyint(1) default 0)
                  --   height_cm DECIMAL(5,1), weight_kg DECIMAL(5,1), target_weight_kg DECIMAL(5,1), updated_at
user_allergies    -- id BIGINT PK AUTO, cognito_sub FK, allergen VARCHAR(100)
```

### 메뉴

```sql
brands         -- id BIGINT PK AUTO, brand_name VARCHAR(100) UNI, created_at
menus          -- id BIGINT PK AUTO, doc_id VARCHAR(255) UNI, brand_name, menu_name, category, description,
               --   size_standard, image_url TEXT, calories/sugar/protein/caffeine/saturated_fat/sodium DECIMAL(6,1),
               --   nutrition_json JSON, is_active tinyint(1) default 1, last_updated_at, created_at
menu_allergies -- id BIGINT PK AUTO, menu_id FK, allergy_name VARCHAR(100), created_at
```

### 소통 게시판

```sql
posts          -- id BIGINT PK AUTO, cognito_sub FK, title VARCHAR(200), content TEXT,
               --   view_count INT default 0, like_count INT default 0, dislike_count INT default 0,
               --   comment_count INT default 0, created_at
               --   ※ is_deleted 없음 — 실제 DELETE 사용
post_votes     -- (post_id, cognito_sub) PK, type ENUM('like','dislike')
post_bookmarks -- (post_id, cognito_sub) PK
comments       -- id BIGINT PK AUTO, post_id BIGINT NULL, recipe_id BIGINT NULL,
               --   parent_id BIGINT NULL (NULL=댓글 / 값=답글), cognito_sub, content TEXT,
               --   like_count INT default 0, created_at
               --   ※ 소통+레시피 댓글 통합 테이블. post_id/recipe_id 중 하나만 사용
               --   ※ is_deleted 없음 — 실제 DELETE 사용
comment_likes  -- (comment_id, cognito_sub) PK
```

### 레시피 게시판

```sql
recipes      -- id BIGINT PK AUTO, cognito_sub FK, title VARCHAR(200), content TEXT,
             --   thumbnail_url VARCHAR(500), view_count INT default 0, like_count INT default 0, created_at
             --   ※ is_deleted 없음 — 실제 DELETE 사용
recipe_tags  -- (recipe_id, tag VARCHAR(50)) PK
recipe_likes -- (recipe_id, cognito_sub) PK
```

### 카운터 동기화 규칙

denormalized 카운터는 관련 행 변경 시 반드시 UPDATE:

| 이벤트 | 업데이트 대상 |
|---|---|
| post_votes INSERT/DELETE | `posts.like_count` 또는 `posts.dislike_count` |
| post_bookmarks INSERT/DELETE | 카운터 없음 |
| comments INSERT | `posts.comment_count` +1 (또는 recipes는 별도 카운터 없음) |
| comments DELETE | `posts.comment_count` -1 |
| comment_likes INSERT/DELETE | `comments.like_count` |
| recipe_likes INSERT/DELETE | `recipes.like_count` |

### FK 규칙

- 모든 유저 관련 테이블: `cognito_sub` → `users.cognito_sub`
- 게시글/레시피/댓글: `ON DELETE CASCADE`

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
