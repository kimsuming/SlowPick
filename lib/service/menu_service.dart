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

  /// 같은 브랜드+메뉴명을 가진 핫/아이스·사이즈 변형들을 하나의 항목으로 묶는다.
  /// 각 그룹은 대표 변형(핫 + 가장 작은 사이즈)의 필드를 그대로 갖고,
  /// 그룹에 속한 모든 변형은 'variants' 키에 담아 상세 화면에서 전환할 수 있게 한다.
  static List<Map<String, dynamic>> groupVariants(List<Map<String, dynamic>> menus) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    final List<String> order = [];

    for (final menu in menus) {
      final key = '${menu['brand_name']}|||${menu['menu_name']}';
      final group = groups.putIfAbsent(key, () {
        order.add(key);
        return [];
      });
      group.add(menu);
    }

    return order.map((key) {
      final variants = groups[key]!;
      return {
        ...pickDefaultVariant(variants),
        'variants': variants,
      };
    }).toList();
  }

  static int _sizeRank(Map<String, dynamic> variant) =>
      (variant['size_rank'] as num?)?.toInt() ?? -1;

  /// 디폴트: [핫] 우선, 그 안에서 가장 작은 사이즈.
  static Map<String, dynamic> pickDefaultVariant(List<Map<String, dynamic>> variants) {
    if (variants.length == 1) return variants.first;

    final hotVariants = variants.where((v) => v['temperature'] == 'HOT').toList();
    final pool = hotVariants.isNotEmpty ? hotVariants : variants;

    final sorted = [...pool]..sort((a, b) => _sizeRank(a).compareTo(_sizeRank(b)));
    return sorted.first;
  }
}
