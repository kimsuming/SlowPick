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
- 소프트 삭제 (`is_deleted = 1`) 사용, 실제 행 삭제 안 함
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
| DELETE | `/api/posts/:id` | 소프트 삭제 (본인만) |
| POST | `/api/posts/:id/vote` | 추천·싫어요 토글 `{ type: 'like'\|'dislike' }` |
| POST | `/api/posts/:id/bookmark` | 북마크 토글 |
| GET | `/api/posts/:id/comments` | 댓글 목록 (2단계 계층) |
| POST | `/api/posts/:id/comments` | 댓글·답글 작성 `{ content, parent_id? }` |
| POST | `/api/posts/comments/:id/like` | 댓글 좋아요 토글 |

### 레시피 게시판 `/api/recipes`

| 메서드 | 경로 | 설명 |
|---|---|---|
| GET | `/api/recipes` | 목록 (`?page=&limit=&q=&sort=latest\|popular&mine=true&liked=true`) |
| POST | `/api/recipes` | 작성 `{ title, content, thumbnail_url?, tags? }` |
| GET | `/api/recipes/:id` | 상세 + 조회수 +1 |
| DELETE | `/api/recipes/:id` | 소프트 삭제 (본인만) |
| POST | `/api/recipes/:id/like` | 찜 토글 |

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
users               -- cognito_sub (PK), email, nickname, created_at, updated_at
user_health_info    -- cognito_sub (PK/FK), 당뇨·유제품·카페인·고카페인·체형 정보
user_allergies      -- id, cognito_sub (FK), allergen
```

### 메뉴

```sql
menus               -- 음료 메뉴 (menu_name, brand_name, calories, sugar, price, ...)
menu_allergies      -- menu_id (FK), allergy_name
```

### 소통 게시판

```sql
community_posts          -- id, cognito_sub (FK), title, content, view_count, is_deleted, created_at
community_post_votes     -- (post_id, cognito_sub) PK, type ENUM('like','dislike')
community_post_bookmarks -- (post_id, cognito_sub) PK
community_comments       -- id, post_id (FK), parent_id (FK, NULL=댓글 / 값=답글), cognito_sub, content, is_deleted, created_at
community_comment_likes  -- (comment_id, cognito_sub) PK
```

### 레시피 게시판

```sql
community_recipes      -- id, cognito_sub (FK), title, content, thumbnail_url, view_count, is_deleted, created_at
community_recipe_tags  -- (recipe_id, tag) PK
community_recipe_likes -- (recipe_id, cognito_sub) PK
```

### FK 규칙

- 모든 유저 관련 테이블: `cognito_sub` → `users.cognito_sub`
- 게시글/레시피/댓글: `ON DELETE CASCADE`
- 소프트 삭제(`is_deleted=1`) 사용 — 실제 행 삭제 없음

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
