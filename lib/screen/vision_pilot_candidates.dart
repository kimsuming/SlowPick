import 'package:flutter/material.dart';
import 'package:slowpick/screen/blood_sugar_check_record.dart';
import 'package:slowpick/screen/search.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/widget/menu_cards.dart';

// vision pilot 플로우 3단계 — 촬영된 음료와 유사한 후보 메뉴 목록.
// 프로토타입 — 실제 이미지 인식 대신, 이전 화면에서 선택 브랜드의 DB 메뉴 중
// 무작위로 뽑은 candidates를 "인식된 후보"인 것처럼 보여준다.
class VisionPilotCandidates extends StatelessWidget {
  final String brand;
  final List<Map<String, dynamic>> candidates;

  const VisionPilotCandidates({
    super.key,
    required this.brand,
    required this.candidates,
  });

  void _handleSelect(BuildContext context, Map<String, dynamic> menu) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BloodSugarCheckRecord(menuData: menu),
      ),
    );
  }

  void _handleRetake(BuildContext context) => Navigator.pop(context);

  void _handleSearchInstead(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          selectionMode: true,
          onMenuSelected: (menu) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BloodSugarCheckRecord(menuData: menu),
            ),
          ),
        ),
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
                  const Text(
                    '이 중에 맞는 음료가 있나요?',
                    style: TextStyle(
                      color: Color(0xFF242526),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '가장 비슷한 후보 3개를 찾았어요.',
                    style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 14),
                  ),
                ],
              ),
            ),

            Expanded(
              child: candidates.isEmpty
                  ? const Center(
                      child: Text(
                        '후보를 찾지 못했어요.\n직접 선택해 주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 15),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      itemCount: candidates.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final candidate = candidates[index];
                        return MenuListCard(
                          data: candidate,
                          onSelectTap: () => _handleSelect(context, candidate),
                        );
                      },
                    ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFEDEDED)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '찾는 음료가 없나요?',
                    style: TextStyle(
                      color: Color(0xFF9A9A9A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _FooterActionButton(
                          label: '다시 촬영',
                          filled: false,
                          onTap: () => _handleRetake(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FooterActionButton(
                          label: '직접 검색하기',
                          filled: true,
                          onTap: () => _handleSearchInstead(context),
                        ),
                      ),
                    ],
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

class _FooterActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _FooterActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  begin: Alignment(0.00, 0.50),
                  end: Alignment(1.00, 0.50),
                  colors: [Color(0xFFB5F369), Color(0xFF7BF15B)],
                )
              : null,
          color: filled ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(color: const Color(0xFF7BF15B), width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : const Color(0xFF242526),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
