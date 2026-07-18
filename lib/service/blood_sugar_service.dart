import 'dart:convert';
import 'package:slowpick/service/api_client.dart';

/// 혈당 기록(blood_sugar_records)을 EC2 백엔드와 주고받는 서비스.
///
/// 백엔드 필요 엔드포인트:
///   POST /api/blood-sugar-records
///     body: { meal_timing, medication, exercise, blood_sugar, menu_id? }
class BloodSugarService {
  BloodSugarService._();

  static Future<void> addRecord({
    required String mealTiming,
    required bool medication,
    required String exercise,
    required int bloodSugar,
    int? menuId,
  }) async {
    final response = await ApiClient.instance.post(
      '/api/blood-sugar-records',
      body: {
        'meal_timing': mealTiming,
        'medication': medication,
        'exercise': exercise,
        'blood_sugar': bloodSugar,
        if (menuId != null) 'menu_id': menuId,
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception('혈당 기록 저장 실패 (${response.statusCode}): $message');
    }
  }
}
