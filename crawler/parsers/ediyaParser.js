const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

function parseEdiya(htmlContent) {
  const $ = cheerio.load(htmlContent);
  const menus = [];

  // 1. "영양성분 보기" 클릭 이벤트가 있는 링크를 순회
  $('a[onclick^="show_nutri"]').each((i, link) => {
    
    const name = $(link).find('span').text().trim();
    if (!name) return;

    // 부모 li 요소를 먼저 찾습니다.
    const $li = $(link).closest('li');

    // 2. 이미지 URL 추출 로직 수정 ⭐️
    // li 내부의 이미지 중 pro_detail(팝업) 안에 있는 gif 등을 제외하고 
    // 실제 메뉴 이미지(보통 png)를 찾습니다.
    let imgUrl = $li.find('img').not('.pro_detail img').attr('src');
    
    // 만약 위 방법으로도 안 잡힌다면, .png 확장자를 가진 이미지를 우선적으로 찾습니다.
    if (!imgUrl || imgUrl.endsWith('.gif')) {
        imgUrl = $li.find('img[src$=".png"]').attr('src') || $li.find('img').first().attr('src');
    }

    if (imgUrl && !imgUrl.startsWith('http')) {
      imgUrl = `https://www.ediya.com${imgUrl}`;
    }

    // 3. 연결된 영양 정보 ID 추출 및 상세 div 선택
    const onClickAttr = $(link).attr('onclick');
    const idMatch = onClickAttr.match(/'(\d+)'/);
    if (!idMatch) return;

    const targetId = `nutri_${idMatch[1]}`;
    const $detail = $(`#${targetId}`);

    if ($detail.length === 0) return;

    // 4. 영양 성분 추출 (이전과 동일)
    const nutrition = {
      calories_kcal: 0,
      sugar_g: 0,
      protein_g: 0,
      sodium_mg: 0,
      saturated_fat_g: 0,
      caffeine_mg: 0,
      size_standard: "정보 없음"
    };

    const sizeText = $detail.find('.pro_size').text();
    if (sizeText.includes(':')) {
      nutrition.size_standard = sizeText.split(':')[1].trim();
    }

    $detail.find('.pro_nutri dl').each((j, dl) => {
      const label = $(dl).find('dt').text().trim();
      const valueStr = $(dl).find('dd').text().trim();
      const numMatch = valueStr.match(/[\d\.]+/);
      const val = numMatch ? parseFloat(numMatch[0]) : 0;

      if (label.includes('칼로리')) nutrition.calories_kcal = val;
      else if (label.includes('당류')) nutrition.sugar_g = val;
      else if (label.includes('단백질')) nutrition.protein_g = val;
      else if (label.includes('나트륨')) nutrition.sodium_mg = val;
      else if (label.includes('포화지방')) nutrition.saturated_fat_g = val;
      else if (label.includes('카페인')) nutrition.caffeine_mg = val;
    });

    // 5. 알레르기 및 설명 추출
    let allergyInfo = [];
    const allergyText = $detail.find('.pro_allergy').text();
    if (allergyText.includes(':')) {
      const rawAllergy = allergyText.split(':')[1];
      if (rawAllergy) {
        allergyInfo = rawAllergy.split(',')
          .map(s => s.trim())
          .filter(s => s !== "");
      }
    }

    let description = "";
    $detail.find('.detail_txt p').each((k, p) => {
      const txt = $(p).text().trim();
      if (txt) description += txt + " ";
    });

    // 6. 카테고리 매핑
    const standardCategory = normalizeCategory("이디야", "음료", name);

    menus.push({
      brand_name: "이디야커피",
      menu_name: name,
      menu_image_url: imgUrl || "",
      category: standardCategory,
      is_active: true,
      menu_type: "regular",
      nutrition: nutrition,
      allergy_info: allergyInfo,
      description: description.trim()
    });
  });

  return menus;
}

module.exports = { parseEdiya };