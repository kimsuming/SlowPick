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

  const match = String(value)
    .replace(/,/g, '')
    .match(/-?\d+(?:\.\d+)?/);

  return match ? Number(match[0]) : null;
}

function absoluteUrl(url) {
  if (!url) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('//')) return `https:${url}`;
  if (url.startsWith('/')) return `https://paikdabang.com${url}`;
  return `https://paikdabang.com/${url}`;
}

function cleanPaikCategory(value) {
  const text = normalizeText(value);
  if (!text) return null;

  return text
    .replace(/\s+/g, '')
    .replace(/^커피$/, '커피')
    .replace(/^디카페인$/, '디카페인')
    .replace(/^기타$/, '기타')
    .replace(/^라떼\/밀크티$/, '라떼/밀크티')
    .replace(/^스무디\/프라페$/, '스무디/프라페');
}

function cleanPaikDescription(value) {
  const text = normalizeText(value);
  if (!text) return null;

  return text
    // 설명 뒤에 붙는 ※ 문구 제거
    .replace(/※\s*카페인이\s*일부\s*함유되어\s*있습니다\.\s*\(.*?\)\s*/gi, ' ')
    .replace(/\*?\s*고카페인\s*함유\s*\)?\s*/gi, ' ')
    .replace(/어린이\s*\/?\s*임산부.*?섭취에\s*주의/gi, ' ')
    .replace(/\(매장\s*상황에\s*따라\s*판매하지\s*않을\s*수\s*있습니다\.\)/gi, ' ')
    // 깨진 띄어쓰기 일부 보정
    .replace(/민\s+감한/g, '민감한')
    .replace(/사람\s+은/g, '사람은')
    .replace(/카페인에\s+민감한/g, '카페인에 민감한')
    .replace(/\s{2,}/g, ' ')
    .trim();
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
    .filter(v => v !== '없음' && v !== '-');
}

function extractPageHint($) {
  const candidates = [
    $('.sub_visual h2').first().text(),
    $('.sub_menu .on').first().text(),
    $('.tab_menu .on').first().text(),
    $('.menu_tab .on').first().text(),
    $('title').first().text(),
  ];

  const joined = candidates
    .map(v => normalizeText(v))
    .filter(Boolean)
    .join(' ');

  if (/디저트|빵|브레드|베이커리|쿠키|케이크|샌드/i.test(joined)) {
    return '디저트';
  }
  if (/티|tea/i.test(joined)) {
    return '티';
  }
  if (/에이드|주스/i.test(joined)) {
    return '에이드/주스';
  }
  if (/스무디|프라페|쉐이크|빙수/i.test(joined)) {
    return '스무디/프라페';
  }
  if (/라떼|밀크티|ccino|카푸치노/i.test(joined)) {
    return '라떼/밀크티';
  }
  if (/커피/i.test(joined)) {
    return '커피';
  }

  return '음료';
}

function normalizePaikCategory(menuName, pageHint) {
  let category = normalizeCategory('빽다방', pageHint || '음료', menuName || '');

  if (category && category !== '기타') {
    return category;
  }

  const name = menuName || '';

  if (/브레드|빵|쿠키|케이크|샌드|토스트|디저트|베이글|크로플/i.test(name)) {
    return '디저트';
  }
  if (/라떼|밀크티|카페모카|카푸치노|슈페너|아인슈페너/i.test(name)) {
    return '라떼/밀크티';
  }
  if (/에이드|주스/i.test(name)) {
    return '에이드/주스';
  }
  if (/스무디|프라페|쉐이크|빙수|슬러시/i.test(name)) {
    return '스무디/프라페';
  }
  if (/티|아이스티|캐모마일|히비스커스|유자차|레몬티/i.test(name)) {
    return '티';
  }
  if (/커피|아메리카노|에스프레소|콜드브루|더치/i.test(name)) {
    return '커피';
  }

  return category || pageHint || '기타';
}

const parsePaik = (html) => {
  const $ = cheerio.load(html);
  const menus = [];
  const pageHint = extractPageHint($);

  $('.menu_list > ul > li').each((index, element) => {
    try {
      const $el = $(element);
      const $hover = $el.find('.hover');

      const name = normalizeText($el.find('.menu_tit').text());
      if (!name) return;

      let imageUrl = absoluteUrl($el.find('.thumb img').attr('src'));

      const description = cleanPaikDescription($hover.find('.txt').text());

      let calories = null;
      let sugar = null;
      let protein = null;
      let saturatedFat = null;
      let sodium = null;
      let caffeine = null;
      let sizeStandard = null;

      const extraNutrition = {};
      const nutritionJson = {};

      const nutrientMap = {
        calories: ['칼로리', '열량'],
        sugar: ['당류'],
        protein: ['단백질'],
        saturated_fat: ['포화지방'],
        sodium: ['나트륨'],
        caffeine: ['카페인'],
      };

      $hover.find('.ingredient_table li').each((i, li) => {
        const keyText = normalizeText($(li).find('div').eq(0).text()) || '';
        const valText = normalizeText($(li).find('div').eq(1).text());

        if (!keyText || !valText) return;

        let matched = false;

        for (const [schemaKey, korKeys] of Object.entries(nutrientMap)) {
          if (korKeys.some(kor => keyText.includes(kor))) {
            const value = parseNullableNumber(valText);

            if (schemaKey === 'calories') calories = value;
            else if (schemaKey === 'sugar') sugar = value;
            else if (schemaKey === 'protein') protein = value;
            else if (schemaKey === 'saturated_fat') saturatedFat = value;
            else if (schemaKey === 'sodium') sodium = value;
            else if (schemaKey === 'caffeine') caffeine = value;

            matched = true;
            break;
          }
        }

        if (!matched) {
          if (keyText.includes('탄수화물')) {
            extraNutrition.carbohydrate = parseNullableNumber(valText);
          } else if (keyText === '지방' || keyText.includes('지방')) {
            extraNutrition.fat = parseNullableNumber(valText);
          } else {
            extraNutrition[keyText] = valText;
          }
        }
      });

      let allergyInfo = [];

      $hover.find('.menu_ingredient_basis').each((i, p) => {
        const text = normalizeText($(p).text());
        if (!text) return;

        if (text.includes('알레르기')) {
          allergyInfo = parseAllergyText(text);
        }

        if (
          text.includes('1회 제공량') ||
          text.includes('컵용량') ||
          text.includes('사이즈')
        ) {
          const rawSize = text.includes(':')
            ? text.split(':').slice(1).join(':').trim()
            : text;

          sizeStandard = normalizeText(rawSize);
        }
      });

      if (Object.keys(extraNutrition).length > 0) {
        nutritionJson.extra_nutrition = extraNutrition;
      }

      let category = normalizePaikCategory(name, pageHint);
      category = cleanPaikCategory(category);

      const menuType = category === '디저트' ? 'food' : 'beverage';

      menus.push({
        brand_name: '빽다방',
        category,
        menu_name: name,
        description,
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
        allergy_info: allergyInfo,
      });
    } catch (err) {
      console.error(`[빽다방 파싱 에러] ${index}번째 항목:`, err.message);
    }
  });

  return menus;
};

module.exports = { parsePaik };