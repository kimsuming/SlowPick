// cleanup-db.js
const { db } = require('./src/config/firebaseAdmin');

async function cleanupOldData() {
  console.log("🔍 구버전 데이터('-' 구분자) 검색 시작...");

  try {
    const menusRef = db.collection('menus');
    const snapshot = await menusRef.get();

    if (snapshot.empty) {
      console.log("❌ 삭제할 데이터가 없습니다.");
      return;
    }

    // Firestore 배치(Batch) 작업 생성 (한 번에 최대 500개 삭제 가능)
    const batch = db.batch();
    let deleteCount = 0;

    snapshot.forEach(doc => {
      const docId = doc.id;

      // ID에 하이픈('-')이 포함되어 있는지 확인
      // 예: "컴포즈커피-흑당카페라떼"
      if (docId.includes('-')) {
        console.log(`🗑️ 삭제 대기 중: ${docId}`);
        batch.delete(doc.ref);
        deleteCount++;
      }
    });

    if (deleteCount > 0) {
      // 실제 삭제 실행
      await batch.commit();
      console.log(`\n✅ 총 ${deleteCount}개의 구버전 데이터가 성공적으로 삭제되었습니다.`);
    } else {
      console.log("\n🙌 삭제할 구버전 데이터가 발견되지 않았습니다.");
    }

  } catch (error) {
    console.error("❌ 클린업 중 오류 발생:", error);
  }
}

// 주의: 실행 전 Firebase 콘솔에서 백업을 권장하거나, 
// 처음에는 batch.commit() 부분을 주석 처리하고 로그만 확인해 보세요.
cleanupOldData();