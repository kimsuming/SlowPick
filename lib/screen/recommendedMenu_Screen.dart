import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slowpick/widget/menu_cards.dart';
import 'package:slowpick/screen/menu_detail_screen.dart';

class RecommendedMenuScreen extends StatefulWidget {
  const RecommendedMenuScreen({super.key});

  @override
  State<RecommendedMenuScreen> createState() => _RecommendedMenuScreenState();
}

class _RecommendedMenuScreenState extends State<RecommendedMenuScreen> {
  @override
  Widget build(BuildContext context) {
    // 그리드 뷰 비율 계산
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double gridAspectRatio = (screenWidth / 2) / (screenHeight * 0.38);

    return Scaffold(
      bottomNavigationBar: Container(
        color: Color(0xFFFCFCFC), // << 여기 색이 하단까지 채워짐
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
          // 상단 UI
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                child: Padding(
                  padding: const EdgeInsets.only(top: 70, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back, size: 35),
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
                                  fontFamily: 'KoPubDotum Medium',
                                  fontWeight: FontWeight.w400,
                                  height: 0.91,
                                  letterSpacing: -1.30,
                                ),
                              ),
                              TextSpan(
                                text: '추천 메뉴',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontFamily: 'KoPubDotum Bold',
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
                ),
              ),

              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width * 1,
                  height: MediaQuery.of(context).size.height * 0.8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 흰박스 상단 여백 조절
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.04,
                      ),
                      //추천 메세지
                      SizedBox(
                        width:
                            MediaQuery.of(context).size.width *
                            0.54, // 원하는 가로 크기
                        height:
                            MediaQuery.of(context).size.height *
                            0.11, // 원하는 세로 크기
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
                          ),
                        ),
                      ),
                      // 흰박스 상단 여백 조절
                      SizedBox(height: screenHeight * 0.03),

                      // === 저당 메뉴 6개 ===
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          // nutrition.sugar_g 기준으로 오름차순 정렬 후 6개 제한
                          stream: FirebaseFirestore.instance
                              .collection('menus')
                              .orderBy('nutrition.sugar_g', descending: false)
                              .limit(6)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFADF950),
                                ),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text('추천 메뉴 데이터가 없습니다.'),
                              );
                            }

                            final docs = snapshot.data!.docs;

                            return GridView.builder(
                              padding: EdgeInsets.fromLTRB(
                                screenWidth * 0.04,
                                0,
                                screenWidth * 0.04,
                                20, // 하단 여백
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: gridAspectRatio,
                                    crossAxisSpacing: screenWidth * 0.04,
                                    mainAxisSpacing: screenWidth * 0.04,
                                  ),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;

                                // 카드 클릭 시 상세 페이지 이동
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MenuDetailScreen(data: data),
                                      ),
                                    );
                                  },
                                  child: MenuGridCard(data: data),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
