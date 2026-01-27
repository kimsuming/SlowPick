const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

// 1. 리스트 페이지 파싱 (사용자 피드백 반영: list_style01 -> listStyleB 등 유연하게 처리)
function parsePaulBassettList(htmlContent) {
  const $ = cheerio.load(htmlContent);
  const items = [];

  // 'list_style01'이 없다고 하셔서, 더 범용적인 선택자를 사용합니다.
  // onclick 이벤트에 'goView'가 있는 모든 a 태그를 찾습니다.
  $('a[onclick*="goView"]').each((i, el) => {
    const onClickAttr = $(el).attr('onclick');
    if (!onClickAttr) return;

    // ID 추출 (PBXXXXXX)
    const idMatch = onClickAttr.match(/goView\('([^']+)'\)/);
    if (!idMatch) return;
    
    const menuId = idMatch[1];
    const detailUrl = `https://www.baristapaulbassett.co.kr/menu/View.pb?cid1=A&cid2=&dpid=${menuId}`;

    // 리스트 상의 이름과 이미지 (보조 정보)
    // 구조가 변경되었을 수 있으므로 안전하게 탐색
    let name = $(el).find('.txtArea').text().trim() || "이름 파싱 실패";
    // 영문명(span) 제거 시도
    const $clone = $(el).find('.txtArea').clone();
    $clone.find('span').remove();
    if ($clone.text().trim()) name = $clone.text().trim();

    let imgUrl = $(el).find('img').attr('src');
    if (imgUrl && !imgUrl.startsWith('http')) {
      imgUrl = `https://www.baristapaulbassett.co.kr${imgUrl}`;
    }

    items.push({ name, imgUrl, detailUrl });
  });

  return items;
}

// 2. 상세 페이지 파싱 (수정됨: pSize_S 우선 타겟팅)
function parsePaulBassettDetail(htmlContent, baseInfo) {
  const $ = cheerio.load(htmlContent);

  // (1) 메뉴 이름 추출
  const $dt = $('.menuTit dl dt');
  $dt.find('span').remove(); 
  const name = $dt.text().trim(); 

  // (2) 설명 추출
  const description = $('.menuTit dl dd').text().trim();

  // (3) 이미지 추출
  let imgUrl = $('.menuSlide img').attr('src');
  if (imgUrl && !imgUrl.startsWith('http')) {
    imgUrl = `https://www.baristapaulbassett.co.kr${imgUrl}`;
  }

  // (4) 영양 정보 및 사이즈 추출 (핵심 수정 부분 ⭐️)
  const nutrition = {
    calories_kcal: 0, sugar_g: 0, protein_g: 0,
    sodium_mg: 0, saturated_fat_g: 0, caffeine_mg: 0,
    size_standard: "정보 없음"
  };

  /**
   * [Context 설정]
   * - 우선 '#pSize_S'(Standard/Small) 영역을 찾습니다.
   * - 만약 사이즈 구분이 없는 메뉴라 pSize_S가 없다면, 기존의 '.nutritional' 클래스를 찾습니다.
   */
  let $nutriContext = $('#pSize_S');
  if ($nutriContext.length === 0) {
     $nutriContext = $('.nutritional'); // pSize_S가 없을 경우의 대비책
  }

  // 4-1. 사이즈 정보 추출 (Context 내부에서만 검색)
  // 구조: <span class="sizeMl">제공량(ml)<span>360</span></span>
  const sizeVal = $nutriContext.find('.sizeMl span').text().trim();
  if (sizeVal) {
    nutrition.size_standard = `${sizeVal}ml`;
  }

  // 4-2. 영양소 수치 추출 (Context 내부에서만 검색)
  // 구조: <ul><li><span class="tit">열량</span><span class="num">180</span>...</li></ul>
  $nutriContext.find('ul li').each((i, li) => {
    const label = $(li).find('.tit').text().trim();
    const valText = $(li).find('.num').text().trim();
    const val = parseFloat(valText.replace(/[^0-9.]/g, '')) || 0;

    if (label.includes('열량')) nutrition.calories_kcal = val;
    else if (label.includes('당류')) nutrition.sugar_g = val;
    else if (label.includes('단백질')) nutrition.protein_g = val;
    else if (label.includes('나트륨')) nutrition.sodium_mg = val;
    else if (label.includes('포화지방')) nutrition.saturated_fat_g = val;
    else if (label.includes('카페인')) nutrition.caffeine_mg = val;
  });

  // (5) 알레르기 정보 추출
  let allergyInfo = [];
  $('.info li').each((i, li) => {
    const label = $(li).find('span').text().trim();
    if (label.includes('알레르기')) {
      const text = $(li).text().replace(label, '').trim();
      allergyInfo = text.split(',')
        .map(s => s.trim())
        .filter(s => s && s !== '없음');
    }
  });

  // (6) 카테고리 매핑
  const category = normalizeCategory("폴 바셋", "음료", name);

  return {
    brand_name: "폴 바셋",
    menu_name: name || baseInfo.name,
    menu_image_url: imgUrl || baseInfo.imgUrl,
    category: category,
    is_active: true,
    menu_type: "regular",
    nutrition: nutrition,
    allergy_info: allergyInfo,
    description: description
  };
}

module.exports = { parsePaulBassettList, parsePaulBassettDetail };