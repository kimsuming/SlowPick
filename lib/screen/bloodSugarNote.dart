import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/screen/bloodSugarRecord.dart';
import 'package:slowpick/screen/mainNote.dart';

class BloodSugarNote extends StatefulWidget {
  const BloodSugarNote({super.key});

  @override
  State<BloodSugarNote> createState() => _BloodSugarNoteState();
}

class _BloodSugarNoteState extends State<BloodSugarNote> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: Container(
        //바텀 바
        color: Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                _noteTitle(),

                Container(height: 1, color: const Color(0xFFEDEDED)),

                SizedBox(height: 13),

                _bloodSugarGraph(),
                _todayBloodSugarContent(size),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 노트 제목 위젯
  Widget _noteTitle() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.only(top: 22, left: 15.0, bottom: 15.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const mainNote()),
              ),
              child: Icon(Icons.arrow_back),
            ),

            SizedBox(width: 8),

            Text(
              '거부기의 혈당 노트',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF242526),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.24,
              ),
            ),

            SizedBox(width: 3),

            Icon(Icons.edit, color: Color(0xFF197100)),
          ],
        ),
      ),
    );
  }

  // 혈당 그래프 위젯
  Widget _bloodSugarGraph() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _todayBloodSugarContent(Size size) {
    return Container(
      child: Column(
        children: [
          // 날짜 선택 위젯
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_left),
              Text(
                '2026년 01월 10일',
                style: TextStyle(
                  color: const Color(0xFF242526),
                  fontFamily: 'KoPubDotum Medium',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.arrow_right),
            ],
          ),

          SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_highestBloodSugar(size), _lowestBloodSugar(size)],
          ),

          SizedBox(height: 27),

          //기록 추가하기 버튼
          Container(
            width: size.width * 0.6,
            height: 52,
            decoration: BoxDecoration(
              color: Color(0xFFB7EE74),
              borderRadius: BorderRadius.circular(10),
            ),

            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BloodSugarRecord(),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 30),
                  Text(
                    '기록 추가하기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.57,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 21),

          _timeData(size, '저녁 식전 19:38', 175),
          _timeData(size, '점심 식후 13:20', 171),
          _timeData(size, '아침 식후 10:10', 163),
          _timeData(size, '아침 식전 09:12', 169),
        ],
      ),
    );
  }

  //최고 혈당 윗젯
  Widget _highestBloodSugar(size) {
    return Container(
      width: size.width * 0.4,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 7,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //최고 혈당 제목
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/bloodSugarNote/bloodDrop.png',
                fit: BoxFit.cover,
              ),

              SizedBox(width: 3),

              Text(
                '최고 혈당',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF242526),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.45,
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '175 ',
                style: TextStyle(
                  color: const Color(0xFF99000F),
                  fontSize: 32,
                  fontFamily: 'Clipartkorea TTF',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.96,
                ),
              ),

              Text(
                'mg/dL',
                style: TextStyle(
                  color: const Color(0xFF242526),
                  fontSize: 28,
                  fontFamily: 'Clipartkorea TTF',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.84,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 최저 혈당 윗젯
  Widget _lowestBloodSugar(size) {
    return Container(
      width: size.width * 0.4,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 7,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //최저 혈당 제목
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/bloodSugarNote/bloodDrop.png',
                fit: BoxFit.cover,
                color: Color(0xFF00009A),
              ),

              SizedBox(width: 3),

              Text(
                '최저 혈당',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF242526),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.45,
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '161 ',
                style: TextStyle(
                  color: const Color(0xFF00009A),
                  fontSize: 32,
                  fontFamily: 'Clipartkorea TTF',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.96,
                ),
              ),

              Text(
                'mg/dL',
                style: TextStyle(
                  color: const Color(0xFF242526),
                  fontSize: 28,
                  fontFamily: 'Clipartkorea TTF',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.84,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 혈당 기록 시간과 수치 위젯
  Widget _timeData(size, String time, int bloodSugar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Container(
        width: size.width * 0.85,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(width: 1.50, color: const Color(0xFFCCCCCC)),
          borderRadius: BorderRadius.circular(7),
        ),

        child: Stack(
          children: [
            Positioned(
              top: 4,
              right: 4,
              child: Image.asset(
                'images/bloodSugarNote/cancel.png',
                fit: BoxFit.contain,
              ),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  SizedBox(width: 12),

                  // 시간 텍스트
                  Text(
                    time,
                    style: TextStyle(
                      color: const Color(0xFFA9A9A9),
                      fontSize: 17,
                      fontFamily: 'KoPubDotum Medium',
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.51,
                    ),
                  ),

                  SizedBox(width: 88),

                  // 혈당 수치 텍스트
                  Text(
                    '$bloodSugar mg/dL',
                    style: TextStyle(
                      color: const Color(0xFF242526),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.78,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
