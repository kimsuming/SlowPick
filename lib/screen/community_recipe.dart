import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/screen/community_screen.dart';
import 'package:slowpick/screen/community_recipewrite.dart';
import 'package:slowpick/service/community_service.dart';

class CommunityRecipe extends StatefulWidget {
  const CommunityRecipe({super.key});

  @override
  State<CommunityRecipe> createState() => _CommunityRecipeState();
}

class _CommunityRecipeState extends State<CommunityRecipe> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _recipes = [];
  bool _loading = false;
  int _page = 1;
  int _total = 0;

  // 필터 상태: all / popular / mine / liked
  String _filter = 'all';

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
      final data = await CommunityService.fetchRecipes(
        page: page,
        limit: _limit,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        sort: _filter == 'popular' ? 'popular' : 'latest',
        mine: _filter == 'mine',
        liked: _filter == 'liked',
      );
      setState(() {
        _recipes = List<Map<String, dynamic>>.from(data['recipes'] as List);
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

  Future<void> _toggleLike(int index) async {
    final recipe = _recipes[index];
    try {
      final liked = await CommunityService.likeRecipe(recipe['id'] as int);
      setState(() {
        recipe['is_liked'] = liked;
        recipe['like_count'] =
            (recipe['like_count'] as int) + (liked ? 1 : -1);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
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
          children: const [
            Text('슬로우 커뮤니티',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 27,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1.70)),
            Text('Slow Community',
                style: TextStyle(
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
            MaterialPageRoute(builder: (_) => const CommunityRecipewrite()),
          );
          if (created == true) _load(page: 1);
        },
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF187100),
        child: const Icon(Icons.add_box_outlined, color: Colors.white, size: 30),
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
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: Column(
            children: [
              _communicationRecipeSelector(),
              _searchBar(),
              _postFilterTab(),
              _pagination(),
              const SizedBox(height: 4),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF187100)));
    }
    if (_recipes.isEmpty) {
      return const Center(
          child: Text('레시피가 없습니다.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: _recipes.length,
      itemBuilder: (_, i) => _recipeListItem(_recipes[i], i),
    );
  }

  Widget _communicationRecipeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CommunityScreen())),
          child: const SizedBox(
            width: 150,
            height: 50,
            child: Center(
              child: Text('소통',
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
        const SizedBox(width: 30),
        Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 2))),
          width: 140,
          height: 50,
          child: const Center(
            child: Text('레시피',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w400,
                    height: 1,
                    letterSpacing: -1)),
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

  Widget _postFilterTab() {
    final filters = [
      ('all', '전체글'),
      ('popular', '인기'),
      ('mine', '내 등록'),
      ('liked', '찜'),
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Row(
        children: filters
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: _filterChip(f.$2, _filter == f.$1, () {
                    setState(() => _filter = f.$1);
                    _load(page: 1);
                  }),
                ))
            .toList(),
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
                fontSize: 15,
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

  Widget _recipeListItem(Map<String, dynamic> recipe, int index) {
    final tags = (recipe['tags'] as List<dynamic>? ?? []).cast<String>();
    final isLiked = recipe['is_liked'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
              bottom: BorderSide(color: Color(0xFFD7D7D7), width: 1.3)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 2,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: recipe['thumbnail_url'] != null
                    ? CachedNetworkImage(
                        imageUrl: recipe['thumbnail_url'] as String,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _thumbPlaceholder(),
                      )
                    : _thumbPlaceholder(),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        recipe['title'] as String? ?? '',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            letterSpacing: -1.70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tags.isNotEmpty)
                        Text(
                          tags.map((t) => '#$t').join(' '),
                          style: const TextStyle(
                              color: Color(0xFF73AD31),
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -1.70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${recipe['nickname'] ?? ''}  l  조회 ${recipe['view_count'] ?? 0}  l  추천 ${recipe['like_count'] ?? 0}',
                        style: const TextStyle(
                            color: Color(0xFFA7A7A7),
                            fontSize: 12,
                            fontFamily: 'KoPubDotum Medium',
                            fontWeight: FontWeight.w400,
                            height: 1.54,
                            letterSpacing: -1),
                      ),
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.black26,
                          size: 22,
                        ),
                        onPressed: () => _toggleLike(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
        width: 80,
        height: 80,
        color: const Color(0xFFE0E0E0),
        child: const Icon(Icons.image_outlined,
            color: Color(0xFFBBBBBB), size: 36));
  }
}
