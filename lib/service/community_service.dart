import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:slowpick/service/api_client.dart';

class CommunityService {
  // ─── 날짜 포맷 ─────────────────────────────────────────────────────────────
  static String fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final y = dt.year;
      final mo = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$y.$mo.$d $h:$mi';
    } catch (_) {
      return iso;
    }
  }

  // ─── 소통 게시판 ────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchPosts({
    int page = 1,
    int limit = 20,
    String? q,
    String sort = 'latest',
  }) async {
    final res = await ApiClient.instance.get('/api/posts', params: {
      'page': '$page',
      'limit': '$limit',
      'sort': sort,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    if (res.statusCode != 200) throw Exception('게시글 로드 실패 (${res.statusCode})');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchPost(int id) async {
    final res = await ApiClient.instance.get('/api/posts/$id');
    if (res.statusCode == 404) throw Exception('삭제된 게시글입니다.');
    if (res.statusCode != 200) throw Exception('게시글 로드 실패');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<int> createPost(String title, String content) async {
    final res = await ApiClient.instance
        .post('/api/posts', body: {'title': title, 'content': content});
    if (res.statusCode != 201) throw Exception('게시글 작성 실패');
    return (jsonDecode(res.body) as Map<String, dynamic>)['id'] as int;
  }

  static Future<void> deletePost(int id) async {
    final res = await ApiClient.instance.delete('/api/posts/$id');
    if (res.statusCode != 200) throw Exception('삭제 실패');
  }

  static Future<String?> votePost(int id, String type) async {
    final res = await ApiClient.instance
        .post('/api/posts/$id/vote', body: {'type': type});
    if (res.statusCode != 200) throw Exception('투표 실패');
    return (jsonDecode(res.body) as Map<String, dynamic>)['voted'] as String?;
  }

  static Future<bool> bookmarkPost(int id) async {
    final res = await ApiClient.instance.post('/api/posts/$id/bookmark');
    if (res.statusCode != 200) throw Exception('북마크 실패');
    return (jsonDecode(res.body) as Map<String, dynamic>)['bookmarked'] as bool;
  }

  static Future<List<dynamic>> fetchComments(int postId) async {
    final res = await ApiClient.instance.get('/api/posts/$postId/comments');
    if (res.statusCode != 200) throw Exception('댓글 로드 실패');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<int> createComment(
    int postId, {
    required String content,
    int? parentId,
  }) async {
    final res = await ApiClient.instance.post(
      '/api/posts/$postId/comments',
      body: {
        'content': content,
        if (parentId != null) 'parent_id': parentId,
      },
    );
    if (res.statusCode != 201) throw Exception('댓글 작성 실패');
    return (jsonDecode(res.body) as Map<String, dynamic>)['id'] as int;
  }

  static Future<bool> likeComment(int commentId) async {
    final res = await ApiClient.instance
        .post('/api/posts/comments/$commentId/like');
    if (res.statusCode != 200) throw Exception('좋아요 실패');
    return (jsonDecode(res.body) as Map<String, dynamic>)['liked'] as bool;
  }

  // ─── 레시피 게시판 ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchRecipes({
    int page = 1,
    int limit = 20,
    String? q,
    String sort = 'latest',
    bool mine = false,
    bool liked = false,
  }) async {
    final res = await ApiClient.instance.get('/api/recipes', params: {
      'page': '$page',
      'limit': '$limit',
      'sort': sort,
      if (q != null && q.isNotEmpty) 'q': q,
      if (mine) 'mine': 'true',
      if (liked) 'liked': 'true',
    });
    if (res.statusCode != 200) throw Exception('레시피 로드 실패 (${res.statusCode})');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<int> createRecipe({
    required String title,
    required String content,
    String? thumbnailUrl,
    List<String>? tags,
  }) async {
    final res = await ApiClient.instance.post('/api/recipes', body: {
      'title': title,
      'content': content,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
    });
    if (res.statusCode != 201) throw Exception('레시피 작성 실패');
    return (jsonDecode(res.body) as Map<String, dynamic>)['id'] as int;
  }

  static Future<bool> likeRecipe(int id) async {
    final res = await ApiClient.instance.post('/api/recipes/$id/like');
    if (res.statusCode != 200) throw Exception('찜 실패');
    return (jsonDecode(res.body) as Map<String, dynamic>)['liked'] as bool;
  }

  // ─── S3 이미지 업로드 ────────────────────────────────────────────────────────
  static Future<String> uploadImage(Uint8List bytes, String contentType) async {
    final presignRes = await ApiClient.instance
        .post('/api/upload/presign', body: {'contentType': contentType});
    if (presignRes.statusCode != 200) {
      throw Exception(
          'URL 발급 실패 (${presignRes.statusCode}): ${presignRes.body}');
    }
    final data = jsonDecode(presignRes.body) as Map<String, dynamic>;

    final s3Res = await http.put(
      Uri.parse(data['upload_url'] as String),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (s3Res.statusCode != 200) {
      throw Exception('이미지 업로드 실패 (${s3Res.statusCode})');
    }
    return data['public_url'] as String;
  }
}
