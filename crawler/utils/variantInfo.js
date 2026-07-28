// 브랜드마다 제각각인 핫/아이스, 사이즈 표기를 하나의 구조로 정규화하기 위한 공용 유틸.
// - 크롤러가 이미 탭 상태(어떤 온도/사이즈를 보고 있는지)를 알고 있는 브랜드(투썸, 매머드, 더벤티,
//   엔제리너스, 폴바셋)는 이 함수를 거치지 않고 직접 temperature/size_label을 채운다.
// - 사이트 원본 메뉴명 자체에 온도/사이즈 표기가 섞여 있는 브랜드(이디야, 메가, 컴포즈)만
//   extractVariantFromName()으로 이름에서 뽑아낸다.

const TEMPERATURE = { HOT: 'HOT', ICED: 'ICED' };

// 상대적인 크기 순서만 맞으면 되므로(그룹 내에서 가장 작은 값 = 기본 선택),
// 절대값 1부터 시작할 필요는 없다. 새 브랜드에서 못 보던 라벨이 나오면 여기에 추가할 것 —
// 없는 라벨은 99로 밀려나 정렬상 "가장 큰 사이즈" 취급된다.
const SIZE_RANK_MAP = {
  '스몰': 1, 'SHORT': 1, '쇼트': 1, 'S': 1, 'EX': 1,
  '레귤러': 2, '미디엄': 2, 'M': 2, 'REGULAR': 2, 'R': 2, 'TALL': 2, '톨': 2, '기본': 2,
  '라지': 3, 'LARGE': 3, 'L': 3, '그란데': 3, 'GRANDE': 3,
  '엑스라지': 4, 'XL': 4, '맥스': 4, 'MAX': 4, '벤티': 4, 'VENTI': 4, 'G': 4,
};

function normalizeTemperatureToken(token) {
  if (!token) return null;
  const t = String(token).trim().toUpperCase();
  if (!t) return null;

  if (/^(HOT|핫|따뜻|따듯)/.test(t)) return TEMPERATURE.HOT;
  if (/^(ICED?|아이스|차가운|콜드)/.test(t)) return TEMPERATURE.ICED;

  return null;
}

function sizeRankFor(label) {
  if (!label) return null;
  const key = String(label).trim().toUpperCase();
  if (!key) return null;
  return SIZE_RANK_MAP[key] ?? 99;
}

/**
 * 이름 문자열에 온도/사이즈 표기가 섞여 있는 경우(이디야 "(EX) HOT 말차라떼",
 * 메가 "(HOT)디카페인 헛개리카노", 컴포즈 "H-곡물라떼" 등) 이를 뽑아내고
 * 깨끗한 표시용 이름을 반환한다.
 */
function extractVariantFromName(rawName) {
  let name = String(rawName || '').trim();
  let temperature = null;
  let sizeLabel = null;
  let changed = true;
  let guard = 0;

  while (changed && guard < 10) {
    changed = false;
    guard += 1;

    // [핫]/[아이스]/[HOT]/[ICE]/[ICED] 형태 (대괄호 또는 소괄호)
    const bracketTempMatch = name.match(/[\[(](HOT|ICED?|핫|아이스)[\])]/i);
    if (bracketTempMatch) {
      temperature = temperature || normalizeTemperatureToken(bracketTempMatch[1]);
      name = name.replace(bracketTempMatch[0], ' ').replace(/\s+/g, ' ').trim();
      changed = true;
      continue;
    }

    // "HOT 말차라떼" / "ICED 말차라떼" — 이름 맨 앞의 온도 단어
    const prefixWordMatch = name.match(/^(HOT|ICED|ICE)\s*[- ]\s*/i);
    if (prefixWordMatch) {
      temperature = temperature || normalizeTemperatureToken(prefixWordMatch[1]);
      name = name.slice(prefixWordMatch[0].length).trim();
      changed = true;
      continue;
    }

    // "H-곡물라떼" / "I-곡물라떼"
    const dashPrefixMatch = name.match(/^([HI])-\s*/);
    if (dashPrefixMatch) {
      temperature = temperature || (dashPrefixMatch[1] === 'H' ? TEMPERATURE.HOT : TEMPERATURE.ICED);
      name = name.slice(dashPrefixMatch[0].length).trim();
      changed = true;
      continue;
    }

    // 남은 괄호 하나는 사이즈 표기로 간주 (온도 표기는 위 단계에서 이미 제거됨)
    const genericParenMatch =
      name.match(/^\(([^)]{1,10})\)\s*/) || name.match(/\s*\(([^)]{1,10})\)$/);
    if (genericParenMatch) {
      const inner = genericParenMatch[1].trim();
      const tempFromInner = normalizeTemperatureToken(inner);

      if (tempFromInner) {
        temperature = temperature || tempFromInner;
      } else if (!sizeLabel) {
        sizeLabel = inner;
      }

      name = name.replace(genericParenMatch[0], ' ').replace(/\s+/g, ' ').trim();
      changed = true;
      continue;
    }
  }

  return {
    displayName: name,
    temperature,
    sizeLabel,
    sizeRank: sizeRankFor(sizeLabel),
  };
}

module.exports = {
  TEMPERATURE,
  normalizeTemperatureToken,
  sizeRankFor,
  extractVariantFromName,
};
