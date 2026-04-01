const puppeteer = require('puppeteer');
const cheerio = require('cheerio');
const axios = require('axios');
const { parseMega } = require('../parsers/megaParser');
const { parseStarbucks } = require('../parsers/starbucksParser');
const { parseCompose } = require('../parsers/composeParser');
const { parseEdiya } = require('../parsers/ediyaParser');
const { parsePaulBassettList, parsePaulBassettDetail } = require('../parsers/paulParser');
const { getMenuIds, parseDetail } = require('../parsers/mammothParser');
const { parsePaik } = require('../parsers/paikParser');
const { getMenuUrls: getVentiMenuUrls, parseDetail: parseVentiDetail } = require('../parsers/theVentiParser');
const { parseAngel, parseAngelImages, parseAngelDescription } = require('../parsers/angelinusParser');
const { parseTwosomeList, parseTwosomeDetail } = require('../parsers/twosomeParser');
const { getMenuUrls: getYogerMenuUrls, parseDetail: parseYogerDetail } = require('../parsers/yogerParser');
const { parseTomNTomsDetail } = require('../parsers/tmntmsParser');

const menuRepository = require('./services/repositories');
const firestoreMenuRepository = require('./firestoreMenuRepository');
const FirebaseService = require('./services/firebaseService');

/**
 * [공통 로직] 데이터 검증, 업로드 및 발견된 ID 수집
 */
async function processMenus(brandName, rawMenus, foundSet) {
  for (const menu of rawMenus) {
    const { isValid, data } = ValidatorService.validate(menu);
    if (isValid) {
      const result = await FirebaseService.uploadMenu(data);
      if (result.success && result.docId) {
        foundSet.add(result.docId); // 생존 확인된 ID 기록
      }
    }
  }
}

/**
 * [공통 로직] 사라진 메뉴 비활성화
 */
async function finalizeDeactivation(brandName, oldIds, foundIds) {
  const missingIds = [...oldIds].filter(id => !foundIds.has(id));
  if (missingIds.length > 0) {
    console.log(`📉 [${brandName}] 사라진 메뉴 ${missingIds.length}개 비활성화 중...`);
    await FirebaseService.deactivateMenus(missingIds);
  } else {
    console.log(`✨ [${brandName}] 모든 메뉴가 최신 상태입니다.`);
  }
}

/**
 * 이디야 토핑 블랙리스트 생성
 */
async function getEdiyaToppingBlacklist(page) {
  const TOPPING_URL = "https://ediya.com/contents/drink.html?chked_val=159,&skeyword=#c";
  console.log("   🚫 토핑 블랙리스트 수집 중...");
  
  await page.goto(TOPPING_URL, { waitUntil: 'networkidle2' });
  
  console.log("   🖱️ 전체 메뉴 로딩 중 (페이지 값 변화 감지)...");

  let clickCount = 0;
  
  while (true) {
    try {
      const prevPageVal = await page.$eval('#menu_page', el => el.value).catch(() => null);
      
      const moreButton = await page.$('.line_btn');
      if (!moreButton || !(await moreButton.boundingBox())) {
        console.log("   ✅ 더보기 버튼이 더 이상 보이지 않습니다. 로딩 완료.");
        break;
      }

      await page.evaluate(btn => btn.click(), moreButton);
      
      try {
        await page.waitForFunction(
          (oldVal) => {
            const el = document.querySelector('#menu_page');
            return el && el.value !== oldVal;
          },
          { timeout: 2000 }, // 2초 안에 안 바뀌면 끝난 걸로 간주
          prevPageVal
        );
        
        clickCount++;

      } catch (timeout) {
        console.log("   ⚠️ 클릭했으나 페이지 번호가 변하지 않습니다. (마지막 페이지 도달)");
        break;
      }

    } catch (err) {
      console.log(`   ❌ 로직 수행 중 에러 발생: ${err.message}`);
      break;
    }
  }

  console.log(`   🔄 총 ${clickCount}회 더보기 클릭 완료.`);
  
  await new Promise(r => setTimeout(r, 1000));

  const html = await page.content();
  const rawMenus = parseEdiya(html);

  console.log(`   📦 총 ${rawMenus.length}개의 메뉴 발견`);

  const $ = cheerio.load(html);
  const toppingNames = new Set();

  $('a[onclick^="show_nutri"] span').each((i, el) => {
    toppingNames.add($(el).text().trim());
  });

  console.log(`   ✅ ${toppingNames.size}개의 토핑 필터링 준비 완료.`);
  return toppingNames;
}


/**
 * 1. 메가커피 실행 로직 (최적화 버전)
 */
async function runMega(page) {
  const BRAND = "메가MGC커피";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);
  
  const oldIds = await FirebaseService.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  const URL = "https://www.mega-mgccoffee.com/menu/?menu_category1=1&menu_category2=1";
  await page.goto(URL, { waitUntil: 'networkidle2' });
  
  const pageButtons = await page.$$("#board_page li a");
  const totalPages = pageButtons.length || 1;

  for (let i = 1; i <= totalPages; i++) {
    if (i > 1) {
      await page.evaluate((n) => {
        const btns = document.querySelectorAll("#board_page li a");
        for (let b of btns) if (b.innerText.trim() == n) { b.click(); break; }
      }, i);
      await new Promise(r => setTimeout(r, 2000));
    }
    const html = await page.content();
    await processMenus(BRAND, parseMega(html), foundIds);
  }
  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 2. 스타벅스 실행 로직 (단일 페이지)
 */
async function runStarbucks(page) {
  const BRAND = "스타벅스";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await FirebaseService.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  await page.goto("https://www.starbucks.co.kr/menu/drink_list.do", { waitUntil: 'networkidle2' });
  const html = await page.content();
  
  await processMenus(BRAND, parseStarbucks(html), foundIds);
  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 3. 컴포즈커피 실행 로직 (다중 페이지 URL)
 */
async function runCompose(page) {
  const BRAND = "컴포즈커피";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await FirebaseService.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  for (let i = 1; i <= 20; i++) { // 최대 20페이지까지 순회
    const URL = i === 1 ? "https://composecoffee.com/menu" : `https://composecoffee.com/menu?page=${i}`;
    await page.goto(URL, { waitUntil: 'networkidle2' });
    
    const html = await page.content();
    const rawMenus = parseCompose(html);
    
    if (rawMenus.length === 0) break; // 메뉴 없으면 조기 종료
    
    await processMenus(BRAND, rawMenus, foundIds);
    await new Promise(r => setTimeout(r, 1000)); // 부하 방지
  }
  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 4. 이디야커피 실행 로직 (Hidden Input 감지 방식)
 */
async function runEdiya(page) {
  const toppingBlacklist = await getEdiyaToppingBlacklist(page);
  
  const BRAND = "이디야커피";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await FirebaseService.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  const URL = "https://www.ediya.com/contents/drink.html";
  await page.goto(URL, { waitUntil: 'networkidle2' });

  // --- [더보기 버튼 클릭 로직: Hidden Input 감지] ---
  console.log("   🖱️ 전체 메뉴 로딩 중 (페이지 값 변화 감지)...");

  let clickCount = 0;
  
  while (true) {
    try {
      // 1. 현재 페이지 번호(Hidden Input 값) 가져오기
      // 값이 없으면 '1'로 가정
      const prevPageVal = await page.$eval('#menu_page', el => el.value).catch(() => null);
      
      // 2. 더보기 버튼 찾기
      // 버튼이 아예 없거나(모두 로딩됨), display: none 상태인지 확인
      const moreButton = await page.$('.line_btn');
      if (!moreButton || !(await moreButton.boundingBox())) {
        console.log("   ✅ 더보기 버튼이 더 이상 보이지 않습니다. 로딩 완료.");
        break;
      }

      // 3. 클릭 실행
      await page.evaluate(btn => btn.click(), moreButton);
      
      // 4. 변화 감지 (핵심 로직 ⭐️)
      // "menu_page의 value가 아까 저장한 prevPageVal과 달라질 때까지 기다려라"
      try {
        await page.waitForFunction(
          (oldVal) => {
            const el = document.querySelector('#menu_page');
            return el && el.value !== oldVal;
          },
          { timeout: 2000 }, // 2초 안에 안 바뀌면 끝난 걸로 간주
          prevPageVal
        );
        
        clickCount++;
        // 진행 상황 로그 (선택 사항)
        // const newVal = await page.$eval('#menu_page', el => el.value);
        // console.log(`      └ ${clickCount}회 클릭 성공 (Page: ${prevPageVal} -> ${newVal})`);

      } catch (timeout) {
        console.log("   ⚠️ 클릭했으나 페이지 번호가 변하지 않습니다. (마지막 페이지 도달)");
        break;
      }

    } catch (err) {
      console.log(`   ❌ 로직 수행 중 에러 발생: ${err.message}`);
      break;
    }
  }

  console.log(`   🔄 총 ${clickCount}회 더보기 클릭 완료.`);
  
  // 잠시 렌더링 안정화 대기
  await new Promise(r => setTimeout(r, 1000));

  // ---------------------------

  // 전체 로딩된 HTML 파싱
  const html = await page.content();
  const rawMenus = parseEdiya(html);

  console.log(`   📦 총 ${rawMenus.length}개의 메뉴 발견`);

  // 3. 필터링하여 업로드
  const filteredMenus = rawMenus.filter(menu => !toppingBlacklist.has(menu.menu_name));
  
  await processMenus(BRAND, filteredMenus, foundIds);
  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 5. 폴 바셋 실행 로직 (다중 카테고리 순회)
 * - cid1=A (커피), B (음료), C (아이스크림)
 */
async function runPaulBassett(page) {
  const BRAND = "폴 바셋";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await FirebaseService.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  // 순회할 카테고리 목록
  const CATEGORIES = ['A', 'B', 'C'];

  for (const catId of CATEGORIES) {
    const LIST_URL = `https://www.baristapaulbassett.co.kr/menu/List.pb?cid1=${catId}`;
    console.log(`📂 카테고리(ID:${catId}) 진입 중...`);

    // 1. 리스트 페이지 접속
    await page.goto(LIST_URL, { waitUntil: 'networkidle2' });

    // 2. 리스트 파싱 (상세 URL 확보)
    const listHtml = await page.content();
    const menuItems = parsePaulBassettList(listHtml);

    console.log(`   🔗 [Category ${catId}] ${menuItems.length}개의 메뉴 발견.`);

    // 3. 상세 페이지 순회
    for (const [index, item] of menuItems.entries()) {
      try {
        // 상세 페이지 이동
        await page.goto(item.detailUrl, { waitUntil: 'networkidle2' });
        
        // 상세 HTML 파싱
        const detailHtml = await page.content();
        const menuData = parsePaulBassettDetail(detailHtml, item);

        // 데이터 검증
        const { isValid, data } = ValidatorService.validate(menuData);
        
        // 카테고리 필터링 (제외대상 아니면 업로드)
        if (isValid && data.category !== "제외대상") {
          const result = await FirebaseService.uploadMenu(data);
          
          if (result.success && result.docId) {
            foundIds.add(result.docId);
          }
          console.log(`      ✅ [${index + 1}/${menuItems.length}] 업로드: ${data.menu_name}`);
        }

        // 서버 부하 방지 (0.5초 대기)
        await new Promise(r => setTimeout(r, 500));

      } catch (err) {
        console.error(`      ❌ [${item.name}] 처리 실패:`, err.message);
      }
    }
  }

  // 4. 모든 카테고리 순회 후 비활성화 처리 (Snapshot 비교)
  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 6. 매머드 통합 실행 로직 (익스프레스 & 매머드커피)
 */
async function runMammoth() {
  // 크롤링할 대상 목록 정의
  const TARGETS = [
    {
      brandName: "매머드 익스프레스",
      listUrl: "https://mmthcoffee.com/sub/menu/list.html"
    },
    {
      brandName: "매머드커피",
      listUrl: "https://mmthcoffee.com/sub/menu/list_coffee.php"
    }
  ];

  for (const target of TARGETS) {
    console.log(`🚀 [${target.brandName}] 크롤링 시작...`);
    
    // 해당 브랜드의 기존 ID 목록 가져오기 (비활성화 로직용)
    const oldIds = await FirebaseService.getAllMenuIdsByBrand(target.brandName);
    const foundIds = new Set();

    try {
      // 1. 목록 페이지 요청
      const { data: listHtml } = await axios.get(target.listUrl);

      // 2. 파서를 통해 메뉴 ID 목록 추출
      const menuList = getMenuIds(listHtml);
      console.log(`   🔗 [${target.brandName}] 총 ${menuList.length}개의 타겟 메뉴 발견.`);

      // 3. 상세 조회 및 업로드
      for (const [index, menu] of menuList.entries()) {
        // 상세 페이지 URL 구조는 두 브랜드가 동일함 (menuSeq만 다름)
        const detailUrl = `https://mmthcoffee.com/sub/menu/list_coffee_view.php?menuSeq=${menu.id}`;
        
        try {
          const { data: detailHtml } = await axios.get(detailUrl);
          
          // 파서 호출 (파서가 리턴하는 brand_name은 무시하고 아래에서 덮어씌움)
          const variants = parseDetail(detailHtml, menu); 

          for (const variant of variants) {
            const mergedData = {
              ...variant,          // 파서가 준 데이터 전개
              brand_name: target.brandName, // ★ 여기서 브랜드명을 현재 타겟으로 강제 지정
              // 필요하다면 categoryCode 등도 여기서 보정 가능
            };

            // 데이터 검증
            const { isValid, data, error } = ValidatorService.validate(mergedData);
            
            if (isValid) {
              const result = await FirebaseService.uploadMenu(data);
              if (result.success && result.docId) {
                foundIds.add(result.docId);
              }
              console.log(`      ✅ [${target.brandName}] (${index + 1}/${menuList.length}) 업로드: ${data.menu_name}`);
            } else {
              // console.log(`      ⚠️ 검증 실패 [${variant.menu_name}]:`, error);
            }
          }

          // 서버 부하 방지
          await new Promise(r => setTimeout(r, 100));

        } catch (err) {
          console.error(`      ❌ [${menu.name}] 상세 조회 실패:`, err.message);
        }
      }

      // 4. 해당 브랜드에 대한 비활성화 처리
      await finalizeDeactivation(target.brandName, oldIds, foundIds);

    } catch (err) {
      console.error(`   ❌ [${target.brandName}] 전체 프로세스 오류:`, err.message);
    }
    
    console.log(`-----------------------------------------`);
  }
}

/**
 * 7. 빽다방 실행 로직 (다중 URL 순회)
 */
async function runPaik(page) {
  const BRAND = "빽다방";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await FirebaseService.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  // 빽다방은 카테고리별로 URL이 다름
  const TARGET_URLS = [
    "https://paikdabang.com/menu/menu_coffee/",   // 커피
    "https://paikdabang.com/menu/menu_drink/",    // 음료
    "https://paikdabang.com/menu/menu_ccino/",    // 빽스치노
    "https://paikdabang.com/menu/menu_dessert/"   // 아이스크림/디저트
  ];

  for (const url of TARGET_URLS) {
    try {
      console.log(`   📂 페이지 이동 중: ${url}`);
      await page.goto(url, { waitUntil: 'networkidle2' });
      
      // 메뉴 리스트가 로딩될 때까지 대기 (안전장치)
      await page.waitForSelector('.menu_list', { timeout: 5000 }).catch(() => {
        console.log("      ⚠️ 메뉴 리스트를 찾을 수 없음 (빈 페이지 가능성)");
      });

      const html = await page.content();
      const rawMenus = parsePaik(html); // 파서 호출

      console.log(`      🔗 ${rawMenus.length}개의 메뉴 발견.`);

      // 공통 업로드 로직 사용
      await processMenus(BRAND, rawMenus, foundIds);

      // 서버 부하 방지 대기
      await new Promise(r => setTimeout(r, 1000));

    } catch (err) {
      console.error(`   ❌ [${url}] 처리 중 오류:`, err.message);
    }
  }

  // 비활성화 처리
  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 8. 더벤티 실행 로직
 * - mode=1 ~ 7 순회
 */
async function runTheVenti(page) {
  const BRAND = "더벤티";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await FirebaseService.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  // 모드 1(신메뉴) ~ 7(베버리지) 순회
  for (let mode = 1; mode <= 7; mode++) {
    const listUrl = `https://www.theventi.co.kr/new2022/menu/all.html?mode=${mode}`;
    console.log(`   📂 페이지 이동 중: mode=${mode}`);

    try {
      // 1. 리스트 페이지 가져오기 (Axios 사용 권장, 속도 때문)
      // 더벤티는 SSR(Server Side Rendering)에 가까워 Axios로 충분히 가져올 수 있습니다.
      const { data: listHtml } = await axios.get(listUrl);
      
      // 2. 메뉴 URL 목록 파싱
      const menuList = getVentiMenuUrls(listHtml); 
      console.log(`      🔗 ${menuList.length}개의 메뉴 발견.`);

      // 3. 상세 페이지 순회
      for (const [index, menu] of menuList.entries()) {
        try {
          const { data: detailHtml } = await axios.get(menu.detailUrl);
          
          // 파서 호출 (배열 반환: HOT/ICE 분리됨)
          const variants = parseVentiDetail(detailHtml, menu);

          for (const variant of variants) {
            const { isValid, data, error } = ValidatorService.validate(variant);

            if (isValid) {
              const result = await FirebaseService.uploadMenu(data);
              if (result.success && result.docId) {
                foundIds.add(result.docId);
              }
              console.log(`      ✅ [${mode}-${index + 1}] 업로드: ${data.menu_name}`);
            } else {
               // 검증 실패 로그 (필요시 주석 해제)
               // console.log(`      ⚠️ 검증 실패 [${variant.menu_name}]: ${error}`);
            }
          }
          
          // 서버 부하 방지
          await new Promise(r => setTimeout(r, 100));

        } catch (err) {
          console.error(`      ❌ [${menu.name}] 상세 조회 실패:`, err.message);
        }
      }
    } catch (err) {
      console.error(`   ❌ [mode=${mode}] 페이지 로드 실패:`, err.message);
    }
  }

  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 9. 엔제리너스 실행 로직
 * - 영양성분(Data) + 주문페이지(Image/ID) + 상세페이지(Description)
 */
async function runAngel() {
  const BRAND = "엔제리너스";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await FirebaseService.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  try {
    const nutritionUrl = "https://www.lotteeatz.com/upload/etc/angel/items.html";
    const orderingUrl = "https://www.lotteeatz.com/brand/angel"; 

    console.log(`   📂 기본 데이터 수집 중...`);

    // 1. 영양정보 & 주문페이지 병렬 요청
    const [nutritionRes, orderingRes] = await Promise.all([
      axios.get(nutritionUrl),
      axios.get(orderingUrl) 
    ]);

    // 2. 이미지 & ID 맵핑 생성
    const infoMap = parseAngelImages(orderingRes.data);
    console.log(`      🖼️ 매핑 정보 ${infoMap.size}개 확보.`);

    // 3. 1차 파싱 (영양정보 + 이미지 + ID)
    const rawMenus = parseAngel(nutritionRes.data, infoMap);
    console.log(`      🔗 총 ${rawMenus.length}개의 메뉴 1차 파싱 완료.`);

    // 4. 상세 페이지 순회 (Description 수집) 및 업로드
    for (const [index, menu] of rawMenus.entries()) {
      
      // 상품 ID가 있는 경우에만 상세 페이지 접속
      if (menu.productId) {
        try {
          const detailUrl = `https://www.lotteeatz.com/products/introductions/${menu.productId}?rccode=brnd_main`;
          const { data: detailHtml } = await axios.get(detailUrl);
          
          // 설명글 파싱하여 덮어쓰기
          const desc = parseAngelDescription(detailHtml);
          if (desc) {
            menu.description = desc;
          }
        } catch (detailErr) {
          // 상세 페이지 조회 실패해도 크리티컬하지 않으므로 로그만 남기고 진행
          // console.warn(`      ⚠️ 상세 조회 실패 [${menu.menu_name}]: ${detailErr.message}`);
        }
      }

      // DB 저장을 위해 임시 필드(productId) 삭제
      delete menu.productId;

      // 데이터 검증 및 업로드
      const { isValid, data, error } = ValidatorService.validate(menu);

      if (isValid) {
        const result = await FirebaseService.uploadMenu(data);
        if (result.success && result.docId) {
          foundIds.add(result.docId);
        }
        console.log(`      ✅ [${index + 1}/${rawMenus.length}] 업로드: ${data.menu_name}`);
      } else {
         // console.log(`      ⚠️ 검증 실패 [${menu.menu_name}]: ${error}`);
      }
      
      // 서버 부하 방지 (상세 페이지 호출이 많으므로 텀을 줌)
      if (index % 10 === 0) await new Promise(r => setTimeout(r, 200));
    }

  } catch (err) {
    console.error(`   ❌ ${BRAND} 로직 실패:`, err.message);
  }

  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 10. 투썸플레이스 실행 로직
 * - 커피/음료 탭 -> 하위 탭 순회
 */
async function runTwosome(page) {
  const BRAND = "투썸플레이스";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await FirebaseService.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  const TABS = ['01', '02', '03']; 

  for (const midCd of TABS) {
    let listUrl = `https://mo.twosome.co.kr/mn/menuInfoList.do?grtCd=1&pMidCd=${midCd}`;
    console.log(`   📂 탭 이동 중: ${midCd}`);
    
    try {
      await page.goto(listUrl, { waitUntil: 'networkidle2' });

      // 목록 파싱
      const listHtml = await page.content();
      const menuList = parseTwosomeList(listHtml);
      console.log(`      🔗 ${midCd}: ${menuList.length}개의 메뉴 발견.`);

      for (const [index, menuItem] of menuList.entries()) {
        try {
          await page.goto(menuItem.detailUrl, { waitUntil: 'networkidle2' });
          
          try { await page.waitForSelector('.text_list_ts24_type02', { timeout: 3000 }); } catch(e) {}

          // ⭐️ [수정된 로직] 첫 번째 컨테이너만 타겟팅 ⭐️
          // 전체 문서에서 탭을 찾지 않고, 첫 번째 컨테이너 안에서만 찾음
          const container = await page.$('.ts24_select_drink_size'); 

          if (container) {
            // 컨테이너 내부의 탭만 조회
            const sizeTabs = await container.$$('ul li a'); 
            const tabCount = sizeTabs.length; // 이제 중복 없이 3개(레,라,맥)만 잡힐 것임

            if (tabCount > 0) {
              for (let i = 0; i < tabCount; i++) {
                // 스코프 내에서 클릭
                await page.evaluate((idx) => {
                  // querySelectorAll은 문서 전체에서 찾지만, 우리는 첫 번째 놈만 클릭하면 됨
                  // (투썸 로직상 하나를 클릭하면 나머지도 연동되거나, 첫 번째가 메인임)
                  const container = document.querySelector('.ts24_select_drink_size');
                  const tabs = container.querySelectorAll('ul li a');
                  if (tabs[idx]) tabs[idx].click();
                }, i);

                await new Promise(r => setTimeout(r, 500)); // AJAX 대기

                const currentHtml = await page.content();
                const menuData = parseTwosomeDetail(currentHtml, menuItem);

                await uploadAndLog(menuData, index, menuList.length, `[Size ${i+1}/${tabCount}]`);
              }
            } else {
               // 탭이 없는 경우 (컨테이너는 있는데 탭이 없을 수 있음?)
               const currentHtml = await page.content();
               const menuData = parseTwosomeDetail(currentHtml, menuItem);
               await uploadAndLog(menuData, index, menuList.length, '[Single]');
            }
          } else {
            // 탭 컨테이너 자체가 없는 경우 (단일 사이즈)
            const currentHtml = await page.content();
            const menuData = parseTwosomeDetail(currentHtml, menuItem);
            await uploadAndLog(menuData, index, menuList.length, '[Single]');
          }

        } catch (err) {
          console.error(`      ❌ [${menuItem.name}] 상세 실패:`, err.message);
        }
      }

    } catch (err) {
      console.error(`   ❌ 탭 [${midCd}] 처리 실패:`, err.message);
    }
  }

  await finalizeDeactivation(BRAND, oldIds, foundIds);

  // 헬퍼 함수: 업로드 및 로그 출력
  async function uploadAndLog(menuData, index, total, suffixLog) {
    const { isValid, data, error } = ValidatorService.validate(menuData);
    if (isValid) {
      const result = await FirebaseService.uploadMenu(data);
      if (result.success && result.docId) foundIds.add(result.docId);
      console.log(`      ✅ [${index + 1}/${total}]${suffixLog} 업로드: ${data.menu_name}`);
    } else {
       // console.log(`      ⚠️ 검증 실패 [${menuData.menu_name}]: ${error}`);
    }
  }
}

/**
 * 11. 요거프레소 실행 로직
 */
async function runYogerpresso() {
  const BRAND = "요거프레소";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await FirebaseService.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  // 수집할 카테고리 목록 (cateno)
  // 1:커피, 34:요거트라떼, 2:스무디, 36:쉐이크, 23:한입, 32:토핑, 35:에이드/티, 3:빙수, 22:신메뉴
  const CATEGORIES = [
    { id: 22, name: '신메뉴' },
    { id: 1, name: '커피/음료' },
    { id: 34, name: '요거트 라떼' },
    { id: 2, name: '요거트 스무디' },
    { id: 36, name: '요거트 쉐이크' },
    { id: 23, name: '한입요거트' },
    { id: 35, name: '에이드/티' },
    { id: 3, name: '빙수' }
  ];

  for (const cat of CATEGORIES) {
    const listUrl = `https://www.yogerpresso.co.kr/menu/menu.html?cateno=${cat.id}`;
    console.log(`   📂 카테고리 이동 중: ${cat.name} (${cat.id})`);

    try {
      // 1. 목록 페이지 요청
      const { data: listHtml } = await axios.get(listUrl);
      
      // 2. 상세 페이지 URL 추출
      const menuList = getYogerMenuUrls(listHtml);
      console.log(`      🔗 ${menuList.length}개의 메뉴 발견.`);

      // 3. 상세 페이지 순회
      for (const [index, menuItem] of menuList.entries()) {
        try {
          // 팝업 HTML 요청
          const { data: detailHtml } = await axios.get(menuItem.detailUrl);
          
          // 파싱
          const menuData = parseYogerDetail(detailHtml, menuItem, cat.name);

          // 검증 및 업로드
          const { isValid, data } = ValidatorService.validate(menuData);
          if (isValid) {
            const result = await FirebaseService.uploadMenu(data);
            if (result.success && result.docId) foundIds.add(result.docId);
            console.log(`      ✅ [${cat.name}-${index + 1}] 업로드: ${data.menu_name}`);
          }

          // 부하 방지
          await new Promise(r => setTimeout(r, 100));

        } catch (err) {
          console.error(`      ❌ [${menuItem.name}] 상세 실패:`, err.message);
        }
      }

    } catch (err) {
      console.error(`   ❌ [${cat.name}] 페이지 로드 실패:`, err.message);
    }
  }

  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 12. 탐앤탐스 실행 로직
 * - 더보기 버튼 반복 클릭 (메뉴 개수 변화 감지)
 * - 각 메뉴 클릭 -> 팝업 띄우기 -> 파싱 -> 닫기
 */
async function runTomNToms(page) {
  const BRAND = "탐앤탐스";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await FirebaseService.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  try {
    const url = "https://www.tomntoms.com/menu";
    await page.goto(url, { waitUntil: 'networkidle2' });

    // 1. "음료" 탭 클릭
    const tabClicked = await page.evaluate(() => {
      const buttons = Array.from(document.querySelectorAll('button'));
      const drinkBtn = buttons.find(b => b.textContent.trim() === '음료');
      if (drinkBtn) {
        drinkBtn.click();
        return true;
      }
      return false;
    });

    if (tabClicked) {
      console.log("   🖱️ '음료' 탭 클릭 완료");
      await new Promise(r => setTimeout(r, 2000));
    }

    // 2. "더보기" 버튼 반복 클릭 로직 (수정됨)
    console.log("   🖱️ 전체 메뉴 로딩 중...");
    
    let prevItemCount = 0;

    while (true) {
      try {
        // 현재 로딩된 메뉴 개수 확인
        // 탐앤탐스 메뉴 버튼 ID 패턴: headlessui-popover-button-
        const currentItems = await page.$$('button[id^="headlessui-popover-button-"]');
        const currentItemCount = currentItems.length;

        // 더보기 버튼 찾기
        const moreBtn = await page.$('button.custom-button.main-tab');

        // 종료 조건 1: 버튼이 아예 없음
        if (!moreBtn) {
            console.log("   ✅ 더보기 버튼이 없습니다.");
            break; 
        }

        // 종료 조건 2: 버튼이 비활성화(disabled) 됨
        const isDisabled = await page.evaluate(btn => btn.disabled, moreBtn);
        if (isDisabled) {
            console.log("   ✅ 더보기 버튼이 비활성화되었습니다.");
            break;
        }

        // 종료 조건 3: 클릭을 했는데도 메뉴 개수가 늘어나지 않음 (첫 루프 제외)
        if (prevItemCount > 0 && currentItemCount === prevItemCount) {
            console.log(`   ✅ 메뉴가 더 이상 추가되지 않습니다. (총 ${currentItemCount}개)`);
            break;
        }

        // 상태 업데이트 및 클릭 실행
        prevItemCount = currentItemCount;
        
        await moreBtn.click();
        process.stdout.write("."); // 진행 표시
        await new Promise(r => setTimeout(r, 1000)); // 로딩 대기 (충분히 줌)

      } catch (e) {
        console.log(`   ⚠️ 더보기 처리 중 예외 발생: ${e.message}`);
        break;
      }
    }
    console.log("\n   ✅ 전체 메뉴 로딩 완료");

    // 3. 메뉴 리스트 확보
    const menuButtons = await page.$$('button[id^="headlessui-popover-button-"]');
    console.log(`      🔗 총 ${menuButtons.length}개의 메뉴 버튼 발견.`);

    // 4. 순회하며 상세 정보 수집 (기존과 동일)
    for (let i = 0; i < menuButtons.length; i++) {
      try {
        // DOM Element가 리렌더링으로 인해 끊길 수 있으므로 매번 다시 쿼리
        const buttons = await page.$$('button[id^="headlessui-popover-button-"]');
        const btn = buttons[i];

        if (!btn) continue;

        const imageUrl = await btn.$eval('img', el => el.src).catch(() => "");

        await btn.click();
        
        try {
           await page.waitForSelector('div[id^="headlessui-popover-panel-"]', { timeout: 2000, visible: true });
        } catch (e) {
           // console.log(`      ⚠️ 팝업 열기 실패 (Index: ${i})`);
           continue;
        }

        const popoverContent = await page.$eval('div[id^="headlessui-popover-panel-"]', el => el.outerHTML);
        const menuData = parseTomNTomsDetail(popoverContent, imageUrl);

        const { isValid, data } = ValidatorService.validate(menuData);
        if (isValid) {
          const result = await FirebaseService.uploadMenu(data);
          if (result.success && result.docId) foundIds.add(result.docId);
          console.log(`      ✅ [${i + 1}/${menuButtons.length}] 업로드: ${data.menu_name}`);
        }

        const closeBtn = await page.$('div[id^="headlessui-popover-panel-"] div.flex.justify-between button');
        if (closeBtn) {
            await closeBtn.click();
        } else {
            await page.keyboard.press('Escape');
        }
        
        await new Promise(r => setTimeout(r, 200));

      } catch (err) {
        console.error(`      ❌ 메뉴 처리 중 오류:`, err.message);
        await page.keyboard.press('Escape');
      }
    }

  } catch (err) {
    console.error(`   ❌ ${BRAND} 로직 실패:`, err.message);
  }

  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

async function main() {
  const browser = await puppeteer.launch({ 
    headless: "new",
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

  try {
    /*
    await runMega(page);
    console.log("-----------------------------------------");
    await runStarbucks(page);
    console.log("-----------------------------------------");
    await runCompose(page);
    console.log("-----------------------------------------");
    await runEdiya(page);
    console.log("-----------------------------------------");    
    await runPaulBassett(page);
    console.log("-----------------------------------------");
    await runPaik(page);
    console.log("-----------------------------------------");
    await runMammoth(); 
    console.log("-----------------------------------------");
    await runTheVenti();
    console.log("-----------------------------------------");
    await runAngel();
    console.log("-----------------------------------------");
    await runTwosome(page);
    console.log("-----------------------------------------");
    await runYogerpresso(page);
    console.log("-----------------------------------------");
    await runTomNToms(page);
    */
    await runMammoth(); 
    console.log("-----------------------------------------");
  } catch (error) {
    console.error("❌ 전체 프로세스 중 오류 발생:", error);
  } finally {
    await browser.close();
    console.log("🏁 전체 크롤링 및 데이터 동기화 완료");
  }
}

main();