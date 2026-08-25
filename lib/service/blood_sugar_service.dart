import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slowpick/service/api_client.dart';

/// 혈당 기록(blood_sugar_records)을 EC2 백엔드와 주고받는 서비스.
///
/// 백엔드 필요 엔드포인트:
///   POST /api/blood-sugar-records
///     body: { meal_timing, medication, exercise, blood_sugar, menu_id? }
///   GET  /api/blood-sugar-records?limit=&days=
///     응답: { records: [{ id, menu_id, menu_name, brand_name, image_url,
///              meal_timing, medication, exercise, blood_sugar, recorded_at }, ...] }
///     (로그인 유저 소유 기록만, req.user.sub 기준, recorded_at DESC)
///   DELETE /api/blood-sugar-records/:id
///     (본인 기록만 삭제 가능, WHERE id = ? AND cognito_sub = ?)
///   POST /api/blood-sugar-records/:id/followups
///     body: { offset_minutes: 30|60|120, blood_sugar }
///     응답: { offset_minutes, blood_sugar, recorded_at }
///     (같은 offset_minutes로 다시 호출하면 값을 덮어씀 — upsert)
class BloodSugarService {
  BloodSugarService._();

  static String _extractMessage(http.Response response) {
    String message = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      }
    } catch (_) {}
    return message;
  }

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
      throw Exception(
          '혈당 기록 저장 실패 (${response.statusCode}): ${_extractMessage(response)}');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRecords({int limit = 200}) async {
    final response = await ApiClient.instance.get(
      '/api/blood-sugar-records',
      params: {'limit': '$limit'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          '혈당 기록 조회 실패 (${response.statusCode}): ${_extractMessage(response)}');
    }
    final decoded = jsonDecode(response.body);
    final List list =
        decoded is List ? decoded : (decoded['records'] as List? ?? []);
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> deleteRecord(int id) async {
    final response = await ApiClient.instance.delete('/api/blood-sugar-records/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          '혈당 기록 삭제 실패 (${response.statusCode}): ${_extractMessage(response)}');
    }
  }

  static Future<void> addFollowup({
    required int recordId,
    required int offsetMinutes,
    required int bloodSugar,
  }) async {
    final response = await ApiClient.instance.post(
      '/api/blood-sugar-records/$recordId/followups',
      body: {
        'offset_minutes': offsetMinutes,
        'blood_sugar': bloodSugar,
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          '후속 혈당 저장 실패 (${response.statusCode}): ${_extractMessage(response)}');
    }
  }
}
