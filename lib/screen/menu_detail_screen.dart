import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MenuDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const MenuDetailScreen({super.key, required this.data});

Map<String, Color> _getSugarColor(num sugar) {
  if (sugar >= 20) {
    return {'bg': const Color(0xFFFFE0E1),
            'text': const Color(0xFFEF4444)};
  } else if (sugar >= 5) {
    return {
      'bg': const Color(0xFFfff6cf),
      'text': const Color(0xFFf29500),
    };
  } else {
    return {
      'bg': const Color(0xFFE8F5E9),
      'text': const Color(0xFF43A047),
    };
  }
}


  @override
  Widget build(BuildContext context) {
    final String name = data['menu_name'] ?? '이름 없음';
    final String brandName = data['brand_name'] ?? '-';
    final String imageUrl = data['menu_image_url'] ?? '';
    final String description = data['description'] ?? '';
    final List<String> allergyList = data['allergy_info'] != null
        ? List<String>.from(data['allergy_info'])
        : [];
    final String allergyText = allergyList.isEmpty ? '알러지 성분 없음' : allergyList.join(', ');

    final Map<String, dynamic> nutrition = data['nutrition'] ?? {};
    final num calories = nutrition['calories_kcal'] ?? 0;
    final num sugar = nutrition['sugar_g'] ?? 0;
    final num protein = nutrition['protein_g'] ?? 0;
    final num sodium = nutrition['sodium_mg'] ?? 0;
    final num satFat = nutrition['saturated_fat_g'] ?? 0;
    final num caffeine = nutrition['caffeine_mg'] ?? 0;
    final String sizeStandard = nutrition['size_standard'] ?? '-';

    final sugarColors = _getSugarColor(sugar);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          brandName,
          style: const TextStyle(
              color: Colors.black54, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
            // TODO: 찜하기 기능 연결
            },
            icon: const Icon(Icons.favorite_border, color: Colors.black26, size:30),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 메뉴 이미지
            Container(
              width: double.infinity,
              height: 400,
              color: const Color(0xFFF1F1F1),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    )
                  : const Icon(Icons.coffee, size: 80, color: Colors.grey),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. 메뉴 이름 및 설명
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'KoPubDotum',
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (description.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        description,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // 3. 당류 정보
                  _buildSugarHighlightCard(sugar, sugarColors),
                  
                  const SizedBox(height: 24),

                  // 4. 상세 영양 정보 그리드
                  const Text(
                    '상세 영양 정보',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '제공량 기준: $sizeStandard',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 한 줄에 3개씩
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    children: [
                      _buildInfoBox('칼로리', '${calories}kcal'),
                      _buildInfoBox('단백질', '${protein}g'),
                      _buildInfoBox('나트륨', '${sodium}mg'),
                      _buildInfoBox('포화지방', '${satFat}g'),
                      _buildInfoBox('카페인', '${caffeine}mg'),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 20),

                  // 5. 알러지 정보
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '알러지 유발 요인',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              allergyText,
                              style: const TextStyle(color: Colors.black87, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 위젯: 당류 강조 카드
  Widget _buildSugarHighlightCard(num sugar, Map<String, Color> colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors['bg'],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors['text']!.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '당류 (Sugar)',
                style: TextStyle(
                  color: colors['text'],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${sugar}g',
                style: TextStyle(
                  color: colors['text'],
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'KoPubDotum',
                ),
              ),
            ],
          ),
          Icon(
            Icons.water_drop_rounded, // 당류 느낌의 아이콘
            size: 40,
            color: colors['text']!.withOpacity(0.5),
          )
        ],
      ),
    );
  }

  // 위젯: 일반 영양 정보 박스
  Widget _buildInfoBox(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}