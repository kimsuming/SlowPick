const cheerio = require('cheerio');

function parseStarbucks(htmlContent) {
  const $ = cheerio.load(htmlContent);
  const menus = [];

  // 1. 영양 성분 데이터를 먼저 수집해서 '이름'을 키(Key)로 하는 Map(사전) 만들기
  // (이렇게 하면 나중에 이미지 리스트를 돌면서 이름으로 영양 정보를 빠르게 찾을 수 있습니다)
  const nutritionMap = new Map();

  $('.m_coffee_info').each((i, div) => {
    // 현재 영양 정보 덩어리가 속한 '카테고리' 찾기 (바로 위에 h3 태그가 있음)
    const category = $(div).prevAll('h3').first().text().trim();

    // 각 메뉴 이름(p.tit)과 영양 정보(ul) 쌍을 순회
    $(div).find('p.tit').each((j, titleElem) => {
      const name = $(titleElem).text().trim();
      const $ul = $(titleElem).next('ul'); // 이름 바로 밑에 있는 ul 태그

      // 숫자만 추출하는 헬퍼 함수 (예: "10" -> 10, "-" -> 0)
      const getNum = (dtText) => {
        const val = $ul.find(`dt:contains("${dtText}")`).next('dd').text().trim();
        return val === '-' ? 0 : parseFloat(val);
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
        }
      });
    });
  });

  // 2. 이미지와 상태 정보가 있는 리스트(menuDataSet)를 순회하며 최종 데이터 조립
  $('.menuDataSet').each((i, el) => {
    const name = $(el).find('dd').text().trim();
    
    // 위에서 만든 Map에서 영양 정보 가져오기
    const nutritionData = nutritionMap.get(name);

    // 영양 정보가 있는 메뉴만 DB에 저장 (MD상품 등 제외)
    if (nutritionData) {

      // 이미지 URL 처리 (//로 시작하면 https: 붙여주기)
      let imgUrl = $(el).find('img').attr('src');
      if (imgUrl && imgUrl.startsWith('//')) {
        imgUrl = 'https:' + imgUrl;
      }

      // 메뉴 상태 판별 (new="Y", sell="1" 등 속성 확인)
      let menuType = 'regular';
      if ($(el).attr('new') === 'Y') {
        menuType = 'new';
      } else if ($(el).attr('sell') === '1') {
        menuType = 'seasonal';
      }

      // 최종 객체 생성
      const menuObj = {
        menu_name: name,
        brand_name: "스타벅스",
        menu_image_url: imgUrl,
        category: nutritionData.category, // 아까 Map에 저장해둔 카테고리 사용
        is_active: true,
        menu_type: menuType,
        size_standard: "Tall (355ml)", // 스타벅스 기본 기준
        nutrition: nutritionData.nutrition
      };

      menus.push(menuObj);
    }
  });

  return menus;
}

module.exports = { parseStarbucks };