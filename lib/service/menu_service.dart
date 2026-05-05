import 'dart:convert';
import 'package:http/http.dart' as http;

class MenuService {
  static const String _baseUrl = 'http://3.34.7.133:3000';

  static Future<List<Map<String, dynamic>>> fetchMenus({
    String? search,
    List<String>? brands,
    String? sort,
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (brands != null && brands.isNotEmpty) params['brands'] = brands.join(',');
    if (sort != null) params['sort'] = sort;

    final uri = Uri.parse('$_baseUrl/api/menus').replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('메뉴 로드 실패 (${response.statusCode})');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['menus']);
  }

  static Future<List<Map<String, dynamic>>> fetchRecommended() async {
    final uri = Uri.parse('$_baseUrl/api/menus/recommended');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('추천 메뉴 로드 실패');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['menus']);
  }

  static Future<List<String>> fetchMenuNames() async {
    final uri = Uri.parse('$_baseUrl/api/menus/names');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('메뉴명 로드 실패');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return List<String>.from(body['names']);
  }
}
