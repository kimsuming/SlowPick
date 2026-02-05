import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slowpick/widget/menu_cards.dart';

class RecommendedMenuScreen extends StatefulWidget {
  final String? initialQuery;

  const RecommendedMenuScreen({super.key, this.initialQuery});

  @override
  State<RecommendedMenuScreen> createState() => _RecommendedMenuScreenState();
}

class _RecommendedMenuScreenState extends State<RecommendedMenuScreen> {
  final bool _isGridView = true;
  late TextEditingController _searchController;
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    String initialText = widget.initialQuery ?? "";
    _searchController = TextEditingController(text: initialText);
    _searchText = initialText;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        color: Color(0xFFFCFCFC), // << 여기 색이 하단까지 채워짐
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.0, 0.5),
            end: Alignment(1.0, 0.5),
            colors: [Color(0xFFE6EB4E), Color(0xFFADF950)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _appTopBar(),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0.50, -0.00),
                    end: Alignment(0.50, 1.00),
                    colors: [Colors.white, Color(0xFFF4FFE5)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Column(
                  children: [
                    // 흰박스 상단 여백 조절
                    SizedBox(height: 40),

                    //추천 메세지
                    _recommendedMessage(),

                    // 흰박스 상단 여백 조절
                    SizedBox(height: 30),

                    _recommendedMenus(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, size: 40),
          ),

          SizedBox(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'OOO 님을 위한 ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      height: 0.91,
                      letterSpacing: -1.30,
                    ),
                  ),
                  TextSpan(
                    text: '추천 메뉴',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 0.91,
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
    );
  }

  Widget _recommendedMessage() {
    return SizedBox(
      width: 207, // 원하는 가로 크기
      height: 87, // 원하는 세로 크기
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), // 네 방향 라운드
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE940), Color(0xFFFFF0A4)],
          ),
        ),
        child: SizedBox(
          child: Center(
            child: Text(
              '저번주보다 혈당이 더 올랐어요.\n이번주엔 혈당에 부담없는\n메뉴들을 추천해드릴게요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.43,
                letterSpacing: -0.24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _recommendedMenus() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double gridAspectRatio = (screenWidth / 2) / (screenHeight * 0.38);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('menus').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data!.docs;

        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['menu_name'] as String? ?? '';
          if (_searchText.isEmpty) return true;
          return name.toLowerCase().contains(_searchText.toLowerCase());
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(child: Text('\'$_searchText\' 검색 결과가 없습니다.'));
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            screenWidth * 0.04,
            0,
            screenWidth * 0.04,
            16,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: gridAspectRatio,
            crossAxisSpacing: screenWidth * 0.04,
            mainAxisSpacing: screenWidth * 0.04,
          ),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index].data() as Map<String, dynamic>;
            return MenuGridCard(data: data);
          },
        );
      },
    );
  }

  Widget _recommendedMenusItem({
    Color? color,
    String? imagePath,
    String? cafeTitle,
    String? menuTitle,
    double? sugarLevels,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 10),

            // 원형 이미지 또는 색상 박스
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 3,
                    offset: Offset(0, 3),
                    spreadRadius: 0,
                  ),
                ],
                color: imagePath == null ? color : null,
                image: imagePath != null
                    ? DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            SizedBox(height: 5),

            // 카페 이름
            Text(
              '[$cafeTitle]',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.24,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            //메뉴 이름
            Text(
              menuTitle ?? '',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.24,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            //당 수치
            Container(
              width: 51,
              height: 25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: getSugarColor(sugarLevels),
                image: imagePath != null
                    ? DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Text(
                '당 $sugarLevels g',
                style: TextStyle(
                  color: Color(0xFF029F00),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.54,
                  letterSpacing: -0.24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color getSugarColor(double? sugarLevels) {
    if (sugarLevels == null) return Colors.red;

    if (sugarLevels < 10) {
      return const Color(0xFFE9FFD9);
    } else if (sugarLevels < 15) {
      return const Color(0xFFFFF8D1);
    } else {
      return const Color(0xFFFFDDDD);
    }
  }
}
