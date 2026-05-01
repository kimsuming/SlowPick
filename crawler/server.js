require('dotenv').config();
const express = require('express');
const pool = require('./src/services/db/mysql');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

const NUM_FIELDS = ['calories', 'sugar', 'protein', 'caffeine', 'saturated_fat', 'sodium'];

function parseMenuRow(row) {
  const parsed = {
    ...row,
    is_active: !!row.is_active,
    allergies: row.allergies ? row.allergies.split(',') : [],
  };
  for (const field of NUM_FIELDS) {
    if (parsed[field] != null) parsed[field] = Number(parsed[field]);
  }
  return parsed;
}

const MENU_SELECT = `
  SELECT m.*, GROUP_CONCAT(ma.allergy_name ORDER BY ma.allergy_name SEPARATOR ',') AS allergies
  FROM menus m
  LEFT JOIN menu_allergies ma ON m.id = ma.menu_id
`;

// GET /api/menus - 전체 메뉴 조회 (검색/브랜드 필터/정렬)
app.get('/api/menus', async (req, res) => {
  try {
    const { search, brands, sort } = req.query;

    let sql = MENU_SELECT + ' WHERE m.is_active = true';
    const params = [];

    if (search) {
      sql += ' AND m.menu_name LIKE ?';
      params.push(`%${search}%`);
    }

    if (brands) {
      const brandList = brands.split(',').map(b => b.trim()).filter(Boolean);
      if (brandList.length > 0) {
        sql += ` AND m.brand_name IN (${brandList.map(() => '?').join(',')})`;
        params.push(...brandList);
      }
    }

    sql += ' GROUP BY m.id';

    if (sort === 'sugar') sql += ' ORDER BY m.sugar ASC';
    else if (sort === 'calories') sql += ' ORDER BY m.calories ASC';
    else if (sort === 'latest') sql += ' ORDER BY m.created_at DESC';

    const [rows] = await pool.execute(sql, params);
    res.json({ menus: rows.map(parseMenuRow) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

// GET /api/menus/recommended - 저당 추천 메뉴 6개
app.get('/api/menus/recommended', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      MENU_SELECT +
      ' WHERE m.is_active = true AND m.sugar IS NOT NULL GROUP BY m.id ORDER BY m.sugar ASC LIMIT 6'
    );
    res.json({ menus: rows.map(parseMenuRow) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

// GET /api/menus/names - 자동완성용 메뉴명 목록
app.get('/api/menus/names', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT menu_name FROM menus WHERE is_active = true ORDER BY menu_name'
    );
    res.json({ names: rows.map(r => r.menu_name) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: '서버 오류가 발생했습니다.' });
  }
});

app.listen(PORT, () => {
  console.log(`SlowPick API 서버 실행 중: http://localhost:${PORT}`);
});
