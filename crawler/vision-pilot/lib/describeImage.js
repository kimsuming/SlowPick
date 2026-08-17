const { getClient } = require('./openaiClient');

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

// top_type은 상단의 "주된 구조"를 표현하고,
// toppings는 그 위/주변의 추가 장식을 표현한다.
// 중복 방지를 위해 아이스크림은 toppings에서 제외한다.
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
    required: ['visibility', 'color'],
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
       * 컵 안 음료 본체에서 실제로 관찰되는 주요 색상만 기록한다.
       * 휘핑/아이스크림/토핑/컵/로고/배경 색은 제외한다.
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
       * 표면 장식은 판단에 사용하지 않는다.
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
       * 컵 안 "음료 본체"를 상단/중단/하단으로 나눈 공간 정보.
       * 컵 위 장식이나 표면 토핑은 포함하지 않는다.
       */
      body_regions: {
        type: 'object',
        properties: {
          top: createRegionSchema(),
          middle: createRegionSchema(),
          bottom: createRegionSchema(),
        },
        required: ['top', 'middle', 'bottom'],
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
        enum: ['있음', '없음', '판단불가'],
      },

      ice_amount: {
        type: 'string',
        enum: ['없음', '적음', '보통', '많음', '판단불가'],
      },

      /**
       * 음료 표면의 주된 구조. 여러 구조가 동시에 보일 수 있다.
       */
      top_type: {
        type: 'array',
        items: {
          type: 'string',
          enum: TOP_TYPES,
        },
      },

      /**
       * top_type 위/주변에 추가로 보이는 장식 요소.
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
       * 컵 안 음료 본체 내부에서 실제로 보이는 고형 요소.
       */
      inclusions: {
        type: 'array',
        items: {
          type: 'string',
          enum: INCLUSIONS,
        },
      },

      /**
       * 컵 자체의 재질/형태. body_clarity와 별개다.
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
       * 촬영 조건/가림 메타데이터.
       * 메뉴 고유 특징이 아니므로 canonicalText에는 넣지 않는다.
       */
      occlusion: {
        type: 'object',
        properties: {
          level: {
            type: 'string',
            enum: ['없음', '부분가림', '많이가림', '판단불가'],
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
        required: ['level', 'sources', 'affected_regions'],
        additionalProperties: false,
      },

      overall_visibility: {
        type: 'string',
        enum: ['좋음', '부분관찰가능', '나쁨'],
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

가장 중요한 원칙은 다음 세 가지다.

1. 보이지 않는 정보는 추측하지 않는다.
2. 컵 안 음료 본체와 음료 표면 위 장식을 분리해서 판단한다.
3. 색상 패턴은 아래 정의에 따라 엄격하게 구분한다.


[1. 가림 처리 규칙]

- 컵홀더, 손, 라벨/스티커, 빨대, 반사, 물방울, 다른 물체 등에
  가려진 부분의 특징을 추측하지 않는다.

- 특히 컵홀더가 음료 중단을 가린 경우,
  컵홀더 뒤의 색이나 층 구조를 다른 영역을 보고 추정하지 않는다.

- 완전히 가려진 body_region은:
  visibility = "가려짐"
  color = "판단불가"

- 사진 구도 때문에 영역이 화면 밖이라면:
  visibility = "화면밖"
  color = "판단불가"

- 부분적으로 가려져 있더라도 실제 보이는 부분만으로 색을 충분히
  확인할 수 있다면 해당 색을 기록한다.
  그렇지 않으면 color = "판단불가"로 기록한다.


[2. 음료 본체와 표면 장식의 구분]

"음료 본체(body)"는 컵 내부에 담긴 액체, 블렌디드 음료,
빙수형 내용물 등 메뉴의 주된 몸체를 뜻한다.

body_colors, color_pattern, body_regions, body_clarity, texture는
음료 본체만 보고 판단한다.

다음 요소의 색이나 형태는 body_colors와 body_regions에 포함하지 않는다.

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
- 컵/컵홀더
- 컵의 로고나 인쇄
- 배경

위 요소들은 top_type, toppings, topping_colors에서만 기록한다.

예를 들어 흰색 음료 위에 빨간 과일과 노란 시리얼이 있어도,
음료 본체가 흰색이라면 body_colors에는 흰색만 기록하고
빨간색/노란색은 topping_colors에 기록한다.

단, 색이 컵 안 음료 본체 내부에 실제로 섞이거나 퍼져 있어
본체 자체의 시각 구조를 형성한다면 body_colors/color_pattern에 포함할 수 있다.


[3. body_regions 공간 정보]

body_regions는 컵 내부의 음료 본체를 세로 방향으로 나눈다.

- top: 음료 본체의 위쪽 약 1/3
- middle: 음료 본체의 가운데 약 1/3
- bottom: 음료 본체의 아래쪽 약 1/3

컵 전체 사진의 상/중/하가 아니라 "컵 안 음료 본체"를 기준으로 한다.

컵 위로 돌출된 휘핑크림, 아이스크림, 과일 등의 장식은
body_regions.top에 포함하지 않는다.

표면 장식 때문에 음료 본체의 top 영역이 보이지 않으면
해당 body_regions.top을 가려짐 또는 판단불가로 처리한다.


[4. body_colors 규칙]

body_colors에는 컵 안 음료 본체에서 실제로 보이는 주요 색만 기록한다.

- 작은 장식의 색은 제외한다.
- 컵/로고/배경의 색은 제외한다.
- 본체 내부에서 넓은 면적을 차지하거나 반복되는 마블/띠/층을 이루는
  식별에 유의미한 색은 포함한다.
- 여러 색이 보이면 여러 값을 기록한다.
- 음료 본체 색을 확인할 수 없다면 ["판단불가"]를 사용한다.
- "판단불가"는 다른 구체적인 색과 함께 사용하지 않는다.


[5. color_pattern 엄격 판정 규칙]

color_pattern은 음료 본체 내부의 색상 구조만 보고 판단한다.
표면 장식의 색은 color_pattern 판정에 사용하지 않는다.

"단색":
음료 본체가 전체적으로 하나의 색으로 보인다.
작은 명암 차이만 있고 별도의 색 구조가 없다.

"상하2층":
서로 다른 두 색 또는 성분이 위아래로 나뉘어 있고,
두 영역의 경계를 육안으로 대략 확인할 수 있다.
경계 일부가 조금 섞여 있어도 전체적으로 두 층 구조가 명확하면
"상하2층"을 선택한다.

"다층":
서로 다른 세 개 이상의 층 또는 띠가 위아래로 구분된다.
각 층 사이의 경계를 대략 식별할 수 있다.

"그라데이션":
한 색/농도가 다른 색/농도로 연속적이고 점진적으로 변화하며,
어디서 층이 바뀌는지 뚜렷한 경계를 지정하기 어렵다.
단순히 위와 아래 색이 다르다는 이유만으로 "그라데이션"을 선택하지 않는다.

"부분혼합":
서로 다른 두 성분이나 색이 일부 섞여 있으나 완전히 균일하지 않고,
불규칙한 퍼짐이나 혼합 경계가 보인다.
위아래 두 층이 명확하게 유지된다면 "부분혼합"보다 "상하2층"을 우선한다.

"마블/소용돌이":
서로 다른 색이 선, 띠, 물결, 소용돌이, 벽면을 따라 흐르는 자국처럼
명확한 마블 패턴을 만든다.
단순한 층 분리는 "마블/소용돌이"가 아니다.

가림이나 사진 상태 때문에 구조를 충분히 판단할 수 없다면
"판단불가"를 사용한다.


[6. body_clarity 규칙]

body_clarity는 컵 재질이 아니라 "음료 내용물 자체의 투명도"다.

절대로 투명 플라스틱 컵이라는 이유만으로
body_clarity를 "맑고투명"으로 판단하지 않는다.

"맑고투명":
음료 내용물을 통해 반대편이나 얼음/뒤쪽 윤곽이 비교적 명확하게 보인다.
예: 맑은 차, 투명한 에이드 계열처럼 보이는 경우.

"반투명":
빛은 통하지만 내용물을 통해 뒤쪽을 명확하게 볼 수는 없다.

"불투명":
우유, 라떼, 크림, 스무디처럼 음료 내용물을 통해 뒤쪽을 볼 수 없다.

예:
- 투명 플라스틱 컵 + 우유 -> "불투명"
- 투명 플라스틱 컵 + 카페라떼 -> "불투명"
- 투명 플라스틱 컵 + 스무디 -> "불투명"

판단하기 어렵다면 "판단불가"를 사용한다.

container와 body_clarity를 혼동하지 않는다.
container는 컵 자체이고, body_clarity는 내용물이다.


[7. texture 규칙]

texture는 음료 본체에서 실제로 보이는 질감만 기록한다.
맛이나 메뉴명, 예상 재료를 근거로 추론하지 않는다.


[8. 얼음 규칙]

- 얼음이 하나라도 명확히 보이면 ice_presence = "있음".
- 충분히 관찰 가능하며 얼음이 없음을 확인할 수 있을 때만 "없음".
- 가림이나 사진 상태 때문에 확인하기 어렵다면 "판단불가".
- 얼음 존재는 확인되지만 양을 판단하기 어렵다면:
  ice_presence = "있음"
  ice_amount = "판단불가"
- ice_presence = "없음"이면 ice_amount = "없음".


[9. top_type 규칙]

top_type은 음료 표면의 주된 구조를 나타내는 배열이다.
실제로 동시에 보이는 구조를 모두 기록할 수 있다.

예:
["일반액체"]
["휘핑크림"]
["크림층"]
["휘핑크림", "아이스크림"]
["두꺼운거품", "크림층"]

특별한 구조 없이 일반적인 액체 표면이면 ["일반액체"]를 사용한다.
상단을 볼 수 없어 판단할 수 없다면 ["판단불가"]를 사용한다.
"판단불가"는 다른 값과 함께 사용하지 않는다.
동일한 값을 중복 기록하지 않는다.

아이스크림처럼 상단의 주된 구조로 분류한 요소는 toppings에 다시 넣지 않는다.


[10. toppings 규칙]

toppings는 top_type 위 또는 주변에 추가로 보이는 장식 요소다.
가루, 시럽/드리즐, 초콜릿, 쿠키, 견과류, 과일, 시리얼, 허브 등을 기록한다.

- 토핑이 없음을 충분히 확인할 수 있으면 []
- 상단이 가려졌거나 화면 밖이라 확인할 수 없으면 ["판단불가"]
- "판단불가"는 다른 값과 함께 사용하지 않는다.
- 동일한 값을 중복 기록하지 않는다.


topping_colors에는 toppings 및 top_type으로 분류된 상단 요소에서
실제로 보이는 주요 색을 기록한다.

- 상단 요소가 전혀 없으면 []
- 색을 판단할 수 없다면 ["판단불가"]
- 컵/로고/배경의 색은 포함하지 않는다.


[11. inclusions 규칙]

inclusions는 컵 안 음료 본체 내부에서 실제로 보이는 고형 요소만 기록한다.
예: 펄, 젤리, 과육, 과일조각, 초콜릿조각, 쿠키조각, 곡물.

표면 위에 놓인 장식은 inclusions가 아니라 toppings다.

- 없음을 충분히 확인할 수 있으면 []
- 가림 때문에 확인할 수 없다면 ["판단불가"]
- "판단불가"는 다른 값과 함께 사용하지 않는다.


[12. 전체 원칙]

보이지 않는 정보를 억지로 맞히지 않는다.
잘못된 구체적 값을 만드는 것보다 "판단불가"가 낫다.
항상 지정된 JSON 스키마만 반환한다.
`.trim();

// --------------------------------------------------
// Normalization helpers
// --------------------------------------------------

function normalizeArray(values, order) {
  if (!Array.isArray(values)) return [];

  const unique = [...new Set(values)];

  // 구체적인 값과 판단불가가 동시에 섞여 나오면
  // 구체적인 관찰값을 우선한다.
  const cleaned =
    unique.length > 1
      ? unique.filter((value) => value !== '판단불가')
      : unique;

  return cleaned.sort((a, b) => {
    const ai = order.indexOf(a);
    const bi = order.indexOf(b);

    if (ai === -1 && bi === -1) return a.localeCompare(b);
    if (ai === -1) return 1;
    if (bi === -1) return -1;
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
  if (!region) return null;

  // 관찰할 수 없는 영역은 검색용 설명에서 제외한다.
  if (
    region.visibility === '가려짐' ||
    region.visibility === '화면밖' ||
    region.visibility === '판단불가'
  ) {
    return null;
  }

  if (!isKnown(region.color)) return null;

  return `${label}(색=${region.color})`;
}

// --------------------------------------------------
// Canonical text
// --------------------------------------------------

function buildCanonicalText(fields) {
  const parts = [];

  const bodyColors = normalizeArray(
    fields.body_colors,
    COLORS,
  ).filter((value) => value !== '판단불가');

  if (bodyColors.length > 0) {
    parts.push(`본체색상:${bodyColors.join('+')}`);
  }

  if (isKnown(fields.color_pattern)) {
    parts.push(`색상구조:${fields.color_pattern}`);
  }

  const regionTexts = [
    regionToCanonical('상단', fields.body_regions?.top),
    regionToCanonical('중단', fields.body_regions?.middle),
    regionToCanonical('하단', fields.body_regions?.bottom),
  ].filter(Boolean);

  parts.push(...regionTexts);

  if (isKnown(fields.body_clarity)) {
    parts.push(`내용물투명도:${fields.body_clarity}`);
  }

  if (isKnown(fields.texture)) {
    parts.push(`질감:${fields.texture}`);
  }

  if (fields.ice_presence === '없음') {
    parts.push('얼음:없음');
  } else if (fields.ice_presence === '있음') {
    if (isKnown(fields.ice_amount) && fields.ice_amount !== '없음') {
      parts.push(`얼음:있음/${fields.ice_amount}`);
    } else {
      parts.push('얼음:있음');
    }
  }

  const topTypes = normalizeArray(fields.top_type, TOP_TYPES);

  if (
    topTypes.length > 0 &&
    !topTypes.includes('판단불가')
  ) {
    parts.push(`상단형태:${topTypes.join('+')}`);
  }

  const toppings = normalizeArray(fields.toppings, TOPPINGS);

  if (toppings.length === 0) {
    parts.push('토핑:없음');
  } else if (!toppings.includes('판단불가')) {
    parts.push(`토핑:${toppings.join('+')}`);
  }

  const toppingColors = normalizeArray(
    fields.topping_colors,
    COLORS,
  ).filter((value) => value !== '판단불가');

  if (toppingColors.length > 0) {
    parts.push(`상단장식색:${toppingColors.join('+')}`);
  }

  const inclusions = normalizeArray(
    fields.inclusions,
    INCLUSIONS,
  );

  if (inclusions.length === 0) {
    parts.push('내부요소:없음');
  } else if (!inclusions.includes('판단불가')) {
    parts.push(`내부요소:${inclusions.join('+')}`);
  }

  // container / occlusion / overall_visibility는 메뉴 고유 특징보다
  // 촬영 조건의 영향을 크게 받으므로 canonicalText에서 제외한다.

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
  const imageUrl = image.url || image.dataUrl;

  if (!imageUrl) {
    throw new Error(
      'describeImage: url 또는 dataUrl이 필요합니다.',
    );
  }

  const response = await client.chat.completions.create({
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
              '색상 구조는 정의된 기준에 따라 엄격히 판단해. ' +
              '컵 자체의 투명도와 음료 내용물의 투명도를 혼동하지 말고, ' +
              '가려진 부분은 절대 추측하지 마.',
          },

          {
            type: 'image_url',

            image_url: {
              url: imageUrl,
              detail: process.env.IMAGE_DETAIL || 'low',
            },
          },
        ],
      },
    ],

    response_format: {
      type: 'json_schema',
      json_schema: DESCRIPTION_SCHEMA,
    },
  });

  const message = response.choices?.[0]?.message;

  if (!message?.content) {
    throw new Error(
      'describeImage: GPT 응답에 content가 없습니다.',
    );
  }

  const fields = JSON.parse(message.content);

  const canonicalText = buildCanonicalText(fields);

  // 모델 분류 품질을 검사할 때만 활성화한다.
  if (process.env.DEBUG_IMAGE_DESCRIPTION === 'true') {
    console.log('[describeImage fields]');
    console.log(JSON.stringify(fields, null, 2));
  }

  return {
    fields,
    canonicalText,
  };
}

module.exports = { describeImage };