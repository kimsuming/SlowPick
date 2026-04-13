const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

/**
 * 1. 목록 페이지에서 클릭 대상 및 기본 정보 추출
 */
const getMenuUrls = (html) => {
  const $ = cheerio.load(html);
  const menuList = [];

  $('.menu_list > ul > li').each((index, element) => {
    const $el = $(element);

    const name = $el.find('.txt_bx .tit').text().trim();
    let imageUrl = $el.find('.img_bx img').attr('src') || null;

    if (imageUrl && !imageUrl.startsWith('http')) {
      imageUrl = `https://www.theventi.co.kr${imageUrl}`;
    }

    if (!name) return;

    menuList.push({
      index,
      name,
      imageUrl,
      clickSelector: `.menu_list > ul > li:nth-child(${index + 1}) a.popup-link`,
    });
  });

  return menuList;
};

const normalizeNullableText = (value) => {
  if (value === undefined || value === null) return null;

  const text = String(value).replace(/\s+/g, ' ').trim();
  if (!text || text === '-') return null;

  return text;
};

const extractFirstNumber = (text) => {
  if (!text) return null;
  const match = String(text).replace(/,/g, '').match(/-?\d+(?:\.\d+)?/);
  return match ? Number(match[0]) : null;
};

const extractAllNumbers = (text) => {
  if (!text) return [];
  const matches = String(text).replace(/,/g, '').match(/-?\d+(?:\.\d+)?/g);
  return matches ? matches.map(Number) : [];
};

/**
 * 예:
 * "355 (Hot) / 315 (Iced)" -> { HOT: 355, ICE: 315 }
 * "28 (28%) (HOT)" -> { HOT: 28 }
 * "266 (HOT / ICED)" -> { HOT: 266, ICE: 266 }
 */
const parseComplexValue = (text) => {
  const result = {};
  if (!text) return result;

  const cleanText = text.replace(/\s+/g, ' ').trim();
  const numberMatches = cleanText.match(/[\d.]+/g) || [];

  if (cleanText.includes('/') && numberMatches.length >= 2) {
    const parts = cleanText.split('/');

    parts.forEach(part => {
      const value = extractFirstNumber(part);
      if (value === null) return;

      if (/hot|따뜻/i.test(part)) result.HOT = value;
      else if (/ice|iced|차가운/i.test(part)) result.ICE = value;
    });

    if (Object.keys(result).length > 0) return result;
  }

  const value = extractFirstNumber(cleanText);
  if (value === null) return result;

  if (/hot/i.test(cleanText) && /ice|iced/i.test(cleanText)) {
    result.HOT = value;
    result.ICE = value;
  } else if (/hot/i.test(cleanText)) {
    result.HOT = value;
  } else if (/ice|iced/i.test(cleanText)) {
    result.ICE = value;
  } else {
    result.STANDARD = value;
  }

  return result;
};

const parseAllergyInfo = (text) => {
  const clean = normalizeNullableText(text);
  if (!clean) return [];

  return clean
    .replace(/^알레르기\s*(유발)?\s*(요인|성분)?\s*[:：]?\s*/i, '')
    .split(/[,/]|·|ㆍ/)
    .map(v => v.trim())
    .filter(Boolean)
    .filter(v => v !== '-');
};

const hasMeaningfulNutrition = (obj) => {
  if (!obj) return false;

  return [
    obj.calories,
    obj.sugar,
    obj.protein,
    obj.saturated_fat,
    obj.sodium,
    obj.caffeine,
  ].some(v => v !== undefined && v !== null);
};

const parseDetail = (detailHtml, basicInfo) => {
  const $ = cheerio.load(detailHtml);
  const { name: baseName, imageUrl: listImageUrl } = basicInfo;

  const popupTitle = $('.menu_desc_wrap .txt_bx .tit span').last().text().trim();
  const finalName = popupTitle || baseName;

  let popupImageUrl = $('.menu_desc_wrap .img_bx img').attr('src') || listImageUrl || null;
  if (popupImageUrl && !popupImageUrl.startsWith('http')) {
    popupImageUrl = `https://www.theventi.co.kr${popupImageUrl}`;
  }

  const descHtml = $('.menu_desc_wrap .txt_bx .txt').first().html() || '';

  const description = normalizeNullableText(
    descHtml
      .replace(/<br\s*\/?>/gi, '\n')
      .replace(/&nbsp;/gi, ' ')
      .replace(/<[^>]+>/g, ' ')
  );

  const $tds = $('.menu-ingredient table tbody tr td');

  const allergyText = $tds.eq(7).text().trim();
  const allergyList = parseAllergyInfo(allergyText);

  const category = normalizeCategory('더벤티', '음료', finalName);
  const menuType = category === '디저트' ? 'food' : 'beverage';

  const tempNutrition = {
    HOT: {},
    ICE: {},
    STANDARD: {},
  };

  const rawValues = {
    size_standard: normalizeNullableText($tds.eq(0).text()),
    calories: normalizeNullableText($tds.eq(1).text()),
    sugar: normalizeNullableText($tds.eq(2).text()),
    protein: normalizeNullableText($tds.eq(3).text()),
    saturated_fat: normalizeNullableText($tds.eq(4).text()),
    sodium: normalizeNullableText($tds.eq(5).text()),
    caffeine: normalizeNullableText($tds.eq(6).text()),
  };

  if (rawValues.size_standard) {
    tempNutrition.HOT.size_standard = rawValues.size_standard;
    tempNutrition.ICE.size_standard = rawValues.size_standard;
    tempNutrition.STANDARD.size_standard = rawValues.size_standard;
  }

  const nutritionFields = [
    'calories',
    'sugar',
    'protein',
    'saturated_fat',
    'sodium',
    'caffeine',
  ];

  nutritionFields.forEach((field, i) => {
    const text = $tds.eq(i + 1).text().trim();

    if (field === 'caffeine') {
      const numbers = extractAllNumbers(text);

      if (numbers.length === 1) {
        tempNutrition.STANDARD[field] = numbers[0];
      } else if (numbers.length >= 2) {
        // 원두별 카페인처럼 복수 값이 있으면 최대값 저장, 원문은 nutrition_json에 보존
        tempNutrition.STANDARD[field] = Math.max(...numbers);
      }

      return;
    }

    const parsed = parseComplexValue(text);

    if (parsed.HOT !== undefined) tempNutrition.HOT[field] = parsed.HOT;
    if (parsed.ICE !== undefined) tempNutrition.ICE[field] = parsed.ICE;
    if (parsed.STANDARD !== undefined) tempNutrition.STANDARD[field] = parsed.STANDARD;
  });

  const variants = [];
  if (hasMeaningfulNutrition(tempNutrition.HOT)) variants.push('HOT');
  if (hasMeaningfulNutrition(tempNutrition.ICE)) variants.push('ICE');
  if (variants.length === 0) variants.push('STANDARD');

  const results = variants.map((variantKey) => {
    let displayName = finalName;

    if (variantKey !== 'STANDARD' && !finalName.toUpperCase().includes(variantKey)) {
      displayName = `${finalName} [${variantKey}]`;
    }

    const nutriData = tempNutrition[variantKey] || {};

    const nutritionJson = {};
    Object.entries(rawValues).forEach(([key, value]) => {
      if (value && /hot|ice|iced|\/|따뜻|차가운|시그니처|다크|고카페인/i.test(value)) {
        nutritionJson[`${key}_raw`] = value;
      }
    });

    if (variantKey !== 'STANDARD') {
      nutritionJson.variant = variantKey;
    }

    return {
      brand_name: '더벤티',
      category,
      menu_name: displayName,
      description,
      size_standard: nutriData.size_standard || null,
      image_url: popupImageUrl || null,
      is_active: true,
      menu_type: menuType,
      calories: nutriData.calories ?? null,
      sugar: nutriData.sugar ?? null,
      protein: nutriData.protein ?? null,
      caffeine: nutriData.caffeine ?? null,
      saturated_fat: nutriData.saturated_fat ?? null,
      sodium: nutriData.sodium ?? null,
      nutrition_json: Object.keys(nutritionJson).length > 0 ? nutritionJson : null,
      allergy_info: allergyList,
    };
  });

  return results;
};

module.exports = { getMenuUrls, parseDetail };