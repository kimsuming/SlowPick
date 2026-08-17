const { getClient } = require('./openaiClient');

const DESCRIPTION_SCHEMA = {
  name: 'drink_visual_description',
  strict: true,
  schema: {
    type: 'object',
    properties: {
      color: {
        type: 'string',
        enum: ['갈색', '연갈색', '흰색/우유색', '초록색', '분홍색', '노란색', '주황색', '빨간색', '보라색', '투명/무색', '기타'],
      },
      layered: { type: 'boolean' },
      has_cream: { type: 'boolean' },
      has_ice: { type: 'boolean' },
      opacity: { type: 'string', enum: ['투명', '반투명', '불투명'] },
      toppings: { type: 'string', description: '가루/시럽/과일 등 눈에 보이는 토핑, 없으면 "없음"' },
    },
    required: ['color', 'layered', 'has_cream', 'has_ice', 'opacity', 'toppings'],
    additionalProperties: false,
  },
};

const SYSTEM_PROMPT =
  '너는 카페 음료 사진의 시각적 특징만 객관적으로 분류하는 도구다. ' +
  '브랜드나 메뉴명을 추측하지 말고, 오직 눈에 보이는 색상/층분리/크림/얼음/투명도/토핑만 판단해서 지정된 스키마로 응답해.';

/**
 * @param {{ url?: string, dataUrl?: string }} image
 * @returns {Promise<{ fields: object, canonicalText: string }>}
 */
async function describeImage(image) {
  const client = getClient();
  const imageUrl = image.url || image.dataUrl;
  if (!imageUrl) throw new Error('describeImage: url 또는 dataUrl이 필요합니다.');

  const response = await client.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      {
        role: 'user',
        content: [
          { type: 'text', text: '이 음료 사진의 시각적 특징을 분류해줘.' },
          { type: 'image_url', image_url: { url: imageUrl } },
        ],
      },
    ],
    response_format: { type: 'json_schema', json_schema: DESCRIPTION_SCHEMA },
  });

  const fields = JSON.parse(response.choices[0].message.content);
  const canonicalText =
    `색상:${fields.color}, 층분리:${fields.layered ? '있음' : '없음'}, ` +
    `크림:${fields.has_cream ? '있음' : '없음'}, 얼음:${fields.has_ice ? '있음' : '없음'}, ` +
    `투명도:${fields.opacity}, 토핑:${fields.toppings || '없음'}`;

  return { fields, canonicalText };
}

module.exports = { describeImage };
