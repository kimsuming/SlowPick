const cheerio = require('cheerio');
const { normalizeCategory } = require('../utils/categoryMapper');

const BRAND_NAME = '엔제리너스';
const IMAGE_BASE_URL = 'https://img.lotteeatz.com';

const BEVERAGE_CATEGORIES = [
  '엔제린밸런스',
  '디카페인커피',
  '신제품',
  '커피',
  '스노우',
  '드링크',
  'TEA',
  '과일티',
  '생과일',
];

const STOP_PREFIXES = ['샌드위치', 'Bakery', '케이크', '디저트', '쿠키', '샐러드'];

const FOOD_KEYWORDS = [
  '케이크',
  '푸딩',
  '반미',
  '토스트',
  '샌드위치',
  '브레드',
  '와플',
  '크로플',
  '스콘',
  '컵과일',
  '파르페볼',
  '생딸기볼',
];

/**
 * 공통 문자열 정리
 */
function cleanText(value = '') {
  return String(value ?? '')
    .replace(/\u00a0/g, ' ')
    .replace(/[\n\r\t]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * 공백 제거용 압축 키
 */
function compactText(value = '') {
  return cleanText(value).replace(/\s+/g, '');
}

/**
 * 메뉴명 매칭용 키
 */
function normalizeMenuKey(value = '') {
  return cleanText(value)
    .replace(/\s+/g, '')
    .replace(/[·•]/g, '')
    .replace(/[^0-9A-Za-z가-힣()]/g, '');
}

/**
 * 숫자 파싱
 * - 정보 없음(-, 빈값): null
 * - "0", "0.0": 0
 * - "0.5미만", "1g미만": 0
 */
function parseNum(text) {
  const clean = cleanText(text);

  if (!clean || clean === '-') return null;
  if (clean.includes('미만')) return 0;

  const num = parseFloat(clean.replace(/,/g, '').replace(/g$/i, ''));
  return Number.isNaN(num) ? null : num;
}

/**
 * HOT/ICE → menu_type 변환
 */
function inferMenuType(tempText = '') {
  const temp = cleanText(tempText).toUpperCase();

  if (temp.includes('HOT')) return 'hot';
  if (temp.includes('ICE')) return 'ice';

  return 'regular';
}

/**
 * size_standard 생성
 */
function buildSizeStandard(sizeText = '') {
  const size = cleanText(sizeText).toUpperCase();
  if (!size || size === '-') return null;
  return size;
}

/**
 * 알러지 파싱
 */
function parseAllergyInfo(allergyText = '') {
  const clean = cleanText(allergyText)
    .replace(/고카페인\s*함유/g, '')
    .replace(/알레르기\s*유발성분\s*:?\s*/g, '')
    .replace(/^[-,\s]+/, '')
    .replace(/^,+|,+$/g, '')
    .trim();

  if (!clean || clean === '-') return [];

  return [
    ...new Set(
      clean
        .split(',')
        .map(v => cleanText(v))
        .filter(Boolean)
        .filter(v => v !== '-')
    ),
  ];
}

/**
 * 카테고리 normalize 안전 래퍼
 */
function safeNormalizeCategory(category = '') {
  const raw = cleanText(category);
  if (!raw) return null;

  try {
    if (typeof normalizeCategory === 'function') {
      return normalizeCategory(raw) || raw;
    }
  } catch (_) {
    // fallback
  }

  return raw;
}

/**
 * 이미지 URL 절대경로 변환
 */
function toAbsoluteImageUrl(url = '') {
  const clean = cleanText(url);
  if (!clean) return null;

  if (/^https?:\/\//i.test(clean)) return clean;
  if (clean.startsWith('//')) return `https:${clean}`;
  if (clean.startsWith('/')) return `${IMAGE_BASE_URL}${clean}`;

  return `${IMAGE_BASE_URL}/${clean.replace(/^\/+/, '')}`;
}

/**
 * infoMap 등록
 */
function setInfoMap(infoMap, menuName, data) {
  const key = normalizeMenuKey(menuName);
  if (!key) return;

  const payload = {
    imageUrl: data?.imageUrl || null,
    productId: cleanText(data?.productId || ''),
  };

  if (!infoMap.has(key)) {
    infoMap.set(key, payload);
  }

  const looseKey = key.replace(/[()]/g, '');
  if (looseKey && !infoMap.has(looseKey)) {
    infoMap.set(looseKey, payload);
  }
}

/**
 * infoMap 조회
 */
function findAngelInfo(infoMap, menuName = '') {
  const baseKey = normalizeMenuKey(menuName);

  const candidates = [
    baseKey,
    baseKey.replace(/[()]/g, ''),
  ].filter(Boolean);

  for (const key of candidates) {
    if (infoMap.has(key)) {
      return infoMap.get(key);
    }
  }

  return {
    imageUrl: null,
    productId: '',
  };
}

/**
 * ordering 페이지의 pList JSON에서 이미지 URL / 상품 ID 매핑
 */
const parseAngelImages = (orderHtml = '') => {
  const infoMap = new Map();

  try {
    const regex = /var\s+pList\s*=\s*(\[.*?\]);/s;
    const match = orderHtml.match(regex);

    if (match && match[1]) {
      const jsonData = JSON.parse(match[1]);

      jsonData.forEach(item => {
        const menuName = cleanText(item.dispNm || item.name || '');
        if (!menuName) return;

        let imageUrl = null;

        if (item.imgSystemFileNm) {
          imageUrl = `${IMAGE_BASE_URL}${item.imgPath}${item.imgSystemFileNm}.${item.imgExtsn}`;
        } else if (item.imageUrl || item.imgUrl || item.imgSrc) {
          imageUrl = toAbsoluteImageUrl(item.imageUrl || item.imgUrl || item.imgSrc);
        }

        setInfoMap(infoMap, menuName, {
          imageUrl,
          productId: item.presPrdId || item.productId || '',
        });
      });
    }
  } catch (error) {
    console.error('[Angel] 이미지/ID JSON 파싱 실패:', error.message);
  }

  return infoMap;
};

/**
 * 상세 페이지 설명 파싱
 */
const parseAngelDescription = (html = '') => {
  const $ = cheerio.load(html);

  let description = $('.prod-detail-header .btext').text().trim();
  if (!description) description = $('.btext').text().trim();
  if (!description) description = $('.txt.scroll-con-y').text().trim();
  if (!description) description = $('.cont-inner .txt').first().text().trim();
  if (!description) description = $('meta[property="og:description"]').attr('content') || '';

  description = cleanText(description);

  const noticePatterns = ['*영양성분', '*고카페인', '※', '*알레르기'];
  let cutIndex = -1;

  noticePatterns.forEach(pattern => {
    const idx = description.indexOf(pattern);
    if (idx > -1 && (cutIndex === -1 || idx < cutIndex)) {
      cutIndex = idx;
    }
  });

  if (cutIndex > -1) {
    description = description.substring(0, cutIndex).trim();
  }

  return description || null;
};

/**
 * nutrition table에서 행 추출
 */
function extractAngelRowsFromTable(nutritionHtml = '') {
  const $ = cheerio.load(nutritionHtml);
  const rows = [];

  $('table tr').each((_, tr) => {
    const cells = $(tr)
      .find('th, td')
      .map((__, cell) => cleanText($(cell).text()))
      .get();

    if (cells.some(Boolean)) {
      rows.push(cells);
    }
  });

  return rows;
}

/**
 * 셀 배열 앞부분에서 카테고리 접두어 제거 후 메뉴명 계산
 */
function stripCategoryPrefixFromCells(cells = [], prefixCompact = '') {
  const cleanCells = cells.map(cell => cleanText(cell)).filter(Boolean);

  if (!prefixCompact) {
    return cleanText(cleanCells.join(' '));
  }

  let acc = '';
  let consumed = 0;

  for (const cell of cleanCells) {
    const compact = compactText(cell);

    if (!compact) {
      consumed += 1;
      continue;
    }

    if (prefixCompact.startsWith(acc + compact)) {
      acc += compact;
      consumed += 1;

      if (acc === prefixCompact) {
        return cleanText(cleanCells.slice(consumed).join(' '));
      }
    } else {
      break;
    }
  }

  return cleanText(cleanCells.join(' '));
}

/**
 * 카테고리 / 메뉴명 판별
 */
function resolveCategoryAndMenu(beforeCells = [], pendingCategory = '', currentCategory = '') {
  const cleanCells = beforeCells.map(cell => cleanText(cell)).filter(Boolean);
  const beforeText = cleanText(cleanCells.join(' '));
  const beforeCompact = compactText(beforeText);
  const pendingCompact = compactText(pendingCategory);

  const sortedCategories = [...BEVERAGE_CATEGORIES].sort(
    (a, b) => compactText(b).length - compactText(a).length
  );

  for (const category of sortedCategories) {
    const categoryCompact = compactText(category);

    if (pendingCompact) {
      if (categoryCompact.startsWith(pendingCompact)) {
        const remainCompact = categoryCompact.slice(pendingCompact.length);
        const menuName = stripCategoryPrefixFromCells(cleanCells, remainCompact);

        if (menuName && menuName !== beforeText) {
          return { category, menuName };
        }

        if (!remainCompact) {
          return { category, menuName: beforeText };
        }
      }

      if ((pendingCompact + beforeCompact).startsWith(categoryCompact)) {
        const remainCompact = categoryCompact.slice(pendingCompact.length);
        const menuName = stripCategoryPrefixFromCells(cleanCells, remainCompact);
        return { category, menuName };
      }
    }

    if (beforeCompact.startsWith(categoryCompact)) {
      const menuName = stripCategoryPrefixFromCells(cleanCells, categoryCompact);
      return { category, menuName };
    }
  }

  return {
    category: cleanText(currentCategory || pendingCategory),
    menuName: beforeText,
  };
}

/**
 * RDS 평탄 구조 메뉴 객체 생성
 * nutritionCells 순서:
 * [중량, 열량, 탄수화물, 당류, 탄수화물DV, 단백질, 단백질DV, 포화지방, 포화지방DV, 나트륨, 나트륨DV, 카페인]
 */
function buildAngelMenuFromCells({
  currentCategory,
  menuName,
  tempText,
  sizeText,
  nutritionCells,
  allergyText,
  infoMap,
}) {
  const info = findAngelInfo(infoMap, menuName);
  const normalizedCategory = safeNormalizeCategory(currentCategory);

  const slots = nutritionCells.slice(0, 12);
  while (slots.length < 12) slots.push('-');

  const nutritionJson = {
    source: 'angel_items_table',
    raw_category: cleanText(currentCategory),
    weight_g: parseNum(slots[0]),
    carbohydrate: parseNum(slots[2]),
    carbohydrate_daily_value: parseNum(slots[4]),
    protein_daily_value: parseNum(slots[6]),
    saturated_fat_daily_value: parseNum(slots[8]),
    sodium_daily_value: parseNum(slots[10]),
  };

  return {
    brand_name: BRAND_NAME,
    category: normalizedCategory,
    menu_name: cleanText(menuName),
    description: null,
    size_standard: buildSizeStandard(sizeText),
    image_url: info.imageUrl || null,
    is_active: true,
    menu_type: inferMenuType(tempText),

    calories: parseNum(slots[1]),
    sugar: parseNum(slots[3]),
    protein: parseNum(slots[5]),
    saturated_fat: parseNum(slots[7]),
    sodium: parseNum(slots[9]),
    caffeine: parseNum(slots[11]),

    nutrition_json: nutritionJson,
    allergy_info: parseAllergyInfo(allergyText),

    // main.js에서 상세 설명 조회 후 delete
    productId: info.productId || '',
  };
}

/**
 * 영양성분표 파싱 → RDS 평탄 구조 반환
 */
const parseAngel = (nutritionHtml, infoMap = new Map()) => {
  const rows = extractAngelRowsFromTable(nutritionHtml);
  const menus = [];

  let currentCategory = '';
  let currentName = '';
  let pendingCategory = '';

  for (const cells of rows) {
    const nonEmptyCells = cells.map(cell => cleanText(cell)).filter(Boolean);
    if (nonEmptyCells.length === 0) continue;

    const joined = cleanText(nonEmptyCells.join(' '));
    if (!joined) continue;

    // 헤더 / 설명 제거
    if (
      joined.includes('제품 영양성분/알레르기 유발성분') ||
      joined.includes('엔제리너스 영양성분표') ||
      joined.startsWith('※ 사이즈') ||
      /^\d{4}\.\d{2}\.\d{2}\s+기준$/.test(joined) ||
      nonEmptyCells.includes('구분') ||
      nonEmptyCells.includes('메뉴명') ||
      nonEmptyCells.includes('HOT/ICE') ||
      nonEmptyCells.includes('사이즈') ||
      joined === '/'
    ) {
      continue;
    }

    // 섹션 라벨(샌드위치, 케이크 등)은 전체 중단하지 말고 그냥 넘김
    if (nonEmptyCells.length === 1 && STOP_PREFIXES.some(prefix => joined.startsWith(prefix))) {
      pendingCategory = '';
      currentCategory = '';
      currentName = '';
      continue;
    }

    const tempIdx = nonEmptyCells.findIndex(cell => /^(HOT|ICE)$/i.test(cell));

    // HOT/ICE가 없으면:
    // 1) 짧은 단일 텍스트면 카테고리 조각으로 누적
    // 2) 아니면 비음료 row로 보고 그냥 스킵
    if (tempIdx === -1) {
      if (
        nonEmptyCells.length === 1 &&
        !/\d/.test(joined) &&
        joined.length <= 20 &&
        !STOP_PREFIXES.some(prefix => joined.startsWith(prefix))
      ) {
        pendingCategory += compactText(joined);
      }
      continue;
    }

    const tempText = nonEmptyCells[tempIdx];
    const sizeText = nonEmptyCells[tempIdx + 1] || '';
    const beforeCells = nonEmptyCells.slice(0, tempIdx);
    const afterCells = nonEmptyCells.slice(tempIdx + 2);

    // ICE/HOT 다음이 S/R/L이 아니면 비정상 row로 보고 스킵
    if (!/^[SRL]$/i.test(sizeText)) {
      continue;
    }

    // 영양 칼럼이 부족하면 스킵
    if (afterCells.length < 12) {
      continue;
    }

    let rowCategory = currentCategory;
    let menuName = currentName;

    if (beforeCells.length > 0) {
      const resolved = resolveCategoryAndMenu(beforeCells, pendingCategory, currentCategory);
      pendingCategory = '';

      if (resolved.category) {
        rowCategory = resolved.category;
      }

      if (resolved.menuName) {
        menuName = resolved.menuName;
      }
    }

    if (!rowCategory || !menuName) {
      continue;
    }

    // 비음료/제외 대상은 중단하지 말고 다음 row로
    if (STOP_PREFIXES.some(prefix => menuName.startsWith(prefix))) {
      continue;
    }

    if (FOOD_KEYWORDS.some(keyword => menuName.includes(keyword))) {
      continue;
    }

    const nutritionCells = afterCells.slice(0, 12);
    const allergyText = cleanText(afterCells.slice(12).join(', '));

    const menu = buildAngelMenuFromCells({
      currentCategory: rowCategory,
      menuName,
      tempText,
      sizeText,
      nutritionCells,
      allergyText,
      infoMap,
    });

    menus.push(menu);

    // 정상 음료로 확정된 row만 current 상태 갱신
    currentCategory = rowCategory;
    currentName = menuName;
  }

  return menus;
};

module.exports = { parseAngel, parseAngelImages, parseAngelDescription };