/// 혈당 기록(blood_sugar_records) API 응답을 감싸는 공용 모델.
/// bloodSugarNote.dart, blood_sugar_note_screen.dart 등 여러 화면에서 공유한다.
class BloodSugarFollowup {
  final int bloodSugar;
  final DateTime recordedAt;

  BloodSugarFollowup({required this.bloodSugar, required this.recordedAt});

  factory BloodSugarFollowup.fromJson(Map<String, dynamic> json) {
    return BloodSugarFollowup(
      bloodSugar: (json['blood_sugar'] as num).toInt(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}

class BloodSugarRecord {
  final int id;
  final int? menuId;
  final String? menuName;
  final String? brandName;
  final String? imageUrl;
  final String mealTiming;
  final bool medication;
  final String exercise;
  final int bloodSugar;
  final DateTime recordedAt;
  final Map<int, BloodSugarFollowup> followups;

  BloodSugarRecord({
    required this.id,
    required this.menuId,
    required this.menuName,
    required this.brandName,
    required this.imageUrl,
    required this.mealTiming,
    required this.medication,
    required this.exercise,
    required this.bloodSugar,
    required this.recordedAt,
    required this.followups,
  });

  factory BloodSugarRecord.fromJson(Map<String, dynamic> json) {
    final followups = <int, BloodSugarFollowup>{};
    final rawFollowups = json['followups'] as List?;
    if (rawFollowups != null) {
      for (final item in rawFollowups) {
        if (item is! Map<String, dynamic>) continue;
        final offset = item['offset_minutes'] as int?;
        if (offset == null) continue;
        followups[offset] = BloodSugarFollowup.fromJson(item);
      }
    }

    return BloodSugarRecord(
      id: json['id'] as int,
      menuId: json['menu_id'] as int?,
      menuName: json['menu_name'] as String?,
      brandName: json['brand_name'] as String?,
      imageUrl: json['image_url'] as String?,
      mealTiming: json['meal_timing'] as String? ?? 'fasting',
      medication: json['medication'] == true || json['medication'] == 1,
      exercise: json['exercise'] as String? ?? 'none',
      bloodSugar: (json['blood_sugar'] as num).toInt(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      followups: followups,
    );
  }

  DateTime get day =>
      DateTime(recordedAt.year, recordedAt.month, recordedAt.day);
}
