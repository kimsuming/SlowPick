import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MenuDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const MenuDetailScreen({super.key, required this.data});

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  // data['variants']가 있으면 같은 메뉴의 핫/아이스·사이즈 변형 목록, 없으면 단일 메뉴.
  late final List<Map<String, dynamic>> _variants;
  late Map<String, dynamic> _selected;

  @override
  void initState() {
    super.initState();

    final rawVariants = widget.data['variants'];
    _variants = rawVariants is List && rawVariants.isNotEmpty
        ? rawVariants.map((v) => Map<String, dynamic>.from(v as Map)).toList()
        : [widget.data];

    _selected = _pickDefaultVariant(_variants);
  }

  // 디폴트: [핫] 우선, 그 안에서 가장 작은 사이즈.
  Map<String, dynamic> _pickDefaultVariant(List<Map<String, dynamic>> variants) {
    if (variants.length == 1) return variants.first;

    final hotVariants = variants.where((v) => v['temperature'] == 'HOT').toList();
    final pool = hotVariants.isNotEmpty ? hotVariants : variants;

    final sorted = [...pool]
      ..sort((a, b) => _sizeRank(a).compareTo(_sizeRank(b)));

    return sorted.first;
  }

  int _sizeRank(Map<String, dynamic> variant) =>
      (variant['size_rank'] as num?)?.toInt() ?? -1;

  List<String> get _availableTemperatures {
    final temps = _variants
        .map((v) => v['temperature'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    temps.sort((a, b) => a == 'HOT' ? -1 : (b == 'HOT' ? 1 : 0));
    return temps;
  }

  List<Map<String, dynamic>> get _sizesForSelectedTemperature {
    final temp = _selected['temperature'];
    final pool = temp == null
        ? _variants
        : _variants.where((v) => v['temperature'] == temp).toList();

    final sized = pool.where((v) => v['size_label'] != null).toList()
      ..sort((a, b) => _sizeRank(a).compareTo(_sizeRank(b)));

    return sized.take(3).toList();
  }

  void _selectTemperature(String temperature) {
    final pool = _variants.where((v) => v['temperature'] == temperature).toList();
    if (pool.isEmpty) return;

    final currentSizeLabel = _selected['size_label'];
    final sameSize = pool.where((v) => v['size_label'] == currentSizeLabel);

    if (sameSize.isNotEmpty) {
      setState(() => _selected = sameSize.first);
      return;
    }

    final sorted = [...pool]..sort((a, b) => _sizeRank(a).compareTo(_sizeRank(b)));
    setState(() => _selected = sorted.first);
  }

  void _selectSize(Map<String, dynamic> variant) {
    setState(() => _selected = variant);
  }

  Map<String, Color> _getSugarColor(num? sugar) {
    if (sugar == null) {
      return {'bg': const Color(0xFFF0F0F0), 'text': const Color(0xFF9E9E9E)};
    } else if (sugar >= 20) {
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

  // 값이 없으면(NULL) '정보 미제공'으로 표시 — 크롤러가 실제로 0인 값과
  // 정보를 못 얻은 값을 구분해 null로 넘겨주므로, 여기서 0으로 뭉개면 안 됨.
  String _formatNutrition(num? value, String unit) {
    return value == null ? '정보 미제공' : '$value$unit';
  }

  String _temperatureLabel(String temperature) => temperature == 'HOT' ? '핫' : '아이스';

  @override
  Widget build(BuildContext context) {
    final data = _selected;

    final String name = data['menu_name'] ?? '이름 없음';
    final String brandName = data['brand_name'] ?? '-';
    final String imageUrl = data['image_url'] ?? '';
    final String description = data['description'] ?? '';
    final List<String> allergyList = data['allergies'] != null
        ? List<String>.from(data['allergies'])
        : [];
    final String allergyText = allergyList.isEmpty ? '알러지 성분 없음' : allergyList.join(', ');

    num? toNum(dynamic v) => v == null ? null : num.tryParse(v.toString());
    final num? calories = toNum(data['calories']);
    final num? sugar = toNum(data['sugar']);
    final num? protein = toNum(data['protein']);
    final num? sodium = toNum(data['sodium']);
    final num? satFat = toNum(data['saturated_fat']);
    final num? caffeine = toNum(data['caffeine']);
    final String sizeStandard = data['size_standard'] ?? '-';

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

                  if (_availableTemperatures.length > 1) ...[
                    const SizedBox(height: 16),
                    _buildTemperatureToggle(),
                  ],

                  if (_sizesForSelectedTemperature.length > 1) ...[
                    const SizedBox(height: 12),
                    _buildSizeSelector(),
                  ],

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
                      _buildInfoBox('칼로리', _formatNutrition(calories, 'kcal')),
                      _buildInfoBox('단백질', _formatNutrition(protein, 'g')),
                      _buildInfoBox('나트륨', _formatNutrition(sodium, 'mg')),
                      _buildInfoBox('포화지방', _formatNutrition(satFat, 'g')),
                      _buildInfoBox('카페인', _formatNutrition(caffeine, 'mg')),
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

  // 위젯: 핫/아이스 토글
  Widget _buildTemperatureToggle() {
    return Row(
      children: _availableTemperatures.map((temp) {
        final bool isSelected = _selected['temperature'] == temp;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(_temperatureLabel(temp)),
            selected: isSelected,
            onSelected: (_) => _selectTemperature(temp),
            selectedColor: const Color(0xFF7BF15B),
            backgroundColor: const Color(0xFFF5F5F5),
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'KoPubDotum',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isSelected ? const Color(0xFF7BF15B) : Colors.black12),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 위젯: 사이즈 선택 (최대 3개)
  Widget _buildSizeSelector() {
    return Row(
      children: _sizesForSelectedTemperature.map((variant) {
        final bool isSelected = variant['size_label'] == _selected['size_label'];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(variant['size_label']?.toString() ?? ''),
            selected: isSelected,
            onSelected: (_) => _selectSize(variant),
            selectedColor: const Color(0xFFFFE586),
            backgroundColor: const Color(0xFFF5F5F5),
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'KoPubDotum',
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isSelected ? const Color(0xFFFFE586) : Colors.black12),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 위젯: 당류 강조 카드
  Widget _buildSugarHighlightCard(num? sugar, Map<String, Color> colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors['bg'],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors['text']!.withValues(alpha: 0.3)),
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
                _formatNutrition(sugar, 'g'),
                style: TextStyle(
                  color: colors['text'],
                  fontSize: sugar == null ? 20 : 32,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'KoPubDotum',
                ),
              ),
            ],
          ),
          Icon(
            Icons.water_drop_rounded, // 당류 느낌의 아이콘
            size: 40,
            color: colors['text']!.withValues(alpha: 0.5),
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
