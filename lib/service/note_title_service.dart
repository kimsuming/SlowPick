import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slowpick/service/api_client.dart';

/// 노트 이름(예: "거부기의 혈당 노트")을 EC2 백엔드와 주고받는 서비스.
/// 유저별로 노트 종류(note_key)마다 커스텀 이름을 저장한다.
///
/// 백엔드 필요 엔드포인트 (신규):
///   GET /api/note-titles/:noteKey   → { note_key, title }
///   PUT /api/note-titles/:noteKey   body: { title } → { note_key, title }
///   (저장된 값이 없으면 GET은 기본 이름을 내려준다)
///
/// 필요 DB 테이블 (신규):
///   CREATE TABLE user_note_titles (
///     cognito_sub VARCHAR(36) NOT NULL,
///     note_key VARCHAR(30) NOT NULL,
///     title VARCHAR(50) NOT NULL,
///     updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
///     PRIMARY KEY (cognito_sub, note_key),
///     FOREIGN KEY (cognito_sub) REFERENCES users(cognito_sub) ON DELETE CASCADE
///   );
class NoteTitleService {
  NoteTitleService._();

  static const String bloodSugarNoteKey = 'blood_sugar';
  static const String dietNoteKey = 'diet';

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

  static Future<String> fetchTitle(String noteKey, {required String fallback}) async {
    final response = await ApiClient.instance.get('/api/note-titles/$noteKey');
    if (response.statusCode != 200) {
      throw Exception(
          '노트 이름 조회 실패 (${response.statusCode}): ${_extractMessage(response)}');
    }
    final decoded = jsonDecode(response.body);
    final title = decoded is Map ? decoded['title'] as String? : null;
    return (title == null || title.isEmpty) ? fallback : title;
  }

  static Future<String> updateTitle(String noteKey, String title) async {
    final response = await ApiClient.instance.put(
      '/api/note-titles/$noteKey',
      body: {'title': title},
    );
    if (response.statusCode != 200) {
      throw Exception(
          '노트 이름 저장 실패 (${response.statusCode}): ${_extractMessage(response)}');
    }
    final decoded = jsonDecode(response.body);
    return decoded['title'] as String? ?? title;
  }
}
