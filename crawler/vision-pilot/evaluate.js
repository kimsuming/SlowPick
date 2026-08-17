// 사용법: node evaluate.js [브랜드명]
// 사전 준비:
//   1) build-corpus.js로 corpus_<브랜드>.json 생성
//   2) test-photos/<브랜드>/ 폴더에 실사용 조건 사진들 넣기
//   3) test-photos/<브랜드>/manifest.csv 작성 (헤더: filename,true_menu_name)
const fs = require('fs');
const path = require('path');
const { describeImage } = require('./lib/describeImage');
const { embedText, cosineSimilarity } = require('./lib/embed');

const BRAND = process.argv[2] || '더벤티';
const CORPUS_PATH = path.join(__dirname, 'output', `corpus_${BRAND}.json`);
const TEST_DIR = path.join(__dirname, 'test-photos', BRAND);
const MANIFEST_PATH = path.join(TEST_DIR, 'manifest.csv');

function extToContentType(ext) {
  ext = ext.toLowerCase();
  if (ext === '.png') return 'image/png';
  if (ext === '.webp') return 'image/webp';
  return 'image/jpeg';
}

function loadManifest() {
  const raw = fs.readFileSync(MANIFEST_PATH, 'utf-8').trim();
  const lines = raw.split('\n').slice(1); // 헤더 제외
  return lines
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      const idx = line.indexOf(',');
      return { filename: line.slice(0, idx).trim(), trueMenuName: line.slice(idx + 1).trim() };
    });
}

async function main() {
  if (!fs.existsSync(CORPUS_PATH)) {
    console.error(`corpus 파일이 없습니다: ${CORPUS_PATH}\n먼저 build-corpus.js를 실행하세요.`);
    process.exit(1);
  }
  if (!fs.existsSync(MANIFEST_PATH)) {
    console.error(`manifest.csv가 없습니다: ${MANIFEST_PATH}\n헤더: filename,true_menu_name`);
    process.exit(1);
  }

  const corpus = JSON.parse(fs.readFileSync(CORPUS_PATH, 'utf-8'));
  const manifest = loadManifest();

  console.log(`corpus ${corpus.length}건, 테스트 사진 ${manifest.length}장 평가 시작\n`);

  const results = [];
  let top1Hit = 0;
  let top3Hit = 0;

  for (const item of manifest) {
    const filePath = path.join(TEST_DIR, item.filename);
    if (!fs.existsSync(filePath)) {
      console.log(`[건너뜀] 파일 없음: ${item.filename}`);
      continue;
    }
    const buf = fs.readFileSync(filePath);
    const contentType = extToContentType(path.extname(item.filename));
    const dataUrl = `data:${contentType};base64,${buf.toString('base64')}`;

    try {
      const { canonicalText } = await describeImage({ dataUrl });
      const queryEmbedding = await embedText(canonicalText);

      const ranked = corpus
        .map((c) => ({ menu_name: c.menu_name, score: cosineSimilarity(queryEmbedding, c.embedding) }))
        .sort((a, b) => b.score - a.score)
        .slice(0, 5);

      const top1 = ranked[0]?.menu_name === item.trueMenuName;
      const top3 = ranked.slice(0, 3).some((r) => r.menu_name === item.trueMenuName);
      if (top1) top1Hit++;
      if (top3) top3Hit++;

      results.push({ filename: item.filename, trueMenuName: item.trueMenuName, ranked, top1, top3 });
      console.log(
        `${item.filename} (정답: ${item.trueMenuName}) → Top3: ${ranked
          .slice(0, 3)
          .map((r) => `${r.menu_name}(${r.score.toFixed(3)})`)
          .join(', ')} ${top3 ? '✅' : '❌'}`
      );
    } catch (e) {
      console.log(`[오류] ${item.filename}: ${e.message}`);
    }
  }

  const n = results.length;
  console.log(`\n=== 결과 (n=${n}) ===`);
  console.log(`Top-1 정확도: ${n ? ((top1Hit / n) * 100).toFixed(1) : 0}%`);
  console.log(`Top-3 Recall: ${n ? ((top3Hit / n) * 100).toFixed(1) : 0}%`);

  const outPath = path.join(__dirname, 'output', `eval_${BRAND}_${Date.now()}.json`);
  fs.writeFileSync(outPath, JSON.stringify({ brand: BRAND, top1Rate: top1Hit / n, top3Recall: top3Hit / n, results }, null, 2), 'utf-8');
  console.log(`상세 결과 저장: ${outPath}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
