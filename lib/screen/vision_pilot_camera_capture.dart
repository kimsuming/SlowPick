import 'package:flutter/material.dart';
import 'package:slowpick/screen/vision_pilot_candidates.dart';
import 'package:slowpick/service/menu_service.dart';

// vision pilot 플로우 2단계 — 음료 촬영 화면.
// 프로토타입 — 실제 카메라/촬영·이미지 인식은 붙어 있지 않다. 셔터를 누르면
// 분석 중 연출을 보여주는 동안 선택된 브랜드의 실제 DB 메뉴 중 3개를 무작위로
// 뽑아 "인식된 후보"인 것처럼 후보군 화면에 넘긴다.
class VisionPilotCameraCapture extends StatefulWidget {
  final String brand;
  const VisionPilotCameraCapture({super.key, required this.brand});

  @override
  State<VisionPilotCameraCapture> createState() =>
      _VisionPilotCameraCaptureState();
}

class _VisionPilotCameraCaptureState extends State<VisionPilotCameraCapture> {
  bool _isAnalyzing = false;

  void _handleShutterTap() async {
    if (_isAnalyzing) return;
    setState(() => _isAnalyzing = true);

    try {
      final minDelay = Future.delayed(const Duration(seconds: 2));
      final menus = await MenuService.fetchMenus(brands: [widget.brand]);
      await minDelay;

      final candidates = MenuService.groupVariants(menus)..shuffle();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VisionPilotCandidates(
            brand: widget.brand,
            candidates: candidates.take(3).toList(),
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
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_cafe_outlined,
                        size: 96,
                        color: Colors.white24,
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
