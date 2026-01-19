const FirebaseService = require('./src/services/firebaseService');
const ValidatorService = require('./src/services/validatorService');

async function testSingleUpload() {
  // 1. 테스트용 가짜 데이터 (컴포즈커피 스타일)
  const mockMenu = {
    brand_name: "컴포즈커피",
    category: "음료",
    menu_name: "테스트용 아메리카노",
    menu_image_url: "https://composecoffee.com/files/test.jpg",
    is_active: true,
    menu_type: "regular",
    nutrition: {
      caffeine_mg: 150,
      calories_kcal: 15,
      protein_g: 1,
      saturated_fat_g: 0,
      sodium_mg: 5,
      sugar_g: 0,
      size_standard: "20oz"
    },
    allergy_info: ["우유"],
    description: "테스트 데이터입니다."
  };

  console.log("🔍 1. 데이터 검증 시작...");
  const { isValid, data, errors } = ValidatorService.validate(mockMenu);

  if (isValid) {
    console.log("✅ 검증 통과! Firebase 업로드 시도...");
    try {
      const result = await FirebaseService.uploadMenu(data);
      console.log(`🚀 업로드 성공! 문서 ID: ${result.docId}`);
    } catch (err) {
      console.error("❌ 업로드 실패:", err);
    }
  } else {
    console.error("❌ 검증 실패:", errors);
  }
}

testSingleUpload();