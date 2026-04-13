const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

function normalizeText(value) {
  if (value === undefined || value === null) return null;

  const text = String(value)
    .replace(/\u00a0/g, ' ')
    .replace(/\s+/g, ' ')
    .replace(/^⚬\s*/, '')
    .trim();

  if (!text || text === '-') return null;
  return text;
}

function htmlToTextWithBreaks(html) {
  if (!html) return null;

  const text = String(html)
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/&nbsp;/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n[ \t]+/g, '\n')
    .replace(/[ \t]{2,}/g, ' ')
    .trim();

  return text || null;
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
 * - itemBox 내부 post_숫자 패턴으로 메뉴 ID 추출
 * - 상세 URL은 /menu/{id} 로 구성
 */
function parseComposeCategoryPage(htmlContent, categoryLabel = '음료') {
  const $ = cheerio.load(htmlContent);
  const menuList = [];
  const seenIds = new Set();

  $('#masonry-container .itemBox').each((i, el) => {
    const $item = $(el);

    const title =
      normalizeText($item.find('h3.undertitle').first().text()) ||
      normalizeText($item.find('.caption .title').first().text());

    if (!title) return;

    const postIdAttr = $item.find('div[id^="post_"]').first().attr('id') || '';
    let menuId = null;

    const postIdMatch = postIdAttr.match(/^post_(\d+)$/);
    if (postIdMatch) {
      menuId = postIdMatch[1];
    }

    const href = $item.find('a[href*="/menu/"]').first().attr('href');
    if (href) {
      const hrefMatch = href.match(/\/menu\/(\d+)/);
      if (hrefMatch) {
        menuId = hrefMatch[1];
      }
    }

    if (!menuId || seenIds.has(menuId)) return;
    seenIds.add(menuId);

    let imageUrl = absoluteUrl($item.find('.rthumbnailimg').attr('src'));

    menuList.push({
      menuId,
      name: title,
      imageUrl: imageUrl || null,
      detailUrl: absoluteUrl(`/menu/${menuId}`),
      categoryLabel,
    });
  });

  return menuList;
}

function normalizeComposeSize(value) {
  const text = normalizeText(value);
  if (!text) return null;

  // 이미 단위가 붙어 있으면 그대로 사용
  if (/(ml|oz)/i.test(text)) return text;

  // 숫자만 있으면 ml 보정
  const num = parseNullableNumber(text);
  if (num !== null) {
    return `${num}ml`;
  }

  return text;
}

function normalizeComposeCategoryByName(menuName, currentCategory) {
  if (currentCategory && currentCategory !== '기타') {
    return currentCategory;
  }

  const name = (menuName || '')
    .replace(/^\s*(ICE|HOT)\s+/i, '')
    .trim();

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
 * - 설명/알레르기 정보는 현재 페이지에 없으므로 null / []
 * - 주요 영양성분은 top-level 컬럼
 * - 탄수화물, 지방, 옵션, 고카페인 문구 등은 nutrition_json에 저장
 */
function parseComposeDetail(detailHtml, baseInfo = {}, categoryLabel = '음료') {
  const $ = cheerio.load(detailHtml);

  const menuName =
    normalizeText($('h3.page-header').first().text()) ||
    baseInfo.name ||
    null;

  const siteCategory =
    normalizeText($('.viewinfo-bar li').first().text()) ||
    categoryLabel ||
    '음료';

  let imageUrl =
    absoluteUrl($('.restdocument img').first().attr('src')) ||
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

  $('.extra-row').each((i, row) => {
    const label = normalizeText($(row).find('.extra-left').first().text());
    const rawHtml = $(row).find('.extra-right').first().html() || '';
    const valueText =
      htmlToTextWithBreaks(rawHtml) ||
      normalizeText($(row).find('.extra-right').first().text());

    if (!label || !valueText) return;

    if (label.includes('용량')) {
      sizeStandard = normalizeComposeSize(valueText);
      return;
    }

    if (label.includes('열량')) {
      calories = parseNullableNumber(valueText);
      return;
    }

    if (label.includes('당류')) {
      sugar = parseNullableNumber(valueText);
      return;
    }

    if (label.includes('단백질')) {
      protein = parseNullableNumber(valueText);
      return;
    }

    if (label.includes('나트륨')) {
      sodium = parseNullableNumber(valueText);
      return;
    }

    if (label.includes('포화지방')) {
      saturatedFat = parseNullableNumber(valueText);
      return;
    }

    if (label.includes('카페인')) {
      caffeine = parseNullableNumber(valueText);

      if (valueText.includes('/') || valueText.includes('고카페인')) {
        nutritionJson.caffeine_raw = valueText;
      }
      if (valueText.includes('고카페인')) {
        nutritionJson.high_caffeine = true;
      }
      return;
    }

    if (label.includes('탄수화물')) {
      extraNutrition.carbohydrate = parseNullableNumber(valueText);
      return;
    }

    if (label === '지방' || label.includes('지방(g)')) {
      extraNutrition.fat = parseNullableNumber(valueText);
      return;
    }

    extraNutrition[label] = valueText;
  });

  if (Object.keys(extraNutrition).length > 0) {
    nutritionJson.extra_nutrition = extraNutrition;
  }

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
    calories,
    sugar,
    protein,
    caffeine,
    saturated_fat: saturatedFat,
    sodium,
    nutrition_json: Object.keys(nutritionJson).length > 0 ? nutritionJson : null,
    allergy_info: [],
  };
}

module.exports = { parseComposeCategoryPage, parseComposeDetail };