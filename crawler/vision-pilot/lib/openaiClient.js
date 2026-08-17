const OpenAI = require('openai');

let client = null;

function getClient() {
  if (!client) {
    if (!process.env.OPENAI_API_KEY) {
      throw new Error('OPENAI_API_KEY가 설정되지 않았습니다. crawler/.env에 추가하세요.');
    }
    client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  }
  return client;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// OpenAI가 429 메시지에 "Please try again in 664ms." / "Please try again in 1.5s."
// 형태로 대기 시간을 알려주므로 거기서 뽑아 쓴다. 응답 헤더에 retry-after(-ms)가
// 있으면 그쪽을 우선한다.
function parseRetryDelayMs(error) {
  const retryAfterMs = error?.headers?.get?.('retry-after-ms');
  if (retryAfterMs) return Math.ceil(parseFloat(retryAfterMs));

  const retryAfterSec = error?.headers?.get?.('retry-after');
  if (retryAfterSec) return Math.ceil(parseFloat(retryAfterSec) * 1000);

  const message = error?.message || '';

  const msMatch = message.match(/try again in\s+([\d.]+)\s*ms/i);
  if (msMatch) return Math.ceil(parseFloat(msMatch[1]));

  const secMatch = message.match(/try again in\s+([\d.]+)\s*s/i);
  if (secMatch) return Math.ceil(parseFloat(secMatch[1]) * 1000);

  return null;
}

/**
 * OpenAI 429(rate limit) 오류를 만나면 응답이 알려준 대기시간만큼(없으면 지수
 * 백오프로) 기다렸다가 자동 재시도한다. 429가 아닌 오류는 그대로 던진다.
 */
async function withRateLimitRetry(fn, { maxRetries = 5, fallbackBaseMs = 2000 } = {}) {
  let attempt = 0;

  while (true) {
    try {
      return await fn();
    } catch (error) {
      const isRateLimit = error?.status === 429;

      if (!isRateLimit || attempt >= maxRetries) {
        throw error;
      }

      const waitMs = parseRetryDelayMs(error) ?? fallbackBaseMs * 2 ** attempt;
      attempt += 1;

      console.log(`   ⏳ Rate limit — ${waitMs}ms 대기 후 재시도 (${attempt}/${maxRetries})`);
      await sleep(waitMs);
    }
  }
}

module.exports = { getClient, withRateLimitRetry };
