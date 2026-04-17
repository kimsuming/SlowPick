require('dotenv').config();
const pool = require('./src/services/db/mysql');

async function cleanupInactiveMenus({ dryRun = false } = {}) {
  let conn;

  try {
    conn = await pool.getConnection();

    console.log('🧹 비활성 메뉴 정리 시작...');
    console.log(`   - dryRun: ${dryRun ? 'ON' : 'OFF'}`);

    // 삭제 대상 메뉴 조회
    const [inactiveMenus] = await conn.query(
      `
      SELECT id, doc_id, brand_name, menu_name, is_active
      FROM menus
      WHERE nutrition_json IS NULL
      ORDER BY id ASC
      `
    );

    if (inactiveMenus.length === 0) {
      console.log('✅ 삭제할 is_active = 0 레코드가 없습니다.');
      return;
    }

    console.log(`📌 삭제 대상 menus: ${inactiveMenus.length}개`);
    console.table(
      inactiveMenus.slice(0, 10).map(menu => ({
        id: menu.id,
        doc_id: menu.doc_id,
        brand_name: menu.brand_name,
        menu_name: menu.menu_name,
        is_active: menu.is_active,
      }))
    );

    const inactiveMenuIds = inactiveMenus.map(menu => menu.id);

    // 연결된 allergy 개수 확인
    const [allergyCountRows] = await conn.query(
      `
      SELECT COUNT(*) AS count
      FROM menu_allergies
      WHERE menu_id IN (?)
      `,
      [inactiveMenuIds]
    );

    const allergyCount = allergyCountRows[0]?.count || 0;
    console.log(`📌 삭제 대상 menu_allergies: ${allergyCount}개`);

    if (dryRun) {
      console.log('👀 dry-run 모드이므로 실제 삭제는 하지 않았습니다.');
      return;
    }

    await conn.beginTransaction();

    // 1) 자식 테이블 먼저 삭제
    const [deleteAllergiesResult] = await conn.query(
      `
      DELETE FROM menu_allergies
      WHERE menu_id IN (?)
      `,
      [inactiveMenuIds]
    );

    // 2) 부모 테이블 삭제
    const [deleteMenusResult] = await conn.query(
      `
      DELETE FROM menus
      WHERE nutrition_json IS NULL
      `
    );

    await conn.commit();

    console.log('✅ 정리 완료');
    console.log(`   - 삭제된 menu_allergies: ${deleteAllergiesResult.affectedRows}개`);
    console.log(`   - 삭제된 menus: ${deleteMenusResult.affectedRows}개`);
  } catch (error) {
    if (conn) {
      try {
        await conn.rollback();
      } catch (rollbackError) {
        console.error('❌ rollback 실패:', rollbackError.message);
      }
    }

    console.error('❌ cleanup 실패:', error.message);
    console.error(error);
    process.exitCode = 1;
  } finally {
    if (conn) conn.release();
    await pool.end();
    console.log('🔌 DB 연결 종료');
  }
}

const dryRun = process.argv.includes('--dry-run');

cleanupInactiveMenus({ dryRun });