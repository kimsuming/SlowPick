const fs = require('fs');
const db = require('./firebase'); // 비서(DB) 불러오기
const { parseMega } = require('./parsers/megaParser'); // 메가커피 파서 불러오기

async function main() {
  try {
    console.log("🚀 메가커피 데이터 DB 업로드를 시작합니다...");

    // 1. 모든 HTML 파일 읽어서 데이터 합치기
    let allMenus = [];
    let page = 1;

    while (true) {
      const filename = `mega_${page}.html`;
      
      // 파일이 존재하지 않으면 반복문 종료 (더 이상 읽을 페이지 없음)
      if (!fs.existsSync(filename)) {
        break;
      }

      console.log(`📂 ${filename} 읽는 중...`);
      const html = fs.readFileSync(filename, 'utf-8');
      
      // 파싱 수행
      const menus = parseMega(html);
      allMenus = [...allMenus, ...menus]; // 기존 리스트에 추가
      
      page++;
    }

    console.log(`✨ 총 ${allMenus.length}개의 메뉴 데이터를 추출했습니다.`);

    if (allMenus.length === 0) {
      console.log("⚠️ 저장할 데이터가 없습니다. HTML 파일이 있는지 확인해주세요.");
      return;
    }

    // 2. Firestore에 저장 (Batch Write)
    // (스타벅스 때와 동일한 배치 로직)
    console.log("🔥 Firestore에 업로드를 시작합니다...");
    
    const CHUNK_SIZE = 400; // 400개씩 끊어서 처리
    const chunks = [];
    
    for (let i = 0; i < allMenus.length; i += CHUNK_SIZE) {
      chunks.push(allMenus.slice(i, i + CHUNK_SIZE));
    }

    let totalCount = 0;

    for (const chunk of chunks) {
      const batch = db.batch(); // 배치 생성

      chunk.forEach(menu => {
        // (A) 문서 ID 생성: "브랜드명-메뉴명"
        // 슬래시(/) 등 특수문자가 메뉴명에 있으면 ID로 쓸 수 없으므로 제거하거나 대체하는 것이 안전합니다.
        const safeName = menu.menu_name.replace(/\//g, '&'); 
        const docId = `${menu.brand_name}-${safeName}`;
        
        // (B) 저장 위치 지정
        const docRef = db.collection('menus').doc(docId);

        // (C) 배치에 저장 명령 담기
        batch.set(docRef, menu, { merge: true });
      });

      // (D) 덩어리 저장 실행
      await batch.commit();
      totalCount += chunk.length;
      console.log(`... ${totalCount} / ${allMenus.length} 개 저장 완료`);
    }

    console.log("✅ 메가커피 데이터 업로드 완료!");

  } catch (error) {
    console.error("❌ 오류 발생:", error);
  }
}

main();