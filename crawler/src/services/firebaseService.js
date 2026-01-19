const { admin, db } = require('../config/firebaseAdmin');

class FirebaseService {
  /**
   * 1. 단일 메뉴 업로드 (Upsert)
   * - 문서 ID를 반환하여 메인 로직에서 '생존 신고'를 할 수 있게 합니다.
   */
  static async uploadMenu(menuData) {
    try {
      // 문서 ID 생성 규칙: "브랜드명_메뉴명" (공백은 언더바로 치환)
      const docId = `${menuData.brand_name}_${menuData.menu_name}`.replace(/\s+/g, '_');
      const menuRef = db.collection('menus').doc(docId);

      await menuRef.set({
        ...menuData,
        // 크롤링 된 시점을 기록 (이 시간으로 나중에 데이터 신선도 체크 가능)
        last_updated_at: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      return { success: true, docId };
    } catch (error) {
      console.error(`❌ [Firebase] 업로드 실패: ${menuData.menu_name}`, error.message);
      return { success: false, docId: null };
    }
  }

  /**
   * 2. 특정 브랜드의 모든 메뉴 ID(문서 ID) 가져오기
   * - 크롤링 시작 전에 "기존에 있던 메뉴들"을 파악하기 위함입니다.
   */
  static async getAllMenuIdsByBrand(brandName) {
    const snapshot = await db.collection('menus')
      .where('brand_name', '==', brandName)
      .get();
    
    // 빠른 검색을 위해 Set 자료구조로 반환
    return new Set(snapshot.docs.map(doc => doc.id));
  }

  /**
   * 3. 사라진 메뉴들 비활성화 처리 (Batch Update)
   * - 삭제하지 않고 is_active를 false로 변경합니다.
   */
  static async deactivateMenus(ids) {
    if (ids.length === 0) return;

    const batch = db.batch();
    const CHUNK_SIZE = 400; // Firestore 배치 제한(500개) 안전턱

    // 500개씩 끊어서 처리
    for (let i = 0; i < ids.length; i += CHUNK_SIZE) {
      const chunk = ids.slice(i, i + CHUNK_SIZE);
      const subBatch = db.batch();

      chunk.forEach(docId => {
        const docRef = db.collection('menus').doc(docId);
        subBatch.update(docRef, { 
          is_active: false,
          last_updated_at: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      await subBatch.commit();
    }
    console.log(`📉 총 ${ids.length}개의 메뉴가 비활성화(Sold Out) 처리되었습니다.`);
  }
}

module.exports = FirebaseService;