import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slowpick/service/auth_service.dart';

/// EC2 백엔드와 통신하는 공용 HTTP 클라이언트.
/// 모든 요청에 Cognito ID 토큰을 Authorization 헤더로 자동 첨부한다.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String _baseUrl = 'http://3.34.7.133:3000';
  static const Duration _timeout = Duration(seconds: 10);

  /// JWT가 포함된 공통 헤더를 반환한다.
  /// 미로그인 상태면 Authorization 헤더 없이 반환한다.
  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.fetchIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 401 응답을 받았을 때 예외로 변환한다.
  void _checkUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      throw const UnauthorizedException();
    }
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: (params?.isNotEmpty ?? false) ? params : null,
    );
    final response = await http
        .get(uri, headers: await _authHeaders())
        .timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> post(
    String path, {
    Object? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .post(uri, headers: await _authHeaders(),
            body: body != null ? jsonEncode(body) : null)
        .timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> put(
    String path, {
    Object? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .put(uri, headers: await _authHeaders(),
            body: body != null ? jsonEncode(body) : null)
        .timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .delete(uri, headers: await _authHeaders())
        .timeout(_timeout);
    _checkUnauthorized(response);
    return response;
  }
}

/// 백엔드가 JWT를 거부했을 때 (401) 발생하는 예외.
/// 호출부에서 로그인 화면으로 리다이렉트하는 등 처리한다.
class UnauthorizedException implements Exception {
  const UnauthorizedException();

  @override
  String toString() => '인증이 만료되었습니다. 다시 로그인해주세요.';
}
