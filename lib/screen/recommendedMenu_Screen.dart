import 'package:flutter/material.dart';
import 'package:slowpick/service/auth_service.dart';
import 'package:slowpick/service/menu_service.dart';
import 'package:slowpick/service/settings_service.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/widget/menu_cards.dart';
import 'package:slowpick/screen/chat_screen.dart';

class RecommendedMenuScreen extends StatefulWidget {
  const RecommendedMenuScreen({super.key});

  @override
  State<RecommendedMenuScreen> createState() => _RecommendedMenuScreenState();
}

class _RecommendedMenuScreenState extends State<RecommendedMenuScreen> {
  List<Map<String, dynamic>> _menus = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _nickname = '';

  // 카드 미리보기에 표시할 영양 성분 (search.dart와 동일하게 SharedPreferences 사용)
  List<String> _previewNutrients = SettingsService.defaultPreviewNutrients;

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _loadMenus();
    _loadPreviewNutrients();
  }

  Future<void> _loadNickname() async {
    final name = await AuthService.instance.fetchNickname();
    if (!mounted) return;
    setState(() => _nickname = name);
  }

  Future<void> _loadPreviewNutrients() async {
    final saved = await SettingsService.loadPreviewNutrients();
    if (!mounted) return;
    setState(() => _previewNutrients = saved);
  }

  Future<void> _loadMenus() async {
    try {
      final menus = await MenuService.fetchRecommended();
      if (!mounted) return;
      setState(() {
        // 핫/아이스·사이즈 변형을 대표 변형 하나로 묶어 보여준다 (search.dart와 동일).
        _menus = MenuService.groupVariants(menus);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike(int menuId) async {
    final idx = _menus.indexWhere((m) => m['id'] as int == menuId);
    if (idx == -1) return;
    final currently = _menus[idx]['is_liked'] as bool? ?? false;
    setState(() => _menus[idx]['is_liked'] = !currently);
    try {
      await MenuService.likeMenu(menuId);
    } catch (e) {
      setState(() => _menus[idx]['is_liked'] = currently);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen()),
          );
        },
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF74AE31),
        child: Image.asset("images/home/chatbot.png", width: 30, height: 30),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      body: Stack(
        children: [
          // 배경 그라디언트
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                stops: [0.2, 0.6],
                colors: [Color(0xFFA2F43D), Color(0xFFD5FF72)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 상단 헤더 (뒤로가기 + 타이틀)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 32),
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${_nickname.isEmpty ? 'OOO' : _nickname} 님을 위한 ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontFamily: 'KoPubDotum Medium',
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -1.30,
                                ),
                              ),
                              const TextSpan(
                                text: '추천 메뉴',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontFamily: 'KoPubDotum Bold',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1.30,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.035),
                        // 추천 메세지 말풍선
                        Container(
                          width: screenWidth * 0.62,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFE940), Color(0xFFFFF0A4)],
                            ),
                          ),
                          child: const Text(
                            '저번주보다 혈당이 더 올랐어요.\n이번주엔 혈당에 부담없는\n메뉴들을 추천해 드릴게요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: "Clipartkorea",
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.43,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.025),

                        // 추천 메뉴 그리드
                        Expanded(child: _buildMenuGrid(screenWidth)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(double screenWidth) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFADF950)),
      );
    }
    if (_errorMessage != null) {
      return Center(child: Text('오류: $_errorMessage'));
    }
    if (_menus.isEmpty) {
      return const Center(child: Text('추천 메뉴 데이터가 없습니다.'));
    }

    // search.dart와 동일한 방식: 카드마다 필요한 높이가 달라서 GridView의 고정
    // childAspectRatio를 쓰면 한 카드가 길어질 때 전체가 늘어나 오버플로우가 난다.
    // 두 장씩 Row로 묶고 IntrinsicHeight로 그 줄 안에서만 높이를 맞춘다.
    final rowCount = (_menus.length / 2).ceil();
    final horizontalPadding = screenWidth * 0.04;
    final gap = screenWidth * 0.04;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        10,
        horizontalPadding,
        18,
      ),
      itemCount: rowCount,
      separatorBuilder: (context, index) => SizedBox(height: gap),
      itemBuilder: (context, rowIndex) {
        final firstIndex = rowIndex * 2;
        final secondIndex = firstIndex + 1;
        final hasSecond = secondIndex < _menus.length;

        Widget buildCard(int index) => MenuGridCard(
              data: _menus[index],
              isLiked: _menus[index]['is_liked'] as bool? ?? false,
              onLikeTap: () => _toggleLike(_menus[index]['id'] as int),
              previewNutrients: _previewNutrients,
            );

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: buildCard(firstIndex)),
              SizedBox(width: gap),
              Expanded(
                child: hasSecond
                    ? buildCard(secondIndex)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}
