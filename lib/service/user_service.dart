import 'dart:convert';
import 'package:slowpick/service/api_client.dart';

/// 유저 프로필 / 건강 정보 / 알러지를 EC2 백엔드와 주고받는 서비스.
///
/// 백엔드 필요 엔드포인트:
///   GET  /api/user/profile  → { nickname, health: {...}, allergies: [String] }
///   PUT  /api/user/profile  → 위와 동일한 body
///   GET  /api/allergens     → { allergens: [String] }  (menu_allergies GROUP BY)
class UserService {
  UserService._();

  static Future<Map<String, dynamic>?> fetchProfile() async {
    final response = await ApiClient.instance.get('/api/user/profile');
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('프로필 로드 실패 (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> saveProfile(Map<String, dynamic> body) async {
    final response =
        await ApiClient.instance.put('/api/user/profile', body: body);
    if (response.statusCode != 200) {
      throw Exception('저장 실패 (${response.statusCode})');
    }
  }

  /// menu_allergies 테이블에서 GROUP BY allergy_name 으로 조회한 목록.
  static Future<List<String>> fetchMenuAllergens() async {
    final response = await ApiClient.instance.get('/api/allergens');
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return List<String>.from(body['allergens'] ?? []);
  }
}
