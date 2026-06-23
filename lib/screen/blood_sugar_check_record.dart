import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:slowpick/screen/blood_sugar_note_screen.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

class BloodSugarCheckRecord extends StatefulWidget {
  final Map<String, dynamic> menuData;
  const BloodSugarCheckRecord({super.key, required this.menuData});

  @override
  State<BloodSugarCheckRecord> createState() => _BloodSugarCheckRecordState();
}

class _BloodSugarCheckRecordState extends State<BloodSugarCheckRecord> {
  String? _mealTiming;
  String? _medication;
  String? _exercise;
  int _bloodSugar = 100;

  static String? _savedMedication;
  static bool _rememberMedication = false;
  static String? _savedExercise;
  static bool _rememberExercise = false;

  @override
  void initState() {
    super.initState();
    if (_savedMedication != null) _medication = _savedMedication;
    if (_savedExercise != null) _exercise = _savedExercise;
  }

  void _onRememberChanged(bool? value) {
    setState(() {
      _rememberMedication = value ?? false;
      if (_rememberMedication) {
        _savedMedication = _medication;
      } else {
        _savedMedication = null;
      }
    });
  }

  void _onRememberExerciseChanged(bool? value) {
    setState(() {
      _rememberExercise = value ?? false;
      if (_rememberExercise) {
        _savedExercise = _exercise;
      } else {
        _savedExercise = null;
      }
    });
  }

  void _showBloodSugarInputDialog() {
    final controller = TextEditingController(text: '$_bloodSugar');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('혈당 직접 입력'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            suffixText: 'mg/dL',
            hintText: '70 ~ 200',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final int? v = int.tryParse(controller.text.trim());
              if (v != null) setState(() => _bloodSugar = v.clamp(70, 200));
              Navigator.pop(ctx);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 15),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '혈당 노트',
                          style: TextStyle(
                            color: Color(0xFF242526),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(height: 1, color: const Color(0xFFEDEDED)),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '기록을 위해 체크해주세요!',
                          style: TextStyle(
                            color: Color(0xFF242526),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '보다 정확한 예측을 할 수 있어요.',
                          style: TextStyle(
                            color: Color(0xFF9A9A9A),
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 20),
                        _buildSelectedDrinkCard(),

                        const SizedBox(height: 28),
                        _buildQuestion(
                          '음료를 드신 시간을 선택해 주세요.',
                          ['식후 (식사 후 2시간 이내)', '식전 (식사 30분 전)', '공복'],
                          _mealTiming,
                          (v) => _mealTiming = v,
                        ),

                        const SizedBox(height: 20),
                        _buildQuestion(
                          '당뇨약을 복용 중이신가요?',
                          ['네. 복용하고 있어요.', '아니오. 복용하고 있지 않아요.'],
                          _medication,
                          (v) {
                            _medication = v;
                            if (_rememberMedication) _savedMedication = v;
                          },
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMedication,
                              onChanged: _onRememberChanged,
                              activeColor: const Color(0xFF74AE31),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const Text(
                              '다음에도 선택하기',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        _buildQuestion(
                          '5시간 안에 운동을 했나요?',
                          ['운동 안함', '가벼운 운동', '격한 운동'],
                          _exercise,
                          (v) {
                            _exercise = v;
                            if (_rememberExercise) _savedExercise = v;
                          },
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberExercise,
                              onChanged: _onRememberExerciseChanged,
                              activeColor: const Color(0xFF74AE31),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const Text(
                              '다음에도 선택하기',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        _buildBloodSugarQuestion(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 완료 버튼
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BloodSugarNoteScreen(),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(0.00, 0.50),
                        end: Alignment(1.00, 0.50),
                        colors: [Color(0xFFB5F369), Color(0xFF7BF15B)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        '완료',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
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

  Widget _buildSelectedDrinkCard() {
    final name = widget.menuData['menu_name'] as String? ?? '이름 없음';
    final brand = widget.menuData['brand_name'] as String? ?? '';
    final imageUrl = widget.menuData['image_url'] as String? ?? '';
    final calories = widget.menuData['calories'];
    final sugar = widget.menuData['sugar'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7BF15B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 72,
              height: 72,
              color: const Color(0xFFF1F1F1),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.coffee, color: Colors.grey),
                    )
                  : const Icon(Icons.coffee, size: 36, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF242526),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  brand,
                  style: const TextStyle(
                    color: Color(0xFF9A9A9A),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _NutriBadge(text: '${calories ?? '-'}Kcal'),
                    const SizedBox(width: 6),
                    _NutriBadge(
                      text: '당 ${sugar ?? '-'}g',
                      isHighlight: true,
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

  Widget _buildQuestion(
    String question,
    List<String> options,
    String? selectedValue,
    void Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Q. $question',
          style: const TextStyle(
            color: Color(0xFF242526),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        ...options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => onSelect(option)),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: selectedValue == option
                      ? const Color(0xFFEAF7DC)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedValue == option
                        ? const Color(0xFF74AE31)
                        : const Color(0xFFDDDDDD),
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: selectedValue == option
                        ? const Color(0xFF4A7A1E)
                        : const Color(0xFF242526),
                    fontSize: 15,
                    fontWeight: selectedValue == option
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodSugarQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Text(
                'Q. 현재 혈당은 얼마인가요?',
                style: TextStyle(
                  color: Color(0xFF242526),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.3,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7BF15B)),
                ),
                child: const Text(
                  '추정하기',
                  style: TextStyle(
                    color: Color(0xFF187100),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 27),
          child: Text(
            '대략 어느정도인지 추정하셔도 좋아요!',
            style: TextStyle(
              color: Color(0xFF73AD31),
              fontSize: 14,
              letterSpacing: -1.3,
            ),
          ),
        ),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 30, 10, 17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 32),
                  GestureDetector(
                    onTap: _showBloodSugarInputDialog,
                    child: Text(
                      '$_bloodSugar',
                      style: const TextStyle(
                        color: Color(0xFF73AD31),
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1,
                        letterSpacing: -1.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6, right: 40),
                    child: Text(
                      'mg/dL',
                      style: TextStyle(
                        color: Color(0xFFBBBBBB),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ScaleLabel('70'),
                  _ScaleLabel('100'),
                  _ScaleLabel('120'),
                  _ScaleLabel('140'),
                  _ScaleLabel('180'),
                  _ScaleLabel('200'),
                ],
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    final double x =
                        d.localPosition.dx.clamp(0.0, constraints.maxWidth);
                    setState(() => _bloodSugar =
                        (70 + (x / constraints.maxWidth) * (200 - 70))
                            .round()
                            .clamp(70, 200));
                  },
                  onTapDown: (d) {
                    final double x =
                        d.localPosition.dx.clamp(0.0, constraints.maxWidth);
                    setState(() => _bloodSugar =
                        (70 + (x / constraints.maxWidth) * (200 - 70))
                            .round()
                            .clamp(70, 200));
                  },
                  child: _GradientSlider(value: _bloodSugar, min: 70, max: 200),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScaleLabel extends StatelessWidget {
  final String text;
  const _ScaleLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFBBBBBB),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.3,
      ),
    );
  }
}

class _GradientSlider extends StatelessWidget {
  final int value;
  final int min;
  final int max;

  const _GradientSlider({
    required this.value,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final double percent = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        const double thumbSize = 32;
        final double thumbLeft = (constraints.maxWidth - thumbSize) * percent;

        return Container(
          height: 43,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0xFFFFEA50), Color(0xFF80DA60)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Positioned(
                left: thumbLeft,
                top: 4,
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(width: 2.75, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NutriBadge extends StatelessWidget {
  final String text;
  final bool isHighlight;

  const _NutriBadge({required this.text, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isHighlight
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isHighlight
              ? const Color(0xFF43A047)
              : const Color(0xFF555555),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
