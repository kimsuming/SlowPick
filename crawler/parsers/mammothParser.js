const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

/**
 * 숫자 파싱 헬퍼
 */
const parseNum = (val) => {
  if (!val) return 0;
  const str = val.toString().trim().replace(/,/g, '');
  if (str === '-' || str === '' || str === '–') return 0;
  const num = parseFloat(str);
  return isNaN(num) ? 0 : num;
};

/**
 * 1. 목록 페이지 파싱 (기존과 동일)
 */
const getMenuIds = (html) => {
  const $ = cheerio.load(html);
  const menuList = [];
  const targetCategories = ['.cate.cate01', '.cate.cate02', '.cate.cate03'];

  targetCategories.forEach((selector) => {
    $(selector).find('li').each((i, el) => {
      const nameElement = $(el).find('.txt_wrap strong');
      const linkElement = $(el).find('a');

      if (nameElement.length === 0 || linkElement.length === 0) return;

      const name = nameElement.text().trim();
      const href = linkElement.attr('href');
      const idMatch = href ? href.match(/goViewB\((\d+)\)/) : null;
      
      if (idMatch && idMatch[1]) {
        menuList.push({
          name: name,
          id: idMatch[1],
          originalCategory: selector.includes('cate04') ? '디저트' : '음료'
        });
      }
    });
  });

  return menuList;
};

/**
 * 2. 상세(Modal HTML) 파싱
 * - 동적 컬럼 매핑 적용 (HOT/ICE 유동적 대응)
 */
const parseDetail = (detailHtml, baseInfo) => {
  const $ = cheerio.load(detailHtml);
  const { name: baseName, originalCategory } = baseInfo;

  // --- [1] 설명 및 알레르기 정보 추출 ---
  let fullText = $('.txt_area').text().trim();
  let description = fullText;
  let allergyList = [];

  const allergyRegex = /[■\s]*알레르기.*[:](.*)/i;
  const match = fullText.match(allergyRegex);

  if (match) {
    const rawAllergyStr = match[1];
    allergyList = rawAllergyStr.split(',').map(s => s.trim()).filter(s => s !== '' && s !== '-');
    description = fullText.replace(match[0], '').replace(/\s+/g, ' ').trim();
  } else {
    description = description.replace(/\s+/g, ' ').trim();
  }

  // --- [2] 이미지 URL 처리 ---
  let imageUrl = $('.img_wrap img').attr('src');
  if (imageUrl && !imageUrl.startsWith('http')) {
    imageUrl = `https://mmthcoffee.com${imageUrl}`;
  }

  // --- [3] 카테고리 정규화 ---
  const normalizedCategory = normalizeCategory("매머드커피", originalCategory, baseName);
  const menuType = (normalizedCategory === '디저트' || originalCategory === '디저트') ? 'food' : 'beverage';


  // --- [4] 테이블 구조 동적 분석 (핵심 수정) ---
  // 헤더를 먼저 읽어서 유효한 컬럼의 인덱스와 옵션명을 파악합니다.
  const validColumns = []; // { index: 1, label: 'HOT', size: '16oz' } 형태

  $('.i_table table thead tr th').each((idx, th) => {
    if (idx === 0) return; // 첫 번째 '구분' 컬럼 제외

    const headerText = $(th).text().trim(); // 예: "HOT(16oz)" 또는 ""
    
    // 헤더 텍스트가 비어있으면 데이터가 없는 컬럼이므로 무시
    if (headerText) {
      let optName = 'Standard';
      let sizeStr = headerText; // 기본적으로 전체 텍스트를 사이즈로 사용

      if (headerText.toUpperCase().includes('HOT')) {
        optName = 'HOT';
      } else if (headerText.toUpperCase().includes('ICE') || headerText.includes('아이스')) {
        optName = 'ICE';
      }

      // 괄호 안에 사이즈가 있는 경우 추출 (예: "HOT(16oz)" -> "16oz")
      const sizeMatch = headerText.match(/\((.*?)\)/);
      if (sizeMatch) {
        sizeStr = sizeMatch[1];
      }

      validColumns.push({
        colIndex: idx, // 실제 td 인덱스
        optName: optName,
        size: sizeStr
      });
    }
  });

  // 유효한 컬럼이 하나도 없으면 리턴
  if (validColumns.length === 0) return [];


  // --- [5] 데이터 파싱 ---
  // validColumns 정보를 기반으로 결과 객체 초기화
  const variants = validColumns.map(col => ({
    ...col,
    nutrition: {
      calories_kcal: 0, sugar_g: 0, protein_g: 0, saturated_fat_g: 0,
      sodium_mg: 0, caffeine_mg: 0, size_standard: col.size
    }
  }));

  const nutrientMap = {
    '칼로리': 'calories_kcal',
    '당류': 'sugar_g',
    '단백질': 'protein_g',
    '나트륨': 'sodium_mg',
    '카페인': 'caffeine_mg',
    '포화지방': 'saturated_fat_g'
  };

  // tbody 순회
  $('.i_table table tbody tr').each((i, tr) => {
    const $tds = $(tr).find('td');
    const labelText = $tds.eq(0).text().trim(); // 영양소 이름

    let targetKey = null;
    for (const [kor, schemaKey] of Object.entries(nutrientMap)) {
      if (labelText.includes(kor)) {
        targetKey = schemaKey;
        break;
      }
    }

    if (targetKey) {
      // 미리 파악해둔 유효 컬럼 인덱스에서만 데이터를 가져옴
      variants.forEach(variant => {
        const valText = $tds.eq(variant.colIndex).text().trim();
        variant.nutrition[targetKey] = parseNum(valText);
      });
    }
  });


  // --- [6] 최종 결과 생성 ---
  const results = [];

  variants.forEach((variant) => {
    // 이미 headerText가 빈칸인 경우는 validColumns 생성 시 걸러졌으므로,
    // 여기서는 별도의 hasValidData 체크를 안 해도 됨 (헤더가 있으면 데이터가 있다고 가정)
    
    // 이름 중복 방지
    let suffix = '';
    // 옵션명이 Standard가 아니고, 원래 이름에 해당 옵션이 없을 경우만 붙임
    if (variant.optName !== 'Standard') {
      const upperBase = baseName.toUpperCase();
      if (!upperBase.includes(variant.optName)) {
        suffix = ` [${variant.optName}]`;
      }
    }

    results.push({
      brand_name: "매머드커피",
      category: normalizedCategory,
      menu_name: `${baseName}${suffix}`,
      description: description,
      is_active: true,
      menu_image_url: imageUrl || "",
      menu_type: menuType,
      allergy_info: allergyList,
      nutrition: variant.nutrition
    });
  });

  return results;
};

module.exports = { getMenuIds, parseDetail };