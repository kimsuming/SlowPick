import 'package:flutter/material.dart';
import 'package:slowpick/service/menu_service.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/widget/menu_cards.dart';

class LikedmenuScreen extends StatefulWidget {
  const LikedmenuScreen({super.key});

  @override
  State<LikedmenuScreen> createState() => _LikedmenuScreenState();
}

class _LikedmenuScreenState extends State<LikedmenuScreen> {
  bool isCategoryView = false;
  String? _selectedBrand; // 브랜드 선택 시 설정, null = 브랜드 목록 보기

  List<Map<String, dynamic>> _likedMenus = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final menus = await MenuService.fetchLikedMenus();
      if (mounted) setState(() => _likedMenus = menus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unlike(int menuId) async {
    final idx = _likedMenus.indexWhere((m) => m['id'] as int == menuId);
    if (idx == -1) return;
    setState(() => _likedMenus.removeAt(idx));
    try {
      await MenuService.likeMenu(menuId);
    } catch (e) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('찜'),
        centerTitle: true,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w500,
          fontFamily: 'KoPubDotum',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(child: _categoryFilter()),
            _contentArea(),
          ],
        ),
      ),
    );
  }

  Widget _categoryFilter() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() {
                isCategoryView = false;
                _selectedBrand = null;
              }),
              child: Container(
                width: 150,
                height: 50,
                decoration: BoxDecoration(
                  color: !isCategoryView ? Colors.white : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('전체',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() {
                isCategoryView = true;
                _selectedBrand = null;
              }),
              child: Container(
                width: 150,
                height: 50,
                decoration: BoxDecoration(
                  color: isCategoryView ? Colors.white : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('카페별 보기',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentArea() {
    if (!isCategoryView) return _likedMenuGrid(_likedMenus, showBack: false);
    if (_selectedBrand == null) return _categoryListView();
    final filtered = _likedMenus
        .where((m) => m['brand_name'] == _selectedBrand)
        .toList();
    return _likedMenuGrid(filtered, showBack: true);
  }

  // 공통 그리드 - 전체 찜 목록 / 브랜드 필터 모두 사용
  Widget _likedMenuGrid(List<Map<String, dynamic>> menus, {required bool showBack}) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF187100))),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double ratio = (screenWidth / 2) / (screenHeight * 0.37);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 브랜드 필터 헤더 (카페별 보기에서 브랜드 선택했을 때만)
        if (showBack)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.black54, size: 20),
                  onPressed: () => setState(() => _selectedBrand = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 6),
                Text(
                  _selectedBrand ?? '',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1),
                ),
              ],
            ),
          ),

        // 개수
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 14, bottom: 10),
          child: Text(
            '총 ${menus.length}개',
            style: const TextStyle(
              color: Color(0xFFB7B7B7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.25,
              letterSpacing: -1,
            ),
          ),
        ),

        // 빈 상태
        if (menus.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border,
                      size: 60, color: Color(0xFFCCCCCC)),
                  SizedBox(height: 12),
                  Text('찜한 메뉴가 없습니다.',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                screenWidth * 0.04, 0, screenWidth * 0.04, 18),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: ratio,
              crossAxisSpacing: screenWidth * 0.04,
              mainAxisSpacing: screenWidth * 0.04,
            ),
            itemCount: menus.length,
            itemBuilder: (_, i) => MenuGridCard(
              data: menus[i],
              isLiked: true,
              onLikeTap: () => _unlike(menus[i]['id'] as int),
            ),
          ),
      ],
    );
  }

  Widget _categoryListView() {
    return Column(
      children: [
        const SizedBox(height: 8),
        GridView.count(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          crossAxisCount: 2,
          crossAxisSpacing: 5,
          mainAxisSpacing: 9,
          childAspectRatio: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _gridItem(imagePath: 'images/brand_logo/logo_starbucks.png',  cafeTitle: '스타벅스'),
            _gridItem(imagePath: 'images/brand_logo/logo_mega.png',       cafeTitle: '메가MGC커피'),
            _gridItem(imagePath: 'images/brand_logo/logo_compose.jpg',    cafeTitle: '컴포즈커피'),
            _gridItem(imagePath: 'images/brand_logo/logo_ediya.jpg',      cafeTitle: '이디야커피'),
            _gridItem(imagePath: 'images/brand_logo/logo_paik.png',       cafeTitle: '빽다방'),
            _gridItem(imagePath: 'images/brand_logo/logo_twosome.png',    cafeTitle: '투썸플레이스'),
            _gridItem(imagePath: 'images/brand_logo/logo_angel.png',      cafeTitle: '엔제리너스'),
            _gridItem(imagePath: 'images/brand_logo/logo_mammoth.png',    cafeTitle: '매머드커피'),
            _gridItem(imagePath: 'images/brand_logo/logo_paul.png',       cafeTitle: '폴 바셋'),
            _gridItem(imagePath: 'images/brand_logo/logo_theventi.png',   cafeTitle: '더벤티'),
            _gridItem(imagePath: 'images/brand_logo/logo_yoger.png',      cafeTitle: '요거프레소'),
            _gridItem(imagePath: 'images/brand_logo/logo_mammoth.png',    cafeTitle: '매머드 익스프레스'),
          ],
        ),
      ],
    );
  }

  Widget _gridItem({String? imagePath, String? cafeTitle}) {
    final count = _likedMenus
        .where((m) => m['brand_name'] == cafeTitle)
        .length;

    return GestureDetector(
      onTap: () => setState(() => _selectedBrand = cafeTitle),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E2E2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SizedBox(width: 10),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFE2E2E2), width: 1.5),
                    image: imagePath != null
                        ? DecorationImage(
                            image: AssetImage(imagePath),
                            fit: BoxFit.cover)
                        : null,
                  ),
                ),
                const SizedBox(width: 5),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        cafeTitle ?? '',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (count > 0)
                      Text(
                        '$count개',
                        style: const TextStyle(
                            color: Color(0xFF73AD31),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.chevron_right,
                color: count > 0
                    ? const Color(0xFF73AD31)
                    : const Color(0xFFE3E3E3),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}