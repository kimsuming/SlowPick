import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/screen/community_recipe.dart';
import 'package:slowpick/screen/community_write.dart';
import 'package:slowpick/screen/community_post.dart';
import 'package:slowpick/screen/community_Screen.dart';
import 'package:slowpick/service/community_service.dart';

class Communitymain extends StatefulWidget {
  const Communitymain({super.key});

  @override
  State<Communitymain> createState() => _CommunitymainState();
}

class _CommunitymainState extends State<Communitymain> {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
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

  ////////////////////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF999999)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('커뮤니티'),
        centerTitle: true,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: -1.30,
          fontFamily: 'KoPubDotum',
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      body: Container(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              _recomendedMenu(size),

              SizedBox(height: 23),

              _searchBar(size),

              SizedBox(height: 48),

              _livePopularPosts(size),

              SizedBox(height: 48),

              _communityButtons(size),
            ],
          ),
        ),
      ),
    );
  }

  // 커뮤니티 추천 멘트 위젯
  Widget _recomendedMenu(Size size) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CommunityScreen()),
        );
      },
      child: Container(
        width: size.width * 0.93,
        height: 151,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(1.00, 0.50),
            end: Alignment(0.00, 0.50),
            colors: [const Color(0xFF81DB60), const Color(0xFFBCEC81)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 6,
              offset: Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
          borderRadius: BorderRadius.circular(15),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 25,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(width: 7),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '슬로우 커뮤니티에서 ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -2,
                        ),
                      ),
                      Text(
                        '다양한 카페 정보를',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -2,
                        ),
                      ),
                      Text(
                        '공유해봐요!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontFamily: 'KoPubDotum Medium',
                          fontWeight: FontWeight.w500,
                          letterSpacing: -2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 이미지
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 150,
                height: 150,
                child: Image.asset(
                  'images/comment_menu/community.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF187100)),
      );
    }
    if (_posts.isEmpty) {
      return const Center(
        child: Text('게시글이 없습니다.', style: TextStyle(color: Colors.grey)),
      );
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
            border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
          ),
          width: 140,
          height: 50,
          child: const Center(
            child: Text(
              '소통',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: 'KoPubDotum Medium',
                fontWeight: FontWeight.w400,
                height: 1,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CommunityRecipe()),
          ),
          child: const SizedBox(
            width: 150,
            height: 50,
            child: Center(
              child: Text(
                '레시피',
                style: TextStyle(
                  color: Color(0xFFB5B5B5),
                  fontSize: 20,
                  fontFamily: 'KoPubDotum Medium',
                  fontWeight: FontWeight.w400,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchBar(Size size) {
    return Container(
      width: size.width * 0.8,
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
                border: InputBorder.none,
                isDense: true,
              ),
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
    );
  }

  Widget _livePopularPosts(Size size) {
    return SizedBox(
      width: size.width * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🔥 실시간 인기글',
                style: TextStyle(
                  color: const Color(0xFF242526),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '보러가기',
                    style: TextStyle(
                      color: const Color(0xFF73AD31),
                      fontSize: 15,
                      fontFamily: 'KoPubDotum Medium',
                      fontWeight: FontWeight.w400,
                      letterSpacing: -2,
                    ),
                  ),

                  SizedBox(width: 2),

                  //화살표 버튼
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF74AE31), // 초록색
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CommunityScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 15),

          Text(
            '1    메가 귤젤리 스무디 당류 80g 넘는거 알 \n2    치이카와 콜라보 제품 사보신분 \n3    여기 논란 터진 것 같던데\n4    할인쿠폰 뿌려요!\n5    투썸에서 케이크 무료로 주는 이벤트 있',
            style: TextStyle(
              color: const Color(0xFF242526),
              fontSize: 14,
              fontFamily: 'KoPubDotum Medium',
              fontWeight: FontWeight.w400,
              height: 2.07,
              letterSpacing: -0.21,
            ),
          ),
        ],
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
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFAEAEAE),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.70,
          ),
        ),
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
        ..._visiblePages.map(
          (p) => GestureDetector(
            onTap: () => _load(page: p),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '$p',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: p == _page ? FontWeight.bold : FontWeight.normal,
                  color: p == _page ? Colors.black : const Color(0xFF666666),
                ),
              ),
            ),
          ),
        ),
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
            bottom: BorderSide(color: Color(0xFFD7D7D7), width: 1.3),
          ),
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
                      letterSpacing: -1,
                    ),
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
                    letterSpacing: -1,
                  ),
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
                  letterSpacing: -1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _communityButtons(Size size) {
    return SizedBox(
      width: size.width * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text(
              '활동하기',
              style: TextStyle(
                color: const Color(0xFF242526),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.50,
              ),
            ),
          ),

          SizedBox(height: 7),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              //소통하기
              GestureDetector(
                onTap: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const CommunityScreen()),
                  );
                  if (created == true) _load(page: 1);
                },
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Image.asset('images/comment_menu/talk.png'),
                    ),

                    SizedBox(height: 5),

                    Text(
                      '소통하기',
                      style: TextStyle(
                        color: const Color(0xFF187100),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1.50,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 12),

              //레시피 공유
              GestureDetector(
                onTap: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const CommunityRecipe()),
                  );
                  if (created == true) _load(page: 1);
                },
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Image.asset('images/comment_menu/recipe.png'),
                    ),

                    SizedBox(height: 5),

                    Text(
                      '레시피 공유',
                      style: TextStyle(
                        color: const Color(0xFF187100),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1.50,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 12),

              //글쓰기
              GestureDetector(
                onTap: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const CommunityWrite()),
                  );
                  if (created == true) _load(page: 1);
                },
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Image.asset('images/comment_menu/pencil.png'),
                    ),

                    SizedBox(height: 5),

                    Text(
                      '글쓰기',
                      style: TextStyle(
                        color: const Color(0xFF187100),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1.50,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 12),

              //설정
              Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                          offset: Offset(0, 1),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Image.asset('images/comment_menu/setting.png'),
                  ),

                  SizedBox(height: 5),

                  Text(
                    '설정',
                    style: TextStyle(
                      color: const Color(0xFF187100),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -1.50,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
