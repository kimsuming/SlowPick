// src/utils/categoryMapper.js

const CATEGORY_MAP = {
  DECAF: "디카페인",
  COFFEE: "커피",
  LATTE: "라떼/밀크티", // 논커피 라떼 포함
  SMOOTHIE: "스무디/프라페",
  ADE: "에이드/주스",
  TEA: "티",
  DESSERT: "디저트",
  ETC: "기타"
};

/**
 * 메뉴 이름과 브랜드 원래 카테고리를 분석해 'SlowPick 표준 카테고리'를 반환
 */
function normalizeCategory(brand, originalCategory, menuName) {
  // 1. 텍스트 전처리 (공백 제거, 소문자 변환 등)
  const name = menuName.replace(/\s+/g, "").toLowerCase();
  
  // 2. 디저트류 우선 필터링 (브랜드 카테고리 활용)
  // 스타벅스나 메가커피가 이미 '디저트', '푸드'로 분류했다면 바로 리턴
  if (originalCategory.includes("디저트") || originalCategory.includes("푸드") || originalCategory.includes("케이크")) {
    return CATEGORY_MAP.DESSERT;
  }

  // 3. 키워드 기반 분류 (우선순위 중요!)
  
  // (1) 디카페인 (가장 중요)
  if (name.includes("디카페인")) return CATEGORY_MAP.DECAF;

  // (2) 스무디 / 프라페 / 쉐이크 / 블렌디드
  if (name.match(/(스무디|프라페|쉐이크|블렌디드|크러쉬|요거트)/)) return CATEGORY_MAP.SMOOTHIE;

  // (3) 에이드 / 주스
  if (name.match(/(에이드|주스|모히또|리프레셔|피지오)/)) return CATEGORY_MAP.ADE;

  // (4) 티 (Tea)
  // '라떼'가 포함되지 않은 순수 티 (예: 캐모마일 티, 유자차)
  if (name.match(/(티|차$|아이스티|블랙티|허브티|얼그레이|카모마일|민트)/) && !name.includes("라떼")) return CATEGORY_MAP.TEA;

  // (5) 라떼 / 밀크티 (우유가 들어간 음료)
  if (name.match(/(라떼|마끼아또|카푸치노|밀크티|돌체|모카|슈페너|플랫화이트)/)) return CATEGORY_MAP.LATTE;

  // (6) 순수 커피 (아메리카노, 콜드브루, 에스프레소)
  if (name.match(/(아메리카노|콜드브루|에스프레소|오늘의커피|드립)/)) return CATEGORY_MAP.COFFEE;

  // (7) 나머지는 '기타' 혹은 브랜드 원래 카테고리 참고
  return CATEGORY_MAP.ETC;
}

module.exports = { normalizeCategory };