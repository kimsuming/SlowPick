const pool = require('./db/mysql');

class RdsMenuRepository {
  static makeDocId(menuData) {
    const safeMenuName = menuData.menu_name
      .replace(/\s+/g, '_')
      .replace(/\//g, '_');

    return `${menuData.brand_name}_${safeMenuName}`;
  }

  static normalizeNumber(value) {
    if (value === undefined || value === null || value === '') return null;
    const num = Number(value);
    return Number.isNaN(num) ? null : num;
  }

  static normalizeString(value) {
    if (value === undefined || value === null || value === '') return null;
    return String(value).trim();
  }

  static async uploadMenu(menuData) {
    const connection = await pool.getConnection();
    const docId = this.makeDocId(menuData);

    try {
      await connection.beginTransaction();

      const sql = `
        INSERT INTO menus (
          doc_id,
          brand_name,
          menu_name,
          category,
          description,
          size_standard,
          image_url,
          calories,
          sugar,
          protein,
          caffeine,
          saturated_fat,
          sodium,
          nutrition_json,
          is_active,
          last_updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        ON DUPLICATE KEY UPDATE
          brand_name = VALUES(brand_name),
          menu_name = VALUES(menu_name),
          category = VALUES(category),
          description = VALUES(description),
          size_standard = VALUES(size_standard),
          image_url = VALUES(image_url),
          calories = VALUES(calories),
          sugar = VALUES(sugar),
          protein = VALUES(protein),
          caffeine = VALUES(caffeine),
          saturated_fat = VALUES(saturated_fat),
          sodium = VALUES(sodium),
          nutrition_json = VALUES(nutrition_json),
          is_active = VALUES(is_active),
          last_updated_at = CURRENT_TIMESTAMP
      `;

      const values = [
        docId,
        menuData.brand_name,
        menuData.menu_name,
        this.normalizeString(menuData.category),
        this.normalizeString(menuData.description),
        this.normalizeString(menuData.size_standard),
        this.normalizeString(menuData.image_url),
        this.normalizeNumber(menuData.calories),
        this.normalizeNumber(menuData.sugar),
        this.normalizeNumber(menuData.protein),
        this.normalizeNumber(menuData.caffeine),
        this.normalizeNumber(menuData.saturated_fat),
        this.normalizeNumber(menuData.sodium),
        menuData.nutrition_json ? JSON.stringify(menuData.nutrition_json) : null,
        menuData.is_active ?? true,
      ];

      await connection.execute(sql, values);

      const [menuRows] = await connection.execute(
        `SELECT id FROM menus WHERE doc_id = ?`,
        [docId]
      );

      if (menuRows.length === 0) {
        throw new Error(`메뉴 ID 조회 실패: ${docId}`);
      }

      const menuId = menuRows[0].id;

      const allergies = Array.isArray(menuData.allergy_info)
        ? [...new Set(menuData.allergy_info.map(a => String(a).trim()).filter(Boolean))]
        : [];

      await connection.execute(
        `DELETE FROM menu_allergies WHERE menu_id = ?`,
        [menuId]
      );

      if (allergies.length > 0) {
        const allergySql = `
          INSERT INTO menu_allergies (menu_id, allergy_name)
          VALUES ${allergies.map(() => '(?, ?)').join(', ')}
        `;

        const allergyValues = allergies.flatMap(allergy => [menuId, allergy]);
        await connection.execute(allergySql, allergyValues);
      }

      await connection.commit();

      return { success: true, docId };
    } catch (error) {
      await connection.rollback();
      console.error(`❌ [RDS] 업로드 실패: ${menuData.menu_name}`, error.message);
      return { success: false, docId: null };
    } finally {
      connection.release();
    }
  }

  static async getAllMenuIdsByBrand(brandName) {
    const [rows] = await pool.execute(
      `SELECT doc_id FROM menus WHERE brand_name = ?`,
      [brandName]
    );

    return new Set(rows.map(row => row.doc_id));
  }

  static async deactivateMenus(ids) {
    const idArray = Array.from(ids);
    if (idArray.length === 0) return;

    const CHUNK_SIZE = 400;
    let totalUpdated = 0;

    for (let i = 0; i < idArray.length; i += CHUNK_SIZE) {
      const chunk = idArray.slice(i, i + CHUNK_SIZE);
      const placeholders = chunk.map(() => '?').join(', ');

      const sql = `
        UPDATE menus
        SET is_active = false,
            last_updated_at = CURRENT_TIMESTAMP
        WHERE doc_id IN (${placeholders})
      `;

      await pool.execute(sql, chunk);
      totalUpdated += chunk.length;
    }

    console.log(`📉 총 ${totalUpdated}개의 메뉴가 비활성화(Sold Out) 처리되었습니다.`);
  }
}

module.exports = RdsMenuRepository;