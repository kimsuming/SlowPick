import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slowpick/service/api_client.dart';
import 'package:slowpick/service/ml_api_client.dart';

/// 혈당 기록(blood_sugar_records)을 EC2 백엔드와 주고받는 서비스.
///
/// [중요] 두 개의 서로 다른 백엔드에 동시에 씁니다 (dual-write):
///   1. Node.js (api_client.dart, 3000번) — 화면에 보여줄 기록 목록, 삭제, 소유권 관리
///   2. Python/FastAPI (ml_api_client.dart, 8000번) — ML 모델 학습/예측용 데이터
///      (model_manager.py가 이 DB만 보고 개인화 단계를 판단하므로, 여기 안 들어가면
///       사용자가 아무리 기록해도 예측이 절대 개인화되지 않음)
///
/// Python 쪽은 실패해도 사용자 경험(노트 저장 자체)을 막지 않도록
/// try/catch로 감싸서 "베스트 에포트"로만 보낸다.
///
/// 백엔드 필요 엔드포인트 (Node.js):
///   POST /api/blood-sugar-records
///     body: { meal_timing, medication, insulin, exercise, blood_sugar, menu_id? }
///     meal_timing: 'after_meal_2h' | 'after_meal_1h' | 'none'
///   GET  /api/blood-sugar-records?limit=&days=
///   DELETE /api/blood-sugar-records/:id
///   POST /api/blood-sugar-records/:id/followups
///     body: { offset_minutes: 30|60|120, blood_sugar }
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

  /// userId는 ML 서버(Python) 저장용으로 필요. Cognito sub를 넘겨준다.
  static Future<int?> addRecord({
    required String userId,
    required String mealTiming,
    required bool medication,
    required bool insulin,
    required String exercise,
    required int bloodSugar,
    int? menuId,
    String? drinkName,
    num? sugarG,
  }) async {
    final response = await ApiClient.instance.post(
      '/api/blood-sugar-records',
      body: {
        'meal_timing': mealTiming,
        'medication': medication,
        'insulin': insulin,
        'exercise': exercise,
        'blood_sugar': bloodSugar,
        if (menuId != null) 'menu_id': menuId,
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        '혈당 기록 저장 실패 (${response.statusCode}): ${_extractMessage(response)}',
      );
    }

    // Node가 만든 record의 id를 파싱 (없으면 followup 연결이 안 되니 null 처리하고 넘어감)
    int? nodeRecordId;
    try {
      final decoded = jsonDecode(response.body);
      final raw = decoded is Map
          ? (decoded['id'] ?? decoded['record']?['id'])
          : null;
      if (raw != null) nodeRecordId = raw is int ? raw : int.tryParse('$raw');
    } catch (_) {}

    final context = _RecordContext(
      mealTiming: mealTiming,
      medication: medication,
      insulin: insulin,
      exercise: exercise,
      menuId: menuId,
      drinkName: drinkName,
      sugarG: sugarG,
    );

    // Python(ML) 서버에도 같은 스냅샷을 베스트 에포트로 저장
    await _mirrorToMl(userId: userId, context: context, bloodSugar: bloodSugar);

    return nodeRecordId;
  }

  static Future<List<Map<String, dynamic>>> fetchRecords({
    int limit = 200,
  }) async {
    final response = await ApiClient.instance.get(
      '/api/blood-sugar-records',
      params: {'limit': '$limit'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        '혈당 기록 조회 실패 (${response.statusCode}): ${_extractMessage(response)}',
      );
    }
    final decoded = jsonDecode(response.body);
    final List list = decoded is List
        ? decoded
        : (decoded['records'] as List? ?? []);
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> deleteRecord(int id) async {
    final response = await ApiClient.instance.delete(
      '/api/blood-sugar-records/$id',
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        '혈당 기록 삭제 실패 (${response.statusCode}): ${_extractMessage(response)}',
      );
    }
  }

  /// userId(Cognito sub)를 추가로 받아야 Python 쪽에도 같이 기록할 수 있음.
  static Future<void> addFollowup({
    required String userId,
    required int recordId,
    required int offsetMinutes,
    required int bloodSugar,
  }) async {
    final response = await ApiClient.instance.post(
      '/api/blood-sugar-records/$recordId/followups',
      body: {'offset_minutes': offsetMinutes, 'blood_sugar': bloodSugar},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        '후속 혈당 저장 실패 (${response.statusCode}): ${_extractMessage(response)}',
      );
    }

    // Python 서버에도 "N분 후 실측값"임을 명시해서 전달.
    // 시간차 계산 없이, 이 offsetMinutes 값을 그대로 믿고 가장 최근 기록에 채워넣는다.
    try {
      await MlApiClient.instance.post(
        '/record',
        body: {
          'user_id': userId,
          'current_glucose': bloodSugar,
          'followup_offset_minutes': offsetMinutes,
        },
      );
    } catch (e) {
      // ML 서버 저장 실패는 노트 저장 자체를 막지 않음 (베스트 에포트)
      // ignore: avoid_print
      print('ML 서버 미러링 실패 (무시하고 계속): $e');
    }
  }

  static Future<void> _mirrorToMl({
    required String userId,
    required _RecordContext context,
    required int bloodSugar,
  }) async {
    try {
      await MlApiClient.instance.post(
        '/record',
        body: {
          'user_id': userId,
          'current_glucose': bloodSugar,
          'meal_status': _mealTimingToCode(context.mealTiming),
          'exercise_level': _exerciseToCode(context.exercise),
          'insulin_taken': context.insulin,
          'medication_taken': context.medication,
          if (context.menuId != null) 'menu_id': context.menuId,
          if (context.drinkName != null) 'drink_name': context.drinkName,
          if (context.sugarG != null) 'sugar_g': context.sugarG,
        },
      );
    } catch (e) {
      // ML 서버 저장 실패는 노트 저장 자체를 막지 않음 (베스트 에포트)
      // ignore: avoid_print
      print('ML 서버 미러링 실패 (무시하고 계속): $e');
    }
  }

  static int _mealTimingToCode(String mealTiming) {
    switch (mealTiming) {
      case 'after_meal_2h':
        return 2; // MealStatus.WITHIN_2H
      case 'after_meal_1h':
        return 1; // MealStatus.WITHIN_1H
      default:
        return 0; // MealStatus.FASTING
    }
  }

  static int _exerciseToCode(String exercise) {
    switch (exercise) {
      case 'light':
        return 1;
      case 'intense':
        return 2;
      default:
        return 0;
    }
  }
}

class _RecordContext {
  final String mealTiming;
  final bool medication;
  final bool insulin;
  final String exercise;
  final int? menuId;
  final String? drinkName;
  final num? sugarG;

  _RecordContext({
    required this.mealTiming,
    required this.medication,
    required this.insulin,
    required this.exercise,
    this.menuId,
    this.drinkName,
    this.sugarG,
  });
}
