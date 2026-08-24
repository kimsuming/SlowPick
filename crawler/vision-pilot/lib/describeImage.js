const { getClient, withRateLimitRetry } = require('./openaiClient');

// --------------------------------------------------
// Normalized vocabularies
// --------------------------------------------------

const COLORS = [
  '검정/매우진한갈색',
  '갈색',
  '연갈색',
  '베이지/크림색',
  '흰색/우유색',
  '초록색',
  '연두색',
  '분홍색',
  '노란색',
  '주황색',
  '빨간색',
  '보라색',
  '파란색',
  '투명/무색',
  '기타',
  '판단불가',
];

const REGION_VISIBILITIES = [
  '잘보임',
  '부분가림',
  '가려짐',
  '화면밖',
  '판단불가',
];

const TOP_TYPES = [
  '일반액체',
  '얇은거품',
  '두꺼운거품',
  '휘핑크림',
  '크림층',
  '아이스크림',
  '기타',
  '판단불가',
];

const TOPPINGS = [
  '가루',
  '시럽/드리즐',
  '초콜릿',
  '쿠키',
  '견과류',
  '과일조각',
  '과일슬라이스',
  '시리얼',
  '허브/잎',
  '기타',
  '판단불가',
];

const INCLUSIONS = [
  '펄',
  '젤리',
  '과육',
  '과일조각',
  '초콜릿조각',
  '쿠키조각',
  '곡물',
  '기타',
  '판단불가',
];

const OCCLUSION_SOURCES = [
  '컵홀더',
  '손',
  '라벨/스티커',
  '빨대',
  '반사/물방울',
  '다른물체',
  '기타',
  '판단불가',
];

const REGION_ORDER = [
  '상단',
  '중단',
  '하단',
];

// --------------------------------------------------
// Color families
//
// 같은 계열 안의 농도 차이를
// 서로 다른 층으로 과도하게 판단하는 것을 방지하기 위한
// 후처리용 분류다.
//
// 너무 넓게 묶으면 실제 층 음료를 단색으로 만들 수 있으므로
// 보수적으로 정의한다.
// --------------------------------------------------

const COLOR_FAMILY_MAP = {
  '검정/매우진한갈색': '갈색계열',
  '갈색': '갈색계열',
  '연갈색': '갈색계열',

  '초록색': '초록계열',
  '연두색': '초록계열',

  '베이지/크림색': '베이지/크림계열',
  '흰색/우유색': '흰색/우유계열',

  '분홍색': '분홍계열',
  '노란색': '노랑계열',
  '주황색': '주황계열',
  '빨간색': '빨강계열',
  '보라색': '보라계열',
  '파란색': '파랑계열',
  '투명/무색': '무색계열',
  '기타': '기타',
  '판단불가': '판단불가',
};

// --------------------------------------------------
// Region schema
// --------------------------------------------------

function createRegionSchema() {
  return {
    type: 'object',

    properties: {
      visibility: {
        type: 'string',
        enum: REGION_VISIBILITIES,
      },

      color: {
        type: 'string',
        enum: COLORS,
      },
    },

    required: [
      'visibility',
      'color',
    ],

    additionalProperties: false,
  };
}

// --------------------------------------------------
// Structured Output schema
// --------------------------------------------------

const DESCRIPTION_SCHEMA = {
  name: 'drink_visual_description',

  strict: true,

  schema: {
    type: 'object',

    properties: {
      /**
       * 컵 안 음료 본체에서 실제로 관찰되는 주요 색상.
       *
       * 휘핑크림, 아이스크림, 토핑, 컵, 로고,
       * 빨대, 컵홀더, 배경 색은 제외한다.
       */
      body_colors: {
        type: 'array',

        items: {
          type: 'string',
          enum: COLORS,
        },
      },

      /**
       * 음료 본체 내부의 색상 배치 구조.
       */
      color_pattern: {
        type: 'string',

        enum: [
          '단색',
          '상하2층',
          '다층',
          '그라데이션',
          '마블/소용돌이',
          '부분혼합',
          '판단불가',
        ],
      },

      /**
       * 컵 내부 음료 본체를
       * 상단 / 중단 / 하단으로 나눈 공간 정보.
       */
      body_regions: {
        type: 'object',

        properties: {
          top: createRegionSchema(),
          middle: createRegionSchema(),
          bottom: createRegionSchema(),
        },

        required: [
          'top',
          'middle',
          'bottom',
        ],

        additionalProperties: false,
      },

      /**
       * 컵이 아니라 음료 내용물 자체의 투명도.
       */
      body_clarity: {
        type: 'string',

        enum: [
          '맑고투명',
          '반투명',
          '불투명',
          '판단불가',
        ],
      },

      texture: {
        type: 'string',

        enum: [
          '맑은액체',
          '일반액체',
          '우유빛',
          '크리미',
          '걸쭉함',
          '스무디/블렌디드',
          '탄산/기포',
          '과육이보임',
          '판단불가',
        ],
      },

      ice_presence: {
        type: 'string',

        enum: [
          '있음',
          '없음',
          '판단불가',
        ],
      },

      ice_amount: {
        type: 'string',

        enum: [
          '없음',
          '적음',
          '보통',
          '많음',
          '판단불가',
        ],
      },

      /**
       * 음료 표면의 주된 구조.
       * 여러 구조가 동시에 보일 수 있다.
       */
      top_type: {
        type: 'array',

        items: {
          type: 'string',
          enum: TOP_TYPES,
        },
      },

      /**
       * 표면의 추가 장식 요소.
       */
      toppings: {
        type: 'array',

        items: {
          type: 'string',
          enum: TOPPINGS,
        },
      },

      topping_colors: {
        type: 'array',

        items: {
          type: 'string',
          enum: COLORS,
        },
      },

      /**
       * 음료 본체 내부에서 보이는 고형 요소.
       */
      inclusions: {
        type: 'array',

        items: {
          type: 'string',
          enum: INCLUSIONS,
        },
      },

      /**
       * 컵 자체의 재질/형태.
       */
      container: {
        type: 'string',

        enum: [
          '투명플라스틱컵',
          '반투명플라스틱컵',
          '불투명종이컵',
          '유리컵',
          '병',
          '기타',
          '판단불가',
        ],
      },

      /**
       * 촬영 조건 및 가림 정보.
       */
      occlusion: {
        type: 'object',

        properties: {
          level: {
            type: 'string',

            enum: [
              '없음',
              '부분가림',
              '많이가림',
              '판단불가',
            ],
          },

          sources: {
            type: 'array',

            items: {
              type: 'string',
              enum: OCCLUSION_SOURCES,
            },
          },

          affected_regions: {
            type: 'array',

            items: {
              type: 'string',
              enum: REGION_ORDER,
            },
          },
        },

        required: [
          'level',
          'sources',
          'affected_regions',
        ],

        additionalProperties: false,
      },

      overall_visibility: {
        type: 'string',

        enum: [
          '좋음',
          '부분관찰가능',
          '나쁨',
        ],
      },
    },

    required: [
      'body_colors',
      'color_pattern',
      'body_regions',
      'body_clarity',
      'texture',
      'ice_presence',
      'ice_amount',
      'top_type',
      'toppings',
      'topping_colors',
      'inclusions',
      'container',
      'occlusion',
      'overall_visibility',
    ],

    additionalProperties: false,
  },
};

// --------------------------------------------------
// System prompt
// --------------------------------------------------

const SYSTEM_PROMPT = `
너는 카페 음료 사진에서 메뉴 식별에 사용할 수 있는
시각적 특징만 객관적으로 추출하는 분류 도구다.

브랜드명이나 메뉴명을 추측하지 않는다.
맛, 제품명, 실제 재료를 추측하지 않는다.
사진에서 실제로 관찰 가능한 시각 정보만 기록한다.

가장 중요한 원칙은 다음과 같다.

1. 보이지 않는 정보는 추측하지 않는다.
2. 컵 안 음료 본체와 음료 표면 위 장식을 분리해서 판단한다.
3. 촬영 환경 때문에 생기는 작은 밝기/농도 차이를
   실제 층 구조로 과도하게 해석하지 않는다.


[1. 가림 처리 규칙]

컵홀더, 손, 라벨/스티커, 빨대, 반사, 물방울,
다른 물체 등에 가려진 부분의 특징을 추측하지 않는다.

특히 컵홀더가 음료 중단을 가리고 있다면,
컵홀더 뒤의 색이나 구조를 다른 영역을 보고 추정하지 않는다.

완전히 가려진 body_region은:

visibility = "가려짐"
color = "판단불가"

이 사진들은 매장이 제공한 공식 메뉴 사진으로,
컵 전체가 항상 프레임 안에 온전히 담겨 있다.
컵이 잘려서 일부만 촬영된 경우는 사실상 없다고 가정한다.

따라서 "화면밖"은
컵 자체가 실제로 사진 프레임을 벗어나
잘려 보이지 않는, 매우 예외적인 경우에만 사용한다.

크림, 토핑, 컵홀더 등에 가려서
해당 영역이 안 보이는 경우는
"화면밖"이 아니라 "가려짐"이다.

구도상 컵은 보이지만
해당 영역의 색을 확신할 수 없는 경우에는
"화면밖" 대신 "판단불가"를 사용한다.

부분적으로 가려져 있더라도
실제로 보이는 부분만으로 색을 충분히 확인할 수 있으면 기록한다.

그렇지 않으면 color = "판단불가"로 기록한다.


[2. 음료 본체와 표면 장식의 구분]

"음료 본체(body)"는 컵 내부에 담긴 액체,
블렌디드 음료, 빙수형 내용물 등
메뉴의 주된 몸체를 뜻한다.

body_colors,
color_pattern,
body_regions,
body_clarity,
texture

는 음료 본체만 보고 판단한다.

다음 요소의 색이나 형태는
body_colors와 body_regions에 포함하지 않는다.

- 휘핑크림
- 크림층
- 아이스크림
- 과일 조각/슬라이스
- 시리얼
- 쿠키
- 견과류
- 가루
- 표면의 시럽/드리즐
- 허브/잎
- 빨대
- 컵
- 컵홀더
- 컵의 로고나 인쇄
- 배경

위 요소는
top_type,
toppings,
topping_colors

에서 기록한다.

예를 들어 흰 음료 위에
빨간 과일과 노란 시리얼이 있어도,

음료 본체가 흰색이라면
body_colors에는 "흰색/우유색"을 기록하고,

빨간색과 노란색은
topping_colors에 기록한다.

단,
색이 컵 안 음료 본체 내부에 실제로 섞이거나 퍼져 있어
본체 자체의 구조를 형성한다면
body_colors와 color_pattern에 포함할 수 있다.


[3. body_regions 공간 정보]

body_regions는 컵 내부 음료 본체를
세로 방향으로 나눈다.

top:
음료 본체의 위쪽 약 1/3

middle:
음료 본체의 가운데 약 1/3

bottom:
음료 본체의 아래쪽 약 1/3

컵 전체 사진의 상/중/하가 아니라
"컵 안 음료 본체"를 기준으로 한다.

컵 위로 돌출된 휘핑크림,
아이스크림,
과일 등의 장식은
body_regions.top에 포함하지 않는다.

표면 장식 때문에
음료 본체의 top 영역이 보이지 않으면
가려짐 또는 판단불가로 처리한다.


[4. body_colors 규칙]

body_colors에는
컵 안 음료 본체에서 실제로 보이는 주요 색만 기록한다.

작은 장식의 색은 제외한다.
컵, 로고, 빨대, 컵홀더, 배경의 색은 제외한다.

본체 내부에서 넓은 면적을 차지하거나
반복되는 마블, 띠, 층을 이루는
식별에 유의미한 색은 포함한다.

여러 색이 보이면 여러 값을 기록한다.

다만 같은 색 계열에서
단순히 밝기나 농도만 달라 보이는 경우에는
불필요하게 여러 색으로 세분화하지 않는다.

예:
갈색 커피가 얼음이나 빛 때문에
위쪽에서 연해 보이고 아래쪽에서 진해 보여도
전체적으로 같은 갈색 계열이라면
대표적인 갈색 계열 위주로 판단한다.

음료 본체 색을 확인할 수 없다면
["판단불가"]를 사용한다.

"판단불가"는
다른 구체적인 색과 함께 사용하지 않는다.


[5. color_pattern 판정 규칙]

color_pattern은
음료 본체 내부의 색상 구조만 보고 판단한다.

표면 장식의 색은
color_pattern 판정에 사용하지 않는다.


가장 중요한 원칙:

같은 색 계열 안에서
밝기, 농도, 투명도만 조금 달라지는 경우에는
원칙적으로 "단색"을 우선한다.

예:

- 갈색 커피가 위로 갈수록 연해 보임
- 얼음 주변만 갈색이 연해 보임
- 같은 초록색 음료에서 위아래 농도만 다름
- 투명컵의 굴절이나 반사 때문에 일부가 밝게 보임
- 조명 때문에 상단과 하단의 명도가 다르게 보임

이런 경우는
"상하2층"이나 "그라데이션"보다
"단색"을 우선한다.


"단색":

음료 본체가 전체적으로
하나의 색 계열로 보인다.

위아래에 밝기 차이,
농도 차이,
얼음 주변의 연한 영역,
투명컵이나 조명에 따른 명암 차이가 있어도

서로 다른 성분의 층이라고 보기 어렵다면
"단색"이다.


"상하2층":

서로 다른 두 성분 또는
시각적으로 구별되는 두 색 계열이

위와 아래로 분리되어 있고
그 경계를 대략 식별할 수 있을 때 사용한다.

예:

갈색 커피층
+
흰색 우유층

처럼 서로 다른 두 영역이 명확한 경우.

같은 갈색 계열이
위쪽에서 연하고 아래쪽에서 진한 정도라면
"상하2층"을 사용하지 않는다.


"다층":

서로 다른 세 개 이상의 층이나 띠가
위아래로 구분될 때 사용한다.

각 층 사이의 경계를
대략적으로 식별할 수 있어야 한다.


"그라데이션":

서로 다른 색 또는 충분히 구별되는 색 변화가
연속적이고 점진적으로 이어지며,

어디서 층이 바뀌는지
명확한 경계를 정하기 어려울 때 사용한다.

그러나 전체가 하나의 색 계열이고
단지 농도나 밝기만 점진적으로 달라지는 경우에는
"그라데이션"보다 "단색"을 우선한다.


"부분혼합":

서로 다른 두 색 또는 성분이
일부 불규칙하게 섞여 있지만
완전히 균일하지 않은 상태다.

불규칙한 퍼짐이나 혼합 경계가 보인다.

위아래 두 층이 명확하게 유지된다면
"부분혼합"보다 "상하2층"을 우선한다.


"마블/소용돌이":

서로 다른 색이

선,
띠,
물결,
소용돌이,
컵 벽면을 따라 흐르는 자국

등의 형태로
명확한 마블 패턴을 만든다.

단순한 층 분리는
"마블/소용돌이"가 아니다.


판단 우선순위:

1. 전체적으로 같은 색 계열이면 "단색"을 우선한다.
2. 서로 다른 색 계열이 층으로 분리되면 "상하2층" 또는 "다층".
3. 서로 다른 색이 불규칙하게 섞이면 "부분혼합".
4. 선/소용돌이 패턴이면 "마블/소용돌이".
5. 서로 다른 색 사이의 연속적 변화가 핵심이면 "그라데이션".

가림이나 사진 상태 때문에
구조를 충분히 판단할 수 없다면
"판단불가"를 사용한다.


[6. body_clarity 규칙]

body_clarity는
컵 재질이 아니라
"음료 내용물 자체의 투명도"다.

절대로 투명 플라스틱 컵이라는 이유만으로
body_clarity를 "맑고투명"으로 판단하지 않는다.


"맑고투명":

음료 내용물을 통해
반대편이나 얼음,
뒤쪽 윤곽이 비교적 명확하게 보인다.


"반투명":

빛은 통하지만
내용물을 통해 뒤쪽을 명확하게 볼 수는 없다.


"불투명":

우유,
라떼,
크림,
스무디처럼

음료 내용물을 통해
뒤쪽을 볼 수 없다.


예:

투명 플라스틱 컵 + 우유
→ "불투명"

투명 플라스틱 컵 + 카페라떼
→ "불투명"

투명 플라스틱 컵 + 스무디
→ "불투명"

맑은 차나 아메리카노처럼
내용물을 통해 얼음과 뒤쪽 윤곽이 보임
→ "맑고투명" 또는 "반투명"


판단하기 어렵다면
"판단불가"를 사용한다.

container와 body_clarity를 혼동하지 않는다.

container:
컵 자체

body_clarity:
컵 안 내용물


[7. texture 규칙]

texture는
음료 본체에서 실제로 보이는 질감만 기록한다.

맛이나 메뉴명,
예상 재료를 근거로 추론하지 않는다.


[8. 얼음 규칙]

얼음이 하나라도 명확하게 보이면:

ice_presence = "있음"

충분히 관찰 가능하고
얼음이 없음을 확인할 수 있을 때만:

ice_presence = "없음"

가림이나 사진 상태 때문에
확인하기 어렵다면:

ice_presence = "판단불가"

얼음 존재는 확인했지만
양을 판단하기 어렵다면:

ice_presence = "있음"
ice_amount = "판단불가"

ice_presence = "없음"이면:

ice_amount = "없음"


[9. top_type 규칙]

top_type은
음료 표면의 주된 구조를 나타내는 배열이다.

실제로 동시에 보이는 구조를
여러 개 기록할 수 있다.

예:

["일반액체"]

["휘핑크림"]

["크림층"]

["휘핑크림", "아이스크림"]

["두꺼운거품", "크림층"]


특별한 구조 없이
일반적인 액체 표면이면:

["일반액체"]

상단을 볼 수 없어
판단할 수 없다면:

["판단불가"]

"판단불가"는
다른 값과 함께 사용하지 않는다.

동일한 값을 중복 기록하지 않는다.

아이스크림처럼
top_type으로 분류한 주된 구조는
toppings에 다시 넣지 않는다.


[10. toppings 규칙]

toppings는
top_type 위 또는 주변에 추가로 보이는
장식 요소다.

예:

가루,
시럽/드리즐,
초콜릿,
쿠키,
견과류,
과일,
시리얼,
허브 등.

토핑이 없음을 충분히 확인할 수 있으면:

[]

상단이 가려졌거나 화면 밖이라
확인할 수 없다면:

["판단불가"]

"판단불가"는
다른 값과 함께 사용하지 않는다.

동일한 값을 중복 기록하지 않는다.


topping_colors에는
top_type 및 toppings에서 보이는
주요 색을 기록한다.

상단 요소가 전혀 없으면:

[]

색을 판단할 수 없다면:

["판단불가"]

컵,
로고,
빨대,
배경의 색은 포함하지 않는다.


[11. inclusions 규칙]

inclusions는
컵 안 음료 본체 내부에서
실제로 보이는 고형 요소만 기록한다.

예:

펄,
젤리,
과육,
과일조각,
초콜릿조각,
쿠키조각,
곡물.

표면 위에 놓인 장식은
inclusions가 아니라 toppings다.

없음을 충분히 확인할 수 있으면:

[]

가림 때문에 확인할 수 없다면:

["판단불가"]

"판단불가"는
다른 값과 함께 사용하지 않는다.


[12. 전체 원칙]

보이지 않는 정보를 억지로 맞히지 않는다.

사진 촬영 조건 때문에 발생한
작은 색상 차이를
메뉴의 고유한 층 구조로 과도하게 해석하지 않는다.

잘못된 구체적 값을 만드는 것보다
"판단불가"가 낫다.

항상 지정된 JSON 스키마만 반환한다.
`.trim();

// --------------------------------------------------
// Normalization helpers
// --------------------------------------------------

function normalizeArray(values, order) {
  if (!Array.isArray(values)) {
    return [];
  }

  const unique = [...new Set(values)];

  // 구체적인 값과 판단불가가 동시에 있다면
  // 구체적인 관찰값을 우선한다.
  const cleaned =
    unique.length > 1
      ? unique.filter((value) => value !== '판단불가')
      : unique;

  return cleaned.sort((a, b) => {
    const ai = order.indexOf(a);
    const bi = order.indexOf(b);

    if (ai === -1 && bi === -1) {
      return a.localeCompare(b);
    }

    if (ai === -1) {
      return 1;
    }

    if (bi === -1) {
      return -1;
    }

    return ai - bi;
  });
}

function isKnown(value) {
  return (
    value !== undefined &&
    value !== null &&
    value !== '' &&
    value !== '판단불가'
  );
}

function regionToCanonical(label, region) {
  if (!region) {
    return null;
  }

  if (
    region.visibility === '가려짐' ||
    region.visibility === '화면밖' ||
    region.visibility === '판단불가'
  ) {
    return null;
  }

  if (!isKnown(region.color)) {
    return null;
  }

  return `${label}(색=${region.color})`;
}

// --------------------------------------------------
// Color-pattern relaxation helpers
// --------------------------------------------------

function getColorFamily(color) {
  if (!color || color === '판단불가') {
    return null;
  }

  return COLOR_FAMILY_MAP[color] || color;
}

/**
 * 주어진 색들이 모두 같은 색 계열인지 확인한다.
 *
 * 예:
 * ['갈색', '연갈색'] -> true
 * ['갈색', '검정/매우진한갈색'] -> true
 * ['갈색', '흰색/우유색'] -> false
 */
function areSameColorFamily(colors) {
  const knownColors = colors.filter(
    (color) =>
      color &&
      color !== '판단불가'
  );

  if (knownColors.length === 0) {
    return false;
  }

  const families = knownColors
    .map(getColorFamily)
    .filter(Boolean);

  return new Set(families).size === 1;
}

/**
 * GPT가 촬영 조건이나 농도 차이를 실제 층으로 과분류한 경우를
 * 보수적으로 "단색"으로 정규화한다.
 *
 * 이 후처리는 다음 조건을 모두 만족할 때만 작동한다.
 *
 * 1. GPT가 상하2층 또는 그라데이션이라고 판단
 * 2. 음료가 맑고투명 또는 반투명
 * 3. body_colors가 하나의 색 계열
 * 4. 실제로 관찰된 body_regions 역시 하나의 색 계열
 *
 * 따라서:
 *
 * 갈색 + 연갈색 아메리카노
 * → 단색으로 완화 가능
 *
 * 갈색 + 흰색 라떼
 * → 색 계열이 다르므로 유지
 */
function relaxColorPattern(fields) {
  if (!fields) {
    return fields;
  }

  const relaxablePattern =
    fields.color_pattern === '상하2층' ||
    fields.color_pattern === '그라데이션';

  if (!relaxablePattern) {
    return fields;
  }

  const transparentLike =
    fields.body_clarity === '맑고투명' ||
    fields.body_clarity === '반투명';

  if (!transparentLike) {
    return fields;
  }

  const bodyColors = Array.isArray(fields.body_colors)
    ? fields.body_colors.filter(
        (color) =>
          color &&
          color !== '판단불가'
      )
    : [];

  if (
    bodyColors.length === 0 ||
    !areSameColorFamily(bodyColors)
  ) {
    return fields;
  }

  const regionColors = [
    fields.body_regions?.top?.color,
    fields.body_regions?.middle?.color,
    fields.body_regions?.bottom?.color,
  ].filter(
    (color) =>
      color &&
      color !== '판단불가'
  );

  if (regionColors.length === 0) {
    return fields;
  }

  if (!areSameColorFamily(regionColors)) {
    return fields;
  }

  /**
   * body_colors와 regions가 각각 같은 계열이어도
   * 서로 다른 계열일 가능성을 막는다.
   *
   * 예:
   * body_colors = ['갈색']
   * regions = ['흰색/우유색']
   *
   * 같은 경우는 보정하지 않는다.
   */
  const combinedColors = [
    ...bodyColors,
    ...regionColors,
  ];

  if (!areSameColorFamily(combinedColors)) {
    return fields;
  }

  fields.color_pattern = '단색';

  return fields;
}

// --------------------------------------------------
// Canonical text
// --------------------------------------------------

function buildCanonicalText(fields) {
  const parts = [];

  // ------------------------------------------------
  // 본체 색
  // ------------------------------------------------

  const bodyColors = normalizeArray(
    fields.body_colors,
    COLORS,
  ).filter(
    (value) =>
      value !== '판단불가'
  );

  if (bodyColors.length > 0) {
    parts.push(
      `본체색상:${bodyColors.join('+')}`,
    );
  }

  // ------------------------------------------------
  // 색상 구조
  // ------------------------------------------------

  if (isKnown(fields.color_pattern)) {
    parts.push(
      `색상구조:${fields.color_pattern}`,
    );
  }

  // ------------------------------------------------
  // 공간 정보
  // ------------------------------------------------

  const regionTexts = [
    regionToCanonical(
      '상단',
      fields.body_regions?.top,
    ),

    regionToCanonical(
      '중단',
      fields.body_regions?.middle,
    ),

    regionToCanonical(
      '하단',
      fields.body_regions?.bottom,
    ),
  ].filter(Boolean);

  parts.push(...regionTexts);

  // ------------------------------------------------
  // 내용물 투명도
  // ------------------------------------------------

  if (isKnown(fields.body_clarity)) {
    parts.push(
      `내용물투명도:${fields.body_clarity}`,
    );
  }

  // ------------------------------------------------
  // 질감
  // ------------------------------------------------

  if (isKnown(fields.texture)) {
    parts.push(
      `질감:${fields.texture}`,
    );
  }

  // ------------------------------------------------
  // 얼음
  // ------------------------------------------------

  if (fields.ice_presence === '없음') {
    parts.push('얼음:없음');
  }

  if (fields.ice_presence === '있음') {
    if (
      isKnown(fields.ice_amount) &&
      fields.ice_amount !== '없음'
    ) {
      parts.push(
        `얼음:있음/${fields.ice_amount}`,
      );
    } else {
      parts.push('얼음:있음');
    }
  }

  // ------------------------------------------------
  // 상단 형태
  // ------------------------------------------------

  const topTypes = normalizeArray(
    fields.top_type,
    TOP_TYPES,
  );

  if (
    topTypes.length > 0 &&
    !topTypes.includes('판단불가')
  ) {
    parts.push(
      `상단형태:${topTypes.join('+')}`,
    );
  }

  // ------------------------------------------------
  // 토핑
  // ------------------------------------------------

  const toppings = normalizeArray(
    fields.toppings,
    TOPPINGS,
  );

  if (toppings.length === 0) {
    parts.push('토핑:없음');
  } else if (
    !toppings.includes('판단불가')
  ) {
    parts.push(
      `토핑:${toppings.join('+')}`,
    );
  }

  // ------------------------------------------------
  // 상단 장식 색
  // ------------------------------------------------

  const toppingColors = normalizeArray(
    fields.topping_colors,
    COLORS,
  ).filter(
    (value) =>
      value !== '판단불가'
  );

  if (toppingColors.length > 0) {
    parts.push(
      `상단장식색:${toppingColors.join('+')}`,
    );
  }

  // ------------------------------------------------
  // 내부 요소
  // ------------------------------------------------

  const inclusions = normalizeArray(
    fields.inclusions,
    INCLUSIONS,
  );

  if (inclusions.length === 0) {
    parts.push(
      '내부요소:없음',
    );
  } else if (
    !inclusions.includes('판단불가')
  ) {
    parts.push(
      `내부요소:${inclusions.join('+')}`,
    );
  }

  /**
   * container
   * occlusion
   * overall_visibility
   *
   * 는 메뉴 고유 특징보다 촬영 조건의 영향을 많이 받으므로
   * canonicalText에는 넣지 않는다.
   */

  if (parts.length === 0) {
    return '관찰가능한 음료 특징 없음';
  }

  return parts.join(' | ');
}

// --------------------------------------------------
// Main
// --------------------------------------------------

/**
 * @param {{ url?: string, dataUrl?: string }} image
 * @returns {Promise<{ fields: object, canonicalText: string }>}
 */
async function describeImage(image) {
  const client = getClient();

  const imageUrl =
    image.url ||
    image.dataUrl;

  if (!imageUrl) {
    throw new Error(
      'describeImage: url 또는 dataUrl이 필요합니다.',
    );
  }

  /**
   * 테스트:
   * IMAGE_DETAIL=low node ...
   *
   * 최종 구축:
   * IMAGE_DETAIL=high node ...
   */
  const imageDetail =
    process.env.IMAGE_DETAIL ||
    'low';

  const response =
    await withRateLimitRetry(() =>
      client.chat.completions.create({
        model: 'gpt-4o-mini',

        messages: [
          {
            role: 'system',
            content: SYSTEM_PROMPT,
          },

          {
            role: 'user',

            content: [
              {
                type: 'text',

                text:
                  '이 음료 사진에서 실제로 관찰 가능한 시각적 특징만 분류해줘. ' +
                  '컵 안 음료 본체와 표면 장식을 분리하고, ' +
                  '같은 색 계열의 단순한 농도나 밝기 차이를 층 구조로 과도하게 판단하지 마. ' +
                  '컵 자체의 투명도와 음료 내용물의 투명도를 혼동하지 말고, ' +
                  '가려진 부분은 절대 추측하지 마.',
              },

              {
                type: 'image_url',

                image_url: {
                  url: imageUrl,
                  detail: imageDetail,
                },
              },
            ],
          },
        ],

        response_format: {
          type: 'json_schema',
          json_schema: DESCRIPTION_SCHEMA,
        },
      }),
    );

  const message =
    response.choices?.[0]?.message;

  if (!message?.content) {
    throw new Error(
      'describeImage: GPT 응답에 content가 없습니다.',
    );
  }

  // GPT 원본 출력
  const rawFields =
    JSON.parse(message.content);

  /**
   * 후처리.
   *
   * 객체를 직접 수정하지 않고 복사해서 사용하면
   * 디버깅할 때 GPT 원본 값과 후처리 값을 비교하기 쉽다.
   */
  const fields =
    relaxColorPattern(
      JSON.parse(
        JSON.stringify(rawFields),
      ),
    );

  const canonicalText =
    buildCanonicalText(fields);

  // ------------------------------------------------
  // Debug
  // ------------------------------------------------

  if (
    process.env.DEBUG_IMAGE_DESCRIPTION === 'true'
  ) {
    console.log(
      '[describeImage raw]',
    );

    console.log(
      JSON.stringify(
        rawFields,
        null,
        2,
      ),
    );

    if (
      rawFields.color_pattern !==
      fields.color_pattern
    ) {
      console.log(
        `[describeImage normalize] color_pattern: ` +
        `${rawFields.color_pattern} -> ${fields.color_pattern}`,
      );
    }

    console.log(
      '[describeImage normalized]',
    );

    console.log(
      JSON.stringify(
        fields,
        null,
        2,
      ),
    );

    if (response.usage) {
      console.log(
        `[tokens] prompt=${response.usage.prompt_tokens}, ` +
        `completion=${response.usage.completion_tokens}, ` +
        `total=${response.usage.total_tokens}`,
      );
    }

    console.log(
      `[vision] detail=${imageDetail}`,
    );
  }

  return {
    fields,
    canonicalText,
  };
}

module.exports = {
  describeImage,
};