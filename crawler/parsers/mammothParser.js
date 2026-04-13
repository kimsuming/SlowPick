const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

function normalizeText(value) {
  if (value === undefined || value === null) return null;

  const text = String(value)
    .replace(/\u00a0/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  if (!text || text === '-' || text === '–') return null;
  return text;
}

function parseNullableNumber(value) {
  if (value === undefined || value === null) return null;

  const str = String(value)
    .trim()
    .replace(/,/g, '');

  if (!str || str === '-' || str === '–') return null;

  const match = str.match(/-?\d+(?:\.\d+)?/);
  return match ? Number(match[0]) : null;
}

function absoluteUrl(url) {
  if (!url) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('//')) return `https:${url}`;
  if (url.startsWith('/')) return `https://mmthcoffee.com${url}`;
  return `https://mmthcoffee.com/${url}`;
}

function parseAllergyText(text) {
  const clean = normalizeText(text);
  if (!clean) return [];

  const raw = clean.includes(':')
    ? clean.split(':').slice(1).join(':').trim()
    : clean;

  return raw
    .split(/[,/]|·|ㆍ/)
    .map(v => v.trim())
    .filter(Boolean)
    .filter(v => v !== '-' && v !== '없음');
}

function inferOriginalCategory($li) {
  const classText = ($li.closest('[class*="cate"]').attr('class') || '').toLowerCase();
  const nearbyHeading = normalizeText(
    $li.closest('[class*="cate"]').find('h3, h4, strong, .title').first().text()
  ) || '';

  if (
    classText.includes('cate04') ||
    /디저트|베이커리|푸드|브레드|쿠키|케이크|샌드|와플/i.test(nearbyHeading)
  ) {
    return '디저트';
  }

  return '음료';
}

function cleanDescriptionText(value) {
  const text = normalizeText(value);
  if (!text) return null;

  return text
    .replace(/\s{2,}/g, ' ')
    .replace(/([가-힣])\s+([를을이가은는와과도만에의로으로])/g, '$1$2')
    .trim();
}

function normalizeMammothCategory(menuName, currentCategory) {
  if (currentCategory && currentCategory !== '기타') {
    return currentCategory;
  }

  const name = (menuName || '').replace(/\s*\[(HOT|ICE)\]\s*$/i, '').trim();

  if (/아메리카노|매머드\s*커피|꿀\s*커피|헤이즐넛\s*커피|스노우\s*매머드\s*커피|디카페인.*커피/i.test(name)) {
    return '커피';
  }

  if (/라떼|카페\s*라떼|헤이즐넛\s*라떼/i.test(name)) {
    return '라떼/밀크티';
  }

  if (/아이스티|티\b/i.test(name)) {
    return '티';
  }

  if (/에이드|주스/i.test(name)) {
    return '에이드/주스';
  }

  if (/스무디|프라페|쉐이크/i.test(name)) {
    return '스무디/프라페';
  }

  return currentCategory || '기타';
}

/**
 * 1. 목록 페이지 파싱
 * - 매머드커피 / 매머드 익스프레스 공용
 * - 기존 인터페이스 유지
 */
const getMenuIds = (html) => {
  const $ = cheerio.load(html);
  const menuList = [];
  const seenIds = new Set();

  $('.cate li').each((i, el) => {
    const $li = $(el);

    const name =
      normalizeText($li.find('.txt_wrap strong').first().text()) ||
      normalizeText($li.find('strong').first().text());

    const href =
      $li.find('a').attr('href') ||
      $li.find('a').attr('onclick') ||
      '';

    const idMatch = href.match(/goViewB\((\d+)\)/);
    if (!name || !idMatch || !idMatch[1]) return;

    const id = idMatch[1];
    if (seenIds.has(id)) return;
    seenIds.add(id);

    menuList.push({
      name,
      id,
      originalCategory: inferOriginalCategory($li),
    });
  });

  return menuList;
};

/**
 * 2. 상세(Modal HTML) 파싱
 * - 동적 컬럼 매핑
 * - RDS 평탄 구조 반환
 * - 기존 인터페이스 유지
 */
const parseDetail = (detailHtml, baseInfo = {}) => {
  const $ = cheerio.load(detailHtml);
  const {
    name: baseName,
    originalCategory = '음료',
    brandName = '매머드커피',
  } = baseInfo;

  // [1] 설명 / 알레르기
  const textLines = [];

  $('.txt_area p, .txt_area li, .txt_area div').each((i, el) => {
    const txt = normalizeText($(el).text());
    if (txt) textLines.push(txt);
  });

  if (textLines.length === 0) {
    const fallbackText = normalizeText($('.txt_area').text());
    if (fallbackText) textLines.push(fallbackText);
  }

  let allergyList = [];
  const descriptionParts = [];

  textLines.forEach(line => {
    if (/알레르기/i.test(line) && line.includes(':')) {
      allergyList = parseAllergyText(line);
    } else {
      descriptionParts.push(line);
    }
  });

  const description =
    descriptionParts.length > 0
      ? cleanDescriptionText(descriptionParts.join(' '))
      : null;

  // [2] 이미지
  const imageUrl = absoluteUrl($('.img_wrap img').attr('src'));

  // [3] 카테고리 / 타입
  let normalizedCategory = normalizeCategory(
    brandName,
    originalCategory,
    baseName || ''
  );

  normalizedCategory = normalizeMammothCategory(baseName, normalizedCategory);

  const menuType =
    normalizedCategory === '디저트' || originalCategory === '디저트'
      ? 'food'
      : 'beverage';

  // [4] 헤더 분석
  const validColumns = [];

  $('.i_table table thead tr th').each((idx, th) => {
    if (idx === 0) return;

    const headerText = normalizeText($(th).text());
    if (!headerText) return;

    let optionName = 'STANDARD';
    let sizeStr = headerText;

    if (/HOT/i.test(headerText)) {
      optionName = 'HOT';
    } else if (/ICE|ICED|아이스/i.test(headerText)) {
      optionName = 'ICE';
    }

    const sizeMatch = headerText.match(/\((.*?)\)/);
    if (sizeMatch && sizeMatch[1]) {
      sizeStr = normalizeText(sizeMatch[1]) || headerText;
    }

    validColumns.push({
      colIndex: idx,
      optionName,
      size: sizeStr || null,
      headerText,
    });
  });

  if (validColumns.length === 0) return [];

  // [5] variant 초기화
  const variants = validColumns.map(col => ({
    colIndex: col.colIndex,
    optionName: col.optionName,
    headerText: col.headerText,
    size_standard: col.size || null,
    calories: null,
    sugar: null,
    protein: null,
    caffeine: null,
    saturated_fat: null,
    sodium: null,
    extra_nutrients: {},
  }));

  const nutrientMap = {
    calories: ['칼로리', '열량'],
    sugar: ['당류'],
    protein: ['단백질'],
    sodium: ['나트륨'],
    caffeine: ['카페인'],
    saturated_fat: ['포화지방'],
  };

  const extraNutrientKeyMap = {
    탄수화물: 'carbohydrate',
    지방: 'fat',
    트랜스지방: 'trans_fat',
    콜레스테롤: 'cholesterol',
    식이섬유: 'dietary_fiber',
  };

  $('.i_table table tbody tr').each((i, tr) => {
    const $tds = $(tr).find('td');
    const labelText = normalizeText($tds.eq(0).text()) || '';

    let targetKey = null;
    for (const [schemaKey, korLabels] of Object.entries(nutrientMap)) {
      if (korLabels.some(kor => labelText.includes(kor))) {
        targetKey = schemaKey;
        break;
      }
    }

    variants.forEach(variant => {
      const valText = normalizeText($tds.eq(variant.colIndex).text());
      const value = parseNullableNumber(valText);

      if (targetKey) {
        variant[targetKey] = value;
        return;
      }

      for (const [korLabel, jsonKey] of Object.entries(extraNutrientKeyMap)) {
        if (labelText.includes(korLabel)) {
          variant.extra_nutrients[jsonKey] = value;
          return;
        }
      }
    });
  });

  // [6] 최종 결과 생성
  return variants.map(variant => {
    let suffix = '';
    if (variant.optionName !== 'STANDARD') {
      const upperBase = (baseName || '').toUpperCase();
      if (!upperBase.includes(variant.optionName)) {
        suffix = ` [${variant.optionName}]`;
      }
    }

    const nutritionJson = {};
    if (Object.keys(variant.extra_nutrients).length > 0) {
      nutritionJson.extra_nutrition = variant.extra_nutrients;
    }
    if (
      variant.headerText &&
      variant.headerText !== variant.size_standard &&
      /\(|HOT|ICE|ICED|아이스/i.test(variant.headerText)
    ) {
      nutritionJson.header_raw = variant.headerText;
    }

    return {
      brand_name: brandName,
      category: normalizedCategory,
      menu_name: `${baseName || ''}${suffix}`.trim(),
      description,
      size_standard: variant.size_standard,
      image_url: imageUrl,
      is_active: true,
      menu_type: menuType,
      calories: variant.calories,
      sugar: variant.sugar,
      protein: variant.protein,
      caffeine: variant.caffeine,
      saturated_fat: variant.saturated_fat,
      sodium: variant.sodium,
      nutrition_json: Object.keys(nutritionJson).length > 0 ? nutritionJson : null,
      allergy_info: allergyList,
    };
  });
};

module.exports = { getMenuIds, parseDetail };