const puppeteer = require('puppeteer');
const fs = require('fs');
const db = require('./firebase');
const { parseStarbucks } = require('./parsers/starbucksParser');

/*async function crawlWithPuppeteer() {
  try {
    // Puppeteer 이용한 크롤링 코드
    const browser = await puppeteer.launch();
    const page = await browser.newPage();
    
    await page.goto("https://www.starbucks.co.kr/menu/drink_list.do");

    await page.waitForSelector("li.menuDataSet"); 

    const htmlContent = await page.content(); 
    
    await browser.close();

    
    fs.writeFileSync('starbucks.html', htmlContent);

  } catch (error) {
    console.error("Puppeteer 크롤링 오류:", error);
  }

crawlWithPuppeteer();
}*/

async function main() {
  try {
    console.log("📂 저장된 starbucks.html 파일을 읽습니다...");
    const html = fs.readFileSync('starbucks.html', 'utf-8');

    // 2. 파싱 (데이터 추출)
    console.log("☕️ 데이터를 추출(Parsing) 중입니다...");
    const menuList = parseStarbucks(html);
    console.log(`✨ 총 ${menuList.length}개의 메뉴 데이터를 준비했습니다.`);

    // 3. Firestore에 저장
    console.log("🔥 Firestore에 업로드를 시작합니다...");
    
    // Firestore는 한 번에 최대 500개까지만 배치(일괄) 작업이 가능합니다.
    // 메뉴가 많을 수 있으니 500개씩 끊어서 저장하는 안전한 방식을 사용합니다.
    
    const CHUNK_SIZE = 400; // 안전하게 400개씩 끊기
    const chunks = [];
    
    for (let i = 0; i < menuList.length; i += CHUNK_SIZE) {
      chunks.push(menuList.slice(i, i + CHUNK_SIZE));
    }

    let totalCount = 0;

    // 각 덩어리(chunk)마다 작업 수행
    for (const chunk of chunks) {
      const batch = db.batch(); // 배치 생성

      chunk.forEach(menu => {
        // (A) 문서 ID 만들기: "브랜드명-메뉴명" (예: starbucks-아이스 아메리카노)
        // (공백은 놔둬도 되지만, ID로 쓸 때는 보통 제거하거나 -로 바꿉니다. 여기선 그냥 씁니다.)
        const docId = `${menu.brand_name}-${menu.menu_name}`;
        
        // (B) 저장 위치 지정: 'menus' 컬렉션의 'docId' 문서
        const docRef = db.collection('menus').doc(docId);

        // (C) 배치에 '저장(set)' 명령 담기
        // { merge: true } 옵션: 이미 데이터가 있으면 덮어쓰고, 없으면 새로 만듦
        batch.set(docRef, menu, { merge: true });
      });

      // (D) 덩어리 저장 실행 (Commit)
      await batch.commit();
      totalCount += chunk.length;
      console.log(`... ${totalCount} / ${menuList.length} 개 저장 완료`);
    }

    console.log("✅ 모든 데이터가 Firestore에 저장되었습니다!");

  } catch (error) {
    console.error("❌ 오류 발생:", error);
  }
}

main();