const admin = require('firebase-admin');
const path = require('path');

// 1. 서비스 계정 키 경로 (기존 경로 유지)
const serviceAccount = require('./slowpick-ebc24-firebase-adminsdk-fbsvc-e20328a442.json'); 

// 2. Firebase 초기화
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();
const COLLECTION_NAME = 'menus';

async function cleanupInactiveMenus() {
  console.log(`🗑️ [${COLLECTION_NAME}] 컬렉션에서 비활성(is_active: false) 데이터 정리를 시작합니다...`);

  const BATCH_SIZE = 400; // 한 번에 처리할 개수 (Firestore 제한 500개 미만으로 설정)
  let totalDeleted = 0;
  let isFinished = false;

  try {
    // 반복문을 돌며 데이터가 없을 때까지 삭제 수행
    while (!isFinished) {
      // 1. 400개만 딱 끊어서 조회 (메모리 절약)
      const snapshot = await db.collection(COLLECTION_NAME)
        .where('is_active', '==', false)
        .limit(BATCH_SIZE) 
        .get();

      // 더 이상 삭제할 문서가 없으면 루프 종료
      if (snapshot.empty) {
        isFinished = true;
        break;
      }

      // 2. 배치 생성 및 삭제 등록
      const batch = db.batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      // 3. 커밋 (삭제 실행)
      await batch.commit();

      // 카운트 증가 및 로그
      totalDeleted += snapshot.size;
      console.log(`   ⏳ ${totalDeleted}개 삭제 완료...`);

      // 서버 부하 방지를 위한 아주 짧은 대기 (선택 사항)
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    console.log(`✅ 최종 완료: 총 ${totalDeleted}개의 비활성 메뉴를 삭제했습니다.`);

  } catch (error) {
    console.error('❌ 정리 작업 중 오류 발생:', error);
  }
}

// 실행
cleanupInactiveMenus();