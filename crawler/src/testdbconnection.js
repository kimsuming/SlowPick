const pool = require('./services/db/mysql');

async function testConnection() {
  try {
    const [rows] = await pool.execute('SELECT 1 AS result');
    console.log('✅ DB 연결 성공:', rows);
    process.exit(0);
  } catch (error) {
    console.error('❌ DB 연결 실패:', error.message);
    process.exit(1);
  }
}

testConnection();