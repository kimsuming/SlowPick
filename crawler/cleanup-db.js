const admin = require('firebase-admin');
const path = require('path');

// 1. 서비스 계정 키 경로 설정 (본인의 키 파일명에 맞게 수정하세요)
// 보통 crawler 폴더 내에 있거나 상위 폴더에 있을 수 있습니다.
const serviceAccount = require('./slowpick-ebc24-firebase-adminsdk-fbsvc-e20328a442.json'); 

// 2. Firebase 초기화
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();
const COLLECTION_NAME = 'menus'; // 삭제할 컬렉션 이름

async function cleanupInactiveMenus() {
  console.log(`🗑️ [${COLLECTION_NAME}] 컬렉션에서 비활성(is_active: false) 데이터 정리를 시작합니다...`);

  try {
    // 3. is_active가 false인 문서 조회
    const snapshot = await db.collection(COLLECTION_NAME)
      .where('is_active', '==', false)
      .get();

    if (snapshot.empty) {
      console.log('✨ 삭제할 비활성 메뉴가 없습니다.');
      return;
    }

    console.log(`📦 총 ${snapshot.size}개의 비활성 문서를 발견했습니다. 삭제를 진행합니다...`);

    // 4. 배치(Batch) 처리 로직 (Firestore는 한 번에 최대 500개까지만 배치 가능)
    const BATCH_SIZE = 400; // 안전하게 400개씩 끊어서 처리
    let batch = db.batch();
    let operationCounter = 0;
    let totalDeleted = 0;

    for (const doc of snapshot.docs) {
      batch.delete(doc.ref);
      operationCounter++;

      // 배치가 가득 차면 커밋하고 새로 생성
      if (operationCounter >= BATCH_SIZE) {
        await batch.commit();
        totalDeleted += operationCounter;
        console.log(`   ⏳ ${totalDeleted}개 삭제 완료...`);
        
        batch = db.batch(); // 새 배치 생성
        operationCounter = 0;
      }
    }

    // 남은 문서들 커밋
    if (operationCounter > 0) {
      await batch.commit();
      totalDeleted += operationCounter;
    }

    console.log(`✅ 최종 완료: 총 ${totalDeleted}개의 비활성 메뉴를 삭제했습니다.`);

  } catch (error) {
    console.error('❌ 정리 작업 중 오류 발생:', error);
  }
}

// 실행
cleanupInactiveMenus();