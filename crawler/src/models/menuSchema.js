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

const allergyArray = z.preprocess((value) => {
  if (value === undefined || value === null || value === '') return [];

  if (Array.isArray(value)) {
    return [...new Set(value.map(v => String(v).trim()).filter(Boolean))];
  }

  if (typeof value === 'string') {
    return [...new Set(
      value
        .split(/[,/|·\n]/)
        .map(v => v.trim())
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