const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

/**
 * 1. 목록 페이지에서 메뉴 ID 및 기본 정보 추출
 */
const getMenuUrls = (html) => {
  const $ = cheerio.load(html);
  const menuList = [];

  // 더벤티 메뉴 리스트 순회
  $('.menu_list > ul > li').each((index, element) => {
    const $el = $(element);
    const $link = $el.find('a.popup-link');
    
    // 기본 정보 추출
    const name = $el.find('.txt_bx .tit').text().trim();
    let imageUrl = $el.find('.img_bx img').attr('src');
    const linkHref = $link.attr('href'); // 예: all-view.new.html?uid=502

    if (name && linkHref) {
      // 이미지 URL 절대경로 변환
      if (imageUrl && !imageUrl.startsWith('http')) {
        imageUrl = `https://www.theventi.co.kr${imageUrl}`;
      }

      menuList.push({
        name: name,
        // 상세 페이지 URL 구성 (상대경로 대응)
        detailUrl: `https://www.theventi.co.kr/new2022/menu/${linkHref}`,
        imageUrl: imageUrl
      });
    }
  });

  return menuList;
};

/**
 * 복잡한 영양성분 텍스트 파싱 헬퍼 함수
 * 예: "355 (Hot) / 315 (Iced)" -> { HOT: 355, ICE: 315 }
 * 예: "28 (28%) (HOT)" -> { HOT: 28 }
 * 예: "266 (HOT / ICED)" -> { HOT: 266, ICE: 266 }
 */
const parseComplexValue = (text) => {
  const result = {};
  if (!text) return result;

  const cleanText = text.replace(/\s+/g, ' ').trim();
  
  // 1. 슬래시(/)로 구분된 경우 (값 자체가 다른 경우)
  if (cleanText.includes('/')) {
    const parts = cleanText.split('/');
    
    // "266 (HOT / ICED)" 같은 케이스 예외 처리 (숫자는 하나인데 라벨이 슬래시)
    // 숫자가 2개 이상 발견되면 분리된 데이터로 간주
    const numberMatches = cleanText.match(/[\d\.]+/g);
    if (numberMatches && numberMatches.length >= 2) {
      parts.forEach(part => {
        const val = parseFloat((part.match(/[\d\.]+/) || ['0'])[0]);
        if (part.match(/hot|따뜻/i)) result.HOT = val;
        else if (part.match(/ice|iced|차가운/i)) result.ICE = val;
      });
      return result;
    }
  }

  // 2. 값이 하나이거나, 공통 적용되는 경우
  const val = parseFloat((cleanText.match(/[\d\.]+/) || ['0'])[0]);
  
  if (cleanText.match(/hot/i) && cleanText.match(/ice/i)) {
    result.HOT = val;
    result.ICE = val;
  } else if (cleanText.match(/hot/i)) {
    result.HOT = val;
  } else if (cleanText.match(/ice/i)) {
    result.ICE = val;
  } else {
    // 아무 표시 없으면 Standard (단일 메뉴)
    result.STANDARD = val;
  }

  return result;
};

/**
 * 2. 상세 페이지 파싱
 */
const parseDetail = (detailHtml, basicInfo) => {
  const $ = cheerio.load(detailHtml);
  const { name: baseName, imageUrl } = basicInfo;

  const description = $('.menu_desc_wrap .txt_bx .txt').first().clone().children().remove().end().text().trim();
  
  // 알레르기 정보 추출 (테이블 마지막 컬럼)
  let allergyList = [];
  const allergyText = $('.menu-ingredient table tbody tr td').last().text().trim();
  if (allergyText && allergyText !== '-') {
    allergyList = allergyText.split(',').map(s => s.trim()).filter(s => s);
  }

  // 카테고리 정규화
  // 더벤티는 페이지별로 모드가 나뉘지만, 파서 내부에서는 이름 기반으로 확실하게 처리
  const category = normalizeCategory("더벤티", "음료", baseName);
  const menuType = category === "디저트" ? "food" : "beverage";

  // 영양성분 데이터 수집을 위한 임시 저장소
  const tempNutrition = {
    HOT: {}, ICE: {}, STANDARD: {}
  };

  // 테이블 컬럼 인덱스 매핑 (더벤티 테이블 순서 고정)
  // 0: 1회제공량, 1: 열량, 2: 당류, 3: 단백질, 4: 포화지방, 5: 나트륨, 6: 카페인, 7: 알레르기
  const fieldByIndex = [
    'size_standard', 'calories_kcal', 'sugar_g', 'protein_g', 'saturated_fat_g', 'sodium_mg', 'caffeine_mg'
  ];

  const $tds = $('.menu-ingredient table tbody tr td');

  // 각 영양소별로 파싱하여 임시 저장소에 배분
  fieldByIndex.forEach((field, idx) => {
    const text = $tds.eq(idx).text().trim();
    
    if (field === 'size_standard') {
      // 사이즈는 텍스트 그대로 사용하되, HOT/ICE 구분 로직은 별도 처리 안함 (보통 동일함)
      tempNutrition.HOT[field] = text;
      tempNutrition.ICE[field] = text;
      tempNutrition.STANDARD[field] = text;
    } else {
      // 숫자 데이터 파싱
      const parsed = parseComplexValue(text);
      if (parsed.HOT !== undefined) tempNutrition.HOT[field] = parsed.HOT;
      if (parsed.ICE !== undefined) tempNutrition.ICE[field] = parsed.ICE;
      if (parsed.STANDARD !== undefined) tempNutrition.STANDARD[field] = parsed.STANDARD;
    }
  });

  // 최종 결과 배열 생성
  const results = [];
  
  // 어떤 변형(Variant)들이 존재하는지 확인
  const variants = [];
  if (Object.keys(tempNutrition.HOT).length > 1) variants.push('HOT');
  if (Object.keys(tempNutrition.ICE).length > 1) variants.push('ICE');
  if (variants.length === 0) variants.push('STANDARD'); // HOT/ICE 구분이 없으면 Standard

  variants.forEach(variantKey => {
    // 이름 뒤에 옵션 붙이기 (Standard는 생략)
    let displayName = baseName;
    if (variantKey !== 'STANDARD') {
      // 이미 이름에 (HOT) 등이 포함되어 있는지 확인 후 중복 방지
      if (!baseName.toUpperCase().includes(variantKey)) {
        displayName = `${baseName} [${variantKey}]`;
      }
    }

    // 영양 데이터 채우기 (누락된 값은 0)
    const nutriData = tempNutrition[variantKey] || {};
    
    results.push({
      brand_name: "더벤티",
      category: category,
      menu_name: displayName,
      description: description,
      is_active: true,
      menu_image_url: imageUrl || "",
      menu_type: menuType,
      allergy_info: allergyList,
      nutrition: {
        calories_kcal: nutriData.calories_kcal || 0,
        sugar_g: nutriData.sugar_g || 0,
        protein_g: nutriData.protein_g || 0,
        saturated_fat_g: nutriData.saturated_fat_g || 0,
        sodium_mg: nutriData.sodium_mg || 0,
        caffeine_mg: nutriData.caffeine_mg || 0,
        size_standard: nutriData.size_standard || "제공량 정보 없음"
      }
    });
  });

  return results;
};

module.exports = { getMenuUrls, parseDetail };