// src/parsers/starbucksParser.js
const cheerio = require('cheerio');

function parseStarbucks(htmlContent) {
  const $ = cheerio.load(htmlContent);
  const menus = [];
  const nutritionMap = new Map();

  // 1. 영양 성분 데이터 수집 (Map 생성)
  $('.m_coffee_info').each((i, div) => {
    const category = $(div).prevAll('h3').first().text().trim();

    $(div).find('p.tit').each((j, titleElem) => {
      const name = $(titleElem).text().trim();
      const $ul = $(titleElem).next('ul');

      const getNum = (dtText) => {
        const val = $ul.find(`dt:contains("${dtText}")`).next('dd').text().trim();
        const num = parseFloat(val.replace(/[^0-9.]/g, '')); // 숫자와 소수점만 추출
        return isNaN(num) ? 0 : num;
      };

      nutritionMap.set(name, {
        category: category,
        nutrition: {
          calories_kcal: getNum('칼로리'),
          sugar_g: getNum('당류'),
          protein_g: getNum('단백질'),
          sodium_mg: getNum('나트륨'),
          saturated_fat_g: getNum('포화지방'),
          caffeine_mg: getNum('카페인'),
          size_standard: "Tall (355ml)" // ⭐️ nutrition 내부로 이동
        }
      });
    });
  });

  // 2. 최종 데이터 조립
  $('.menuDataSet').each((i, el) => {
    const name = $(el).find('dd').text().trim();
    const nutritionData = nutritionMap.get(name);

    if (nutritionData) {
      let imgUrl = $(el).find('img').attr('src');
      if (imgUrl && imgUrl.startsWith('//')) {
        imgUrl = 'https:' + imgUrl;
      }

      let menuType = 'regular';
      if ($(el).attr('new') === 'Y') menuType = 'new';
      else if ($(el).attr('sell') === '1') menuType = 'seasonal';

      menus.push({
        brand_name: "스타벅스",
        category: nutritionData.category || "음료",
        menu_name: name,
        menu_image_url: imgUrl || "",
        is_active: true,
        menu_type: menuType,
        nutrition: nutritionData.nutrition,
        allergy_info: [], // ⭐️ 스키마 필수 필드 추가
        description: ""   // ⭐️ 스키마 필수 필드 추가
      });
    }
  });

  return menus;
}

module.exports = { parseStarbucks };