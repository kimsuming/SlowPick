import 'package:flutter/material.dart';
import 'package:slowpick/screen/bloodSugarNote.dart';
import 'package:slowpick/screen/dietNote.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:percent_indicator/percent_indicator.dart';

class mainNote extends StatefulWidget {
  const mainNote({super.key});

  @override
  State<mainNote> createState() => _mainNoteState();
}

class _mainNoteState extends State<mainNote> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: Container(
        //바텀 바
        color: Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const mainNote()),
          );
        },
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFFFFFFFF),
        child: Image.asset(
          'images/bloodSugarNote/filepen.png', // 펜 사진
          fit: BoxFit.contain,
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.50, 1.00),
                end: Alignment(0.50, 0.00),
                colors: [const Color(0xFFF7FFE5), Colors.white],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //혈당표시
                _bloodSugarNote(),

                //다이어트 표시
                _dietNote(),

                //나의 노트
                _myNote(),

                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bloodSugarNote() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              '거부기의 혈당노트',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.30,
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //혈당노트 모양 구현
              Container(
                width: screenWidth * 0.43,
                height: screenHeight * 0.23,
                decoration: BoxDecoration(
                  color: Color(0xFFB6ED74),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(11.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'images/bloodSugarNote/sugarNoteTurtle.png', // 거북이 사진
                        width: screenWidth * 0.3,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 6),

              //혈당 정보 칸
              Container(
                width: screenWidth * 0.43,
                height: screenHeight * 0.23,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      //오늘의 혈당 & 평균 혈당
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //오늘의 혈당 제목
                          Text(
                            '오늘의 혈당',
                            style: TextStyle(
                              color: const Color(0xFF9A9A9A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.36,
                            ),
                          ),

                          //오늘 혈당 정보
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '175',
                                  style: TextStyle(
                                    color: const Color(0xFF99000F),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.96,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.96,
                                  ),
                                ),
                                TextSpan(
                                  text: 'mg/dL',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.84,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          //평균 혈당 제목
                          Text(
                            '평균 혈당',
                            style: TextStyle(
                              color: const Color(0xFF9A9A9A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.36,
                            ),
                          ),

                          //평균 혈당 내용
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '168',
                                  style: TextStyle(
                                    color: const Color(0xFF187100),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.96,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.96,
                                  ),
                                ),
                                TextSpan(
                                  text: 'mg/dL',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.84,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      //혈당 점수
                      Column(
                        children: [
                          LinearPercentIndicator(
                            lineHeight: 19.0,
                            percent: 0.52,
                            backgroundColor: Color(0xFFDFFF94),
                            progressColor: Color(0xFF62F431),
                            barRadius: Radius.circular(10),
                            animation: true,
                            animationDuration: 800,
                            animateFromLastPercent: true,
                          ),

                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '나의 혈당 점수: ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.36,
                                  ),
                                ),
                                TextSpan(
                                  text: '52',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.60,
                                  ),
                                ),
                                TextSpan(
                                  text: ' 점',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.36,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _dietNote() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              '느린거북 다이어트',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.30,
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //혈당노트 모양 구현
              Container(
                width: screenWidth * 0.43,
                height: screenHeight * 0.23,
                decoration: BoxDecoration(
                  color: Color(0xFFF8E76C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(11.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'images/bloodSugarNote/sugarNoteTurtle.png', // 거북이 사진
                        width: screenWidth * 0.3,
                        fit: BoxFit.contain,
                        color: Color(0xFFF6F6C5),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 6),

              //혈당 정보 칸
              Container(
                width: screenWidth * 0.43,
                height: screenHeight * 0.23,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //오늘의 몸무게 & BMI
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //오늘의 몸무게 제목
                          Text(
                            '오늘의 몸무게',
                            style: TextStyle(
                              color: const Color(0xFF9A9A9A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.36,
                            ),
                          ),

                          //오늘 몸무게 정보
                          Text(
                            '72kg',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.96,
                            ),
                          ),

                          //BMU 제목
                          Text(
                            '오늘의 BMI 수치',
                            style: TextStyle(
                              color: const Color(0xFF9A9A9A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.36,
                            ),
                          ),

                          //BMI 내용
                          Text(
                            '27.34',
                            style: TextStyle(
                              color: const Color(0xFF99000F),
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.96,
                            ),
                          ),
                        ],
                      ),

                      //혈당 점수
                      Column(
                        children: [
                          LinearPercentIndicator(
                            lineHeight: 19.0,
                            percent: 0.5,
                            backgroundColor: Color(0xFFFFE494),
                            progressColor: Color(0xFFF4AF31),
                            barRadius: Radius.circular(10),
                            animation: true,
                            animationDuration: 800,
                            animateFromLastPercent: true,
                          ),

                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '나의 다이어트 점수: ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.36,
                                  ),
                                ),
                                TextSpan(
                                  text: '50',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.60,
                                  ),
                                ),
                                TextSpan(
                                  text: ' 점',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.36,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _myNote() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 13.0),
                  child: Text(
                    '나의 노트',
                    style: TextStyle(
                      color: const Color(0xFF242526),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -1,
                    ),
                  ),
                ),

                Row(
                  children: [
                    Image.asset(
                      'images/bloodSugarNote/icon-park-outline_sort-one.png', // 오름차순 정렬 아이콘
                      fit: BoxFit.cover,
                    ),

                    Text(
                      '최신 순',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFA9B38D),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 13),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 0.87,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BloodSugarNote(),
                    ),
                  ),
                  child: _managementNotes('혈당관리 노트'),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DietNote()),
                  ),
                  child: _managementNotes('느린거북 다이어트'),
                ),
                _managementNotes('운동 기록'),
                _managementNotes('식단 기록'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _managementNotes(String title) {
    return Container(
      child: Column(
        children: [
          Image.asset('images/bloodSugarNote/note.png', fit: BoxFit.cover),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF242526),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.20,
            ),
          ),
        ],
      ),
    );
  }
}
