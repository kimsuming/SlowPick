const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');
const { extractVariantFromName } = require('../utils/variantInfo');

function normalizeText(value) {
  if (value === undefined || value === null) return null;

  const text = String(value)
    .replace(/ /g, ' ')
    .replace(/\s+/g, ' ')
    .replace(/^⚬\s*/, '')
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
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('//')) return `https:${url}`;
  if (url.startsWith('/')) return `https://composecoffee.com${url}`;
  return `https://composecoffee.com/${url}`;
}

/**
 * 카테고리 페이지 파싱
 * - .cafemenu-menu-grid 내 a.cafemenu-menu-item 을 순회
 * - href 의 item_srl 쿼리파라미터로 메뉴 ID 추출
 */
function parseComposeCategoryPage(htmlContent, categoryLabel = '음료') {
  const $ = cheerio.load(htmlContent);
  const menuList = [];
  const seenIds = new Set();

  $('.cafemenu-menu-grid a.cafemenu-menu-item').each((i, el) => {
    const $item = $(el);

    const title = normalizeText($item.find('.cafemenu-menu-name').first().text());
    if (!title) return;

    const href = $item.attr('href') || '';
    const idMatch = href.match(/item_srl=(\d+)/);
    if (!idMatch) return;

    const menuId = idMatch[1];
    if (seenIds.has(menuId)) return;
    seenIds.add(menuId);

    const imageUrl = absoluteUrl($item.find('.cafemenu-menu-image img').first().attr('src'));

    menuList.push({
      menuId,
      name: title,
      imageUrl: imageUrl || null,
      detailUrl: absoluteUrl(href),
      categoryLabel,
    });
  });

  return menuList;
}

function normalizeComposeCategoryByName(menuName, currentCategory) {
  if (currentCategory && currentCategory !== '기타') {
    return currentCategory;
  }

  // 이 시점의 menuName은 이미 온도 표기(H-/I-)가 제거된 표시용 이름이다.
  const name = (menuName || '').trim();

  // 명확한 예외 보정
  if (/올데이오트/i.test(name)) return '라떼/밀크티';

  // 이건 이름상 커피 계열 가능성이 높아서 우선 커피로 보정
  // 실행 후 실제 사이트 분류와 다르면 이 한 줄만 수정하면 됨
  if (/매샷추/i.test(name)) return '커피';

  // 일반 규칙
  if (/아메리카노|에스프레소|더치|콜드브루|커피/i.test(name)) return '커피';
  if (/라떼|카페모카|카푸치노|플랫화이트|오트/i.test(name)) return '라떼/밀크티';
  if (/스무디|프라페|쉐이크/i.test(name)) return '스무디/프라페';
  if (/에이드|주스/i.test(name)) return '에이드/주스';
  if (/티|말차/i.test(name) && !/라떼/i.test(name)) return '티';

  return currentCategory || '기타';
}

/**
 * 상세 페이지 파싱
 * - 설명 정보는 현재 페이지에 없으므로 null
 * - 영양 정보는 .cafemenu-nutrition-item 의 value id(capacity/calories/sodium/
 *   carbohydrates/sugars/fat/saturated_fat/protein/caffeine)로 매핑
 * - 알레르기 정보는 .cafemenu-allergen-text 텍스트에서 라벨(<strong>)을 제거하고 파싱
 */
function parseComposeDetail(detailHtml, baseInfo = {}, categoryLabel = '음료') {
  const $ = cheerio.load(detailHtml);

  const rawMenuName =
    normalizeText($('#detailTitle').first().text()) ||
    normalizeText($('.cafemenu-detail-title').first().text()) ||
    baseInfo.name ||
    null;

  const extractedVariant = extractVariantFromName(rawMenuName || '');
  const menuName = rawMenuName ? extractedVariant.displayName : null;
  const { temperature, sizeLabel, sizeRank } = extractedVariant;

  const siteCategory = categoryLabel || '음료';

  const imageUrl =
    absoluteUrl($('#detailImage').first().attr('src')) ||
    absoluteUrl($('.cafemenu-detail-image').first().attr('src')) ||
    absoluteUrl($('meta[property="og:image"]').attr('content')) ||
    baseInfo.imageUrl ||
    null;

  let sizeStandard = null;
  let calories = null;
  let sugar = null;
  let protein = null;
  let caffeine = null;
  let saturatedFat = null;
  let sodium = null;

  const extraNutrition = {};
  const nutritionJson = {};

  $('.cafemenu-nutrition-item').each((i, item) => {
    const $item = $(item);
    const $value = $item.find('.cafemenu-nutrition-value').first();
    const id = $value.attr('id');
    const label = normalizeText($item.find('.cafemenu-nutrition-label').first().text());
    const valueText = normalizeText($value.text());
    const unit = normalizeText($value.find('.cafemenu-nutrition-unit').first().text()) || '';

    if (!valueText) return;
    const value = parseNullableNumber(valueText);

    switch (id) {
      case 'capacity':
        sizeStandard = value !== null ? `${value}${unit}` : valueText;
        return;

      case 'calories':
        calories = value;
        return;

      case 'sodium':
        sodium = value;
        return;

      case 'carbohydrates':
        extraNutrition.carbohydrate = value;
        return;

      case 'sugars':
        sugar = value;
        return;

      case 'fat':
        extraNutrition.fat = value;
        return;

      case 'saturated_fat':
        saturatedFat = value;
        return;

      case 'protein':
        protein = value;
        return;

      case 'caffeine':
        caffeine = value;
        if (valueText.includes('/') || valueText.includes('고카페인')) {
          nutritionJson.caffeine_raw = valueText;
        }
        if (valueText.includes('고카페인')) {
          nutritionJson.high_caffeine = true;
        }
        return;

      default:
        if (label) extraNutrition[label] = value !== null ? value : valueText;
    }
  });

  if (Object.keys(extraNutrition).length > 0) {
    nutritionJson.extra_nutrition = extraNutrition;
  }

  const allergySet = new Set();
  $('.cafemenu-allergen-list .cafemenu-allergen-text').each((i, el) => {
    const $text = $(el).clone();
    $text.find('strong').remove();

    normalizeText($text.text())
      ?.replace(/\([^)]*\)/g, '')
      .split(/[,/]|·|ㆍ/)
      .map(v => v.trim())
      .filter(Boolean)
      .filter(v => v !== '없음' && v !== '-')
      .forEach(v => allergySet.add(v));
  });

  let category = normalizeCategory('컴포즈커피', siteCategory, menuName || '');
  category = normalizeComposeCategoryByName(menuName, category);

  const menuType =
    category === '디저트' || /디저트|콤보/.test(siteCategory)
      ? 'food'
      : 'beverage';

  return {
    brand_name: '컴포즈커피',
    category,
    menu_name: menuName,
    description: null,
    size_standard: sizeStandard,
    image_url: imageUrl,
    is_active: true,
    menu_type: menuType,
    temperature,
    size_label: sizeLabel,
    size_rank: sizeRank,
    calories,
    sugar,
    protein,
    caffeine,
    saturated_fat: saturatedFat,
    sodium,
    nutrition_json: Object.keys(nutritionJson).length > 0 ? nutritionJson : null,
    allergy_info: Array.from(allergySet),
  };
}

module.exports = { parseComposeCategoryPage, parseComposeDetail };
