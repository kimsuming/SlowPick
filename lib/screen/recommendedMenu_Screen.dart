import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

class RecommendedMenuScreen extends StatefulWidget {
  const RecommendedMenuScreen({super.key});

  @override
  State<RecommendedMenuScreen> createState() => _RecommendedMenuScreenState();
}

class _RecommendedMenuScreenState extends State<RecommendedMenuScreen> {
  @override
  Widget build(BuildContext context) {
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
                begin: Alignment(-0.0, 0.5),
                end: Alignment(1.0, 0.5),
                colors: [Color(0xFFE6EB4E), Color(0xFFADF950)],
              ),
            ),
          ),

          // 상단 UI
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                child: Padding(
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
                  height: MediaQuery.of(context).size.height * 0.75,
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
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      //추천 메세지
                      SizedBox(
                        width:
                            MediaQuery.of(context).size.width *
                            0.5, // 원하는 가로 크기
                        height:
                            MediaQuery.of(context).size.height *
                            0.1, // 원하는 세로 크기
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
                                  fontWeight: FontWeight.bold,
                                  height: 1.43,
                                  letterSpacing: -0.24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 흰박스 상단 여백 조절
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: const DecorationImage(
                              image: AssetImage(
                                "images/comment_menu/Frame 17.png",
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      /*SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(0.50, -0.00),
                              end: Alignment(0.50, 1.00),
                              colors: [Colors.white, const Color(0xFFF4FFE5)],
                            ),
                          ),
                        ),
                      ),*/
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
