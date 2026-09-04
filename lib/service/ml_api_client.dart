import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slowpick/service/auth_service.dart';

/// 혈당 예측 ML 서버(FastAPI, EC2 8000번 포트)와 통신하는 전용 클라이언트.
/// 카페 메뉴 서버(Node.js, 3000번)와는 baseUrl이 다르므로 ApiClient와 분리했다.
/// 사용법은 ApiClient와 동일: MlApiClient.instance.post('/record', body: {...})
class MlApiClient {
  MlApiClient._();
  static final MlApiClient instance = MlApiClient._();

  static const String _baseUrl = 'http://3.34.7.133:8000';
  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.fetchIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _checkUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      throw const MlUnauthorizedException();
    }
  }

  Future<http.Response> get(String path, {Map<String, String>? params}) async {
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: (params?.isNotEmpty ?? false) ? params : null);
    final response = await http
        .get(uri, headers: await _authHeaders())
        .timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .post(
          uri,
          headers: await _authHeaders(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }
}

class MlUnauthorizedException implements Exception {
  const MlUnauthorizedException();

  @override
  String toString() => '인증이 만료되었습니다. 다시 로그인해주세요.';
}
