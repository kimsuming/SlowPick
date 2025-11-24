const admin = require('firebase-admin'); //SDK 라이브러리 불러오기
const serviceAccount = require("./slowpick-ebc24-firebase-adminsdk-fbsvc-e20328a442.json"); // key

// 중복 실행 방지 및 초기화
if (!admin.apps.length) { // firebase가 안 켜져 있을 때만 
  admin.initializeApp({ // admin.initializeApp(config): 부팅
    credential: admin.credential.cert(serviceAccount)
  });
}

// admin 앱에서 firebase 데이터베이스를 다루는 Client만 뽑아 db라고 한다
const db = admin.firestore();

// 호출 시 db 내보냄
module.exports = db;