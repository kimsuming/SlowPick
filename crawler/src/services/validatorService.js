const menuSchema = require('../models/menuSchema');

class ValidatorService {
  static validate(rawData) {
    const result = menuSchema.safeParse(rawData);

    if (!result.success) {
      console.error(`❌ 검증 실패 [${rawData.menu_name}]:`, result.error.format());
      return { isValid: false, errors: result.error.errors };
    }

    return { isValid: true, data: result.data };
  }
}

module.exports = ValidatorService;