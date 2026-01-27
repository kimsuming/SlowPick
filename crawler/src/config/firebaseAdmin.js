// src/config/firebaseAdmin.js
const admin = require('firebase-admin');
const serviceAccount = require("../../slowpick-ebc24-firebase-adminsdk-fbsvc-e20328a442"); // 실제 파일명으로 수정

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log("🔥 Firebase Admin SDK 초기화 완료");
}

const db = admin.firestore();

// db와 admin을 모두 내보내서 유틸리티(FieldValue 등)를 쓸 수 있게 함
module.exports = { admin, db };