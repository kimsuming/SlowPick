import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // DB 연동을 위해 추가
import 'package:slowpick/screen/recommendedMenu_Screen.dart';
import 'package:slowpick/screen/search.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

      // 검색창 및 메인 컨텐츠
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 35),

              // 기존 GestureDetector를 StreamBuilder + Autocomplete로 교체
              SizedBox(
                width: 326,
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
                        .map((doc) => (doc.data() as Map<String, dynamic>)['menu_name'] as String? ?? '')
                        .where((name) => name.isNotEmpty)
                        .toList();

                    // 자동 완성 위젯
                    return Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return menuNames.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        _navigateToSearch(selection);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return SizedBox(
                          height: 45,
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onSubmitted: (value) => _navigateToSearch(value),
                            textAlignVertical: TextAlignVertical.center, // 텍스트 수직 중앙 정렬
                            decoration: InputDecoration(
                              hintText: '메뉴를 검색해보세요!',
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFFEEEEEE),
                              prefixIcon: const Icon(Icons.search, size: 25, color: Colors.black54),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                                    leading: const Icon(Icons.search, size: 18, color: Colors.grey),
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
              ),
              // [여기까지 수정됨]

              // 거북이 말하는 거
              SizedBox(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecommendedMenuScreen(),
                        ),
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.1,
                        child: Row(
                          children: [
                            Container(
                              width: 101,
                              height: 113,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage("images/home/mainTurtle.png"),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: MediaQuery.of(context).size.height * 0.06,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage("images/home/Vector.png"),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 25, right: 10),
                                child: Text(
                                  '오늘도 느리게, 슬로우픽과 \n함께해요!',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontFamily: 'NEXON Lv1 Gothic',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 메인 상단 이미지
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.height * 0.25,
                      child: Container(
                        width: 368,
                        height: 519,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          image: const DecorationImage(
                            image: AssetImage("images/home/mainImage.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              color: Colors.white,
                              iconSize: 40,
                              onPressed: () {
                                debugPrint("눌림!");
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              color: Colors.white,
                              iconSize: 40,
                              onPressed: () {
                                debugPrint("눌림!");
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 카페 목록
              SizedBox(
                width: 422,
                height: 69,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0.50, 0.00),
                      end: Alignment(0.50, 1.00),
                      colors: [Colors.white, Color(0xFFE1F0CE)],
                    ),
                  ),
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
                ),
              ),
              const SizedBox(height: 16),

              // 예시이미지
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.32,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage("images/home/exam.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // 예시이미지2
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecommendedMenuScreen(),
                  ),
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 1.0,
                  height: MediaQuery.of(context).size.height * 0.32,
                  child: Container(
                    height: 243,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: AssetImage("images/home/exam2.png"),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cafeBtn({Color? color, String? imagePath}) {
    return GestureDetector(
      onTap: () => debugPrint("버튼 클릭"),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 50,
        height: 50,
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
}