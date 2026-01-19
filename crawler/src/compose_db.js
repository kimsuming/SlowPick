const fs = require('fs');
const db = require('./firebase'); 
const { parseCompose } = require('./parsers/composeParser');

async function main() {
  try {
    console.log("🚀 컴포즈커피 데이터 DB 업로드를 시작합니다...");

    let allMenus = [];
    let page = 1;

    // 1. HTML 파일 순회 및 파싱
    while (true) {
      const filename = `compose_${page}.html`;
      
      if (!fs.existsSync(filename)) {
        if (page === 1) {
             console.log("❌ compose_1.html 파일이 없습니다. 크롤링 먼저 진행해주세요.");
             return;
        }
        break; // 파일이 없으면 종료
      }

      console.log(`📂 ${filename} 읽는 중...`);
      const html = fs.readFileSync(filename, 'utf-8');
      
      const menus = parseCompose(html);
      console.log(`   └─ ${menus.length}개 메뉴 발견`);
      allMenus = [...allMenus, ...menus];
      
      page++;
    }

    console.log(`✨ 총 ${allMenus.length}개의 컴포즈커피 데이터를 준비했습니다.`);

    // 2. Firestore 저장 (Batch)
    const CHUNK_SIZE = 400;
    const chunks = [];
    
    for (let i = 0; i < allMenus.length; i += CHUNK_SIZE) {
      chunks.push(allMenus.slice(i, i + CHUNK_SIZE));
    }

    let totalCount = 0;

    for (const chunk of chunks) {
      const batch = db.batch();

      chunk.forEach(menu => {
        // ID 생성: 컴포즈커피-메뉴명
        // 슬래시(/)나 특수문자 제거
        const safeName = menu.menu_name.replace(/\//g, '&');
        const docId = `${menu.brand_name}-${safeName}`;
        
        const docRef = db.collection('menus').doc(docId);
        batch.set(docRef, menu, { merge: true });
      });

      await batch.commit();
      totalCount += chunk.length;
      console.log(`🔥 ... ${totalCount} / ${allMenus.length} 개 저장 완료`);
    }

    console.log("✅ 컴포즈커피 업로드 완료!");

  } catch (error) {
    console.error("❌ 오류 발생:", error);
  }
}

main();