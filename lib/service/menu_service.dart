import 'dart:convert';
import 'package:slowpick/service/api_client.dart';

class MenuService {
  static Future<List<Map<String, dynamic>>> fetchMenus({
    String? search,
    List<String>? brands,
    String? sort,
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (brands != null && brands.isNotEmpty) params['brands'] = brands.join(',');
    if (sort != null) params['sort'] = sort;

    final response = await ApiClient.instance.get('/api/menus', params: params);
    if (response.statusCode != 200) {
      throw Exception('메뉴 로드 실패 (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['menus']);
  }

  static Future<List<Map<String, dynamic>>> fetchRecommended() async {
    final response = await ApiClient.instance.get('/api/menus/recommended');
    if (response.statusCode != 200) throw Exception('추천 메뉴 로드 실패');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['menus']);
  }

  static Future<List<String>> fetchMenuNames() async {
    final response = await ApiClient.instance.get('/api/menus/names');
    if (response.statusCode != 200) throw Exception('메뉴명 로드 실패');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return List<String>.from(body['names']);
  }

  static Future<bool> likeMenu(int id) async {
    final response = await ApiClient.instance.post('/api/menus/$id/like');
    if (response.statusCode != 200) throw Exception('찜 실패 (${response.statusCode})');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['liked'] as bool;
  }

  static Future<List<Map<String, dynamic>>> fetchLikedMenus() async {
    final response = await ApiClient.instance.get('/api/menus/liked');
    if (response.statusCode != 200) throw Exception('찜 목록 로드 실패 (${response.statusCode})');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['menus']);
  }
}
