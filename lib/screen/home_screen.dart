import 'package:flutter/material.dart';
import 'package:slowpick/screen/recommendedMenu_Screen.dart';
import 'package:slowpick/screen/search.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Home();
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        color: Color(0xFFFCFCFC), // << 여기 색이 하단까지 채워짐
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leadingWidth: 200,
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

      //검색창
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 35),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SearchScreen()),
                  );
                },
                child: SizedBox(
                  width: 326,
                  height: 35,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 25), // 검색 아이콘
                        SizedBox(width: 8),

                        /*Icon(Icons.mic, size: 20), // 음성 아이콘*/
                      ],
                    ),
                  ),
                ),
              ),

              //거북이 말하는 거
              SizedBox(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecommendedMenuScreen(),
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
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                    "images/home/mainTurtle.png",
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: MediaQuery.of(context).size.height * 0.06,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage("images/home/Vector.png"),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 25,
                                  right: 10,
                                ),
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

                    //메인 상단 이미지
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.height * 0.25,
                      child: Container(
                        width: 368,
                        height: 519,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          image: DecorationImage(
                            image: AssetImage("images/home/mainImage.png"),
                            fit: BoxFit.cover,
                          ),
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left),
                              color: Colors.white,
                              iconSize: 40,
                              onPressed: () {
                                print("눌림!");
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right),
                              color: Colors.white,
                              iconSize: 40,
                              onPressed: () {
                                print("눌림!");
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              //카페 목록
              SizedBox(
                width: 422,
                height: 69,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
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
                        const SizedBox(width: 12), // 좌측 여백
                        _cafeBtn(color: Colors.green),
                        _cafeBtn(color: Colors.yellow),
                        _cafeBtn(color: Colors.grey),
                        _cafeBtn(color: Colors.amber),
                        _cafeBtn(color: Colors.blueGrey),
                        _cafeBtn(color: Colors.redAccent),
                        _cafeBtn(color: Colors.white),

                        const SizedBox(width: 12), // 우측 여백
                      ],
                    ),
                  ),
                ),
              ),

              /* //사용자 질문
              SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 16),
                    Container(
                      alignment: Alignment.center,
                      width: 192,
                      height: 37,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("images/home/littleVector.png"),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 25, right: 10),
                        child: Text(
                          '00 님! 이런 건 어떠세요?',
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
              ), */
              SizedBox(height: 16),

              //예시이미지
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.32,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage("images/home/exam.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              //예시이미지2
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecommendedMenuScreen(),
                  ),
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 1.0,
                  height: MediaQuery.of(context).size.height * 0.32,
                  child: Container(
                    height: 243,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
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
}

Widget _cafeBtn({Color? color, String? imagePath}) {
  return GestureDetector(
    onTap: () => print("버튼 클릭"),
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: imagePath == null ? color : null, // 이미지 없으면 색 사용
        image: imagePath != null
            ? DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover)
            : null,
      ),
    ),
  );
}
