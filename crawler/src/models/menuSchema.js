const { z } = require('zod');

const nullableNumber = z.preprocess((value) => {
  if (value === '' || value === undefined || value === null) return null;
  if (typeof value === 'number') return Number.isNaN(value) ? null : value;

  const cleaned = String(value)
    .trim()
    .replace(/,/g, '')
    .replace(/mg|g|kcal|ml|oz|㎖|㎎|%/gi, '')
    .trim();

  if (cleaned === '') return null;

  const num = Number(cleaned);
  return Number.isNaN(num) ? null : num;
}, z.number().nullable());

const nullableString = z.preprocess((value) => {
  if (value === undefined || value === null) return null;
  const str = String(value).replace(/\s+/g, ' ').trim();
  return str === '' ? null : str;
}, z.string().nullable());

const nullableObject = z.preprocess((value) => {
  if (value === undefined || value === null || value === '') return null;
  return value;
}, z.record(z.string(), z.any()).nullable());

// 크롤러마다 표기가 제각각인 알러지 이름을 하나의 대표 이름으로 합친다.
// 키에 없는 값은 트림된 원본 그대로 통과시킨다 (신규 변형 발견 시 여기에 추가).
const ALLERGY_ALIAS_MAP = {
  '계란': '알류',
  '난류': '알류',
  '달걀': '알류',
  '달걀 함유': '알류',
  '알류(달걀)': '알류',

  '닭가슴살': '닭고기',

  '대두 함유': '대두',
  '대두유': '대두',
  '대두유 함유': '대두',

  '돼지고기 함유': '돼지고기',

  '밀 함유': '밀',

  '복숭아 함유': '복숭아',

  '아몬드 함유': '아몬드',

  '아황산류 함유': '아황산류',

  '우유(우유변경 불가메뉴)': '우유',

  '조개류(굴)': '조개류',

  '토마토 함유': '토마토',

  '호두 함유': '호두',

  '쇠고기' : '소고기',
  
  '우유 함유' : '우유',
  '우유 (우유변경 불가메뉴)' : '우유',
  '라지 우유' : '우유',
  '미디엄 우유' : '우유',
};

// 실제 알러지 정보가 아니라 "정보 없음"을 뜻하는 크롤링 값 — 필터링해서 저장되지 않도록 한다.
const NO_ALLERGY_INFO_VALUES = new Set(['정보 없음']);

function normalizeAllergyName(value) {
  const trimmed = String(value).trim();
  if (NO_ALLERGY_INFO_VALUES.has(trimmed)) return null;
  return ALLERGY_ALIAS_MAP[trimmed] || trimmed;
}

const allergyArray = z.preprocess((value) => {
  if (value === undefined || value === null || value === '') return [];

  if (Array.isArray(value)) {
    return [...new Set(value.map(v => normalizeAllergyName(v)).filter(Boolean))];
  }

  if (typeof value === 'string') {
    return [...new Set(
      value
        .split(/[,/|·\n]/)
        .map(v => normalizeAllergyName(v))
        .filter(Boolean)
    )];
  }

  return [];
}, z.array(z.string().min(1)).default([]));

const menuSchema = z.object({
  brand_name: z.string().trim().min(1, 'brand_name은 필수입니다.'),
  category: z.string().trim().min(1, 'category는 필수입니다.'),
  menu_name: z.string().trim().min(1, 'menu_name은 필수입니다.'),

  description: nullableString.optional().default(null),
  size_standard: nullableString.optional().default(null),
  image_url: nullableString.optional().default(null),

  is_active: z.coerce.boolean().default(true),
  menu_type: z.string().trim().optional().default('regular'),

  calories: nullableNumber.optional().default(null),
  sugar: nullableNumber.optional().default(null),
  protein: nullableNumber.optional().default(null),
  caffeine: nullableNumber.optional().default(null),
  saturated_fat: nullableNumber.optional().default(null),
  sodium: nullableNumber.optional().default(null),

  nutrition_json: nullableObject.optional().default(null),
  allergy_info: allergyArray,
}).strict();

module.exports = menuSchema;