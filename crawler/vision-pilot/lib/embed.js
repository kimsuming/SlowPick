const { getClient, withRateLimitRetry } = require('./openaiClient');

async function embedText(text) {
  const client = getClient();
  const response = await withRateLimitRetry(() =>
    client.embeddings.create({
      model: 'text-embedding-3-small',
      input: text,
    })
  );
  return response.data[0].embedding;
}

function cosineSimilarity(a, b) {
  let dot = 0, normA = 0, normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

module.exports = { embedText, cosineSimilarity };
