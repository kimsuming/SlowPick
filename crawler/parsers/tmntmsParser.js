const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

/**
 * 숫자 파싱 헬퍼 함수
 * - "-" 또는 빈 문자열이면 0 반환
 * - 숫자와 소수점만 남기고 파싱
 */
const parseNum = (text) => {
  if (!text) return 0;
  
  const clean = text.trim();
  
  // "-" 표시는 0으로 처리
  if (clean === '-' || clean === '') return 0;

  // 숫자와 소수점(.)을 제외한 모든 문자 제거 (단위 등 제거)
  const numStr = clean.replace(/[^0-9.]/g, '');
  
  const num = parseFloat(numStr);
  return isNaN(num) ? 0 : num;
};

/**
 * 탐앤탐스 상세 팝업 HTML 파싱
 * @param {string} html - 상세 팝업 영역의 HTML
 * @param {string} imageUrl - 목록에서 추출한 이미지 URL
 */
const parseTomNTomsDetail = (html, imageUrl) => {
  const $ = cheerio.load(html);

  // 1. 기본 정보
  const name = $('h3.text-xl.font-bold').text().trim();
  const description = $('.break-words.text-sm').text().trim();
  
  // 2. 카테고리 (기본값 음료)
  const category = normalizeCategory("탐앤탐스", "음료", name);

  // 3. 영양성분 매핑
  const nutrition = {
    calories_kcal: 0,
    sugar_g: 0,
    protein_g: 0,
    saturated_fat_g: 0,
    sodium_mg: 0,
    caffeine_mg: 0,
    size_standard: '정보 없음'
  };

  // 영양성분 그리드 순회
  $('.grid.grid-cols-2 > div.flex.justify-between').each((i, el) => {
    const label = $(el).find('p').first().text().trim(); // 예: 열량[kal]
    const value = $(el).find('p').last().text().trim(); // 예: 278 또는 -

    // 키워드 매칭
    if (label.includes('열량')) nutrition.calories_kcal = parseNum(value);
    else if (label.includes('당류')) nutrition.sugar_g = parseNum(value);
    else if (label.includes('단백질')) nutrition.protein_g = parseNum(value);
    else if (label.includes('포화지방')) nutrition.saturated_fat_g = parseNum(value);
    else if (label.includes('나트륨')) nutrition.sodium_mg = parseNum(value);
    else if (label.includes('카페인')) nutrition.caffeine_mg = parseNum(value);
    else if (label.includes('1회 제공량')) {
      // 대괄호 제거 및 공백 정리
      nutrition.size_standard = value.replace(/[\[\]]/g, '').trim();
    }
  });

  // 4. 알레르기 정보 (현재 HTML 구조상 정보가 없으면 빈 배열)
  const allergyInfo = ["정보 없음"];
  
  // (만약 추후 알레르기 정보가 .txt 클래스나 특정 영역에 추가된다면 여기에 로직 추가)

  return {
    brand_name: "탐앤탐스",
    category: category,
    menu_name: name,
    description: description,
    is_active: true,
    menu_image_url: imageUrl || "",
    menu_type: "beverage",
    nutrition: nutrition,
    allergy_info: allergyInfo
  };
};

module.exports = { parseTomNTomsDetail };