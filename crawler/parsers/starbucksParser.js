const cheerio = require('cheerio');

function parseStarbucks(htmlContent) {
  const $ = cheerio.load(htmlContent);
  const menus = [];
  const nutritionMap = new Map();

  // 1. 영양 성분 데이터 수집
  $('.m_coffee_info').each((i, div) => {
    const category = $(div).prevAll('h3').first().text().trim();

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

      nutritionMap.set(name, {
        category: category || '음료',
        nutrition,
      });
    });
  });

  // 2. 최종 메뉴 데이터 조립
  $('.menuDataSet').each((i, el) => {
    const name = $(el).find('dd').text().trim();
    const nutritionData = nutritionMap.get(name);

    if (!nutritionData) return;

    let imgUrl = $(el).find('img').attr('src');
    if (imgUrl && imgUrl.startsWith('//')) {
      imgUrl = 'https:' + imgUrl;
    }

    let menuType = 'regular';
    if ($(el).attr('new') === 'Y') menuType = 'new';
    else if ($(el).attr('sell') === '1') menuType = 'seasonal';

    menus.push({
      brand_name: '스타벅스',
      category: nutritionData.category,
      menu_name: name,
      image_url: imgUrl || '',
      is_active: true,
      menu_type: menuType,

      // DB 컬럼용 평탄화 필드
      calories: nutritionData.nutrition.calories,
      sugar: nutritionData.nutrition.sugar,
      protein: nutritionData.nutrition.protein,
      sodium: nutritionData.nutrition.sodium,
      saturated_fat: nutritionData.nutrition.saturated_fat,
      caffeine: nutritionData.nutrition.caffeine,
      size_standard: nutritionData.nutrition.size_standard,

      // 원본 영양 정보 보존용
      nutrition_json: nutritionData.nutrition,

      allergy_info: [],
      description: '',
    });
  });

  return menus;
}

module.exports = { parseStarbucks };