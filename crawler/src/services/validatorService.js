const menuSchema = require('../models/menuSchema');

class ValidatorService {
  static normalizeText(value) {
    if (value === undefined || value === null) return null;
    const str = String(value).replace(/\s+/g, ' ').trim();
    return str === '' ? null : str;
  }

  static normalizeNumber(value) {
    if (value === undefined || value === null || value === '') return null;
    if (typeof value === 'number') return Number.isNaN(value) ? null : value;

    const str = String(value).trim();
    if (!str) return null;

    const cleaned = str
      .replace(/,/g, '')
      .replace(/mg|g|kcal|ml|oz|㎖|㎎|%/gi, '')
      .trim();

    if (!cleaned) return null;

    const num = Number(cleaned);
    return Number.isNaN(num) ? null : num;
  }

  static normalizeArray(value) {
    if (Array.isArray(value)) {
      return [...new Set(value.map(v => this.normalizeText(v)).filter(Boolean))];
    }

    if (typeof value === 'string') {
      return [...new Set(
        value
          .split(/[,/|·\n]/)
          .map(v => this.normalizeText(v))
          .filter(Boolean)
      )];
    }

    return [];
  }

  static pickNutritionJson(rawData) {
    if (rawData?.nutrition_json && typeof rawData.nutrition_json === 'object') {
      return rawData.nutrition_json;
    }

    if (rawData?.nutrition && typeof rawData.nutrition === 'object') {
      return rawData.nutrition;
    }

    const extras = {};
    const reservedKeys = new Set([
      'brand_name', 'category', 'menu_name', 'description', 'size_standard', 'image_url',
      'menu_image_url', 'is_active', 'menu_type', 'calories', 'sugar', 'protein',
      'caffeine', 'saturated_fat', 'sodium', 'nutrition_json', 'nutrition',
      'allergy_info', 'allergies'
    ]);

    for (const [key, value] of Object.entries(rawData || {})) {
      if (reservedKeys.has(key)) continue;
      if (value === undefined || value === null || value === '') continue;
      extras[key] = value;
    }

    return Object.keys(extras).length > 0 ? extras : null;
  }

  static toRdsShape(rawData = {}) {
    const nutritionSource = rawData.nutrition_json || rawData.nutrition || {};

    return {
      brand_name: this.normalizeText(rawData.brand_name),
      category: this.normalizeText(rawData.category) || '기타',
      menu_name: this.normalizeText(rawData.menu_name),
      description: this.normalizeText(rawData.description),
      size_standard:
        this.normalizeText(rawData.size_standard) ||
        this.normalizeText(nutritionSource.size_standard) ||
        this.normalizeText(rawData.size),
      image_url:
        this.normalizeText(rawData.image_url) ||
        this.normalizeText(rawData.menu_image_url),
      is_active: typeof rawData.is_active === 'boolean' ? rawData.is_active : true,
      menu_type: this.normalizeText(rawData.menu_type) || 'regular',
      calories: this.normalizeNumber(rawData.calories ?? nutritionSource.calories),
      sugar: this.normalizeNumber(rawData.sugar ?? nutritionSource.sugar),
      protein: this.normalizeNumber(rawData.protein ?? nutritionSource.protein),
      caffeine: this.normalizeNumber(rawData.caffeine ?? nutritionSource.caffeine),
      saturated_fat: this.normalizeNumber(
        rawData.saturated_fat ?? nutritionSource.saturated_fat ?? nutritionSource.sat_fat
      ),
      sodium: this.normalizeNumber(rawData.sodium ?? nutritionSource.sodium),
      nutrition_json: this.pickNutritionJson(rawData),
      allergy_info: this.normalizeArray(rawData.allergy_info ?? rawData.allergies),
    };
  }

  static validate(rawData) {
    const normalizedData = this.toRdsShape(rawData);
    const result = menuSchema.safeParse(normalizedData);

    if (!result.success) {
      console.error(
        `❌ 검증 실패 [${rawData?.menu_name || normalizedData?.menu_name || 'unknown'}]:`,
        result.error.format()
      );
      return {
        isValid: false,
        data: null,
        error: result.error.format(),
        errors: result.error.errors,
        normalizedData,
      };
    }

    return {
      isValid: true,
      data: result.data,
      error: null,
      errors: null,
    };
  }
}

module.exports = ValidatorService;