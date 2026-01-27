const { z } = require('zod');

const menuSchema = z.object({
  brand_name: z.string(),
  category: z.string(),
  menu_name: z.string().min(1),
  description: z.string().optional(), // "HOT" 등의 정보
  is_active: z.boolean().default(true),
  menu_image_url: z.string().url(), // 유효한 URL 형태인지 검증
  menu_type: z.string(),
  
  nutrition: z.object({
    caffeine_mg: z.number().nonnegative(),
    calories_kcal: z.number().nonnegative(),
    protein_g: z.number().nonnegative(),
    saturated_fat_g: z.number().nonnegative(),
    sodium_mg: z.number().nonnegative(),
    sugar_g: z.number().nonnegative().max(150), //비정상적인 당 수치 체크
    size_standard: z.string()
  }),
  
  allergy_info: z.array(z.string()).default([]) // 배열 형태 검증
});

module.exports = menuSchema;