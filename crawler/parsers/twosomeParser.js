const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

/**
 * [1] 목록 페이지 파싱 (기존과 동일)
 */
const parseTwosomeList = (html) => {
  const $ = cheerio.load(html);
  const menus = [];

  $('.ui-goods-list-default > li').each((index, element) => {
    const $el = $(element);
    const $a = $el.find('a');

    const name = $el.find('.menu-title').text().trim();
    let imageUrl = $el.find('.thum-img img').attr('src');
    
    if (imageUrl && !imageUrl.startsWith('http')) {
       // mcdn 도메인 처리
       imageUrl = `https://mcdn.twosome.co.kr${imageUrl}`;
    }

    const dataUrl = $a.attr('data');
    let detailUrl = '';
    if (dataUrl) {
      detailUrl = `https://mo.twosome.co.kr${dataUrl}`;
    }

    if (name && detailUrl) {
      menus.push({ name, imageUrl, detailUrl });
    }
  });

  return menus;
};

/**
 * [2] 상세 페이지 파싱 (사이즈 탭 대응 수정)
 */
const parseTwosomeDetail = (detailHtml, baseInfo) => {
  const $ = cheerio.load(detailHtml);
  const { name: baseName, imageUrl } = baseInfo;

   // 1. 설명
  let description = '';
  $('.menu-detail-info .desc').each((i, el) => {
      const text = $(el).text().trim();
      if (text && !text.startsWith('※') && !text.startsWith('*')) {
          description += text + ' ';
      }
  });
  description = description.trim();

  // 2. 카테고리
  const category = normalizeCategory("투썸플레이스", "음료", baseName);

  // 3. [핵심 수정] 현재 활성화된 사이즈 탭 확인
  let currentSizeName = '';
  
  // .first()를 추가하여 중복된 탭이 있어도 하나만 가져옴
  const $activeTab = $('.ts24_select_drink_size ul li.is-active a').first(); 
  
  if ($activeTab.length > 0) {
    currentSizeName = $activeTab.text().trim();
  }

  // 메뉴 이름에 사이즈 붙이기
  const finalMenuName = currentSizeName 
    ? `${baseName}` 
    : baseName;

  // 4. 영양성분 추출
  const nutrition = {
    calories_kcal: 0,
    sugar_g: 0,
    protein_g: 0,
    saturated_fat_g: 0,
    sodium_mg: 0,
    caffeine_mg: 0,
    size_standard: currentSizeName || '정보 없음'
  };

  // 영양성분 리스트 파싱
  $('.text_list_ts24_type02 li').each((i, li) => {
    const label = $(li).find('.label').text().trim();
    const value = $(li).find('.value').text().trim();
    
    // "170" 또는 "36/36" 같은 형태 처리
    // 투썸은 "당류(g/%)" -> "36/36" 형태로 표시함. 앞자리 숫자만 가져와야 함.
    const cleanValue = value.split('/')[0].replace(/[^0-9.]/g, ''); 
    const numVal = parseFloat(cleanValue) || 0;

    if (label.includes('열량')) nutrition.calories_kcal = numVal;
    else if (label.includes('당류')) nutrition.sugar_g = numVal;
    else if (label.includes('단백질')) nutrition.protein_g = numVal;
    else if (label.includes('포화지방')) nutrition.saturated_fat_g = numVal;
    else if (label.includes('나트륨')) nutrition.sodium_mg = numVal;
    else if (label.includes('카페인')) nutrition.caffeine_mg = numVal;
    else if (label.includes('1회 제공량') || label.includes('총 제공량')) {
        // 값이 "414ml" 형태임
        nutrition.size_standard = `${currentSizeName} (${value})`.trim(); 
    }
  });

  // 5. 알레르기
  let allergyInfo = [];
  const allergyText = $('.menu-detail-info .desc.is-type1').text().trim();
  if (allergyText.includes('알레르기')) {
    const parts = allergyText.split(':');
    if (parts.length > 1) {
      allergyInfo = parts[1].split(',').map(s => s.trim()).filter(s => s);
    }
  }

  return {
    brand_name: "투썸플레이스",
    category: category,
    menu_name: finalMenuName,
    description: description,
    is_active: true,
    menu_image_url: imageUrl || "",
    menu_type: "beverage",
    nutrition: nutrition,
    allergy_info: allergyInfo
  };
};

module.exports = { parseTwosomeList, parseTwosomeDetail };