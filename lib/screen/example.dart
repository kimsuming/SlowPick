import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:slowpick/service/auth_service.dart';

void main() {
  runApp(const MaterialApp(home: Example()));
}

// ─────────────────────────────────────────
// 응답 모델
// ─────────────────────────────────────────
class GlucoseCurve {
  final List<int> timeMinutes;
  final List<double> predictedGlucose;

  GlucoseCurve({required this.timeMinutes, required this.predictedGlucose});

  factory GlucoseCurve.fromJson(Map<String, dynamic> json) => GlucoseCurve(
    timeMinutes: List<int>.from(json['time_minutes']),
    predictedGlucose: List<double>.from(
      json['predicted_glucose'].map((e) => (e as num).toDouble()),
    ),
  );
}

class RiskLevel {
  final String label;
  final String color;
  final String description;

  RiskLevel({
    required this.label,
    required this.color,
    required this.description,
  });

  factory RiskLevel.fromJson(Map<String, dynamic> json) => RiskLevel(
    label: json['label'],
    color: json['color'],
    description: json['description'],
  );
}

class PredictResponse {
  final double currentGlucose;
  final double predicted30m;
  final double predicted60m;
  final double predicted120m;
  final double deltaGlucose;
  final GlucoseCurve glucoseCurve;
  final RiskLevel risk;
  final int modelStage;
  final String modelStageLabel;
  final bool isPersonalized;
  final String? accuracyWarning;
  final String? coachingDrinkAlt;
  final String? coachingAction;

  PredictResponse({
    required this.currentGlucose,
    required this.predicted30m,
    required this.predicted60m,
    required this.predicted120m,
    required this.deltaGlucose,
    required this.glucoseCurve,
    required this.risk,
    required this.modelStage,
    required this.modelStageLabel,
    required this.isPersonalized,
    this.accuracyWarning,
    this.coachingDrinkAlt,
    this.coachingAction,
  });

  factory PredictResponse.fromJson(Map<String, dynamic> json) =>
      PredictResponse(
        currentGlucose: (json['current_glucose'] as num).toDouble(),
        predicted30m: (json['predicted_glucose_30m'] as num).toDouble(),
        predicted60m: (json['predicted_glucose_60m'] as num).toDouble(),
        predicted120m: (json['predicted_glucose_120m'] as num).toDouble(),
        deltaGlucose: (json['delta_glucose'] as num).toDouble(),
        glucoseCurve: GlucoseCurve.fromJson(json['glucose_curve']),
        risk: RiskLevel.fromJson(json['risk']),
        modelStage: json['model_stage'],
        modelStageLabel: json['model_stage_label'],
        isPersonalized: json['is_personalized'],
        accuracyWarning: json['accuracy_warning'],
        coachingDrinkAlt: json['coaching_drink_alt'],
        coachingAction: json['coaching_action'],
      );
}

// ─────────────────────────────────────────
// 상태값 enum
// ─────────────────────────────────────────
enum MealStatus {
  fasting(0, '공복'),
  within1h(1, '1시간 이내'),
  within2h(2, '2시간 이내');

  const MealStatus(this.value, this.label);
  final int value;
  final String label;
}

enum ExerciseLevel {
  none(0, '없음'),
  light(1, '가벼운'),
  intense(2, '강한');

  const ExerciseLevel(this.value, this.label);
  final int value;
  final String label;
}

// ─────────────────────────────────────────
// 화면
// ─────────────────────────────────────────
class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  // 음료 입력
  final TextEditingController drinkNameController = TextEditingController();
  final TextEditingController sugarController = TextEditingController();
  final TextEditingController carbsController = TextEditingController();
  final TextEditingController fatController = TextEditingController(text: '0');

  // 사용자 입력
  final TextEditingController glucoseController = TextEditingController();
  MealStatus selectedMeal = MealStatus.within1h;
  ExerciseLevel selectedExercise = ExerciseLevel.none;
  bool isInsulin = false;
  bool isMedication = false;

  // 예측 결과
  PredictResponse? result;
  bool isLoading = false;

  // ─────────────────────────────────────────
  // 실측값 입력 (추가된 부분)
  // ─────────────────────────────────────────
  final TextEditingController actual30Controller = TextEditingController();
  final TextEditingController actual60Controller = TextEditingController();
  final TextEditingController actual120Controller = TextEditingController();

  bool isRecording = false; // /record 전송 중
  bool recordDone = false; // 기록 완료 여부

  // 타이머
  Timer? _timer;
  int _timerSeconds = 5; // 30분 = 1800초
  bool _timerRunning = false;
  bool _timerDone = false;

  // ─────────────────────────────────────────
  // 타이머 시작
  // ─────────────────────────────────────────
  void _startTimer() {
    setState(() {
      _timerSeconds = 5; // 테스트용으로 5초로 설정 (실제론 1800초) 30 * 60
      _timerRunning = true;
      _timerDone = false;
      recordDone = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds <= 0) {
        t.cancel();
        setState(() {
          _timerRunning = false;
          _timerDone = true;
        });
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  String get _timerLabel {
    final m = _timerSeconds ~/ 60;
    final s = _timerSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // /predict 호출
  // ─────────────────────────────────────────
  Future<void> predictGlucose() async {
    if (sugarController.text.isEmpty || glucoseController.text.isEmpty) {
      _showSnack('당류와 현재 혈당을 입력하세요');

      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse('http://3.34.7.133:8000/predict');
      final body = jsonEncode({
        'user_id': _userId ?? 'user_001',
        'drink': {
          'name': drinkNameController.text.isEmpty
              ? '음료'
              : drinkNameController.text,
          'sugar_g': double.parse(sugarController.text),
          'carbs_g': carbsController.text.isEmpty
              ? double.parse(sugarController.text)
              : double.parse(carbsController.text),
          'fat_g': double.parse(fatController.text),
        },
        'current_glucose': double.parse(glucoseController.text),
        'meal_status': selectedMeal.value,
        'exercise_level': selectedExercise.value,
        'insulin_taken': isInsulin,
        'medication_taken': isMedication,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          result = PredictResponse.fromJson(data);
          recordDone = false;
        });
        _startTimer(); // 예측 성공 → 타이머 자동 시작
      } else {
        _showSnack('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      _showSnack('예측 실패: $e');
    }

    setState(() => isLoading = false);
  }

  // ─────────────────────────────────────────
  // /record 호출 (추가된 부분)
  // ─────────────────────────────────────────
  Future<void> recordActual() async {
    // 하나도 입력 안 했으면 막기
    if (actual30Controller.text.isEmpty &&
        actual60Controller.text.isEmpty &&
        actual120Controller.text.isEmpty) {
      _showSnack('측정값을 하나 이상 입력하세요');
      return;
    }

    setState(() => isRecording = true);

    try {
      final url = Uri.parse('http://3.34.7.133:8000/record');

      // null 처리: 입력 안 한 항목은 null로 전송
      double? actual30 = actual30Controller.text.isNotEmpty
          ? double.parse(actual30Controller.text)
          : null;
      double? actual60 = actual60Controller.text.isNotEmpty
          ? double.parse(actual60Controller.text)
          : null;
      double? actual120 = actual120Controller.text.isNotEmpty
          ? double.parse(actual120Controller.text)
          : null;

      final body = jsonEncode({
        'user_id': _userId ?? 'user_001',
        'predict_request': {
          'user_id': _userId ?? 'user_001',
          'drink': {
            'name': drinkNameController.text.isEmpty
                ? '음료'
                : drinkNameController.text,
            'sugar_g': double.parse(sugarController.text),
            'carbs_g': carbsController.text.isEmpty
                ? double.parse(sugarController.text)
                : double.parse(carbsController.text),
            'fat_g': double.parse(fatController.text),
          },
          'current_glucose': double.parse(glucoseController.text),
          'meal_status': selectedMeal.value,
          'exercise_level': selectedExercise.value,
          'insulin_taken': isInsulin,
          'medication_taken': isMedication,
        },
        'actual_glucose_30m': actual30,
        'actual_glucose_60m': actual60,
        'actual_glucose_120m': actual120,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => recordDone = true);
        _showSnack('✅ 기록 완료! ${data['message']}');
      } else {
        _showSnack('기록 실패: ${response.statusCode}');
      }
    } catch (e) {
      _showSnack('기록 실패: $e');
    }

    setState(() => isRecording = false);
  }

  // _ExampleState에 추가
  String? _userId;

  @override
  void initState() {
    super.initState();
    print('initState 호출됨');
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final id = await AuthService.instance.fetchUserId();
      print('fetchUserId 결과: $id');
      setState(() => _userId = id);
    } catch (e) {
      print('fetchUserId 에러: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('혈당 예측'),
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
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _inputField(
                    '음료 이름',
                    drinkNameController,
                    hint: '예: 메가커피 블루베리 스무디',
                  ),
                  const SizedBox(height: 16),
                  _inputField('당류 (g)', sugarController, hint: '예: 39'),
                  const SizedBox(height: 16),
                  _inputField('탄수화물 (g)', carbsController, hint: '예: 42'),
                  const SizedBox(height: 16),
                  _inputField('지방 (g)', fatController, hint: '예: 0'),
                  const SizedBox(height: 16),
                  _inputField(
                    '현재 혈당 (mg/dL)',
                    glucoseController,
                    hint: '예: 105',
                  ),
                  const SizedBox(height: 20),

                  _sectionLabel('마지막 식사'),
                  _segmentRow(
                    MealStatus.values.map((e) => e.label).toList(),
                    MealStatus.values.indexOf(selectedMeal),
                    (i) => setState(() => selectedMeal = MealStatus.values[i]),
                  ),
                  const SizedBox(height: 16),

                  _sectionLabel('운동'),
                  _segmentRow(
                    ExerciseLevel.values.map((e) => e.label).toList(),
                    ExerciseLevel.values.indexOf(selectedExercise),
                    (i) => setState(
                      () => selectedExercise = ExerciseLevel.values[i],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      children: [
                        Expanded(
                          child: _toggleCard(
                            '인슐린 투여',
                            isInsulin,
                            (v) => setState(() => isInsulin = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _toggleCard(
                            '약 복용',
                            isMedication,
                            (v) => setState(() => isMedication = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (result?.accuracyWarning != null) _accuracyBadge(),
                  _resultSection(size),
                ],
              ),
            ),

            // 예측 버튼
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: isLoading ? null : predictGlucose,
                child: Center(
                  child: Container(
                    width: size.width * 0.43,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB5F369), Color(0xFF7BF15B)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              '예측하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.57,
                              ),
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

  // ─────────────────────────────────────────
  // 타이머 + 실측값 입력 위젯 (핵심 추가 부분)
  // ─────────────────────────────────────────
  Widget _timerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기록 완료 상태
          if (recordDone)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFe8f5ee),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1a6b4a), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF1a6b4a)),
                  SizedBox(width: 8),
                  Text(
                    '실측값 기록 완료! 모델 학습에 반영됩니다.',
                    style: TextStyle(
                      color: Color(0xFF1a6b4a),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          // 타이머 진행 중
          else if (_timerRunning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
              ),
              child: Column(
                children: [
                  const Text(
                    '30분 후 혈당을 측정해주세요',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF242526),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _timerLabel,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1a6b4a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '남은 시간',
                    style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                  ),
                ],
              ),
            )
          // 타이머 완료 → 실측값 입력
          else if (_timerDone)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1a6b4a), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Color(0xFF1a6b4a),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '혈당을 측정하고 입력해주세요',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1a6b4a),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '입력할수록 예측 정확도가 높아져요',
                    style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 14),

                  // 실측값 입력 3개
                  _actualInputField(
                    '30분 후 실측 혈당 (mg/dL)',
                    actual30Controller,
                    hint: '예: 128',
                  ),
                  const SizedBox(height: 10),
                  _actualInputField(
                    '60분 후 실측 혈당 (mg/dL)',
                    actual60Controller,
                    hint: '예: 145',
                  ),
                  const SizedBox(height: 10),
                  _actualInputField(
                    '120분 후 실측 혈당 (mg/dL)',
                    actual120Controller,
                    hint: '예: 118',
                  ),
                  const SizedBox(height: 14),

                  // 기록하기 버튼
                  GestureDetector(
                    onTap: isRecording ? null : recordActual,
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a6b4a),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: isRecording
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                '기록하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _actualInputField(
    String label,
    TextEditingController controller, {
    String hint = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFCCCCCC),
                width: 1.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFCCCCCC),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // 기존 위젯 헬퍼 (변경 없음)
  // ─────────────────────────────────────────
  Widget _inputField(
    String label,
    TextEditingController controller, {
    String hint = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 7, bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: -0.48,
                color: Color(0xFF242526),
              ),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFCCCCCC),
                  width: 1.5,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFCCCCCC),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 47, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.48,
        color: Color(0xFF242526),
      ),
    ),
  );

  Widget _segmentRow(List<String> labels, int selected, Function(int) onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                margin: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF1a6b4a) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF1a6b4a)
                        : const Color(0xFFCCCCCC),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: active ? Colors.white : const Color(0xFF888888),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _toggleCard(String label, bool value, Function(bool) onChange) {
    return GestureDetector(
      onTap: () => onChange(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFe8f5ee) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? const Color(0xFF1a6b4a) : const Color(0xFFCCCCCC),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: value ? const Color(0xFF1a6b4a) : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }

  Widget _accuracyBadge() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF5E7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE67E22), width: 1),
      ),
      child: Text(
        '⚠ ${result!.accuracyWarning}',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFFE67E22),
          fontWeight: FontWeight.w400,
        ),
      ),
    ),
  );

  Widget _resultSection(Size size) {
    if (result == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 7, bottom: 8),
              child: Text(
                '예상 혈당',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.48,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: 117,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
                border: Border.all(color: const Color(0xFFCCCCCC), width: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    final isHigh = result!.predicted60m >= 140;
    final borderColor = isHigh
        ? const Color(0xFFFF7D7F)
        : const Color(0xFF73AD31);
    final bgColor = isHigh ? const Color(0xFFFFF2F2) : const Color(0xFFF6FFE4);
    final textColor = isHigh
        ? const Color(0xFFD40707)
        : const Color(0xFF187100);
    final riskMsg = isHigh ? '고혈당 주의! ' : '';
    final subMsg = isHigh ? '식단을 확인하세요.' : '정상 범주에요.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 7, bottom: 8),
            child: Text(
              '예상 혈당',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: -0.48,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: bgColor,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      result!.predicted60m.toStringAsFixed(1),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 35,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.05,
                      ),
                    ),
                    Text(
                      ' mg/dL',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: size.width * 0.45,
                  height: 1,
                  color: borderColor,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (riskMsg.isNotEmpty)
                      Text(
                        riskMsg,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      subMsg,
                      style: const TextStyle(
                        color: Color(0xFF242526),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStatCard('30분 후', result!.predicted30m, textColor),
              const SizedBox(width: 8),
              _miniStatCard('60분 후', result!.predicted60m, textColor),
              const SizedBox(width: 8),
              _miniStatCard('120분 후', result!.predicted120m, textColor),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최대 상승량  +${result!.deltaGlucose.toStringAsFixed(1)} mg/dL',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF242526),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '모델: ${result!.modelStageLabel} (${result!.modelStage}단계)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (result!.coachingDrinkAlt != null ||
              result!.coachingAction != null)
            _coachingCard(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _miniStatCard(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCCCCCC), width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coachingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFe8f5ee),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1a6b4a), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI 코칭',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1a6b4a),
            ),
          ),
          const SizedBox(height: 8),
          if (result!.coachingDrinkAlt != null) ...[
            const Text(
              '음료 대체',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF1a6b4a),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              result!.coachingDrinkAlt!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF242526),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (result!.coachingAction != null) ...[
            const Text(
              '행동 추천',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF1a6b4a),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              result!.coachingAction!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF242526),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
