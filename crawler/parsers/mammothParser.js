const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

/**
 * 1. 목록 페이지에서 메뉴 ID 및 기본 정보 추출
 */
const getMenuIds = (html) => {
  const $ = cheerio.load(html);
  const menuList = [];
  
  // 매머드 카테고리 정의
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
 * 2. 상세(Modal HTML) 파싱 및 Schema 맞춤 변환
 */
const parseDetail = (detailHtml, baseInfo) => {
  const $ = cheerio.load(detailHtml);
  const { name: baseName, originalCategory } = baseInfo;

  // --- [1] 설명 및 알레르기 정보 추출 (핵심 수정 부분) ---
  let fullText = $('.txt_area').text().trim(); // 전체 텍스트 가져오기
  let description = fullText;
  let allergyList = [];

  // 정규식: "알레르기" 문구가 포함된 패턴 찾기 (■ 기호나 공백 유동적 대응)
  // 예: "■ 알레르기 유발 성분 : 우유, 대두"
  const allergyRegex = /[■\s]*알레르기.*[:](.*)/i;
  const match = fullText.match(allergyRegex);

  if (match) {
    // 1. 알레르기 정보 배열화 (쉼표 기준 분리)
    const rawAllergyStr = match[1]; // 콜론(:) 뒤의 텍스트 (예: " 우유, 대두")
    allergyList = rawAllergyStr
      .split(',')
      .map(s => s.trim())
      .filter(s => s !== '' && s !== '-'); // 빈 값이나 하이픈 제외

    // 2. 설명글에서 알레르기 문구 제거 (전체 매치된 문자열을 삭제)
    description = fullText.replace(match[0], '').replace(/\s+/g, ' ').trim();
  } else {
    // 알레르기 정보가 없는 경우 공백 정리만 수행
    description = description.replace(/\s+/g, ' ').trim();
  }

  // --- [2] 이미지 URL 처리 ---
  let imageUrl = $('.img_wrap img').attr('src');
  if (imageUrl && !imageUrl.startsWith('http')) {
    imageUrl = `https://mmthcoffee.com${imageUrl}`;
  }

  // --- [3] 카테고리 정규화 ---
  const normalizedCategory = normalizeCategory("매머드커피", originalCategory, baseName);
  const menuType = (normalizedCategory === '디저트' || originalCategory === '디저트') 
    ? 'food' 
    : 'beverage';

  // --- [4] 옵션(HOT/ICE) 추출 ---
  const options = [];
  $('.i_table table thead tr th').each((index, el) => {
    if (index > 0) { 
      let optName = $(el).text().trim();
      if (!optName) optName = 'Standard';
      options.push(optName);
    }
  });

  if (options.length === 0) return []; 

  // --- [5] 결과 객체 생성 ---
  const results = options.map((opt) => {
    const suffix = opt === 'Standard' ? '' : ` [${opt}]`;
    
    return {
      brand_name: "매머드커피",
      category: normalizedCategory,
      menu_name: `${baseName}${suffix}`,
      description: description, // 알레르기 문구가 제거된 깔끔한 설명
      is_active: true,
      menu_image_url: imageUrl || "",
      menu_type: menuType,
      allergy_info: allergyList, // 추출된 알레르기 배열 (예: ["우유", "대두"])
      nutrition: {
        calories_kcal: 0,
        sugar_g: 0,
        protein_g: 0,
        saturated_fat_g: 0, 
        sodium_mg: 0,
        caffeine_mg: 0,
        size_standard: opt 
      }
    };
  });

  // --- [6] 영양성분 매핑 ---
  const nutrientMap = {
    '칼로리': 'calories_kcal',
    '당류': 'sugar_g',
    '단백질': 'protein_g',
    '나트륨': 'sodium_mg',
    '카페인': 'caffeine_mg'
  };

  $('.i_table table tbody tr').each((i, tr) => {
    const labelText = $(tr).find('td').eq(0).text().trim();
    
    let targetKey = null;
    for (const [kor, schemaKey] of Object.entries(nutrientMap)) {
      if (labelText.includes(kor)) {
        targetKey = schemaKey;
        break;
      }
    }

    if (targetKey) {
      options.forEach((opt, optIdx) => {
        const valText = $(tr).find('td').eq(optIdx + 1).text().trim();
        let valNum = 0;

        if (valText === '-' || valText === '–' || valText === '') {
          valNum = 0;
        } else {
          valNum = parseFloat(valText.replace(/[^0-9.]/g, ''));
          if (isNaN(valNum)) valNum = 0;
        }

        if (results[optIdx]) {
          results[optIdx].nutrition[targetKey] = valNum;
        }
      });
    }
  });

  return results;
};

module.exports = { getMenuIds, parseDetail };