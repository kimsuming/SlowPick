import 'package:flutter/material.dart';

// 브랜드명 + 로고 에셋 경로 쌍. likedmenu_screen, vision pilot 브랜드 선택 등
// 브랜드 목록이 필요한 화면에서 공통으로 사용한다.
class BrandInfo {
  final String name;
  final String logoAsset;
  const BrandInfo(this.name, this.logoAsset);
}

const List<BrandInfo> kBrandList = [
  BrandInfo('스타벅스', 'images/brand_logo/logo_starbucks.png'),
  BrandInfo('메가MGC커피', 'images/brand_logo/logo_mega.png'),
  BrandInfo('컴포즈커피', 'images/brand_logo/logo_compose.jpg'),
  BrandInfo('이디야커피', 'images/brand_logo/logo_ediya.jpg'),
  BrandInfo('빽다방', 'images/brand_logo/logo_paik.png'),
  BrandInfo('투썸플레이스', 'images/brand_logo/logo_twosome.png'),
  BrandInfo('엔제리너스', 'images/brand_logo/logo_angel.png'),
  BrandInfo('매머드커피', 'images/brand_logo/logo_mammoth.png'),
  BrandInfo('폴 바셋', 'images/brand_logo/logo_paul.png'),
  BrandInfo('더벤티', 'images/brand_logo/logo_theventi.png'),
  BrandInfo('요거프레소', 'images/brand_logo/logo_yoger.png'),
  BrandInfo('매머드 익스프레스', 'images/brand_logo/logo_mammoth.png'),
];

// likedmenu_screen '카페별 보기'에서 쓰던 브랜드 카드(원형 로고 + 이름 + 우측 chevron)를
// 다른 화면에서도 재사용할 수 있도록 뽑아낸 공통 위젯.
class BrandCard extends StatelessWidget {
  final String name;
  final String? logoAsset;
  // 브랜드 옆에 덧붙일 보조 텍스트 (예: 찜한 개수). null이면 표시하지 않음.
  final String? badgeText;
  final VoidCallback? onTap;

  const BrandCard({
    super.key,
    required this.name,
    this.logoAsset,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool highlighted = badgeText != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E2E2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SizedBox(width: 10),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E2E2),
                      width: 1.5,
                    ),
                    image: logoAsset != null
                        ? DecorationImage(
                            image: AssetImage(logoAsset!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 5),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badgeText != null)
                      Text(
                        badgeText!,
                        style: const TextStyle(
                          color: Color(0xFF73AD31),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.chevron_right,
                color: highlighted
                    ? const Color(0xFF73AD31)
                    : const Color(0xFFE3E3E3),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
