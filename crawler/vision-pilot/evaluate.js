// 사용법: node evaluate.js [브랜드명]
// 사전 준비:
//   1) build-corpus.js로 corpus_<브랜드>.json 생성
//   2) test-photos/<브랜드>/ 폴더에 실사용 조건 사진들 넣기
//   3) test-photos/<브랜드>/manifest.csv 작성 (헤더: filename,true_menu_name)
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
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

  const TOP_N = 10;
  const RECALL_KS = [1, 3, 5, 10];

  const results = [];
  const hits = { 1: 0, 3: 0, 5: 0, 10: 0 };

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
      console.log(`${item.filename} 판단 - ${canonicalText}`);
      const queryEmbedding = await embedText(canonicalText);

      const ranked = corpus
        .map((c) => ({ menu_name: c.menu_name, score: cosineSimilarity(queryEmbedding, c.embedding) }))
        .sort((a, b) => b.score - a.score)
        .slice(0, TOP_N);

      const recallAt = {};
      for (const k of RECALL_KS) {
        recallAt[k] = ranked.slice(0, k).some((r) => r.menu_name === item.trueMenuName);
        if (recallAt[k]) hits[k]++;
      }

      // 정답이 top10 안에 있다면 몇 위인지, 없다면 null
      const rankPosition = ranked.findIndex((r) => r.menu_name === item.trueMenuName);

      results.push({
        filename: item.filename,
        trueMenuName: item.trueMenuName,
        ranked,
        rankPosition: rankPosition === -1 ? null : rankPosition + 1,
        top1: recallAt[1],
        top3: recallAt[3],
        top5: recallAt[5],
        top10: recallAt[10],
      });

      console.log(
        `${item.filename} (정답: ${item.trueMenuName}, 순위: ${rankPosition === -1 ? 'top10 밖' : rankPosition + 1 + '위'}) → Top10: ${ranked
          .map((r, i) => `${i + 1}.${r.menu_name}(${r.score.toFixed(3)})`)
          .join(', ')} ${recallAt[3] ? '✅top3' : recallAt[10] ? '🟡top10' : '❌'}`
      );
    } catch (e) {
      console.log(`[오류] ${item.filename}: ${e.message}`);
    }
  }

  const n = results.length;
  console.log(`\n=== 결과 (n=${n}) ===`);
  for (const k of RECALL_KS) {
    console.log(`Top-${k} ${k === 1 ? '정확도' : 'Recall'}: ${n ? ((hits[k] / n) * 100).toFixed(1) : 0}%`);
  }

  const outPath = path.join(__dirname, 'output', `eval_${BRAND}_${Date.now()}.json`);
  fs.writeFileSync(
    outPath,
    JSON.stringify(
      {
        brand: BRAND,
        top1Rate: hits[1] / n,
        top3Recall: hits[3] / n,
        top5Recall: hits[5] / n,
        top10Recall: hits[10] / n,
        results,
      },
      null,
      2
    ),
    'utf-8'
  );
  console.log(`상세 결과 저장: ${outPath}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
