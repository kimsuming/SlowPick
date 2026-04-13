const cheerio = require('cheerio');

const STARBUCKS_BASE_URL = 'https://www.starbucks.co.kr';

function normalizeText(value = '') {
  return String(value)
    .replace(/\r/g, '')
    .replace(/\u00a0/g, ' ')
    .replace(/[ \t]+/g, ' ')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function toAbsoluteUrl(url = '') {
  if (!url) return '';
  if (url.startsWith('//')) return `https:${url}`;
  if (url.startsWith('/')) return `${STARBUCKS_BASE_URL}${url}`;
  return url;
}

function parseStarbucksAllergy(raw = '') {
  const text = normalizeText(raw);
  if (!text) return [];

  return [...new Set(
    text
      .replace(/^알레르기\s*유발요인\s*:\s*/i, '')
      .replace(/@/g, '/')
      .replace(/,/g, '/')
      .split('/')
      .map(item => normalizeText(item))
      .filter(Boolean)
  )];
}

function parseStarbucksAjaxDetail(responseData) {
  const view = responseData?.view || responseData?.data?.view || null;

  if (!view) {
    return {
      description: '',
      allergy_info: [],
    };
  }

  return {
    // 사용자가 앞서 원하던 설명 본문
    description: normalizeText(view.content || ''),
    // product_factor에 표시되는 알레르기 원본
    allergy_info: parseStarbucksAllergy(view.allergy || ''),
  };
}

function parseStarbucks(htmlContent) {
  const $ = cheerio.load(htmlContent);
  const menus = [];
  const nutritionMap = new Map();

  $('.m_coffee_info').each((i, div) => {
    const category = $(div).prevAll('h3').first().text().trim() || '음료';

    $(div).find('p.tit').each((j, titleElem) => {
      const name = $(titleElem).text().trim();
      const $ul = $(titleElem).next('ul');

      const getNum = (dtText) => {
        const val = $ul.find(`dt:contains("${dtText}")`).next('dd').text().trim();
        const num = parseFloat(val.replace(/[^0-9.]/g, ''));
        return Number.isNaN(num) ? null : num;
      };

      const nutrition = {
        calories: getNum('칼로리'),
        sugar: getNum('당류'),
        protein: getNum('단백질'),
        sodium: getNum('나트륨'),
        saturated_fat: getNum('포화지방'),
        caffeine: getNum('카페인'),
        size_standard: 'Tall (355ml)',
      };

      nutritionMap.set(name, { category, nutrition });
    });
  });

  $('.menuDataSet').each((i, el) => {
    const name = $(el).find('dd').text().trim();
    const nutritionData = nutritionMap.get(name);
    if (!nutritionData) return;

    const $link = $(el).find('a.goDrinkView').first();
    const productId = ($link.attr('prod') || '').trim();

    let imgUrl = toAbsoluteUrl($(el).find('img').attr('src') || '');

    let menuType = 'regular';
    if ($(el).attr('new') === 'Y') menuType = 'new';
    else if ($(el).attr('sell') === '1') menuType = 'seasonal';

    menus.push({
      brand_name: '스타벅스',
      category: nutritionData.category,
      menu_name: name,
      description: '',
      size_standard: nutritionData.nutrition.size_standard,
      image_url: imgUrl || '',
      is_active: true,
      menu_type: menuType,

      calories: nutritionData.nutrition.calories,
      sugar: nutritionData.nutrition.sugar,
      protein: nutritionData.nutrition.protein,
      caffeine: nutritionData.nutrition.caffeine,
      saturated_fat: nutritionData.nutrition.saturated_fat,
      sodium: nutritionData.nutrition.sodium,

      nutrition_json: nutritionData.nutrition,
      allergy_info: [],

      product_id: productId || null,
    });
  });

  return menus;
}

module.exports = {
  parseStarbucks,
  parseStarbucksAjaxDetail,
};