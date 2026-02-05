import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// 당류 수치에 따라 색상을 반환하는 함수
Map<String, Color> _getSugarColor(num sugar) {
  if (sugar >= 20) {
    return {'bg': const Color(0xFFFFE0E1), 'text': const Color(0xFFEF4444)};
  } else if (sugar >= 5) {
    return {'bg': const Color(0xFFE3F2FD), 'text': const Color(0xFF1E88E5)};
  } else {
    return {'bg': const Color(0xFFE8F5E9), 'text': const Color(0xFF43A047)};
  }
}

// === 그리드 뷰 카드 위젯 === 세로로 긴 카드
class MenuGridCard extends StatelessWidget {
  // 메뉴 데이터를 담는 Map 변수 (Firebase에서 받아온 데이터)
  final Map<String, dynamic> data;

  // 생성자: data를 필수로 받음
  const MenuGridCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // 화면 너비 가져오기 (반응형 디자인용)
    final double screenHeight = MediaQuery.of(context).size.height;
    // 화면 높이 가져오기 (반응형 디자인용)

    final String name = data['menu_name'] ?? '이름 없음';
    final String brandName = data['brand_name'] ?? '-';
    final String imageUrl = data['menu_image_url'] ?? '';
    final num kcal = data['nutrition']?['calories_kcal'] ?? 0;
    final num sugar = data['nutrition']?['sugar_g'] ?? 0;
    final List<String> allergyList = data['allergy_info'] != null
        ? List<String>.from(data['allergy_info'])
        : [];
    // 알러지 리스트를 쉼표로 연결, 없으면 '-'
    final String allergyText = allergyList.isEmpty
        ? '-'
        : allergyList.join(', ');

    // 당류 수치에 따른 배경색/텍스트색 가져오기
    final Map<String, Color> sugarColors = _getSugarColor(sugar);

    // 카드의 최외곽 컨테이너(카드위젯)
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: screenHeight * 0.2,
                color: const Color(0xFFF1F1F1),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : const Icon(Icons.coffee, size: 50, color: Colors.grey),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: _NutritionBadge(
                  screenWidth: screenWidth,
                  text: '${sugar}g',
                  bgColor: sugarColors['bg']!,
                  textColor: sugarColors['text']!,
                ),
              ),
              Positioned(right: 8, top: 8, child: const _HeartIcon(size: 35)),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE586),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          brandName,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'KoPubDotum',
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.003),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'KoPubDotum',
                        ),
                      ),
                      Text(
                        '${kcal}Kcal',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: screenWidth * 0.04,
                          fontFamily: 'KoPubDotum',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '알러지 정보: $allergyText',
                        style: TextStyle(
                          color: const Color(0xFF7B7B7B),
                          fontSize: screenWidth * 0.03,
                          fontFamily: 'KoPubDotum',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === 리스트 뷰 카드 위젯 === 가로로 긴 카드
class MenuListCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const MenuListCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardHeight = 110.0;

    final String name = data['menu_name'] ?? '이름 없음';
    final String imageUrl = data['menu_image_url'] ?? '';
    final num kcal = data['nutrition']?['calories_kcal'] ?? 0;
    final num sugar = data['nutrition']?['sugar_g'] ?? 0;
    // 임시 데이터 (나중에 실제 데이터 연결 필요)
    final num protein = 12;
    final num fat = 5;

    final List<String> allergyList = data['allergy_info'] != null
        ? List<String>.from(data['allergy_info'])
        : [];
    final String allergyText = allergyList.isEmpty
        ? '-'
        : allergyList.join(', ');

    final Map<String, Color> sugarColors = _getSugarColor(sugar);

    return Container(
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: cardHeight,
            height: cardHeight,
            color: const Color(0xFFF1F1F1),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  )
                : const Icon(Icons.coffee, size: 40, color: Colors.grey),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: screenWidth * 0.042,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'KoPubDotum',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${kcal}Kcal',
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                fontFamily: 'KoPubDotum',
                              ),
                            ),
                            Text(
                              '알러지 정보: $allergyText',
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                color: Colors.black54,
                                fontFamily: 'KoPubDotum',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _HeartIcon(size: 24),
                    ],
                  ),
                  Row(
                    children: [
                      _ColorMiniBadge(
                        text: '당 ${sugar}g',
                        bgColor: sugarColors['bg']!,
                        textColor: sugarColors['text']!,
                      ),
                      const SizedBox(width: 6),
                      _MiniBadge(text: '단백질 ${protein}g'),
                      const SizedBox(width: 6),
                      _MiniBadge(text: '지방 ${fat}g'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === 내부 전용 작은 위젯들 (Private Widgets) ===

// 찜 뱃지
class _HeartIcon extends StatelessWidget {
  final double size;
  const _HeartIcon({this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white38,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.favorite_border,
        size: size * 0.8,
        color: const Color(0xFF65B700),
      ),
    );
  }
}

// 그리드용 영양 뱃지
class _NutritionBadge extends StatelessWidget {
  final double screenWidth;
  final String text;
  final Color bgColor;
  final Color textColor;

  const _NutritionBadge({
    required this.screenWidth,
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
      decoration: ShapeDecoration(
        color: bgColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: textColor),
          borderRadius: BorderRadius.circular(60),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: screenWidth * 0.04,
          fontWeight: FontWeight.bold,
          fontFamily: 'KoPubDotum',
        ),
      ),
    );
  }
}

// 리스트용 기본 미니 뱃지 (회색)
class _MiniBadge extends StatelessWidget {
  final String text;
  const _MiniBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 11,
          fontFamily: 'KoPubDotum',
        ),
      ),
    );
  }
}

// 리스트용 컬러 미니 뱃지 (당류용)
class _ColorMiniBadge extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const _ColorMiniBadge({
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontFamily: 'KoPubDotum',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
