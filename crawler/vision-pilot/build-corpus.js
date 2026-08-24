// 사용법: node build-corpus.js [브랜드명] [최대개수]
// 예:    node build-corpus.js 더벤티 39
const fs = require('fs');
const path = require('path');
const { getConnection } = require('./lib/db');
const { describeImage } = require('./lib/describeImage');
const { embedText } = require('./lib/embed');

const BRAND = process.argv[2] || '더벤티';
const LIMIT = Number(process.argv[3] || 1000);
const OUT_PATH = path.join(__dirname, 'output', `corpus_${BRAND}.json`);

async function main() {
  const conn = await getConnection();
  const [rows] = await conn.query(
    `SELECT id, menu_name, category, image_url FROM menus
     WHERE brand_name = ? AND is_active = 1 AND image_url IS NOT NULL AND image_url != ''
     LIMIT ?`,
    [BRAND, LIMIT]
  );
  await conn.end();

  console.log(`${BRAND}: 이미지 보유 메뉴 ${rows.length}개, 임베딩 생성 시작`);

  const corpus = [];
  const failures = [];
  for (let i = 0; i < rows.length; i++) {
    const m = rows[i];
    process.stdout.write(`[${i + 1}/${rows.length}] ${m.menu_name} ... `);

    let lastError = null;
    let done = false;

    for (let attempt = 1; attempt <= 2 && !done; attempt++) {
      try {
        const { fields, canonicalText } = await describeImage({ url: m.image_url });
        const embedding = await embedText(canonicalText);
        corpus.push({
          menu_id: m.id,
          menu_name: m.menu_name,
          category: m.category,
          image_url: m.image_url,
          description_fields: fields,
          canonical_text: canonicalText,
          embedding,
        });
        console.log('완료 -', canonicalText);
        done = true;
      } catch (e) {
        lastError = e;
        if (attempt === 1) {
          console.log(`실패 (1차) - ${e.message} → 재시도`);
          process.stdout.write(`[${i + 1}/${rows.length}] ${m.menu_name} (재시도) ... `);
        }
      }
    }

    if (!done) {
      console.log('실패 (재시도 후에도 실패) -', lastError.message);
      failures.push({ menu_id: m.id, menu_name: m.menu_name, error: lastError.message });
    }
  }

  fs.mkdirSync(path.dirname(OUT_PATH), { recursive: true });
  fs.writeFileSync(OUT_PATH, JSON.stringify(corpus, null, 2), 'utf-8');
  console.log(`\n저장 완료: ${OUT_PATH} (${corpus.length}건)`);

  if (failures.length > 0) {
    console.log(`\n=== 재시도 후에도 실패한 항목 (${failures.length}건) ===`);
    for (const f of failures) {
      console.log(`- [${f.menu_id}] ${f.menu_name}: ${f.error}`);
    }
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
