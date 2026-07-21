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
  // 원본 마크업이 <p class="desc"> 안에 <p>를 중첩시켜 놓아, HTML 파서가 바깥 <p>를
  // 즉시 닫고 안쪽 문단들을 형제 요소로 끌어올린다. 그래서 .desc 자체는 항상 비어 있고,
  // 실제 설명 문단들은 같은 <dd> 안의 형제 <p> 로 존재한다.
  let description = '';
  $('.menu-detail-info-title dd p').each((i, el) => {
      const text = $(el).text().trim();
      if (text && !text.startsWith('※') && !text.startsWith('*')) {
          description += text + ' ';
      }
  });
  description = description.trim();

  // 2. 카테고리
  const category = normalizeCategory("투썸플레이스", "음료", baseName);

  // 3. 현재 활성화된 온도(핫/아이스) · 사이즈(레귤러/라지/맥스) 탭 확인
  // .first()를 추가하여 중복된 탭(구매정보 영역에 숨겨진 사본)이 있어도 하나만 가져옴
  const $activeOndoTab = $('.hot_n_iced li.is-active a').first();
  const currentOndoName = $activeOndoTab.length > 0 ? $activeOndoTab.text().trim() : '';

  const $activeSizeTab = $('.ts24_select_drink_size ul li.is-active a').first();
  const currentSizeName = $activeSizeTab.length > 0 ? $activeSizeTab.text().trim() : '';

  // 메뉴 이름에 온도/사이즈 옵션 붙이기 (예: 디카페인 민트 밀샷추[아이스](레귤러))
  let finalMenuName = baseName;
  if (currentOndoName) finalMenuName += `[${currentOndoName}]`;
  if (currentSizeName) finalMenuName += `(${currentSizeName})`;

  // 4. 영양성분 추출
  const nutrition = {
    calories: null,
    sugar: null,
    protein: null,
    saturated_fat: null,
    sodium: null,
    caffeine: null,
    size_standard: null
  };

  // 영양성분 리스트 파싱
  $('.text_list_ts24_type02 li').each((i, li) => {
    const label = $(li).find('.label').text().trim();
    const value = $(li).find('.value').text().trim();

    // "170" 또는 "36/36" 같은 형태 처리
    // 투썸은 "당류(g/%)" -> "36/36" 형태로 표시함. 앞자리 숫자만 가져와야 함.
    const cleanValue = value.split('/')[0].replace(/[^0-9.]/g, '');
    const numVal = parseFloat(cleanValue) || 0;

    if (label.includes('열량')) nutrition.calories = numVal;
    else if (label.includes('당류')) nutrition.sugar = numVal;
    else if (label.includes('단백질')) nutrition.protein = numVal;
    else if (label.includes('포화지방')) nutrition.saturated_fat = numVal;
    else if (label.includes('나트륨')) nutrition.sodium = numVal;
    else if (label.includes('카페인')) nutrition.caffeine = numVal;
    else if (label.includes('1회 제공량')) {
        // 값이 "(컵용량)414ml" 형태이므로 앞의 괄호 설명만 제거
        nutrition.size_standard = value.replace(/^\([^)]*\)/, '').trim() || value;
    }
  });

  // 5. 알레르기
  // "알레르기 유발요인" 제목을 가진 .info_box 안의 .contents 텍스트를 사용
  // (구 마크업의 '.desc.is-type1' 셀렉터는 HTML 주석 안에만 존재해 항상 빈 값이었음)
  let allergyInfo = [];
  $('.info_box').each((i, box) => {
    const titleText = $(box).find('.contents_title').first().text().trim();
    if (!titleText.includes('알레르기')) return;

    const contentText = $(box).find('.contents').first().text().trim();
    if (contentText && contentText !== '-' && contentText !== '해당없음') {
      allergyInfo = contentText.split(',').map(s => s.trim()).filter(s => s);
    }
  });

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