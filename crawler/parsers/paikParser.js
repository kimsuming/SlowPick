const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

const parsePaik = (html) => {
  const $ = cheerio.load(html);
  const menus = [];

  // 빽다방 메뉴 리스트 순회
  $('.menu_list > ul > li').each((index, element) => {
    try {
      const $el = $(element);
      const $hover = $el.find('.hover'); // 상세 정보가 담긴 hover 영역

      // 1. 기본 정보 추출
      const name = $el.find('.menu_tit').text().trim(); // 예: 원조커피(ICED)
      let imageUrl = $el.find('.thumb img').attr('src');
      const description = $hover.find('.txt').text().trim().replace(/\s+/g, ' ');

      // 이미지 URL 보정
      if (imageUrl && !imageUrl.startsWith('http')) {
        imageUrl = `https://paikdabang.com${imageUrl}`; // 도메인 없는 경우 대비 (현재는 있어 보임)
      }

      // 2. 영양 성분 추출
      // 빽다방은 <table>이 아니라 <ul><li><div>...</div></li></ul> 구조임
      const nutrition = {
        calories_kcal: 0,
        sugar_g: 0,
        protein_g: 0,
        saturated_fat_g: 0,
        sodium_mg: 0,
        caffeine_mg: 0,
        size_standard: '정보 없음'
      };

      const nutrientMap = {
        '칼로리': 'calories_kcal',
        '당류': 'sugar_g',
        '단백질': 'protein_g',
        '포화지방': 'saturated_fat_g',
        '나트륨': 'sodium_mg',
        '카페인': 'caffeine_mg'
      };

      $hover.find('.ingredient_table li').each((i, li) => {
        const keyText = $(li).find('div').eq(0).text().trim(); // 예: 카페인 (mg)
        const valText = $(li).find('div').eq(1).text().trim(); // 예: 371

        // 키워드 매칭 (괄호 안 단위 무시하고 한글만 매칭)
        for (const [korKey, schemaKey] of Object.entries(nutrientMap)) {
          if (keyText.includes(korKey)) {
            // 숫자 변환 (콤마 제거 등)
            const valNum = parseFloat(valText.replace(/[^0-9.]/g, '')) || 0;
            nutrition[schemaKey] = valNum;
            break;
          }
        }
      });

      // 3. 알레르기 및 사이즈 정보 추출
      // p.menu_ingredient_basis 태그가 여러 개 있을 수 있음
      let allergyInfo = [];
      
      $hover.find('.menu_ingredient_basis').each((i, p) => {
        const text = $(p).text().trim(); // 예: ※ 알레르기 유발 성분 : 우유
        
        // 알레르기 정보 파싱
        if (text.includes('알레르기')) {
           // " : " 기준으로 자르고, 쉼표로 분리
           const parts = text.split(':');
           if (parts.length > 1) {
             allergyInfo = parts[1].split(',').map(s => s.trim()).filter(s => s);
           }
        }
        
        // 사이즈 정보 파싱 (1회 제공량 기준)
        if (text.includes('1회 제공량')) {
          const parts = text.split(':');
          if (parts.length > 1) {
            nutrition.size_standard = parts[1].trim(); // 예: 24oz
          }
        }
      });

      // 4. 카테고리 정규화
      // 빽다방은 페이지별로 카테고리가 나뉘어 있지만, 
      // 파서에서는 메뉴 이름 기반으로 다시 한 번 정규화하여 정확도 높임
      // (현재 페이지 타이틀이 "커피"이므로 기본값으로 커피 관련 키워드 사용 가능)
      const category = normalizeCategory('빽다방', '커피', name);

      // 5. 최종 데이터 구성
      const menuData = {
        brand_name: '빽다방',
        category: category,
        menu_name: name,
        description: description,
        is_active: true,
        menu_image_url: imageUrl || '',
        menu_type: 'beverage', // 커피 페이지이므로 음료로 고정
        nutrition: nutrition,
        allergy_info: allergyInfo
      };

      menus.push(menuData);

    } catch (err) {
      console.error(`[빽다방 파싱 에러] ${index}번째 항목:`, err.message);
    }
  });

  return menus;
};

module.exports = { parsePaik };