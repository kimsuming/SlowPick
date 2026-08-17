import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:slowpick/screen/menu_detail_screen.dart';
import 'package:slowpick/service/settings_service.dart';

num? _toNum(dynamic v) => v == null ? null : num.tryParse(v.toString());

// 검색 화면 카드 미리보기에서 선택 가능한 영양 성분 목록.
// key는 menus 테이블 컬럼명과 동일하게 맞춰 data map에서 바로 조회한다.
class NutrientOption {
  final String key;
  final String label;
  final String unit;
  const NutrientOption(this.key, this.label, this.unit);
}

const List<NutrientOption> kPreviewNutrientOptions = [
  NutrientOption('sugar', '당류', 'g'),
  NutrientOption('protein', '단백질', 'g'),
  NutrientOption('saturated_fat', '지방', 'g'),
  NutrientOption('calories', '칼로리', 'Kcal'),
  NutrientOption('caffeine', '카페인', 'mg'),
  NutrientOption('sodium', '나트륨', 'mg'),
];

NutrientOption? findNutrientOption(String key) {
  for (final option in kPreviewNutrientOptions) {
    if (option.key == key) return option;
  }
  return null;
}

Map<String, Color> _getSugarColor(num? sugar) {
  if (sugar == null) {
    return {'bg': const Color(0xFFF0F0F0), 'text': const Color(0xFF9E9E9E)};
  } else if (sugar >= 20) {
    return {'bg': const Color(0xFFFFE0E1), 'text': const Color(0xFFEF4444)};
  } else if (sugar >= 5) {
    return {'bg': const Color(0xFFfff6cf), 'text': const Color(0xFFf29500)};
  } else {
    return {'bg': const Color(0xFFE8F5E9), 'text': const Color(0xFF43A047)};
  }
}

// 값이 없으면(NULL) '정보 미제공'으로 표시 — 크롤러가 실제로 0인 값과
// 정보를 못 얻은 값을 구분해 null로 넘겨주므로, 여기서 0으로 뭉개면 안 됨.
String _formatNutrition(num? value, String unit) {
  return value == null ? '정보 미제공' : '$value$unit';
}

// === 그리드 뷰 카드 위젯 === 세로로 긴 카드
class MenuGridCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLiked;
  final VoidCallback? onLikeTap;
  final bool isSelected;
  final VoidCallback? onSelectTap;
  final List<String> previewNutrients;

  const MenuGridCard({
    super.key,
    required this.data,
    this.isLiked = false,
    this.onLikeTap,
    this.isSelected = false,
    this.onSelectTap,
    this.previewNutrients = SettingsService.defaultPreviewNutrients,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // 화면 너비 가져오기 (반응형 디자인용)
    final double screenHeight = MediaQuery.of(context).size.height;
    // 화면 높이 가져오기 (반응형 디자인용)

    final String name = data['menu_name'] ?? '이름 없음';
    final String brandName = data['brand_name'] ?? '-';
    final String imageUrl = data['image_url'] ?? '';
    final List<String> allergyList = data['allergies'] != null
        ? List<String>.from(data['allergies'])
        : [];
    final String allergyText = allergyList.isEmpty
        ? '-'
        : allergyList.join(', ');

    // 당류는 항상 이미지 위 뱃지로 고정 표시, 나머지 선택 성분은 이름 아래에 나열
    final num? sugar = _toNum(data['sugar']);
    final Map<String, Color> sugarColors = _getSugarColor(sugar);
    final List<NutrientOption> extraOptions = previewNutrients
        .where((key) => key != 'sugar')
        .map(findNutrientOption)
        .whereType<NutrientOption>()
        .toList();

    return GestureDetector(
      onTap: onSelectTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MenuDetailScreen(data: data)),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFF7BF15B), width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // 메뉴 이미지
                  Container(
                    width: double.infinity,
                    height: screenHeight * 0.2,
                    color: const Color(0xFFF1F1F1),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.coffee,
                            size: 50,
                            color: Colors.grey,
                          ),
                  ),
                  // 당류 뱃지 (고정)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _NutritionBadge(
                      screenWidth: screenWidth,
                      text: _formatNutrition(sugar, 'g'),
                      bgColor: sugarColors['bg']!,
                      textColor: sugarColors['text']!,
                    ),
                  ),
                  // 찜 버튼
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _HeartIcon(size: 35, isLiked: isLiked, onTap: onLikeTap),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 메뉴명 배경
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
                          // 메뉴명
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
                          // 나머지 선택된 성분 뱃지
                          if (extraOptions.isNotEmpty) ...[
                            SizedBox(height: screenHeight * 0.004),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: extraOptions.map((option) {
                                final num? value = _toNum(data[option.key]);
                                return _MiniBadge(
                                  text: '${option.label} ${_formatNutrition(value, option.unit)}',
                                );
                              }).toList(),
                            ),
                          ],
                          // 알러지 정보
                          SizedBox(height: screenHeight * 0.005),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === 리스트 뷰 카드 위젯 === 가로로 긴 카드
class MenuListCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLiked;
  final VoidCallback? onLikeTap;
  final bool isSelected;
  final VoidCallback? onSelectTap;
  final List<String> previewNutrients;

  const MenuListCard({
    super.key,
    required this.data,
    this.isLiked = false,
    this.onLikeTap,
    this.isSelected = false,
    this.onSelectTap,
    this.previewNutrients = SettingsService.defaultPreviewNutrients,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardHeight = 110.0;

    final String name = data['menu_name'] ?? '이름 없음';
    final String imageUrl = data['image_url'] ?? '';
    final num? kcal = _toNum(data['calories']);

    // 당류는 항상 고정 뱃지로 표시, 나머지 선택 성분은 옆으로 스크롤되는 영역에 나열
    final num? sugar = _toNum(data['sugar']);
    final Map<String, Color> sugarColors = _getSugarColor(sugar);
    final List<NutrientOption> extraOptions = previewNutrients
        .where((key) => key != 'sugar')
        .map(findNutrientOption)
        .whereType<NutrientOption>()
        .toList();

    final List<String> allergyList = data['allergies'] != null
        ? List<String>.from(data['allergies'])
        : [];
    final String allergyText = allergyList.isEmpty
        ? '-'
        : allergyList.join(', ');

    return GestureDetector(
      onTap: onSelectTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MenuDetailScreen(data: data),
          ),
        );
      },
      child: Container(
        height: cardHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFF7BF15B), width: 2) : null,
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
                                _formatNutrition(kcal, 'Kcal'),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.032,
                                  fontFamily: 'KoPubDotum',
                                ),
                              ),
                              Text(
                                '알러지 정보: $allergyText',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.032,
                                  color: Colors.black54,
                                  fontFamily: 'KoPubDotum',
                                ),
                              ),
                            ],
                          ),
                        ),
                        _HeartIcon(size: 24, isLiked: isLiked, onTap: onLikeTap),
                      ],
                    ),
                    Row(
                      children: [
                        _ColorMiniBadge(
                          text: '당 ${_formatNutrition(sugar, 'g')}',
                          bgColor: sugarColors['bg']!,
                          textColor: sugarColors['text']!,
                        ),
                        if (extraOptions.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final option in extraOptions) ...[
                                    _MiniBadge(
                                      text: '${option.label} ${_formatNutrition(_toNum(data[option.key]), option.unit)}',
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === 내부 전용 작은 위젯들 (Private Widgets) ===

// 찜 뱃지
class _HeartIcon extends StatelessWidget {
  final double size;
  final bool isLiked;
  final VoidCallback? onTap;
  const _HeartIcon({this.size = 30, this.isLiked = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white38,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          size: size * 0.8,
          color: isLiked ? const Color(0xFFEF4444) : Colors.black26,
        ),
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