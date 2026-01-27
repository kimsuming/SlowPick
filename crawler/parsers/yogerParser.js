const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

const BASE_URL = "https://www.yogerpresso.co.kr";

/**
 * 1. 목록 페이지 파싱
 * - 상세 팝업 URL 추출
 */
const getMenuUrls = (html) => {
  const $ = cheerio.load(html);
  const menus = [];

  // 리스트 아이템 순회
  $('.gallery-custom-list > li').each((index, element) => {
    const $el = $(element);
    const $link = $el.find('a.popup-link');
    
    const name = $el.find('.text').text().trim();
    const href = $link.attr('href'); // 예: ../pop/manu-pop.html?uid=477
    let imageUrl = $el.find('.img-bx img').attr('src');

    if (name && href) {
      // 상세 URL 절대경로 변환 (../pop -> /pop)
      // href가 "../pop/..." 형태이므로 "menu" 폴더 상위로 이동 필요
      // 결과: https://www.yogerpresso.co.kr/pop/manu-pop.html?uid=...
      const cleanHref = href.replace(/^\.\./, ''); // ".." 제거
      const detailUrl = `${BASE_URL}${cleanHref}`;

      if (imageUrl && !imageUrl.startsWith('http')) {
        imageUrl = `${BASE_URL}${imageUrl}`;
      }

      menus.push({
        name,
        imageUrl,
        detailUrl
      });
    }
  });

  return menus;
};

/**
 * 2. 상세(팝업) 페이지 파싱
 */
const parseDetail = (detailHtml, baseInfo, categoryName) => {
  const $ = cheerio.load(detailHtml);
  const { name: baseName, imageUrl } = baseInfo;

  // 1. 설명
  let description = $('.txt-bx .text').text().trim();
  description = description.replace(/[\n\r]+/g, ' ').replace(/\s+/g, ' ').trim();

  // 2. 카테고리 정규화
  const category = normalizeCategory("요거프레소", categoryName, baseName);
  const menuType = category === "디저트" ? "food" : "beverage";

  // 3. 영양성분 추출
  const nutrition = {
    calories_kcal: 0,
    sugar_g: 0,
    protein_g: 0,
    saturated_fat_g: 0,
    sodium_mg: 0,
    caffeine_mg: 0,
    size_standard: '정보 없음'
  };

  $('.noti-des dl').each((i, dl) => {
    const key = $(dl).find('dt').text().trim();
    const val = $(dl).find('dd').text().trim();

    // 값 정제: "9.35(17.0%) g" -> 9.35
    // 괄호, 퍼센트, 단위(g, mg, kcal, ml) 제거하고 첫 번째 숫자만 추출
    const cleanVal = val.split('(')[0].replace(/[^0-9.]/g, ''); 
    const numVal = parseFloat(cleanVal) || 0;

    if (key.includes('열량')) nutrition.calories_kcal = numVal;
    else if (key.includes('당류')) nutrition.sugar_g = numVal;
    else if (key.includes('단백질')) nutrition.protein_g = numVal;
    else if (key.includes('포화지방')) nutrition.saturated_fat_g = numVal;
    else if (key.includes('나트륨')) nutrition.sodium_mg = numVal;
    else if (key.includes('카페인')) nutrition.caffeine_mg = numVal;
    else if (key.includes('1회 제공량')) {
        nutrition.size_standard = val;
    }
  });

  // 4. 알레르기 정보
  // noti-txt 안의 p.des
  let allergyInfo = [];
  const allergyText = $('.noti-txt .des').text().trim();
  if (allergyText && allergyText !== '-') {
    allergyInfo = allergyText.split(',').map(s => s.trim()).filter(s => s);
  }

  // 5. 이미지 URL (팝업 안에 더 큰 이미지가 있다면 교체)
  let detailImage = $('.img-bx img').attr('src');
  if (detailImage) {
    if (!detailImage.startsWith('http')) {
        detailImage = `${BASE_URL}${detailImage}`;
    }
    // 기존 썸네일보다 상세 이미지를 우선 사용
    baseInfo.imageUrl = detailImage;
  }

  return {
    brand_name: "요거프레소",
    category: category,
    menu_name: baseName,
    description: description,
    is_active: true,
    menu_image_url: baseInfo.imageUrl,
    menu_type: menuType,
    nutrition: nutrition,
    allergy_info: allergyInfo
  };
};

module.exports = { getMenuUrls, parseDetail };