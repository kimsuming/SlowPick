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
    return Scaffold(
      appBar: AppBar(title: const Text("혈당 예측")),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // -----------------------------
              // 당 섭취 입력
              // -----------------------------
              TextField(
                controller: sugarController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "당 섭취 (g)",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              // -----------------------------
              // 현재 혈당 입력
              // -----------------------------
              TextField(
                controller: glucoseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "현재 혈당 (mg/dL)",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // -----------------------------
              // 스위치들
              // -----------------------------
              SwitchListTile(
                title: const Text("운동 했나요?"),
                value: isExercise,
                onChanged: (val) {
                  setState(() {
                    isExercise = val;
                  });
                },
              ),

              SwitchListTile(
                title: const Text("인슐린 투여"),
                value: isInsulin,
                onChanged: (val) {
                  setState(() {
                    isInsulin = val;
                  });
                },
              ),

              SwitchListTile(
                title: const Text("약 복용"),
                value: isMedication,
                onChanged: (val) {
                  setState(() {
                    isMedication = val;
                  });
                },
              ),

              const SizedBox(height: 20),

              // -----------------------------
              // 예측 버튼
              // -----------------------------
              ElevatedButton(
                onPressed: isLoading ? null : predictGlucose,
                child: const Text("예측하기"),
              ),

              const SizedBox(height: 20),

              // 로딩
              if (isLoading) const CircularProgressIndicator(),

              // 결과
              if (prediction != null)
                Text(
                  "예측 결과: $prediction mg/dL",
                  style: const TextStyle(fontSize: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
