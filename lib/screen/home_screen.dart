import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // DB 연동을 위해 추가
import 'package:slowpick/screen/recommendedMenu_Screen.dart';
import 'package:slowpick/screen/search.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  int _currentIndex1 = 0;
  int _currentIndex2 = 0;

  final List<int> _sliderItems = [1, 2, 3, 4, 5];
  // 검색 화면으로 이동하는 헬퍼 함수
  void _navigateToSearch(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // initialQuery
        builder: (context) => SearchScreen(initialQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        child: const SafeArea(top: false, child: BottomBarNew()),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leadingWidth: 180,
        leading: Image.asset(
          "images/SlowPick_logo.png",
          width: 184,
          height: 44,
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              "images/main_icon/bell.png",
              width: 30,
              height: 30,
            ),
            onPressed: null,
          ),
          IconButton(
            icon: Image.asset(
              "images/main_icon/list.png",
              width: 30,
              height: 30,
            ),
            onPressed: null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 첫 번째 배너
              _firstBanner(),

              // 카페 목록
              _cafeCatalog(),

              //추천 메뉴 선택
              _recomendedMenu(),

              const SizedBox(height: 20),

              // 첫번째 슬라이더
              _firstSlider(),

              const SizedBox(height: 17),
              // 검색창 및 메인 컨텐츠
              _menuSearchBar(),

              const SizedBox(height: 30),

              // 추천 문구 (두번쨰 슬라이더 위 문구)
              Padding(
                padding: const EdgeInsets.only(left: 20.0, bottom: 10.0),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "00 님! 이런 건 어떠세요?",
                    style: TextStyle(fontSize: 18, letterSpacing: -1),
                  ),
                ),
              ),

              // 두번째 슬라이더
              _secondSlider(),

              SizedBox(height: 30),

              // 구분선
              const SizedBox(
                width: double.infinity,
                height: 20,
                child: ColoredBox(color: Color(0xFFF6F6F6)),
              ),

              // 메뉴 순위
              _menuRank(),

              // 구분선
              const SizedBox(
                width: double.infinity,
                height: 20,
                child: ColoredBox(color: Color(0xFFF6F6F6)),
              ),

              _informationCard(),

              // 구분선
              const SizedBox(
                width: double.infinity,
                height: 20,
                child: ColoredBox(color: Color(0xFFF6F6F6)),
              ),

              _collaborationCategory(),

              SizedBox(height: 20),

              _secondBanner(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 첫 번째 배너 위젯
  Widget _firstBanner() {
    return Container(height: 75, color: Colors.red);
  }

  // 카페 목록 위젯
  Widget _cafeBtn({Color? color, String? imagePath}) {
    return GestureDetector(
      onTap: () => debugPrint("버튼 클릭"),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7),
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: imagePath == null ? color : null,
          image: imagePath != null
              ? DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover)
              : null,
        ),
      ),
    );
  }

  // 카페 목록 가로 스크롤 위젯
  Widget _cafeCatalog() {
    return SizedBox(
      height: 69,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 12),
            _cafeBtn(color: Colors.green),
            _cafeBtn(color: Colors.yellow),
            _cafeBtn(color: Colors.grey),
            _cafeBtn(color: Colors.amber),
            _cafeBtn(color: Colors.blueGrey),
            _cafeBtn(color: Colors.redAccent),
            _cafeBtn(color: Colors.white),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  // 추천 메뉴 위젯
  Widget _recomendedMenu() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RecommendedMenuScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 140,
        color: Color(0xFFF6F6F6),
        child: Padding(
          padding: const EdgeInsets.all(26.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "환영해요, OO 님!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.24,
                    ),
                  ),
                  Text(
                    "제가 OO 님을 위한 추천메뉴를\n만들어 왔어요. 한번 보시겠어요?",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -1.5, // 글자 간격 조정
                    ),
                  ),
                ],
              ),

              // 화살표 버튼
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF74AE31), // 초록색
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecommendedMenuScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 30,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 첫 번째 슬라이더 위젯
  Widget _firstSlider() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.28,
      child: Stack(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 400.0,
              viewportFraction: 1, //화면 너비 대비 한 슬라이드가 차지하는 비율
              initialPage: 0, //시작 시 보여줄 슬라이드 인덱스
              enableInfiniteScroll: true, //무한 스크롤 여부
              //페이지 변경 시 호출되는 콜백
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex1 = index;
                });
              },
            ),
            items: _sliderItems.map((i) {
              return Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(color: Colors.amber),
                child: Center(
                  child: Text('text $i', style: const TextStyle(fontSize: 16)),
                ),
              );
            }).toList(),
          ),

          Positioned(
            right: 15,
            bottom: 15,
            child: Container(
              width: 67,
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                color: Colors.black.withValues(alpha: 0.49),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '${_currentIndex1 + 1} / ${_sliderItems.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 메뉴 검색 바 위젯
  Widget _menuSearchBar() {
    // 기존 GestureDetector를 StreamBuilder + Autocomplete로 교체
    return SizedBox(
      width: 350,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menus').snapshots(),
        builder: (context, snapshot) {
          // 데이터 로딩 중이거나 에러가 있을 때는 기존 디자인의 껍데기만 보여줌
          if (!snapshot.hasData) {
            return Container(
              height: 35,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  SizedBox(width: 12),
                  Icon(Icons.search, size: 25, color: Colors.grey),
                  SizedBox(width: 8),
                  Text("불러오는 중...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // DB에서 메뉴 이름 리스트 추출
          final List<String> menuNames = snapshot.data!.docs
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['menu_name']
                        as String? ??
                    '',
              )
              .where((name) => name.isNotEmpty)
              .toList();

          // 자동 완성 위젯
          return Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return menuNames.where((String option) {
                return option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            onSelected: (String selection) {
              _navigateToSearch(selection);
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x4C000000),
                          blurRadius: 2,
                          offset: Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    height: 40,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onSubmitted: (value) => _navigateToSearch(value),
                      textAlignVertical:
                          TextAlignVertical.center, // 텍스트 수직 중앙 정렬
                      decoration: InputDecoration(
                        hintText: '원하는 카페 음료를 검색해봐요!',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFEEEEEE),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 25,
                          color: Colors.black54,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        // 테두리 없애고 둥글게 처리
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  );
                },

            // 추천 검색어 목록 디자인
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: 326,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(option),
                          leading: const Icon(
                            Icons.search,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
    // [여기까지 수정됨]
  }

  // 두 번째 슬라이더 위젯
  Widget _secondSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        aspectRatio: 1,
        viewportFraction: 0.5,
        enlargeCenterPage: true, //중앙 슬라이드 확대 여부
        enlargeFactor: 0.2, //확대 비율
      ),
      items: [1, 2, 3, 4, 5].map((i) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: 220, // 🔥 height와 동일
              height: 220,
              margin: EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 2,
                    offset: Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text('text $i', style: TextStyle(fontSize: 16.0)),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  // 메뉴 순위 위젯
  Widget _menuRank() {
    return Column(
      children: [
        SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 10.0),
          child: Container(
            alignment: Alignment.centerLeft,
            child: Text(
              '주간 인기 검색어 TOP3',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -1,
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _rankingItem(130, '[메가커피]', '아사이볼'),

              SizedBox(width: 8),

              _rankingItem(110, '[컴포즈]', '제로 리얼 믹스커피'),

              SizedBox(width: 8),

              _rankingItem(80, '[메가커피]', '윈터 뱅쇼'),
            ],
          ),
        ),
      ],
    );
  }

  // 개별 랭킹 아이템 위젯
  Widget _rankingItem(int boxSize, String cafeName, String menuName) {
    return Column(
      children: [
        Container(
          width: boxSize.toDouble(),
          height: boxSize.toDouble(),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(15),
          ),
        ),

        SizedBox(height: 8),

        Text(
          cafeName,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),

        Text(
          menuName,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  // 정보 카드 위젯
  Widget _informationCard() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 20.0),
          child: Container(
            alignment: Alignment.centerLeft,
            child: Text(
              "우리 이렇게 해봐요!",
              style: TextStyle(fontSize: 16, letterSpacing: -1, height: 1.25),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Container(
            alignment: Alignment.centerLeft,
            child: Text(
              '소중한 내 혈당을 위한 한 걸음',
              style: TextStyle(
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [Color(0xFF39BB4C), Color(0xFF399EEB)],
                  ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                fontSize: 12,
                fontFamily: 'KoPubDotum Light',
                fontWeight: FontWeight.w400,
                height: 1.67,
                letterSpacing: -1,
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 3, left: 10, bottom: 20),
          child: CarouselSlider(
            options: CarouselOptions(
              height: 170,
              enableInfiniteScroll: false,
              viewportFraction: 0.38, //한 슬라이드가 차지하는 화면 비율
              autoPlayCurve: Curves.fastOutSlowIn,
              padEnds: false,
            ),
            items: [1, 2, 3, 4, 5].map((i) {
              return Container(
                width: 130,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: Center(
                  child: Text('text $i', style: TextStyle(fontSize: 16.0)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 콜라보 카테고리 위젯
  Widget _collaborationCategory() {
    return Column(
      children: [
        SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 5.0, top: 10.0),
          child: Container(
            alignment: Alignment.centerLeft,
            child: Text(
              '놓칠 수 없는 카페들의 콜라보 상품!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -1,
              ),
            ),
          ),
        ),

        SizedBox(
          height: MediaQuery.of(context).size.height * 0.26,
          child: Stack(
            children: [
              CarouselSlider(
                carouselController: _carouselController,
                options: CarouselOptions(
                  viewportFraction: 1,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex2 = index;
                    });
                  },
                ),
                items: _sliderItems.map((i) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.green,
                    child: Center(child: Text('text $i')),
                  );
                }).toList(),
              ),

              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.chevron_left, size: 50),
                  color: Colors.white,
                  onPressed: () {
                    _carouselController.animateToPage(
                      _currentIndex2 - 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),

              // 오른쪽 화살표
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.chevron_right, size: 50),
                  color: Colors.white,
                  onPressed: () {
                    _carouselController.animateToPage(
                      _currentIndex2 + 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),

              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_sliderItems.length, (index) {
                    final bool isActive = index == _currentIndex2;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.grey : Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 두 번째 배너 위젯
  Widget _secondBanner() {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 70.0,
            viewportFraction: 1, //화면 너비 대비 한 슬라이드가 차지하는 비율
            initialPage: 0, //시작 시 보여줄 슬라이드 인덱스
            enableInfiniteScroll: true, //무한 스크롤 여부
            //페이지 변경 시 호출되는 콜백
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex1 = index;
              });
            },
          ),
          items: _sliderItems.map((i) {
            return Container(
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(color: Colors.purple),
              child: Center(
                child: Text('text $i', style: const TextStyle(fontSize: 16)),
              ),
            );
          }).toList(),
        ),

        SizedBox(height: 10),

        CarouselSlider(
          options: CarouselOptions(
            height: 70.0,
            viewportFraction: 1, //화면 너비 대비 한 슬라이드가 차지하는 비율
            initialPage: 0, //시작 시 보여줄 슬라이드 인덱스
            enableInfiniteScroll: true, //무한 스크롤 여부
            //페이지 변경 시 호출되는 콜백
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex1 = index;
              });
            },
          ),
          items: _sliderItems.map((i) {
            return Container(
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Center(
                child: Text('text $i', style: const TextStyle(fontSize: 16)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
