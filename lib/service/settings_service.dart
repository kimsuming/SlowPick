import 'package:shared_preferences/shared_preferences.dart';

/// 검색 화면 카드 미리보기에 표시할 영양 성분을 선택하는 설정.
/// 기기 로컬(SharedPreferences)에 저장되며 로그인 계정과는 무관하다.
class SettingsService {
  static const _previewNutrientsKey = 'preview_nutrients';

  /// 당류는 항상 고정으로 표시되므로 여기에는 포함하지 않음.
  /// 기존에 리스트 뷰가 고정으로 보여주던 나머지 조합을 기본값으로 유지.
  static const List<String> defaultPreviewNutrients = ['protein', 'saturated_fat'];

  static Future<List<String>> loadPreviewNutrients() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_previewNutrientsKey);
    // saved가 null이면 한 번도 저장한 적 없는 상태 → 기본값.
    // saved가 빈 리스트면 사용자가 의도적으로 전부 해제한 상태 → 그대로 존중.
    return saved ?? defaultPreviewNutrients;
  }

  static Future<void> savePreviewNutrients(List<String> nutrientKeys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_previewNutrientsKey, nutrientKeys);
  }
}
