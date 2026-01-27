const admin = require('firebase-admin');
const serviceAccount = require('./slowpick-ebc24-firebase-adminsdk-fbsvc-e20328a442.json'); 


if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();
const COLLECTION_NAME = 'menus';

async function migrateBrandName() {
  console.log("🔄 브랜드명 변경 시작: '매머드커피' -> '매머드 익스프레스'");

  try {
    // 1. 기존 '매머드커피'로 저장된 문서들 찾기
    const snapshot = await db.collection(COLLECTION_NAME)
      .where('brand_name', '==', '매머드커피')
      .get();

    if (snapshot.empty) {
      console.log("✨ 변경할 문서가 없습니다.");
      return;
    }

    console.log(`📦 총 ${snapshot.size}개의 문서를 찾았습니다. 업데이트 진행 중...`);

    const BATCH_SIZE = 400;
    let batch = db.batch();
    let counter = 0;
    let totalUpdated = 0;

    for (const doc of snapshot.docs) {
      // 브랜드명을 '매머드 익스프레스'로 업데이트
      batch.update(doc.ref, { brand_name: '매머드 익스프레스' });
      counter++;

      if (counter >= BATCH_SIZE) {
        await batch.commit();
        totalUpdated += counter;
        console.log(`   ⏳ ${totalUpdated}개 업데이트 완료...`);
        batch = db.batch();
        counter = 0;
      }
    }

    if (counter > 0) {
      await batch.commit();
      totalUpdated += counter;
    }

    console.log(`✅ 최종 완료: 총 ${totalUpdated}개의 메뉴 브랜드명을 변경했습니다.`);

  } catch (error) {
    console.error("❌ 업데이트 중 오류 발생:", error);
  }
}

migrateBrandName();