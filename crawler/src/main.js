const puppeteer = require('puppeteer');
const cheerio = require('cheerio');
const { parseMega } = require('../parsers/megaParser');
const { parseStarbucks } = require('../parsers/starbucksParser');
const { parseCompose } = require('../parsers/composeParser');
const { parseEdiya } = require('../parsers/ediyaParser');

const ValidatorService = require('./services/validatorService');
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
    */
    await runEdiya(page);
    console.log("-----------------------------------------");
  } catch (error) {
    console.error("❌ 전체 프로세스 중 오류 발생:", error);
  } finally {
    await browser.close();
    console.log("🏁 전체 크롤링 및 데이터 동기화 완료");
  }
}

main();