import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/screen/home_screen.dart';

class LikedmenuScreen extends StatefulWidget {
  const LikedmenuScreen({super.key});

  @override
  State<LikedmenuScreen> createState() => _LikedmenuScreenState();
}

class _LikedmenuScreenState extends State<LikedmenuScreen> {
  bool isCategoryView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //바텀 바
      bottomNavigationBar: Container(
        color: Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Color(0xFF808080),
            size: 40,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
        title: const Text('찜'),
        centerTitle: true,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w500,
          fontFamily: 'KoPubDotum',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF808080), size: 30),
            onPressed: () {},
          ),
        ],
      ),

      // 본문
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

  // 카테고리 필터 위젯
  Widget _categoryFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5), // 배경 색상
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 전체 보기 버튼
            GestureDetector(
              onTap: () {
                setState(() {
                  isCategoryView = false;
                });
              },
              child: Container(
                width: 150,
                height: 50,
                decoration: BoxDecoration(
                  color: !isCategoryView ? Colors.white : Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '전체',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),

            SizedBox(width: 8),

            // 카테고리별 보기 버튼
            GestureDetector(
              onTap: () {
                setState(() {
                  isCategoryView = true;
                });
              },
              child: Container(
                width: 150,
                height: 50,
                decoration: BoxDecoration(
                  color: isCategoryView ? Colors.white : Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '카페별 보기',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 화면 전환 위젯
  Widget _contentArea() {
    if (isCategoryView) {
      return _categoryListView(); // 오른쪽 화면
    } else {
      return _likedMenuGrid(); // 왼쪽 화면
    }
  }

  // 찜한 메뉴 그리드 화면
  Widget _likedMenuGrid() {
    return Column(
      children: [
        _menuNumber(),
        Container(height: 700, color: Colors.amber),
      ],
    );
  }

  // 찜한 메뉴 개수 표시 위젯
  Widget _menuNumber() {
    return Container(
      padding: const EdgeInsets.only(left: 20.0, bottom: 10.0, top: 20.0),
      alignment: Alignment.centerLeft,
      child: Text(
        "총 n개",
        style: TextStyle(
          color: const Color(0xFFB7B7B7),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.25,
          letterSpacing: -1,
        ),
      ),
    );
  }

  // 카페별 보기 화면
  Widget _categoryListView() {
    final List<Map<String, dynamic>> cafes = [
      {'color': Colors.green, 'title': '메가커피'},
      {'color': Colors.indigo, 'title': '컴포즈'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
      {'color': Colors.orange, 'title': '이디야'},
    ];

    return Column(
      children: [
        _gridbutton(),

        GridView.builder(
          padding: const EdgeInsets.only(
            left: 10,
            right: 10,
            bottom: 10,
            top: 0,
          ),
          shrinkWrap: true,
<<<<<<< HEAD
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cafes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 5,
            mainAxisSpacing: 9,
            childAspectRatio: 3,
          ),
          itemBuilder: (context, index) {
            final cafe = cafes[index];

            return _gridItem(color: cafe['color'], cafeTitle: cafe['title']);
          },
=======
          physics: NeverScrollableScrollPhysics(),
          children: [
            _gridItem(imagePath: 'images/brand_logo/logo_starbucks.png', cafeTitle: '스타벅스'),
            _gridItem(imagePath: 'images/brand_logo/logo_mega.png', cafeTitle: '메가커피'),
            _gridItem(imagePath: 'images/brand_logo/logo_compose.jpg', cafeTitle: '컴포즈'),
            _gridItem(imagePath: 'images/brand_logo/logo_ediya.jpg', cafeTitle: '이디야'),
            _gridItem(imagePath: 'images/brand_logo/logo_paik.png', cafeTitle: '빽다방'),
            _gridItem(imagePath: 'images/brand_logo/logo_twosome.png', cafeTitle: '투썸플레이스'),
            _gridItem(imagePath: 'images/brand_logo/logo_angel.png', cafeTitle: '앤제리너스'),
            _gridItem(imagePath: 'images/brand_logo/logo_mammoth.png', cafeTitle: '매머드커피'),
            _gridItem(imagePath: 'images/brand_logo/logo_paul.png', cafeTitle: '폴 바셋'),
            _gridItem(imagePath: 'images/brand_logo/logo_theventi.png', cafeTitle: '더벤티'),
            _gridItem(imagePath: 'images/brand_logo/logo_yoger.png', cafeTitle: '요거프레소'),
          ],
>>>>>>> 17234d5c744973b72a6de7531713de0848957360
        ),
      ],
    );
  }

  // 그리드 버튼 위젯
  Widget _gridbutton() {
    return Container(
      padding: const EdgeInsets.only(right: 10.0),
      alignment: Alignment.centerRight,
      child: IconButton(
        icon: const Icon(Icons.drag_handle, color: Color(0xFF909090), size: 40),
        onPressed: () {},
      ),
    );
  }

  Widget _gridItem({Color? color, String? imagePath, String? cafeTitle}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFE2E2E2), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 10),

              // 원형 이미지 또는 색상 박스
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFE2E2E2), width: 1.5),
                  color: imagePath == null ? color : null,
                  image: imagePath != null
                      ? DecorationImage(
                          image: AssetImage(imagePath),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              SizedBox(width: 5),

              // 카페 이름
              SizedBox(
                width: 75,
                child: Text(
                  cafeTitle ?? '',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          //기본 패딩값이 너무 커서 나중에 이미지로 변경해야할 필요가 있음
          // 화살표 아이콘
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              color: Color(0xFFE3E3E3),
              size: 30,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
