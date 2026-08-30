import 'package:flutter/material.dart';
import 'package:slowpick/screen/vision_pilot_camera_capture.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/widget/brand_card.dart';

// 카메라로 음료를 촬영해 후보 메뉴를 추정하는 vision pilot 플로우의 1단계.
// 브랜드 선택 UI는 likedmenu_screen의 '카페별 보기'와 동일한 BrandCard를 재사용한다.
class VisionPilotBrandSelect extends StatelessWidget {
  const VisionPilotBrandSelect({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 22, left: 15, bottom: 15),
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '어느 브랜드에서 구매하셨나요?',
                    style: const TextStyle(
                      color: Color(0xFF242526),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '브랜드를 먼저 선택하면 촬영 결과를 더 정확히 찾을 수 있어요.',
                    style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 14),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 9,
                  childAspectRatio: 3,
                  children: kBrandList
                      .map(
                        (brand) => BrandCard(
                          name: brand.name,
                          logoAsset: brand.logoAsset,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  VisionPilotCameraCapture(brand: brand.name),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
