const cheerio = require('cheerio');

function parseMega(htmlContent) {
  const $ = cheerio.load(htmlContent);
  const menus = [];

  // 메가커피 메뉴 리스트 순회 (중복 ID 문제 해결을 위해 구체적인 셀렉터 사용)
  // HTML 구조상 ul#menu_list 안에 또 ul#menu_list가 있는 경우가 있어 li를 모두 찾습니다.
  $('#menu_list li').each((i, el) => {
    // 1. 기본 정보 추출
    // (수정 전) const nameNode = $(el).find('.cont_text_title b');
    
    // (수정 후) ⭐️ .first()를 추가해서 첫 번째(리스트에 있는 것)만 가져옵니다.
    const nameNode = $(el).find('.cont_text_title b').first();
    
    if (nameNode.length === 0) return;
    
    const name = nameNode.text().trim();
    const imgUrl = $(el).find('.cont_gallery_list_img img').attr('src');
    
    // 모달(상세 정보) 컨테이너
    const $modal = $(el).find('.inner_modal');

    // 2. 사이즈 및 칼로리 추출
    // 구조: <div class="cont_text_inner">24oz</div> <div class="cont_text_inner">1회 제공량 100kcal</div>
    let size = "";
    let calories = 0;

    $modal.find('.cont_text').each((j, textDiv) => {
      $(textDiv).find('.cont_text_inner').each((k, innerDiv) => {
        const text = $(innerDiv).text().trim();
        if (text.includes('1회 제공량')) {
          // "1회 제공량 468.1kcal" -> 468.1 추출
          const calMatch = text.match(/[\d\.]+/); 
          calories = calMatch ? parseFloat(calMatch[0]) : 0;
        } else if (text.match(/\d+ml|\d+oz/i)) {
          // "591ml" 또는 "20oz" 같은 사이즈 정보 추출
          size = text;
        }
      });
    });

    // 3. 영양 성분 추출
    // 구조: <ul><li>당류 10g</li><li>단백질 1g</li>...</ul>
    const nutrition = {
      calories_kcal: calories,
      sugar_g: 0,
      protein_g: 0,
      sodium_mg: 0,
      saturated_fat_g: 0,
      caffeine_mg: 0
    };

    $modal.find('.cont_list_small2 ul li').each((j, li) => {
      const text = $(li).text().trim(); // 예: "당류 69.5g"
      const numMatch = text.match(/[\d\.]+/); // 숫자만 추출
      const val = numMatch ? parseFloat(numMatch[0]) : 0;

      if (text.includes('당류')) nutrition.sugar_g = val;
      else if (text.includes('단백질')) nutrition.protein_g = val;
      else if (text.includes('나트륨')) nutrition.sodium_mg = val;
      else if (text.includes('포화지방')) nutrition.saturated_fat_g = val;
      else if (text.includes('카페인')) nutrition.caffeine_mg = val;
    });

    // 4. 알레르기 정보 추출 (수정된 코드)
    // 구조: <div class="cont_text_info"> 알레르기 성분 : 우유, 대두 <br> 고카페인 함유 </div>
    let allergyInfo = [];
    const allergyText = $modal.find('.cont_text_info').text();
    
    if (allergyText.includes('알레르기 성분')) {
      // (1) "알레르기 성분 :" 뒷부분만 가져오기
      let rawAllergy = allergyText.split('알레르기 성분 :')[1] || "";
      
      // (2) ⭐️ 핵심 수정: "고카페인 함유" 텍스트 및 관련 문구 제거
      // (정규식: '고카페인' 뒤에 공백이 있든 없든 '함유'까지 찾아서 지움)
      rawAllergy = rawAllergy.replace(/고카페인\s*함유/g, "");

      // (3) 쉼표(,)로 분리하고 앞뒤 공백(탭 문자 포함) 제거
      allergyInfo = rawAllergy.split(',')
        .map(s => s.trim()) // 여기서 \t(탭)들이 사라집니다.
        .filter(s => s && s !== "");
    }

    // 5. 카테고리 추론 (현재 페이지는 '음료' 페이지임)
    // 필요하다면 HTML 상단의 타이틀("DRINK MENU")을 파싱해서 넣을 수도 있음
    const category = "음료"; 

    // 6. 메뉴 타입 및 상태 (HOT/ICE 태그 확인)
    let is_active = true;
    const labels = $(el).find('.cont_gallery_list_label').text(); // "ICE", "HOT" 등
    
    // 최종 객체 생성
    menus.push({
      menu_name: name,
      brand_name: "메가MGC커피",
      menu_image_url: imgUrl,
      category: category,
      is_active: is_active,
      menu_type: "regular", // 메가커피는 리스트 상에 신메뉴 표시가 명확지 않아 일단 regular로 둡니다.
      size_standard: size || "1회 제공량",
      nutrition: nutrition,
      allergy_info: allergyInfo,
      description: labels // (선택) ICE/HOT 정보를 설명이나 별도 필드에 넣을 수 있음
    });
  });

  return menus;
}

module.exports = { parseMega };