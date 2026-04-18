import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; //이미지 캐싱 패키지
import 'package:cloud_firestore/cloud_firestore.dart'; // DB 연동을 위해 추가
import 'package:slowpick/screen/recommendedMenu_Screen.dart';
import 'package:slowpick/screen/search.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  List<String> _firstSliderUrls = [];
  late StreamSubscription _firstSliderSub;
  int _currentIndex1 = 0;
  int _currentIndex2 = 0;

  List<String> _secondSliderUrls = [];
  late StreamSubscription _secondSliderSub;

  @override
  void initState() {
    super.initState();

    _firstSliderSub = FirebaseFirestore.instance
        .collection('banners')
        .snapshots()
        .listen((snapshot) {
          final docs =
              snapshot.docs
                  .where((doc) => doc.id.startsWith("firstSlider_"))
                  .toList()
                ..sort((a, b) => a.id.compareTo(b.id));

          final newUrls = docs
              .map((doc) {
                final data = doc.data();
                return data['imgURL'] as String? ?? '';
              })
              .where((url) => url.isNotEmpty)
              .toList();

          if (_firstSliderUrls.toString() != newUrls.toString()) {
            setState(() {
              _firstSliderUrls = newUrls;
            });
          }
        });

    _secondSliderSub = FirebaseFirestore.instance
        .collection('banners')
        .snapshots()
        .listen((snapshot) {
          final docs =
              snapshot.docs
                  .where((doc) => doc.id.startsWith("seasonSlider_"))
                  .toList()
                ..sort((a, b) => a.id.compareTo(b.id));

          final newUrls = docs
              .map((doc) {
                final data = doc.data();
                return data['imgURL'] as String? ?? '';
              })
              .where((url) => url.isNotEmpty)
              .toList();

          if (_secondSliderUrls.toString() != newUrls.toString()) {
            setState(() {
              _secondSliderUrls = newUrls;
            });
          }
        });
  }


  @override
  void dispose() {
    _firstSliderSub.cancel();
    _secondSliderSub.cancel();
    super.dispose();
  }

  final List<int> _sliderItems = [1, 2, 3, 4, 5];
  // 검색 화면으로 이동하는 헬퍼 함수
  void _navigateToSearch({String? query, String? brand}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          initialQuery: query,
          initialBrand: brand, // 브랜드 정보 전달
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
              const SizedBox(height: 10),

              // 첫 번째 배너
              _firstBanner(),
              const SizedBox(height: 17),

              // 카페 목록
              _cafeCatalog(),

              const SizedBox(height: 25),

              // 검색창 및 메인 컨텐츠
              _menuSearchBar(size),

              const SizedBox(height: 34),

              _aiRecomendedMenu(size),

              const SizedBox(height: 14),

              _recomendedMenu(size),

              const SizedBox(height: 30),

              // 추천 문구 (두번쨰 슬라이더 위 문구)
              Padding(
                padding: const EdgeInsets.only(left: 20.0, bottom: 10.0),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '00 님을 위한 시즌 한정 메뉴!',
                    style: TextStyle(
                      color: const Color(0xFF242526),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),

              // 두번째 슬라이더
              _secondSlider(),

              SizedBox(height: 36),

              // 첫번째 슬라이더
              _firstSlider(),

              SizedBox(height: 28),

              // 메뉴 순위
              _menuRank(),

              // 구분선
              const SizedBox(
                width: double.infinity,
                height: 7,
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
    return SizedBox(
      height: 80,
      width: double.infinity, // 가로 꽉 채우기
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('banners').snapshots(),
        builder: (context, snapshot) {
          // 1. 로딩 중일 때 (회색 박스)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(color: Colors.grey[200]);
          }

          // 2. 데이터가 없을 때
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Container(color: Colors.grey[300]);
          }

          // 3. "firstBanner"로 시작하는 문서 찾기
          QueryDocumentSnapshot? targetDoc;
          try {
            targetDoc = snapshot.data!.docs.firstWhere((doc) {
              return doc.id.startsWith("firstBanner");
            });
          } catch (e) {
            // 조건에 맞는 문서가 하나도 없으면 여기로 옴
            targetDoc = null;
          }

          // 문서가 없거나 이미지 URL이 없으면 빈 박스 보여주기
          if (targetDoc == null) {
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: Text(
                  "배너 준비 중",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            );
          }

          final data = targetDoc.data() as Map<String, dynamic>;
          final imageUrl = data['imgURL'] as String? ?? '';

          if (imageUrl.isEmpty) {
            return Container(color: Colors.grey[300]);
          }

          // 4. 이미지 표시 (캐싱 적용)
          return CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover, // 박스 크기에 맞춰 꽉 채우기 (비율 유지)
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  // 카페 목록 위젯
  Widget _cafeBtn({
    Color? color,
    String? imagePath,
    required String brandName, // [필수] 클릭 시 전달할 브랜드 이름
  }) {
    return GestureDetector(
      onTap: () {
        // 해당 브랜드를 선택한 상태로 검색 화면 이동
        _navigateToSearch(brand: brandName);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 55,
        height: 55,
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
      height: 55,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 12),
            // brandName은 search.dart의 _brandList에 있는 이름과 같아야 함
            _cafeBtn(
              imagePath: 'images/brand_logo/logo_starbucks.png',
              brandName: '스타벅스',
            ),
            _cafeBtn(
              imagePath: 'images/brand_logo/logo_mega.png',
              brandName: '메가MGC커피',
            ),
            _cafeBtn(
              imagePath: 'images/brand_logo/logo_compose.jpg',
              brandName: '컴포즈커피',
            ),
            _cafeBtn(
              imagePath: 'images/brand_logo/logo_ediya.jpg',
              brandName: '이디야커피',
            ),
            _cafeBtn(
              imagePath: 'images/brand_logo/logo_paik.png',
              brandName: '빽다방',
            ),
            _cafeBtn(
              imagePath: 'images/brand_logo/logo_twosome.png',
              brandName: '투썸플레이스',
            ),
            _cafeBtn(
              imagePath: 'images/brand_logo/logo_angel.png',
              brandName: '엔제리너스',
            ),
            _cafeBtn(
              imagePath: 'images/brand_logo/logo_mammoth.png',
              brandName: '매머드커피',
            ),
            _cafeBtn(
              imagePath: 'images/brand_logo/logo_paul.png',
              brandName: '폴 바셋',
            ),
            _cafeBtn(
              imagePath: 'images/brand_logo/logo_theventi.png',
              brandName: '더벤티',
            ),
            _cafeBtn(
              imagePath: 'images/brand_logo/logo_yoger.png',
              brandName: '요거프레소',
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  // AI 추천 메뉴 위젯
  Widget _aiRecomendedMenu(Size size) {
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
        width: size.width * 0.9,
        height: 126,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.00, 0.50),
            end: Alignment(1.00, 0.50),
            colors: [Colors.white, const Color(0xFFF1FFDA)],
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

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('images/home/aiIcon.png', fit: BoxFit.cover),

                  SizedBox(width: 7),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OO 님을 위한 메뉴 추천 !',
                        style: TextStyle(
                          color: const Color(0xFF242526),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -1,
                        ),
                      ),

                      Text(
                        '제가 OO 님을 위한 추천메뉴를\n만들어 왔어요. 한번 보시겠어요?',
                        style: TextStyle(
                          color: const Color(0xFF777777),
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
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

  // 추천 메뉴 위젯
  Widget _recomendedMenu(Size size) {
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
        width: size.width * 0.9,
        height: 82,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.00, 0.50),
            end: Alignment(1.00, 0.50),
            colors: [Colors.white, const Color(0xFFEBFFF8)],
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

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('images/home/recommendIcon.png', fit: BoxFit.cover),

              SizedBox(width: 7),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '고혈당이 3일 이상 지속되고 있어요.',
                    style: TextStyle(
                      color: const Color(0xFF242526),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1,
                    ),
                  ),

                  Text(
                    '오늘은 꼭 30분 이상 걸으세요!',
                    style: TextStyle(
                      color: const Color(0xFF242526),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 첫 번째 슬라이더 위젯
  Widget _firstSlider() {
    final double sliderHeight = MediaQuery.of(context).size.height * 0.28;

    if (_firstSliderUrls.isEmpty) {
      return SizedBox(
        height: sliderHeight,
        child: Container(
          color: Colors.grey[300],
          child: const Center(child: Text("배너가 없습니다.")),
        ),
      );
    }

    return SizedBox(
      height: sliderHeight,
      child: Stack(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: sliderHeight,
              viewportFraction: 1,
              enableInfiniteScroll: _firstSliderUrls.length > 1,
              autoPlay: _firstSliderUrls.length > 1,
              autoPlayInterval: const Duration(seconds: 5),
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex1 = index;
                });
              },
            ),
            items: _firstSliderUrls.map((url) {
              return SizedBox(
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
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
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                color: Colors.black.withOpacity(0.49),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '${_currentIndex1 + 1} / ${_firstSliderUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 메뉴 검색 바 위젯
  Widget _menuSearchBar(Size size) {
    return SizedBox(
      width: size.width * 0.9,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menus').snapshots(),
        builder: (context, snapshot) {
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

          final List<String> menuNames = snapshot.data!.docs
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['menu_name']
                        as String? ??
                    '',
              )
              .where((name) => name.isNotEmpty)
              .toList();

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
              _navigateToSearch(query: selection);
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  return SizedBox(
                    height: 50,

                    //텍스트필드 스타일링
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onSubmitted: (value) => _navigateToSearch(query: value),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: '원하는 카페 음료를 검색해봐요!',
                        hintStyle: const TextStyle(
                          color: Color(0xFFCFDACA),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.24,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 25,
                          color: Color(0xFF74AE31),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFF7BF15B), // 테두리 색
                            width: 2, // 테두리 두께
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Color(0xFF7BF15B), // 테두리 색
                            width: 2, // 테두리 두께
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
  }

  // 두 번째 슬라이더 위젯
  Widget _secondSlider() {
    if (_secondSliderUrls.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        aspectRatio: 1,
        viewportFraction: 0.5,
        enlargeCenterPage: true,
        enlargeFactor: 0.2,
      ),
      items: _secondSliderUrls.map((url) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: 250,
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 2,
                    offset: Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 40),
                    );
                  },
                ),
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
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '주간 인기 검색어 TOP3',
                style: TextStyle(
                  color: const Color(0xFF242526),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -1,
                ),
              ),

              SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _rankingItem(140, '[메가커피]', '아사이볼'),

                  SizedBox(width: 8),

                  _rankingItem(120, '[컴포즈]', '제로 리얼 믹스커피'),

                  SizedBox(width: 8),

                  _rankingItem(90, '[메가커피]', '윈터 뱅쇼'),
                ],
              ),
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
              height: 177,
              enableInfiniteScroll: false,
              viewportFraction: 0.38,
              autoPlayCurve: Curves.fastOutSlowIn,
              padEnds: false,
            ),
            items: [1, 2, 3, 4, 5].map((i) {
              return Container(
                width: 125,
                height: 177,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 0.70,
                      color: Color(0xFFCCCCCC),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 1,
                      child: Container(
                        width: 125,
                        height: 87,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(color: Colors.white),
                        child: Stack(
                          children: [
                            Positioned(
                              left: -22,
                              top: -14,
                              child: Opacity(
                                opacity: 0.90,
                                child: Container(
                                  width: 150,
                                  height: 100,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        "https://placehold.co/150x100",
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 9,
                      top: 150,
                      child: Container(
                        width: 53,
                        height: 11,
                        clipBehavior: Clip.antiAlias,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFF8E76C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      top: 94,
                      child: Container(
                        width: 111,
                        height: 18,
                        clipBehavior: Clip.antiAlias,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFDDDDDD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 14,
                      top: 93,
                      child: Text(
                        '공복에 단 음료는 안돼요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF242526),
                          fontSize: 11,
                          fontFamily: 'KoPubDotum Bold',
                          fontWeight: FontWeight.w400,
                          height: 1.82,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 10,
                      top: 116,
                      child: Text(
                        '공복이나 식사 직후에는\n혈당이 급격히 오르기 쉬워요.\n식후 30분 이후가 가장 좋아요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF242526),
                          fontSize: 10,
                          fontFamily: 'KoPubDotum Light',
                          fontWeight: FontWeight.w400,
                          height: 1.60,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ],
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
