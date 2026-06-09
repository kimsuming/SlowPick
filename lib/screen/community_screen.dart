import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/screen/community_recipe.dart';
import 'package:slowpick/screen/community_write.dart';
import 'package:slowpick/screen/community_post.dart';
import 'package:slowpick/service/community_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _posts = [];
  bool _loading = false;
  int _page = 1;
  int _total = 0;
  bool _popular = false; // false=latest, true=popular

  static const int _limit = 20;
  int get _totalPages => (_total / _limit).ceil().clamp(1, 999);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() => _loading = true);
    try {
      final data = await CommunityService.fetchPosts(
        page: page,
        limit: _limit,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        sort: _popular ? 'popular' : 'latest',
      );
      setState(() {
        _posts = List<Map<String, dynamic>>.from(data['posts'] as List);
        _total = data['total'] as int;
        _page = page;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<int> get _visiblePages {
    if (_totalPages <= 5) return List.generate(_totalPages, (i) => i + 1);
    final start = (_page - 2).clamp(1, _totalPages - 4);
    return List.generate(5, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('슬로우 커뮤니티',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 27,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1.70)),
            Text('Slow Community',
                style: const TextStyle(
                    color: Color(0xFF718F74),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.50)),
          ],
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(1, .5),
              end: Alignment(0, .5),
              colors: [Color(0xFFA2F43D), Color(0xFFD5FF72)],
            ),
          ),
        ),
        elevation: 0,
        toolbarHeight: 76,
        actions: [
          IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 50),
              onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CommunityWrite()),
          );
          if (created == true) _load(page: 1);
        },
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF187100),
        child: const Icon(Icons.edit, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(1, .5),
            end: Alignment(0, .5),
            colors: [Color(0xFFA2F43D), Color(0xFFD5FF72)],
          ),
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: Column(
            children: [
              _communicationRecipeSelector(),
              _searchBar(),
              _noticeBar(),
              _postFilterTab(),
              _pagination(),
              Container(height: 1.3, color: const Color(0xFFD7D7D7)),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF187100)));
    }
    if (_posts.isEmpty) {
      return const Center(
          child: Text('게시글이 없습니다.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (_, i) => _postListItem(_posts[i]),
    );
  }

  Widget _communicationRecipeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 2))),
          width: 140,
          height: 50,
          child: const Center(
            child: Text('소통',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w400,
                    height: 1,
                    letterSpacing: -1)),
          ),
        ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const CommunityRecipe())),
          child: const SizedBox(
            width: 150,
            height: 50,
            child: Center(
              child: Text('레시피',
                  style: TextStyle(
                      color: Color(0xFFB5B5B5),
                      fontSize: 20,
                      fontFamily: 'KoPubDotum Medium',
                      fontWeight: FontWeight.w400,
                      height: 1,
                      letterSpacing: -1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Container(
        height: 41,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC1D350), width: 2),
        ),
        child: Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.search, color: Color(0xFFC1D350)),
              onPressed: () => _load(page: 1),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                    border: InputBorder.none, isDense: true),
                onSubmitted: (_) => _load(page: 1),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.clear, color: Color(0xFFC1D350)),
                onPressed: () {
                  _searchCtrl.clear();
                  _load(page: 1);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _noticeBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 2, left: 4),
              child: Icon(Icons.campaign_outlined,
                  color: Color(0xFF666666), size: 40),
            ),
            const Text('필독!',
                style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.70)),
            const SizedBox(width: 6),
            Text('[ 슬로우 커뮤니티 소통 공지 ]',
                style: const TextStyle(
                    color: Color(0xFFA5A5A5),
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                    letterSpacing: -1.70)),
          ],
        ),
      ),
    );
  }

  Widget _postFilterTab() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const SizedBox(width: 15),
          _filterChip('전체글', !_popular, () {
            if (_popular) setState(() => _popular = false);
            _load(page: 1);
          }),
          const SizedBox(width: 6),
          _filterChip('인기글', _popular, () {
            if (!_popular) setState(() => _popular = true);
            _load(page: 1);
          }),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFAEAEAE) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFAEAEAE), width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : const Color(0xFFAEAEAE),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.70)),
      ),
    );
  }

  Widget _pagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF7CB342),
        ),
        ..._visiblePages.map((p) => GestureDetector(
              onTap: () => _load(page: p),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('$p',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: p == _page
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: p == _page
                            ? Colors.black
                            : const Color(0xFF666666))),
              ),
            )),
        IconButton(
          onPressed: _page < _totalPages ? () => _load(page: _page + 1) : null,
          icon: const Icon(Icons.arrow_forward),
          color: const Color(0xFF7CB342),
        ),
      ],
    );
  }

  Widget _postListItem(Map<String, dynamic> post) {
    final id = post['id'] as int;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CommunityPost(postId: id)),
        );
        _load(page: _page);
      },
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color(0xFFD7D7D7), width: 1.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post['title'] as String? ?? '',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '[${post['comment_count'] ?? 0}]',
                  style: const TextStyle(
                      color: Color(0xFF73AD31),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1),
                ),
                const SizedBox(width: 8),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                '${post['nickname'] ?? ''}  l  조회 ${post['view_count'] ?? 0}  l  추천 ${post['like_count'] ?? 0}  l  ${CommunityService.fmtDate(post['created_at'] as String?)}',
                style: const TextStyle(
                    color: Color(0xFFA7A7A7),
                    fontSize: 13,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w400,
                    height: 1.54,
                    letterSpacing: -1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
