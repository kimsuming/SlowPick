const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');
const { TEMPERATURE } = require('../utils/variantInfo');

// 더벤티는 메뉴명 뒤에 "(라지/점보)", "(라지)" 같은 사이즈 안내가 붙어서 오는 경우가 있다.
// 이 정보는 이미 영양정보 표의 size_standard(예: "라지(600ml) / 점보(960ml)")에 따로
// 들어있으므로, 메뉴명에 붙은 괄호는 그냥 잘라낸다.
function stripTrailingSizeAnnotation(name) {
  if (!name) return name;
  return name.replace(/\s*\([^)]*\)\s*$/, '').trim();
}

// 설명 뒤에 "※ ..."나 "*..." 형태의 부가 안내(고카페인 기준, 영양성분 측정 기준 등)가
// 붙는 경우가 많아, 그런 마커가 처음 나오는 지점 앞까지만 설명으로 남긴다.
function truncateAtFootnoteMarker(text) {
  if (!text) return text;
  const idx = text.search(/[*※]/);
  return idx === -1 ? text : text.slice(0, idx).trim();
}

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

// 사이트에서 0을 "-"로 표기하는 경우가 있다 (예: 카페인 칸에 "-"만 있는 메뉴).
// 숫자가 아예 없는데 대시만 있으면 "정보 없음"이 아니라 0으로 본다.
const isDashOnly = (text) => /^[-–]+$/.test(String(text).trim());

const extractFirstNumber = (text) => {
  if (!text) return null;
  if (isDashOnly(text)) return 0;
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
 * "355 (Hot) / 315 (Iced)" -> { HOT: 355, ICE: 315, isSplit: true }
 * "266 (HOT / ICED)" -> { HOT: 266, ICE: 266, isSplit: true }
 * "564 (Iced)" -> { STANDARD: 564, impliedTemperature: 'ICED' }
 *   ("/"로 실제 두 값이 나열된 게 아니라 단일 값에 서빙 온도를 주석처럼 붙인 것 —
 *    이 메뉴가 그 온도로만 나온다는 뜻이지, 온도별로 다른 값이 있다는 뜻이 아니다.)
 */
const parseComplexValue = (text) => {
  const result = {};
  if (!text) return result;

  const cleanText = text.replace(/\s+/g, ' ').trim();
  const numberMatches = cleanText.match(/[\d.]+/g) || [];

  if (cleanText.includes('/') && numberMatches.length >= 2) {
    const parts = cleanText.split('/');
    const splitResult = {};

    parts.forEach(part => {
      const value = extractFirstNumber(part);
      if (value === null) return;

      if (/hot|따뜻/i.test(part)) splitResult.HOT = value;
      else if (/ice|iced|차가운/i.test(part)) splitResult.ICE = value;
    });

    if (Object.keys(splitResult).length > 0) {
      return { ...splitResult, isSplit: true };
    }
  }

  const value = extractFirstNumber(cleanText);
  if (value === null) return result;

  result.STANDARD = value;

  // 슬래시로 나열되지 않은 단일 값은 온도별로 다른 게 아니라 이 메뉴가 그 온도로만
  // 제공된다는 뜻이므로 STANDARD로 두고, 어떤 온도인지만 impliedTemperature에 남긴다.
  if (/hot/i.test(cleanText) && /ice|iced/i.test(cleanText)) {
    // 앙쪽 키워드가 다 있는데 슬래시가 없는 경우는 애매하므로 특정 온도로 단정하지 않는다.
  } else if (/hot|따뜻/i.test(cleanText)) {
    result.impliedTemperature = 'HOT';
  } else if (/ice|iced|차가운/i.test(cleanText)) {
    result.impliedTemperature = 'ICED';
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
  const finalName = stripTrailingSizeAnnotation(popupTitle || baseName);

  let popupImageUrl = $('.menu_desc_wrap .img_bx img').attr('src') || listImageUrl || null;
  if (popupImageUrl && !popupImageUrl.startsWith('http')) {
    popupImageUrl = `https://www.theventi.co.kr${popupImageUrl}`;
  }

  const descHtml = $('.menu_desc_wrap .txt_bx .txt').first().html() || '';

  const description = normalizeNullableText(
    truncateAtFootnoteMarker(
      descHtml
        .replace(/<br\s*\/?>/gi, '\n')
        .replace(/&nbsp;/gi, ' ')
        .replace(/<[^>]+>/g, ' ')
    )
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

  // 1차: 필드별로 파싱만 해두고, 이 메뉴에 실제로 온도별 분리 값("A / B" 형태)이
  // 있는지 먼저 판단한다. ("564 (Iced)"처럼 슬래시 없는 단일 값에 온도 주석만 붙은
  // 경우는 분리가 아니라 "이 메뉴는 그 온도로만 나온다"는 뜻이므로 분리로 치지 않는다 —
  // 안 그러면 아이스 전용 메뉴에도 칼로리 없는 가짜 HOT 변형이 생겨버린다.)
  const fieldParsed = {};
  let hasRealSplit = false;
  let impliedTemperature = null;

  nutritionFields.forEach((field, i) => {
    const text = $tds.eq(i + 1).text().trim();

    if (field === 'caffeine') {
      let caffeineValue = null;

      if (isDashOnly(text)) {
        caffeineValue = 0;
      } else {
        const numbers = extractAllNumbers(text);

        if (numbers.length === 1) {
          caffeineValue = numbers[0];
        } else if (numbers.length >= 2) {
          // 원두별 카페인처럼 복수 값이 있으면 최대값 저장, 원문은 nutrition_json에 보존
          caffeineValue = Math.max(...numbers);
        }
      }

      // 카페인 칸은 표에서 온도별로 나뉘지 않는 단일 값이라 항상 STANDARD로 취급한다.
      fieldParsed[field] = caffeineValue === null ? {} : { STANDARD: caffeineValue };
      return;
    }

    const parsed = parseComplexValue(text);
    fieldParsed[field] = parsed;

    if (parsed.isSplit) {
      hasRealSplit = true;
    } else if (parsed.impliedTemperature && !impliedTemperature) {
      impliedTemperature = parsed.impliedTemperature;
    }
  });

  // 2차: 실제로 온도별 분리가 있는 메뉴만 STANDARD 값을 HOT/ICE 양쪽의 기본값으로 채우고,
  // 분리가 전혀 없는 메뉴는 기존대로 STANDARD 한 줄에만 채운다.
  nutritionFields.forEach((field) => {
    const parsed = fieldParsed[field] || {};

    if (hasRealSplit) {
      if (parsed.STANDARD !== undefined) {
        tempNutrition.HOT[field] = parsed.STANDARD;
        tempNutrition.ICE[field] = parsed.STANDARD;
      }
      if (parsed.HOT !== undefined) tempNutrition.HOT[field] = parsed.HOT;
      if (parsed.ICE !== undefined) tempNutrition.ICE[field] = parsed.ICE;
    } else if (parsed.STANDARD !== undefined) {
      tempNutrition.STANDARD[field] = parsed.STANDARD;
    }
  });

  const variants = [];
  if (hasMeaningfulNutrition(tempNutrition.HOT)) variants.push('HOT');
  if (hasMeaningfulNutrition(tempNutrition.ICE)) variants.push('ICE');
  if (variants.length === 0) variants.push('STANDARD');

  const results = variants.map((variantKey) => {
    const temperature =
      variantKey === 'HOT' ? TEMPERATURE.HOT :
      variantKey === 'ICE' ? TEMPERATURE.ICED :
      impliedTemperature;

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
      menu_name: finalName,
      description,
      size_standard: nutriData.size_standard || null,
      image_url: popupImageUrl || null,
      is_active: true,
      menu_type: menuType,
      temperature,
      size_label: null,
      size_rank: null,
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