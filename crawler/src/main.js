const puppeteer = require('puppeteer');
const cheerio = require('cheerio');
const axios = require('axios');

const { parseMega } = require('../parsers/megaParser');
const { parseStarbucks, parseStarbucksAjaxDetail } = require('../parsers/starbucksParser');
const { parseComposeCategoryPage, parseComposeDetail } = require('../parsers/composeParser');
const { parseEdiya } = require('../parsers/ediyaParser');
const { parsePaulBassettList, parsePaulBassettDetail } = require('../parsers/paulParser');
const { getMenuIds, parseDetail } = require('../parsers/mammothParser');
const { parsePaik } = require('../parsers/paikParser');
const { getMenuUrls: getVentiMenuUrls, parseDetail: parseVentiDetail } = require('../parsers/theVentiParser');
const { parseAngel, parseAngelImages, parseAngelDescription } = require('../parsers/angelinusParser');
const { parseTwosomeList, parseTwosomeDetail } = require('../parsers/twosomeParser');
const { getMenuUrls: getYogerMenuUrls, parseDetail: parseYogerDetail } = require('../parsers/yogerParser');
const { parseTomNTomsDetail } = require('../parsers/tmntmsParser');

const MenuRepository = require('./services/menuRepository');
const ValidatorService = require('./services/validatorService');

const pool = require('./services/db/mysql');

/**
 * 검증 + 업로드 + 발견 ID 기록
 */
async function uploadValidatedMenu(rawMenu, foundSet, logPrefix = '') {
  const { isValid, data, error } = ValidatorService.validate(rawMenu);

  if (!isValid) {
    if (logPrefix) {
      console.log(`      ⚠️ ${logPrefix}검증 실패: ${rawMenu?.menu_name || 'unknown'} ${error ? `- ${error}` : ''}`);
    }
    return null;
  }

  const result = await MenuRepository.uploadMenu(data);

  if (result.success && result.docId) {
    foundSet.add(result.docId);
    return { result, data };
  }

  return null;
}

/**
 * [공통 로직] 데이터 검증, 업로드 및 발견된 ID 수집
 */
async function processMenus(brandName, rawMenus, foundSet) {
  for (const menu of rawMenus) {
    await uploadValidatedMenu(menu, foundSet, `[${brandName}] `);
  }
}

/**
 * [공통 로직] 사라진 메뉴 비활성화
 */
async function finalizeDeactivation(brandName, oldIds, foundIds) {
  const missingIds = [...oldIds].filter(id => !foundIds.has(id));

  if (missingIds.length > 0) {
    console.log(`📉 [${brandName}] 사라진 메뉴 ${missingIds.length}개 비활성화 중...`);
    await MenuRepository.deactivateMenus(missingIds);
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
          { timeout: 2000 },
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
 * 1. 메가커피 실행 로직
 */
async function runMega(page) {
  const BRAND = "메가MGC커피";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await MenuRepository.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  const URL = "https://www.mega-mgccoffee.com/menu/?menu_category1=1&menu_category2=1";
  await page.goto(URL, { waitUntil: 'networkidle2' });

  const pageButtons = await page.$$("#board_page li a");
  const totalPages = pageButtons.length || 1;

  for (let i = 1; i <= totalPages; i++) {
    if (i > 1) {
      await page.evaluate((n) => {
        const btns = document.querySelectorAll("#board_page li a");
        for (const b of btns) {
          if (b.innerText.trim() == n) {
            b.click();
            break;
          }
        }
      }, i);
      await new Promise(r => setTimeout(r, 2000));
    }

    const html = await page.content();
    await processMenus(BRAND, parseMega(html), foundIds);
  }

  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 2. 스타벅스 실행 로직
 */
async function runStarbucks(page) {
  const BRAND = "스타벅스";
  const LIST_URL = "https://www.starbucks.co.kr/menu/drink_list.do";
  const AJAX_URL = "https://www.starbucks.co.kr/menu/productViewAjax.do";

  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await MenuRepository.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  await page.goto(LIST_URL, { waitUntil: 'networkidle2' });
  const html = await page.content();
  const rawMenus = parseStarbucks(html);

  console.log(`   🔗 총 ${rawMenus.length}개의 메뉴 발견.`);

  for (const [index, menu] of rawMenus.entries()) {
    try {
      if (menu.product_id) {
        const body = new URLSearchParams({
          product_cd: menu.product_id,
        }).toString();

        const { data } = await axios.post(AJAX_URL, body, {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': LIST_URL,
            'User-Agent': 'Mozilla/5.0',
          },
        });

        const detail = parseStarbucksAjaxDetail(data);

        if (detail.description) {
          menu.description = detail.description;
        }

        menu.allergy_info = detail.allergy_info;
      }

      delete menu.product_id;

      const uploaded = await uploadValidatedMenu(
        menu,
        foundIds,
        `[${BRAND} ${index + 1}/${rawMenus.length}] `
      );

      if (uploaded) {
        console.log(
          `      ✅ [${index + 1}/${rawMenus.length}] 업로드: ${uploaded.data.menu_name}`
        );
      }
    } catch (err) {
      console.error(`      ❌ [${menu.menu_name}] 상세 설명/알레르기 조회 실패:`, err.message);
    }

    if ((index + 1) % 10 === 0) {
      await new Promise(r => setTimeout(r, 200));
    }
  }

  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 3. 컴포즈커피 실행 로직
 */
async function runCompose(page) {
  const BRAND = "컴포즈커피";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await MenuRepository.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();
  const seenMenuIds = new Set();

  const CATEGORIES = [
    { name: '컴포즈 콤보', url: 'https://composecoffee.com/menu/category/207002' },
    { name: '시즌한정', url: 'https://composecoffee.com/menu/category/192677' },
    { name: '커피 · 더치', url: 'https://composecoffee.com/menu/category/185' },
    { name: '논커피 라떼', url: 'https://composecoffee.com/menu/category/187' },
    { name: '프라페 · 스무디', url: 'https://composecoffee.com/menu/category/192' },
    { name: '밀크쉐이크', url: 'https://composecoffee.com/menu/category/193' },
    { name: '에이드 · 주스', url: 'https://composecoffee.com/menu/category/188' },
    { name: '티', url: 'https://composecoffee.com/menu/category/191' },
  ];

  for (const category of CATEGORIES) {
    console.log(`   📂 카테고리 이동 중: ${category.name}`);

    let pageNo = 1;

    while (true) {
      const pageUrl = pageNo === 1
        ? category.url
        : `${category.url}?page=${pageNo}`;

      try {
        const { data: listHtml } = await axios.get(pageUrl, {
          headers: { 'User-Agent': 'Mozilla/5.0' },
        });

        const menuItems = parseComposeCategoryPage(listHtml, category.name);

        if (menuItems.length === 0) {
          if (pageNo === 1) {
            console.log(`      ⚠️ ${category.name}: 메뉴를 찾지 못했습니다.`);
          }
          break;
        }

        console.log(`      🔗 ${category.name} page=${pageNo}: ${menuItems.length}개의 메뉴 발견.`);

        for (const [index, item] of menuItems.entries()) {
          if (seenMenuIds.has(item.menuId)) {
            continue;
          }
          seenMenuIds.add(item.menuId);

          try {
            const { data: detailHtml } = await axios.get(item.detailUrl, {
              headers: { 'User-Agent': 'Mozilla/5.0' },
            });

            const menuData = parseComposeDetail(detailHtml, item, category.name);

            const uploaded = await uploadValidatedMenu(
              menuData,
              foundIds,
              `[${BRAND} ${category.name} p${pageNo} ${index + 1}/${menuItems.length}] `
            );

            if (uploaded) {
              console.log(
                `      ✅ [${category.name} p${pageNo} ${index + 1}/${menuItems.length}] 업로드: ${uploaded.data.menu_name}`
              );
            }

            await new Promise(r => setTimeout(r, 100));
          } catch (err) {
            console.error(`      ❌ [${item.name}] 상세 조회 실패:`, err.message);
          }
        }

        const $ = cheerio.load(listHtml);
        const hasNextPage =
          $('li.page-item:not(.disabled) > a.page-link[aria-label="Next"]').length > 0;

        if (!hasNextPage) {
          break;
        }

        pageNo += 1;
      } catch (err) {
        console.error(`   ❌ [${category.name} page=${pageNo}] 페이지 로드 실패:`, err.message);
        break;
      }
    }
  }

  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 4. 이디야커피 실행 로직
 */
async function runEdiya(page) {
  const toppingBlacklist = await getEdiyaToppingBlacklist(page);

  const BRAND = "이디야커피";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await MenuRepository.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  const URL = "https://www.ediya.com/contents/drink.html";
  await page.goto(URL, { waitUntil: 'networkidle2' });

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
          { timeout: 2000 },
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

  const filteredMenus = rawMenus.filter(menu => !toppingBlacklist.has(menu.menu_name));

  await processMenus(BRAND, filteredMenus, foundIds);
  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 5. 폴 바셋 실행 로직
 */
async function runPaulBassett(page) {
  const BRAND = "폴 바셋";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await MenuRepository.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  const CATEGORIES = ['A', 'B', 'C'];

  for (const catId of CATEGORIES) {
    const LIST_URL = `https://www.baristapaulbassett.co.kr/menu/List.pb?cid1=${catId}`;
    console.log(`📂 카테고리(ID:${catId}) 진입 중...`);

    await page.goto(LIST_URL, { waitUntil: 'networkidle2' });

    const listHtml = await page.content();
    const menuItems = parsePaulBassettList(listHtml, catId);

    console.log(`   🔗 [Category ${catId}] ${menuItems.length}개의 메뉴 발견.`);

    for (const [index, item] of menuItems.entries()) {
      try {
        await page.goto(item.detailUrl, { waitUntil: 'networkidle2' });

        const detailHtml = await page.content();
        const menuData = parsePaulBassettDetail(detailHtml, item);

        const { isValid, data } = ValidatorService.validate(menuData);

        if (isValid && data.category !== "제외대상") {
          const result = await MenuRepository.uploadMenu(data);

          if (result.success && result.docId) {
            foundIds.add(result.docId);
          }

          console.log(`      ✅ [${index + 1}/${menuItems.length}] 업로드: ${data.menu_name}`);
        }

        await new Promise(r => setTimeout(r, 500));
      } catch (err) {
        console.error(`      ❌ [${item.name}] 처리 실패:`, err.message);
      }
    }
  }

  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 6. 매머드 통합 실행 로직
 */
async function runMammoth() {
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

    const oldIds = await MenuRepository.getAllMenuIdsByBrand(target.brandName);
    const foundIds = new Set();

    try {
      const { data: listHtml } = await axios.get(target.listUrl);

      const menuList = getMenuIds(listHtml);
      console.log(`   🔗 [${target.brandName}] 총 ${menuList.length}개의 타겟 메뉴 발견.`);

      for (const [index, menu] of menuList.entries()) {
        const detailUrl = `https://mmthcoffee.com/sub/menu/list_coffee_view.php?menuSeq=${menu.id}`;

        try {
          const { data: detailHtml } = await axios.get(detailUrl);
          const variants = parseDetail(detailHtml, {
            ...menu,
            brandName: target.brandName,
          });

          for (const variant of variants) {
            const mergedData = {
              ...variant,
              brand_name: target.brandName,
            };

            const uploaded = await uploadValidatedMenu(
              mergedData,
              foundIds,
              `[${target.brandName} ${index + 1}/${menuList.length}] `
            );

            if (uploaded) {
              console.log(`      ✅ [${target.brandName}] (${index + 1}/${menuList.length}) 업로드: ${uploaded.data.menu_name}`);
            }
          }

          await new Promise(r => setTimeout(r, 100));
        } catch (err) {
          console.error(`      ❌ [${menu.name}] 상세 조회 실패:`, err.message);
        }
      }

      await finalizeDeactivation(target.brandName, oldIds, foundIds);
    } catch (err) {
      console.error(`   ❌ [${target.brandName}] 전체 프로세스 오류:`, err.message);
    }

    console.log("-----------------------------------------");
  }
}

/**
 * 7. 빽다방 실행 로직
 */
async function runPaik(page) {
  const BRAND = "빽다방";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await MenuRepository.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  const TARGET_URLS = [
    "https://paikdabang.com/menu/menu_coffee/",
    "https://paikdabang.com/menu/menu_drink/",
    "https://paikdabang.com/menu/menu_ccino/",
    "https://paikdabang.com/menu/menu_dessert/"
  ];

  for (const url of TARGET_URLS) {
    try {
      console.log(`   📂 페이지 이동 중: ${url}`);
      await page.goto(url, { waitUntil: 'networkidle2' });

      await page.waitForSelector('.menu_list', { timeout: 5000 }).catch(() => {
        console.log("      ⚠️ 메뉴 리스트를 찾을 수 없음 (빈 페이지 가능성)");
      });

      const html = await page.content();
      const rawMenus = parsePaik(html);

      console.log(`      🔗 ${rawMenus.length}개의 메뉴 발견.`);

      await processMenus(BRAND, rawMenus, foundIds);
      await new Promise(r => setTimeout(r, 1000));
    } catch (err) {
      console.error(`   ❌ [${url}] 처리 중 오류:`, err.message);
    }
  }

  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 8. 더벤티 실행 로직
 */
async function runTheVenti(page) {
  const BRAND = "더벤티";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await MenuRepository.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  for (let mode = 1; mode <= 7; mode++) {
    const listUrl = `https://www.theventi.co.kr/new2022/menu/all.html?mode=${mode}`;
    console.log(`   📂 페이지 이동 중: mode=${mode}`);

    try {
      await page.goto(listUrl, { waitUntil: 'networkidle2' });
      await page.waitForSelector('.menu_list > ul > li', { timeout: 10000 });

      const listHtml = await page.content();
      const menuList = getVentiMenuUrls(listHtml);

      console.log(`      🔗 ${menuList.length}개의 메뉴 발견.`);

      for (let index = 0; index < menuList.length; index++) {
        const menu = menuList[index];

        try {
          // 팝업이 열려 있으면 먼저 닫기
          const openedCloseBtn = await page.$('.mfp-content .mfp-close');
          if (openedCloseBtn) {
            await openedCloseBtn.click().catch(() => { });
            await new Promise(r => setTimeout(r, 300));
          }

          // 현재 DOM 기준으로 링크 핸들 다시 가져오기
          const links = await page.$$('.menu_list > ul > li a.popup-link');
          const linkHandle = links[index];

          if (!linkHandle) {
            throw new Error(`popup-link handle not found at index ${index}`);
          }

          await linkHandle.evaluate(el => {
            el.scrollIntoView({ block: 'center', inline: 'center' });
          });

          await new Promise(r => setTimeout(r, 200));

          await linkHandle.click();

          // 팝업 내부 실데이터가 뜰 때까지 대기
          await page.waitForFunction(() => {
            const popup = document.querySelector('.mfp-content');
            const desc = document.querySelector('.mfp-content .menu_desc_wrap');
            const row = document.querySelector('.mfp-content .menu-ingredient table tbody tr');
            return !!popup && !!desc && !!row;
          }, { timeout: 7000 });

          const popupHtml = await page.$eval(
            '.mfp-content',
            el => el.innerHTML
          );

          const variants = parseVentiDetail(popupHtml, menu);

          for (const variant of variants) {
            const uploaded = await uploadValidatedMenu(
              variant,
              foundIds,
              `[${BRAND} mode=${mode} ${index + 1}/${menuList.length}] `
            );

            if (uploaded) {
              console.log(`      ✅ [${mode}-${index + 1}] 업로드: ${uploaded.data.menu_name}`);
            }
          }

          // 팝업 닫기
          const closeBtn = await page.$('.mfp-content .mfp-close');
          if (closeBtn) {
            await closeBtn.click();
          } else {
            await page.keyboard.press('Escape').catch(() => { });
          }

          await new Promise(r => setTimeout(r, 300));
        } catch (err) {
          console.error(`      ❌ [${menu.name}] 상세 조회 실패:`, err.message);

          const closeBtn = await page.$('.mfp-content .mfp-close');
          if (closeBtn) {
            await closeBtn.click().catch(() => { });
          } else {
            await page.keyboard.press('Escape').catch(() => { });
          }

          await new Promise(r => setTimeout(r, 300));
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
 */
async function runAngel() {
  const BRAND = "엔제리너스";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await MenuRepository.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();
  let rawMenus = [];

  try {
    const nutritionUrl = "https://www.lotteeatz.com/upload/etc/angel/items.html";
    const orderingUrl = "https://www.lotteeatz.com/brand/angel";

    console.log(`   📂 기본 데이터 수집 중...`);

    const [nutritionRes, orderingRes] = await Promise.all([
      axios.get(nutritionUrl),
      axios.get(orderingUrl)
    ]);

    const infoMap = parseAngelImages(orderingRes.data);
    console.log(`      🖼️ 매핑 정보 ${infoMap.size}개 확보.`);

    rawMenus = parseAngel(nutritionRes.data, infoMap);
    console.log(`      🔗 총 ${rawMenus.length}개의 메뉴 1차 파싱 완료.`);

    if (rawMenus.length === 0) {
      console.log('      ⚠️ parseAngel 결과가 0건입니다. angelinusParser.js를 확인하세요.');
    }

    for (const [index, menu] of rawMenus.entries()) {
      if (menu.productId) {
        try {
          const detailUrl = `https://www.lotteeatz.com/products/introductions/${menu.productId}?rccode=brnd_main`;
          const { data: detailHtml } = await axios.get(detailUrl);

          const desc = parseAngelDescription(detailHtml);
          if (desc) {
            menu.description = desc;
          }
        } catch (detailErr) {
          console.log(`      ⚠️ [${menu.menu_name}] 상세 설명 수집 실패`);
        }
      }

      delete menu.productId;

      const uploaded = await uploadValidatedMenu(
        menu,
        foundIds,
        `[${BRAND} ${index + 1}/${rawMenus.length}] `
      );

      if (uploaded) {
        console.log(`      ✅ [${index + 1}/${rawMenus.length}] 업로드: ${uploaded.data.menu_name}`);
      }

      if ((index + 1) % 10 === 0) {
        await new Promise(r => setTimeout(r, 200));
      }
    }
  } catch (err) {
    console.error(`   ❌ ${BRAND} 로직 실패:`, err.stack || err);
  }

  await finalizeDeactivation(BRAND, oldIds, foundIds);
}

/**
 * 10. 투썸플레이스 실행 로직
 */
async function runTwosome(page) {
  const BRAND = "투썸플레이스";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await MenuRepository.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  const TABS = ['01', '02', '03'];

  for (const midCd of TABS) {
    const listUrl = `https://mo.twosome.co.kr/mn/menuInfoList.do?grtCd=1&pMidCd=${midCd}`;
    console.log(`   📂 탭 이동 중: ${midCd}`);

    try {
      await page.goto(listUrl, { waitUntil: 'networkidle2' });

      const listHtml = await page.content();
      const menuList = parseTwosomeList(listHtml);
      console.log(`      🔗 ${midCd}: ${menuList.length}개의 메뉴 발견.`);

      for (const [index, menuItem] of menuList.entries()) {
        try {
          await page.goto(menuItem.detailUrl, { waitUntil: 'networkidle2' });

          try {
            await page.waitForSelector('.text_list_ts24_type02', { timeout: 3000 });
          } catch (e) { }

          const container = await page.$('.ts24_select_drink_size');

          if (container) {
            const sizeTabs = await container.$$('ul li a');
            const tabCount = sizeTabs.length;

            if (tabCount > 0) {
              for (let i = 0; i < tabCount; i++) {
                await page.evaluate((idx) => {
                  const c = document.querySelector('.ts24_select_drink_size');
                  const tabs = c?.querySelectorAll('ul li a') || [];
                  if (tabs[idx]) tabs[idx].click();
                }, i);

                await new Promise(r => setTimeout(r, 500));

                const currentHtml = await page.content();
                const menuData = parseTwosomeDetail(currentHtml, menuItem);
                await uploadAndLog(menuData, index, menuList.length, `[Size ${i + 1}/${tabCount}]`);
              }
            } else {
              const currentHtml = await page.content();
              const menuData = parseTwosomeDetail(currentHtml, menuItem);
              await uploadAndLog(menuData, index, menuList.length, '[Single]');
            }
          } else {
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

  async function uploadAndLog(menuData, index, total, suffixLog) {
    const uploaded = await uploadValidatedMenu(menuData, foundIds, `[${BRAND}] `);
    if (uploaded) {
      console.log(`      ✅ [${index + 1}/${total}]${suffixLog} 업로드: ${uploaded.data.menu_name}`);
    }
  }
}

/**
 * 11. 요거프레소 실행 로직
 */
async function runYogerpresso() {
  const BRAND = "요거프레소";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await MenuRepository.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

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
      const { data: listHtml } = await axios.get(listUrl);
      const menuList = getYogerMenuUrls(listHtml);
      console.log(`      🔗 ${menuList.length}개의 메뉴 발견.`);

      for (const [index, menuItem] of menuList.entries()) {
        try {
          const { data: detailHtml } = await axios.get(menuItem.detailUrl);
          const menuData = parseYogerDetail(detailHtml, menuItem, cat.name);

          const uploaded = await uploadValidatedMenu(
            menuData,
            foundIds,
            `[${BRAND} ${cat.name} ${index + 1}] `
          );

          if (uploaded) {
            console.log(`      ✅ [${cat.name}-${index + 1}] 업로드: ${uploaded.data.menu_name}`);
          }

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
 */
async function runTomNToms(page) {
  const BRAND = "탐앤탐스";
  console.log(`🚀 ${BRAND} 크롤링 시작...`);

  const oldIds = await MenuRepository.getAllMenuIdsByBrand(BRAND);
  const foundIds = new Set();

  try {
    const url = "https://www.tomntoms.com/menu";
    await page.goto(url, { waitUntil: 'networkidle2' });

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

    console.log("   🖱️ 전체 메뉴 로딩 중...");
    let prevItemCount = 0;

    while (true) {
      try {
        const currentItems = await page.$$('button[id^="headlessui-popover-button-"]');
        const currentItemCount = currentItems.length;

        const moreBtn = await page.$('button.custom-button.main-tab');

        if (!moreBtn) {
          console.log("   ✅ 더보기 버튼이 없습니다.");
          break;
        }

        const isDisabled = await page.evaluate(btn => btn.disabled, moreBtn);
        if (isDisabled) {
          console.log("   ✅ 더보기 버튼이 비활성화되었습니다.");
          break;
        }

        if (prevItemCount > 0 && currentItemCount === prevItemCount) {
          console.log(`   ✅ 메뉴가 더 이상 추가되지 않습니다. (총 ${currentItemCount}개)`);
          break;
        }

        prevItemCount = currentItemCount;

        await moreBtn.click();
        process.stdout.write(".");
        await new Promise(r => setTimeout(r, 1000));
      } catch (e) {
        console.log(`   ⚠️ 더보기 처리 중 예외 발생: ${e.message}`);
        break;
      }
    }
    console.log("\n   ✅ 전체 메뉴 로딩 완료");

    const menuButtons = await page.$$('button[id^="headlessui-popover-button-"]');
    console.log(`      🔗 총 ${menuButtons.length}개의 메뉴 버튼 발견.`);

    for (let i = 0; i < menuButtons.length; i++) {
      try {
        const buttons = await page.$$('button[id^="headlessui-popover-button-"]');
        const btn = buttons[i];
        if (!btn) continue;

        const imageUrl = await btn.$eval('img', el => el.src).catch(() => "");
        await btn.click();

        try {
          await page.waitForSelector('div[id^="headlessui-popover-panel-"]', { timeout: 2000, visible: true });
        } catch (e) {
          continue;
        }

        const popoverContent = await page.$eval('div[id^="headlessui-popover-panel-"]', el => el.outerHTML);
        const menuData = parseTomNTomsDetail(popoverContent, imageUrl);

        const uploaded = await uploadValidatedMenu(menuData, foundIds, `[${BRAND}] `);
        if (uploaded) {
          console.log(`      ✅ [${i + 1}/${menuButtons.length}] 업로드: ${uploaded.data.menu_name}`);
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
  await page.setUserAgent(
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  );

  try {
    /*
    await runMega(page);
    console.log("-----------------------------------------");
    await runStarbucks(page);
    console.log("-----------------------------------------");
    await runAngel(page);
    console.log("-----------------------------------------");
    await runPaulBassett(page);
    console.log("-----------------------------------------");
    await runTheVenti(page);
    console.log("-----------------------------------------");
    await runCompose(page);
    console.log("-----------------------------------------");
    await runEdiya(page);
    console.log("-----------------------------------------");
    await runMammoth();
    console.log("-----------------------------------------");
    await runTwosome(page);
    console.log("-----------------------------------------");
    await runYogerpresso();
    console.log("-----------------------------------------");
    await runMammoth();
    console.log("-----------------------------------------");
    await runTomNToms(page);
    */
    await runPaik(page);
    console.log("-----------------------------------------");
  } catch (error) {
    console.error("❌ 전체 프로세스 중 오류 발생:", error);
  } finally {
    await browser.close();
    await pool.end();
    console.log("🏁 전체 크롤링 및 데이터 동기화 완료");
  }
}

main();