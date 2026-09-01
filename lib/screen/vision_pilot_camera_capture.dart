import 'package:flutter/material.dart';
import 'package:slowpick/screen/vision_pilot_candidates.dart';
import 'package:slowpick/service/menu_service.dart';

// 프로토타입 — 메가MGC커피는 실제 이미지 인식 대신 항상 이 메뉴명 3개를 "인식 결과"로
// 취급한다. 이름만 고정이고, 실제 표시 데이터(이미지·칼로리·당류 등)는 DB에서 그대로 가져온다.
const String kMegaCoffeeBrand = '메가MGC커피';
const List<String> kMegaCoffeeMockMenuNames = [
  '복숭아 퐁당 요거트 스무디',
  '꿀수박주스',
  '멋쟁이 토마토 스무디',
];

// vision pilot 플로우 2단계 — 음료 촬영 화면.
// 프로토타입 — 실제 카메라/촬영·이미지 인식은 붙어 있지 않다. 셔터를 누르면
// 분석 중 연출을 보여주는 동안 후보 메뉴 3개를 후보군 화면에 넘긴다.
// 메가MGC커피는 위 고정 메뉴명으로 DB에서 실제 메뉴를 찾아 보여주고,
// 그 외 브랜드는 DB 메뉴 중 무작위 3개를 사용한다.
class VisionPilotCameraCapture extends StatefulWidget {
  final String brand;
  const VisionPilotCameraCapture({super.key, required this.brand});

  @override
  State<VisionPilotCameraCapture> createState() =>
      _VisionPilotCameraCaptureState();
}

Map<String, dynamic>? _findByMenuName(
  List<Map<String, dynamic>> menus,
  String name,
) {
  for (final menu in menus) {
    if (menu['menu_name'] == name) return menu;
  }
  return null;
}

class _VisionPilotCameraCaptureState extends State<VisionPilotCameraCapture> {
  bool _isAnalyzing = false;

  void _handleShutterTap() async {
    if (_isAnalyzing) return;
    setState(() => _isAnalyzing = true);

    try {
      final minDelay = Future.delayed(const Duration(seconds: 2));

      final menus = await MenuService.fetchMenus(brands: [widget.brand]);
      final grouped = MenuService.groupVariants(menus);

      List<Map<String, dynamic>> candidates;
      if (widget.brand == kMegaCoffeeBrand) {
        candidates = kMegaCoffeeMockMenuNames
            .map((name) => _findByMenuName(grouped, name))
            .whereType<Map<String, dynamic>>()
            .toList();
      } else {
        candidates = (grouped..shuffle()).take(3).toList();
      }

      await minDelay;
      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisionPilotCandidates(
            brand: widget.brand,
            candidates: candidates,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('분석에 실패했어요: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 22, 15, 15),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.brand,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.24,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 카메라 미리보기를 흉내낸 더미 뷰파인더
                  // 영상 촬영용 임시 처리 — 실제 카메라 대신 샘플 사진을 뷰파인더에
                  // 깔아, 이 음료를 찍는 것처럼 연출한다. 촬영이 끝나면 되돌린다.
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'images/bloodSugarNote/mega_sample.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.local_cafe_outlined,
                            size: 96,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (!_isAnalyzing)
                    const Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Text(
                        '음료가 잘 보이도록 화면 중앙에 맞춰주세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  if (_isAnalyzing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF7BF15B),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '음료를 분석하고 있어요...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: GestureDetector(
                onTap: _handleShutterTap,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAnalyzing
                        ? const Color(0xFF4C4C4C)
                        : Colors.white,
                    border: Border.all(
                      color: const Color(0xFF7BF15B),
                      width: 4,
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
}
