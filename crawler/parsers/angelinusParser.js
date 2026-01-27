const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

// ... (parseAngelImages, parseAngelDescription 함수는 기존과 동일하므로 생략, 아래 parseAngel만 수정) ...

// [기존 코드 유지]
const parseAngelImages = (orderHtml) => { /* ... 기존과 동일 ... */ 
  const infoMap = new Map();
  const IMAGE_BASE_URL = "https://img.lotteeatz.com";

  try {
    const regex = /var\s+pList\s*=\s*(\[.*?\]);/s;
    const match = orderHtml.match(regex);

    if (match && match[1]) {
      const jsonData = JSON.parse(match[1]);
      jsonData.forEach(item => {
        const normalize = (str) => str ? str.replace(/\s+/g, '') : '';
        const nameKey = normalize(item.dispNm); 
        const data = { imageUrl: "", productId: item.presPrdId || "" };
        if (item.imgSystemFileNm) {
          data.imageUrl = `${IMAGE_BASE_URL}${item.imgPath}${item.imgSystemFileNm}.${item.imgExtsn}`;
        }
        infoMap.set(nameKey, data);
      });
    }
  } catch (error) {
    console.error("[Angel] 이미지/ID JSON 파싱 실패:", error.message);
  }
  return infoMap;
};

const parseAngelDescription = (html) => { /* ... 기존과 동일 ... */
  const $ = cheerio.load(html);
  let description = $('.prod-detail-header .btext').text().trim();
  if (!description) description = $('.btext').text().trim();
  if (!description) description = $('.txt.scroll-con-y').text().trim();
  if (!description) description = $('.cont-inner .txt').first().text().trim();

  description = description.replace(/[\n\r]+/g, ' ').replace(/\s+/g, ' ').trim();
  
  const noticePatterns = ['*영양성분', '*고카페인', '※', '*알레르기'];
  let cutIndex = -1;
  noticePatterns.forEach(pattern => {
    const idx = description.indexOf(pattern);
    if (idx > -1) {
      if (cutIndex === -1 || idx < cutIndex) cutIndex = idx;
    }
  });

  if (cutIndex > -1) description = description.substring(0, cutIndex).trim();
  return description;
};
// [기존 코드 유지 끝]


/**
 * [3] 영양성분표 파싱 (음료만 필터링 기능 강화)
 */
const parseAngel = (nutritionHtml, infoMap) => {
  const $ = cheerio.load(nutritionHtml);
  const menus = [];

  let currentCategory = '';
  let currentName = '';

  // 1. 수집할 "음료" 관련 카테고리
  const BEVERAGE_CATEGORIES = [
    '신제품', '엔제린밸런스', 
    '커피', '디카페인커피', '스노우', '드링크', 'TEA', '과일티', '생과일'
  ];

  // 2. 수집을 완전히 중단할 시점 (이 카테고리들이 나오면 루프 종료)
  const STOP_CATEGORIES = ['Bakery', '케이크', '디저트', '쿠키', '샐러드'];

  // 3. 메뉴 이름에 포함되면 제외할 "푸드" 키워드 (신제품 등에 섞인 경우 대비)
  const FOOD_KEYWORDS = ['케이크', '푸딩', '반미', '토스트', '샌드위치', '브레드', '와플', '크로플', '스콘'];

  let stopParsing = false;

  $('table tbody tr').each((i, tr) => {
    if (stopParsing) return;

    const $tds = $(tr).find('td');
    const colCount = $tds.length;
    let dataOffset = 0;

    // --- 행 구조 분석 ---
    if (colCount === 17) {
      let rawCat = $tds.eq(0).text().trim();
      // 공백/슬래시 제거하여 정규화
      currentCategory = rawCat.replace(/[\n\t\s]+/g, '').replace('/', ''); 
      currentName = $tds.eq(1).text().trim();
      dataOffset = 2;
    } else if (colCount === 16) {
      currentName = $tds.eq(0).text().trim();
      dataOffset = 1;
    } else if (colCount === 15) {
      dataOffset = 0;
    } else {
      return;
    }

    // --- [필터링 1] 카테고리 기준 ---
    
    // 수집 중단 카테고리인지 확인 (Bakery 등)
    if (STOP_CATEGORIES.some(cat => currentCategory.includes(cat))) {
      stopParsing = true;
      return;
    }

    // 샌드위치/토스트는 STOP은 아니지만(중간에 껴있어서), 수집 대상도 아님 -> 건너뛰기(return)
    const isTargetCategory = BEVERAGE_CATEGORIES.some(cat => currentCategory.includes(cat));
    if (!isTargetCategory) {
      return; // 이번 행 스킵
    }

    // --- [필터링 2] 메뉴 이름 기준 (신제품 내 푸드 제외) ---
    if (FOOD_KEYWORDS.some(keyword => currentName.includes(keyword))) {
      return; // 이번 행 스킵
    }


    // --- 데이터 추출 (음료임이 확실시됨) ---
    const tempText = $tds.eq(dataOffset).text().trim(); // HOT/ICE
    const sizeText = $tds.eq(dataOffset + 1).text().trim(); // Size
    
    // 옵션명이 없거나 '-'인 경우 처리
    let optionStr = '';
    if (tempText && tempText !== '-') optionStr += tempText;
    if (sizeText && sizeText !== '-') optionStr += (optionStr ? `(${sizeText})` : sizeText);
    
    // 메뉴명 조합
    const fullName = optionStr ? `${currentName} [${optionStr}]` : currentName;

    // 영양 성분
    const nutrition = {
      calories_kcal: parseNum($tds.eq(dataOffset + 3).text()),
      sugar_g: parseNum($tds.eq(dataOffset + 5).text()),
      protein_g: parseNum($tds.eq(dataOffset + 7).text()),
      saturated_fat_g: parseNum($tds.eq(dataOffset + 9).text()),
      sodium_mg: parseNum($tds.eq(dataOffset + 11).text()),
      caffeine_mg: parseNum($tds.eq(dataOffset + 13).text()),
      size_standard: `${tempText} ${sizeText}`.replace(/-/g, '').trim() || '제공량 정보 없음'
    };

    const allergyText = $tds.eq(dataOffset + 14).text().trim();
    const allergyInfo = (allergyText === '-' || !allergyText) 
      ? [] 
      : allergyText.split(',').map(s => s.trim()).filter(s => s);

    const finalCategory = normalizeCategory('엔제리너스', currentCategory, currentName);
    
    // 이미지/ID 매칭
    const searchKey = currentName.replace(/\s+/g, '');
    const mappedInfo = infoMap.get(searchKey) || { imageUrl: "", productId: "" };

    menus.push({
      brand_name: '엔제리너스',
      category: finalCategory,
      menu_name: fullName,
      description: currentName, 
      is_active: true,
      menu_image_url: mappedInfo.imageUrl,
      menu_type: 'beverage', // 확실한 음료만 남김
      nutrition: nutrition,
      allergy_info: allergyInfo,
      productId: mappedInfo.productId
    });
  });

  return menus;
};

const parseNum = (text) => {
  if (!text) return 0;
  const clean = text.trim();
  if (clean === '-' || clean === '') return 0;
  if (clean.includes('미만')) return 0; 
  const num = parseFloat(clean.replace(/,/g, ''));
  return isNaN(num) ? 0 : num;
};

module.exports = { parseAngel, parseAngelImages, parseAngelDescription };