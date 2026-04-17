import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(home: Example()));
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  // -----------------------------
  // 입력 컨트롤러
  // -----------------------------
  final TextEditingController sugarController = TextEditingController();
  final TextEditingController glucoseController = TextEditingController();

  bool isExercise = false;
  bool isInsulin = false;
  bool isMedication = false;

  double? prediction;
  bool isLoading = false;

  // -----------------------------
  // 예측 함수
  // -----------------------------
  Future<void> predictGlucose() async {
    // 입력값 검증
    if (sugarController.text.isEmpty || glucoseController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("값을 모두 입력하세요")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse("http://10.0.2.2:8000/predict");
      //10.0.2.2
      //172.30.1.76

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sugar_g": double.parse(sugarController.text),
          "is_exercise": isExercise,
          "current_glucose": double.parse(glucoseController.text),
          "is_insulin": isInsulin,
          "is_medication": isMedication,
        }),
      );

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          prediction = data["prediction"];
        });
      } else {
        throw Exception("서버 오류");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("예측 실패")));
    }

    setState(() {
      isLoading = false;
    });
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('간단 혈당 예측'),
        centerTitle: true,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Color(0xFF242526),
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: -1.30,
        ),
      ),

      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 메뉴 입력
                _inputMenu(),

                const SizedBox(height: 36),

                // 현재 혈당 입력
                _currentBloodSugar(),

                const SizedBox(height: 20),

                // 로딩
                if (isLoading) const CircularProgressIndicator(),

                // 결과
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 47.0),
                  child: Row(
                    children: [
                      Text(
                        textAlign: TextAlign.left,
                        '예상 혈당',
                        style: TextStyle(
                          color: const Color(0xFF242526),
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -0.48,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8),

                if (prediction != null)
                  if (prediction! >= 140)
                    _highPredictionScreen(prediction, size)
                  else
                    _normalPredictionScreen(prediction, size)
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Container(
                      width: size.width,
                      height: 117,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFCCCCCC), // 테두리 색
                          width: 1.5, // 테두리 두께
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            //예측 버튼
            Positioned(
              bottom: 20, // 바텀바 위로 띄움
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: isLoading ? null : predictGlucose,
                child: Center(
                  child: Container(
                    width: size.width * 0.43,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0.00, 0.50),
                        end: Alignment(1.00, 0.50),
                        colors: [
                          const Color(0xFFB5F369),
                          const Color(0xFF7BF15B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),

                    child: Align(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'images/bloodSugarNote/prediction.png',
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '예측하기',
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 7.0),
            child: Text(
              '먹을 메뉴의 당 수치 (g)',
              style: TextStyle(
                color: const Color(0xFF242526),
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: -0.48,
              ),
            ),
          ),

          SizedBox(height: 8),

          TextField(
            controller: sugarController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '예: 메가커피 블루베리 스무디',
              hintStyle: const TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.39,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFCCCCCC), // 테두리 색
                  width: 1.5, // 테두리 두께
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFCCCCCC), // 테두리 색
                  width: 1.5, // 테두리 두께
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentBloodSugar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 7.0),
            child: Text(
              '현재 혈당 (mg/dL)',
              style: TextStyle(
                color: const Color(0xFF242526),
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: -0.48,
              ),
            ),
          ),

          SizedBox(height: 8),

          TextField(
            controller: glucoseController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '예: 120',
              hintStyle: const TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.39,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFCCCCCC), // 테두리 색
                  width: 1.5, // 테두리 두께
                ),
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFCCCCCC), // 테두리 색
                  width: 1.5, // 테두리 두께
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 고혈당 예측 화면
  Widget _highPredictionScreen(prediction, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        children: [
          Container(
            width: size.width,
            height: 117,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFFFFF2F2),
              border: Border.all(
                color: const Color(0xFFFF7D7F), // 테두리 색
                width: 1.5, // 테두리 두께
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //예상 당 수치
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$prediction',
                      style: TextStyle(
                        color: const Color(0xFFD40707),
                        fontSize: 35,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.05,
                      ),
                    ),

                    Text(
                      ' ',
                      style: TextStyle(
                        color: const Color(0xFFD40707),
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.60,
                      ),
                    ),

                    Text(
                      'mg/dL',
                      style: TextStyle(
                        color: const Color(0xFFD40707),
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.60,
                      ),
                    ),
                  ],
                ),

                // 가로선
                Container(
                  width: size.width * 0.45,
                  height: 1,
                  color: const Color(0xFFD40707),
                ),

                SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '고혈당 주의!',
                      style: TextStyle(
                        color: const Color(0xFFD40707),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.48,
                      ),
                    ),

                    Text(
                      ' ',
                      style: TextStyle(
                        color: const Color(0xFFD40707),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.48,
                      ),
                    ),

                    Text(
                      '식단을 확인하세요.',
                      style: TextStyle(
                        color: const Color(0xFF242526),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.48,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 정상 혈당 예측 화면
  Widget _normalPredictionScreen(prediction, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        children: [
          Container(
            width: size.width,
            height: 117,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFFF6FFE4),
              border: Border.all(
                color: const Color(0xFF73AD31), // 테두리 색
                width: 1.5, // 테두리 두께
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //예상 당 수치
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$prediction',
                      style: TextStyle(
                        color: const Color(0xFF187100),
                        fontSize: 35,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.05,
                      ),
                    ),

                    Text(
                      ' ',
                      style: TextStyle(
                        color: const Color(0xFF187100),
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.60,
                      ),
                    ),

                    Text(
                      'mg/dL',
                      style: TextStyle(
                        color: const Color(0xFF187100),
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.60,
                      ),
                    ),
                  ],
                ),

                // 가로선
                Container(
                  width: size.width * 0.45,
                  height: 1,
                  color: const Color(0xFF74AE31),
                ),

                SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '정삼 범주에요.',
                      style: TextStyle(
                        color: const Color(0xFF242526),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.48,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
