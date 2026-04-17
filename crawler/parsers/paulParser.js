const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

function normalizeText(value) {
  if (value === undefined || value === null) return null;

  const text = String(value)
    .replace(/\s+/g, ' ')
    .trim();

  if (!text || text === '-') return null;
  return text;
}

function parseNullableNumber(value) {
  if (value === undefined || value === null) return null;

  const match = String(value)
    .replace(/,/g, '')
    .match(/-?\d+(?:\.\d+)?/);

  return match ? Number(match[0]) : null;
}

function absoluteUrl(url) {
  if (!url) return null;
  if (url.startsWith('http')) return url;
  return `https://www.baristapaulbassett.co.kr${url}`;
}

function parseAllergyText(text) {
  const clean = normalizeText(text);
  if (!clean) return [];

  return clean
    .replace(/^알레르기\s*[:：]?\s*/i, '')
    .split(/[,/]|·|ㆍ/)
    .map(v => v.trim())
    .filter(Boolean)
    .filter(v => v !== '없음' && v !== '-');
}

function normalizePaulMenuName(rawName) {
  let name = normalizeText(rawName);
  if (!name) {
    return {
      menuName: null,
      temperature: null,
      sizeCode: null,
      rawName: rawName || null,
    };
  }

  const rawNormalized = name;

  let temperature = null;
  let sizeCode = null;

  // 앞의 H / I 제거
  // 예: H고창 땅콩 카페라떼S / I체리블라썸 카페라떼S
  const prefixMatch = name.match(/^([HI])\s*(.+)$/);
  if (prefixMatch) {
    const code = prefixMatch[1];
    const rest = prefixMatch[2]?.trim();

    if (rest) {
      temperature = code === 'H' ? 'HOT' : 'ICE';
      name = rest;
    }
  }

  // 뒤의 S / G 제거
  // 예: 체리블라썸 카페라떼S -> 체리블라썸 카페라떼
  const suffixMatch = name.match(/^(.*?)([SG])$/);
  if (suffixMatch) {
    const body = suffixMatch[1]?.trim();
    const code = suffixMatch[2];

    // 끝 문자가 단순 사이즈 코드일 때만 제거
    // "LATTE G" 같은 정상 이름 오탐 방지용 최소 조건
    if (body && /[가-힣A-Za-z0-9)]$/.test(body)) {
      sizeCode = code;
      name = body;
    }
  }

  if (temperature) {
    name = `${name} [${temperature}]`;
  }

  return {
    menuName: name,
    temperature,
    sizeCode,
    rawName: rawNormalized,
  };
}

/**
 * 1. 리스트 페이지 파싱
 * main.js에서 parsePaulBassettList(listHtml, catId) 형태로 호출해야 함
 */
function parsePaulBassettList(htmlContent, cid1 = 'A') {
  const $ = cheerio.load(htmlContent);
  const items = [];
  const seen = new Set();

  $('a[onclick*="goView"]').each((i, el) => {
    const onClickAttr = $(el).attr('onclick');
    if (!onClickAttr) return;

    const idMatch = onClickAttr.match(/goView\('([^']+)'\)/);
    if (!idMatch) return;

    const menuId = idMatch[1];
    if (seen.has(menuId)) return;
    seen.add(menuId);

    const detailUrl = `https://www.baristapaulbassett.co.kr/menu/View.pb?cid1=${cid1}&cid2=&dpid=${menuId}`;

    const $clone = $(el).find('.txtArea').first().clone();
    $clone.find('span').remove();

    let name = $clone.text().trim();
    if (!name) {
      name = $(el).find('.txtArea').text().trim() || '이름 파싱 실패';
    }

    let imgUrl = $(el).find('img').attr('src');
    if (imgUrl && !imgUrl.startsWith('http')) {
      imgUrl = `https://www.baristapaulbassett.co.kr${imgUrl}`;
    }

    items.push({
      menuId,
      name,
      imgUrl: imgUrl || null,
      detailUrl,
    });
  });

  return items;
}

function parseNutritionBlock($, $context) {
  if (!$context || $context.length === 0) return null;

  const sizeLabelText = normalizeText($context.find('.sizeMl').first().text());
  const sizeNumberText = normalizeText($context.find('.sizeMl span').first().text());

  let sizeStandard = null;
  if (sizeNumberText) {
    if (/oz/i.test(sizeLabelText || '')) {
      sizeStandard = `${sizeNumberText}oz`;
    } else {
      sizeStandard = `${sizeNumberText}ml`;
    }
  } else if (sizeLabelText) {
    sizeStandard = sizeLabelText
      .replace(/제공량\s*\(?ml\)?/gi, '')
      .replace(/제공량\s*\(?oz\)?/gi, '')
      .trim() || sizeLabelText;
  }

  const data = {
    block_id: $context.attr('id') || null,
    size_standard: sizeStandard,
    calories: null,
    sugar: null,
    protein: null,
    caffeine: null,
    saturated_fat: null,
    sodium: null,
    extra_nutrients: {},
  };

  $context.find('ul li').each((i, li) => {
    const label = normalizeText($(li).find('.tit').text()) || normalizeText($(li).text());
    const valueText = normalizeText($(li).find('.num').text()) || normalizeText($(li).text());
    const value = parseNullableNumber(valueText);

    if (!label) return;

    if (label.includes('열량')) data.calories = value;
    else if (label.includes('당류')) data.sugar = value;
    else if (label.includes('단백질')) data.protein = value;
    else if (label.includes('나트륨')) data.sodium = value;
    else if (label.includes('포화지방')) data.saturated_fat = value;
    else if (label.includes('카페인')) data.caffeine = value;
    else if (value !== null) data.extra_nutrients[label] = value;
  });

  const hasAnyValue =
    data.size_standard ||
    data.calories !== null ||
    data.sugar !== null ||
    data.protein !== null ||
    data.caffeine !== null ||
    data.saturated_fat !== null ||
    data.sodium !== null ||
    Object.keys(data.extra_nutrients).length > 0;

  return hasAnyValue ? data : null;
}

/**
 * 2. 상세 페이지 파싱
 * - 여러 사이즈 블록이 있으면 pSize_S 우선
 * - 나머지 블록은 nutrition_json에 보관
 */
function parsePaulBassettDetail(htmlContent, baseInfo = {}) {
  const $ = cheerio.load(htmlContent);

  const $dt = $('.menuTit dl dt').first().clone();
  $dt.find('span').remove();

  const rawName = normalizeText($dt.text()) || baseInfo.name || null;
  const normalizedNameInfo = normalizePaulMenuName(rawName);
  const name = normalizedNameInfo.menuName || baseInfo.name || null;
  const description = normalizeText($('.menuTit dl dd').first().text());

  let imgUrl = absoluteUrl($('.menuSlide img').first().attr('src'));
  if (!imgUrl) {
    imgUrl = baseInfo.imgUrl || null;
  }

  const nutritionBlocks = [];

  const $sizeSections = $('[id^="pSize_"]');
  if ($sizeSections.length > 0) {
    $sizeSections.each((i, el) => {
      const parsed = parseNutritionBlock($, $(el));
      if (parsed) nutritionBlocks.push(parsed);
    });
  } else {
    const parsed = parseNutritionBlock($, $('.nutritional').first());
    if (parsed) nutritionBlocks.push(parsed);
  }

  const primaryNutrition =
    nutritionBlocks.find(block => block.block_id === 'pSize_S') ||
    nutritionBlocks.find(block => block.block_id === 'pSize_R') ||
    nutritionBlocks[0] || {
      size_standard: null,
      calories: null,
      sugar: null,
      protein: null,
      caffeine: null,
      saturated_fat: null,
      sodium: null,
      extra_nutrients: {},
    };

  let allergyInfo = [];
  $('.info li').each((i, li) => {
    const label = normalizeText($(li).find('span').first().text());
    if (label && label.includes('알레르기')) {
      const fullText = normalizeText($(li).text()) || '';
      const textWithoutLabel = fullText.replace(label, '').trim();
      allergyInfo = parseAllergyText(textWithoutLabel);
    }
  });

  const category = normalizeCategory('폴 바셋', '음료', name || '');
  const menuType = category === '디저트' ? 'food' : 'beverage';

  const nutritionJson = {};

  if (Object.keys(primaryNutrition.extra_nutrients || {}).length > 0) {
    nutritionJson.extra_nutrients = primaryNutrition.extra_nutrients;
  }

  if (nutritionBlocks.length > 1) {
    nutritionJson.additional_sizes = nutritionBlocks
      .filter(block => block !== primaryNutrition)
      .map(block => ({
        block_id: block.block_id || null,
        size_standard: block.size_standard || null,
        calories: block.calories,
        sugar: block.sugar,
        protein: block.protein,
        caffeine: block.caffeine,
        saturated_fat: block.saturated_fat,
        sodium: block.sodium,
        extra_nutrients:
          Object.keys(block.extra_nutrients || {}).length > 0
            ? block.extra_nutrients
            : null,
      }));
  }

  return {
    brand_name: '폴 바셋',
    menu_name: name || baseInfo.name || null,
    category,
    description,
    size_standard: primaryNutrition.size_standard || null,
    image_url: imgUrl || null,
    is_active: true,
    menu_type: menuType,
    calories: primaryNutrition.calories ?? null,
    sugar: primaryNutrition.sugar ?? null,
    protein: primaryNutrition.protein ?? null,
    caffeine: primaryNutrition.caffeine ?? null,
    saturated_fat: primaryNutrition.saturated_fat ?? null,
    sodium: primaryNutrition.sodium ?? null,
    nutrition_json: Object.keys(nutritionJson).length > 0 ? nutritionJson : null,
    allergy_info: allergyInfo,
  };
}

module.exports = { parsePaulBassettList, parsePaulBassettDetail };