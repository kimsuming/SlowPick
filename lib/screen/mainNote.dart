import 'package:flutter/material.dart';
import 'package:slowpick/screen/bloodSugarDrinkSelect.dart';
import 'package:slowpick/screen/bloodSugarNote.dart';
import 'package:slowpick/screen/dietNote.dart';
import 'package:slowpick/screen/example.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:percent_indicator/percent_indicator.dart';

class mainNote extends StatefulWidget {
  const mainNote({super.key});

  @override
  State<mainNote> createState() => _mainNoteState();
}

class _mainNoteState extends State<mainNote> with SingleTickerProviderStateMixin {
  bool _isFabExpanded = false;
  late AnimationController _fabController;
  late Animation<double> _bloodSugarAnim;
  late Animation<double> _dietAnim;
  late Animation<double> _basicAnim;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _basicAnim = CurvedAnimation(
      parent: _fabController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _dietAnim = CurvedAnimation(
      parent: _fabController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
    );
    _bloodSugarAnim = CurvedAnimation(
      parent: _fabController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });
    if (_isFabExpanded) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  Widget _buildFabOption({
    required Animation<double> animation,
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        axis: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF242526),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0.50, 1.00),
                    end: Alignment(0.50, 0.00),
                    colors: [Color(0xFFF7FFE5), Colors.white],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 26),
                    _bloodSugarPrediction(size),
                    _bloodSugarNote(),
                    _dietNote(),
                    _myNote(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            if (_isFabExpanded)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleFab,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.15),
                  ),
                ),
              ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildFabOption(
                    animation: _bloodSugarAnim,
                    label: '혈당 관리',
                    color: const Color(0xFF7BF15B),
                    icon: Icons.water_drop,
                    onTap: () {
                      _toggleFab();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BloodSugarDrinkSelect(),
                        ),
                      );
                    },
                  ),
                  _buildFabOption(
                    animation: _dietAnim,
                    label: '다이어트',
                    color: const Color(0xFFF4AF31),
                    icon: Icons.monitor_weight,
                    onTap: _toggleFab,
                  ),
                  _buildFabOption(
                    animation: _basicAnim,
                    label: '기본',
                    color: const Color(0xFF9E9E9E),
                    icon: Icons.edit_note,
                    onTap: _toggleFab,
                  ),
                  const SizedBox(height: 4),
                  FloatingActionButton(
                    onPressed: _toggleFab,
                    shape: const CircleBorder(),
                    backgroundColor: const Color(0xFFFFFFFF),
                    child: Image.asset(
                      'images/bloodSugarNote/filepen.png',
                      fit: BoxFit.contain,
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

  Widget _bloodSugarPrediction(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            '내 혈당을 바로 확인하고 싶다면?',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w300,
              height: 1.25,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Example()),
          ),
          child: Container(
            width: size.width * 0.9,
            height: 57,
            padding: const EdgeInsets.only(left: 16, right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                begin: Alignment(1.00, 0.50),
                end: Alignment(0.00, 0.50),
                colors: [Color(0xFF7BF15B), Color(0xFFB5F369)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '지금 예측하러 가기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.30,
                  ),
                ),
                Container(
                  width: 37,
                  height: 37,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF7BF15B),
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bloodSugarNote() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              '거부기의 혈당노트',
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
              Container(
                width: screenWidth * 0.43,
                height: screenHeight * 0.23,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFB6ED74),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      'images/bloodSugarNote/sugarNoteTurtle.png',
                      width: screenWidth * 0.3,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: screenWidth * 0.43,
                height: screenHeight * 0.23,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '오늘의 혈당',
                          style: TextStyle(
                            color: const Color(0xFF9A9A9A),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.36,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '175 ',
                                style: TextStyle(
                                  color: const Color(0xFF99000F),
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
                        Text(
                          '평균 혈당',
                          style: TextStyle(
                            color: const Color(0xFF9A9A9A),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.36,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '168 ',
                                style: TextStyle(
                                  color: const Color(0xFF187100),
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
                    Column(
                      children: [
                        LinearPercentIndicator(
                          lineHeight: 19.0,
                          percent: 0.52,
                          backgroundColor: const Color(0xFFDFFF94),
                          progressColor: const Color(0xFF62F431),
                          barRadius: const Radius.circular(10),
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              '느린거북 다이어트',
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
              Container(
                width: screenWidth * 0.43,
                height: screenHeight * 0.23,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8E76C),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      'images/bloodSugarNote/sugarNoteTurtle.png',
                      width: screenWidth * 0.3,
                      fit: BoxFit.contain,
                      color: const Color(0xFFF6F6C5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: screenWidth * 0.43,
                height: screenHeight * 0.23,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '오늘의 몸무게',
                          style: TextStyle(
                            color: const Color(0xFF9A9A9A),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.36,
                          ),
                        ),
                        Text(
                          '72kg',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.96,
                          ),
                        ),
                        Text(
                          '오늘의 BMI 수치',
                          style: TextStyle(
                            color: const Color(0xFF9A9A9A),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.36,
                          ),
                        ),
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
                    Column(
                      children: [
                        LinearPercentIndicator(
                          lineHeight: 19.0,
                          percent: 0.5,
                          backgroundColor: const Color(0xFFFFE494),
                          progressColor: const Color(0xFFF4AF31),
                          barRadius: const Radius.circular(10),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _myNote() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 13),
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
                    'images/bloodSugarNote/icon-park-outline_sort-one.png',
                    fit: BoxFit.cover,
                  ),
                  Text(
                    '최신 순',
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
          const SizedBox(height: 13),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
    );
  }

  Widget _managementNotes(String title) {
    return Column(
      children: [
        Image.asset('images/bloodSugarNote/note.png', fit: BoxFit.cover),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF242526),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.20,
          ),
        ),
      ],
    );
  }
}
