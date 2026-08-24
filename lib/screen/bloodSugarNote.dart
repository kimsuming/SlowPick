import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/screen/bloodSugarDrinkSelect.dart';
import 'package:slowpick/screen/mainNote.dart';
import 'package:slowpick/service/blood_sugar_service.dart';
import 'package:slowpick/service/note_title_service.dart';

class BloodSugarNote extends StatefulWidget {
  const BloodSugarNote({super.key});

  @override
  State<BloodSugarNote> createState() => _BloodSugarNoteState();
}

class _BloodSugarRecord {
  final int id;
  final int? menuId;
  final String? menuName;
  final String? brandName;
  final String? imageUrl;
  final String mealTiming;
  final bool medication;
  final String exercise;
  final int bloodSugar;
  final DateTime recordedAt;

  _BloodSugarRecord({
    required this.id,
    required this.menuId,
    required this.menuName,
    required this.brandName,
    required this.imageUrl,
    required this.mealTiming,
    required this.medication,
    required this.exercise,
    required this.bloodSugar,
    required this.recordedAt,
  });

  factory _BloodSugarRecord.fromJson(Map<String, dynamic> json) {
    return _BloodSugarRecord(
      id: json['id'] as int,
      menuId: json['menu_id'] as int?,
      menuName: json['menu_name'] as String?,
      brandName: json['brand_name'] as String?,
      imageUrl: json['image_url'] as String?,
      mealTiming: json['meal_timing'] as String? ?? 'fasting',
      medication: json['medication'] == true || json['medication'] == 1,
      exercise: json['exercise'] as String? ?? 'none',
      bloodSugar: (json['blood_sugar'] as num).toInt(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  DateTime get day =>
      DateTime(recordedAt.year, recordedAt.month, recordedAt.day);
}

class _BloodSugarNoteState extends State<BloodSugarNote> {
  static const Color _accent = Color(0xFF10B981);
  static const Color _textDark = Color(0xFF242526);
  static const Color _muted = Color(0xFF9A9A9A);
  static const String _defaultNoteTitle = '거부기의 혈당 노트';

  List<_BloodSugarRecord> _records = [];
  bool _isLoading = true;
  String? _error;
  int _graphCount = 6;
  int _selectedDateIndex = 0;
  final Set<int> _deletingIds = {};
  String _noteTitleText = _defaultNoteTitle;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _loadNoteTitle();
  }

  Future<void> _loadNoteTitle() async {
    try {
      final title = await NoteTitleService.fetchTitle(
        NoteTitleService.bloodSugarNoteKey,
        fallback: _defaultNoteTitle,
      );
      if (!mounted) return;
      setState(() => _noteTitleText = title);
    } catch (_) {
      // 노트 이름 로딩 실패 시 기본 이름을 그대로 둔다.
    }
  }

  Future<void> _editNoteTitle() async {
    final controller = TextEditingController(text: _noteTitleText);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('노트 이름 편집'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(hintText: '노트 이름을 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx, text);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (result == null || result == _noteTitleText) return;

    final previous = _noteTitleText;
    setState(() => _noteTitleText = result);
    try {
      await NoteTitleService.updateTitle(
          NoteTitleService.bloodSugarNoteKey, result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _noteTitleText = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('노트 이름 저장에 실패했어요. ($e)')),
      );
    }
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final raw = await BloodSugarService.fetchRecords();
      final parsed = raw.map(_BloodSugarRecord.fromJson).toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      if (!mounted) return;
      setState(() {
        _records = parsed;
        final dates = _recordDates(parsed);
        _selectedDateIndex = dates.isEmpty ? 0 : dates.length - 1;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<DateTime> _recordDates([List<_BloodSugarRecord>? source]) {
    final list = source ?? _records;
    final set = <DateTime>{for (final r in list) r.day};
    return set.toList()..sort();
  }

  Future<void> _deleteRecord(_BloodSugarRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('기록 삭제'),
        content: const Text('이 혈당 기록을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deletingIds.add(record.id));
    try {
      await BloodSugarService.deleteRecord(record.id);
      if (!mounted) return;
      setState(() {
        _records.removeWhere((r) => r.id == record.id);
        _deletingIds.remove(record.id);
        final dates = _recordDates();
        if (_selectedDateIndex >= dates.length) {
          _selectedDateIndex = dates.isEmpty ? 0 : dates.length - 1;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(record.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제에 실패했어요. ($e)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: Container(
        //바텀 바
        color: const Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),

      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              RefreshIndicator(
                color: _accent,
                onRefresh: _loadRecords,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _noteTitle(),

                      Container(height: 1, color: const Color(0xFFEDEDED)),

                      const SizedBox(height: 13),

                      _body(size),

                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),

              //기록 추가하기 버튼
              Positioned(
                bottom: 20, // 바텀바 위로 띄움
                left: 0,
                right: 0,
                child: Center(child: _addButton(size)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(Size size) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 90),
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              '기록을 불러오지 못했어요.\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadRecords,
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (_records.isEmpty) {
      return _emptyState();
    }

    return Column(
      children: [
        _bloodSugarGraph(),
        _todayBloodSugarContent(size),
      ],
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 30),
      child: Column(
        children: [
          Image.asset(
            'images/bloodSugarNote/bloodDrop.png',
            width: 48,
            color: const Color(0xFFCFCFCF),
          ),
          const SizedBox(height: 16),
          const Text(
            '아직 혈당 기록이 없어요',
            style: TextStyle(
              color: _textDark,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '첫 혈당을 기록하고 변화를 확인해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _addButton(Size size) {
    return Container(
      width: size.width * 0.43,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.00, 0.50),
          end: Alignment(1.00, 0.50),
          colors: [Color(0xFFB5F369), Color(0xFF7BF15B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 5,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),

      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BloodSugarDrinkSelect(),
          ),
        ).then((_) => _loadRecords()),
        child: const Align(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white, size: 30),
              Text(
                '기록 추가하기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.57,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 노트 제목 위젯
  Widget _noteTitle() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.only(top: 22, left: 15.0, bottom: 15.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const mainNote()),
              ),
              child: const Icon(Icons.arrow_back),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                _noteTitleText,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.24,
                ),
              ),
            ),

            const SizedBox(width: 3),

            GestureDetector(
              onTap: _editNoteTitle,
              child: const Icon(Icons.edit, color: Color(0xFF197100)),
            ),
          ],
        ),
      ),
    );
  }

  // 그래프에 표시할 최근 N개 기록 (오름차순 = 왼쪽이 과거)
  List<_BloodSugarRecord> get _graphRecords {
    final total = _records.length;
    final count = _graphCount.clamp(1, total);
    return _records.sublist(total - count);
  }

  // 혈당 그래프 위젯
  Widget _bloodSugarGraph() {
    final spots = _graphRecords;
    final total = _records.length;
    final displayedCount = spots.length;
    final minStep = total < 2 ? total : 2;
    final canDecrease = displayedCount > minStep;
    final canIncrease = displayedCount < total;

    final values = spots.map((r) => r.bloodSugar.toDouble()).toList();
    final rawMin = values.reduce((a, b) => a < b ? a : b);
    final rawMax = values.reduce((a, b) => a > b ? a : b);
    final pad = ((rawMax - rawMin) * 0.3).clamp(10, 40);
    double minY = (((rawMin - pad) / 10).floor() * 10).toDouble();
    double maxY = (((rawMax + pad) / 10).ceil() * 10).toDouble();
    if (minY < 0) minY = 0;
    if (maxY - minY < 20) maxY = minY + 20;
    final interval = ((maxY - minY) / 4).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 4, 15, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 18, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(width: 1, color: const Color(0xFFEDEDED)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  minX: -0.5,
                  maxX: (spots.length - 1).clamp(1, 1 << 30).toDouble() + 0.5,
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Color(0xFFF2F2F2), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: interval,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          fitInside:
                              SideTitleFitInsideData.fromTitleMeta(meta),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                                color: Color(0xFFAAAAAA), fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final idx = value.round();
                          if (idx < 0 || idx >= spots.length) {
                            return const SizedBox.shrink();
                          }
                          final d = spots[idx].recordedAt;
                          return SideTitleWidget(
                            meta: meta,
                            fitInside:
                                SideTitleFitInsideData.fromTitleMeta(meta),
                            child: Text(
                              '${d.month}/${d.day}',
                              style: const TextStyle(
                                  color: Color(0xFFAAAAAA), fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => _accent,
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                        final r = spots[s.x.toInt()];
                        return LineTooltipItem(
                          '${r.bloodSugar} mg/dL\n${r.recordedAt.month}/${r.recordedAt.day}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    // 차트 선
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < spots.length; i++)
                          FlSpot(i.toDouble(), spots[i].bloodSugar.toDouble()),
                      ],
                      curveSmoothness: 0.2,
                      isCurved: true, // 차트 선이 꺾은선(false), 부드러운 선(true)
                      color: _accent,
                      barWidth: 2.5, // 차트 선 굵기
                      isStrokeCapRound: true, // 차트 선의 처음과 끝을 둥글게 처리
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: _accent,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        // 차트 선 하단 공간 명암
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _accent.withValues(alpha: 0.25),
                            _accent.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 그래프에 표시할 기록 개수 조절
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _graphStepButton(
                  Icons.remove,
                  canDecrease,
                  () => setState(() => _graphCount =
                      (displayedCount - 2).clamp(minStep, total)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '최근 $displayedCount개 기록',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _graphStepButton(
                  Icons.add,
                  canIncrease,
                  () => setState(() => _graphCount =
                      (displayedCount + 2).clamp(minStep, total)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _graphStepButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? const Color(0xFFEAFBEA) : const Color(0xFFF5F5F5),
          border: Border.all(
            color: enabled ? _accent : const Color(0xFFE0E0E0),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? _accent : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }

  Widget _todayBloodSugarContent(Size size) {
    final dates = _recordDates();
    final selectedDate = dates[_selectedDateIndex.clamp(0, dates.length - 1)];
    final dayRecords = _records.where((r) => r.day == selectedDate).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    final values = dayRecords.map((r) => r.bloodSugar).toList();
    final highest = values.isEmpty
        ? null
        : values.reduce((a, b) => a > b ? a : b);
    final lowest =
        values.isEmpty ? null : values.reduce((a, b) => a < b ? a : b);

    return Container(
      child: Column(
        children: [
          const SizedBox(height: 14),

          // 날짜 선택 위젯
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _selectedDateIndex > 0
                    ? () => setState(() => _selectedDateIndex--)
                    : null,
                child: Icon(
                  Icons.arrow_left,
                  color: _selectedDateIndex > 0
                      ? _textDark
                      : const Color(0xFFDDDDDD),
                ),
              ),
              Text(
                _formatDate(selectedDate),
                style: const TextStyle(
                  color: _textDark,
                  fontFamily: 'KoPubDotum Medium',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: _selectedDateIndex < dates.length - 1
                    ? () => setState(() => _selectedDateIndex++)
                    : null,
                child: Icon(
                  Icons.arrow_right,
                  color: _selectedDateIndex < dates.length - 1
                      ? _textDark
                      : const Color(0xFFDDDDDD),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryCard(size, '최고 혈당', highest, const Color(0xFFDB6B6B)),
              _summaryCard(size, '최저 혈당', lowest, const Color(0xFF6E8FDE)),
            ],
          ),

          const SizedBox(height: 23),

          for (final r in dayRecords) _recordTile(size, r),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}년 $mm월 $dd일';
  }

  // 최고/최저 혈당 요약 위젯
  Widget _summaryCard(Size size, String title, int? value, Color color) {
    return Container(
      width: size.width * 0.4,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/bloodSugarNote/bloodDrop.png',
                width: 15,
                fit: BoxFit.cover,
                color: color,
              ),

              const SizedBox(width: 3),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.45,
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value == null ? '- ' : '$value ',
                style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontFamily: 'Clipartkorea TTF',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.96,
                ),
              ),

              const Text(
                'mg/dL',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 20,
                  fontFamily: 'Clipartkorea TTF',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _valueColor(int v) {
    if (v >= 180) return const Color(0xFFD40707);
    if (v >= 140) return const Color(0xFFF4AF31);
    return const Color(0xFF187100);
  }

  String _timingLabel(_BloodSugarRecord r) {
    final h = r.recordedAt.hour;
    final String period;
    if (h < 11) {
      period = '아침';
    } else if (h < 17) {
      period = '점심';
    } else if (h < 21) {
      period = '저녁';
    } else {
      period = '밤';
    }

    final String meal;
    switch (r.mealTiming) {
      case 'before_meal':
        meal = '식전';
        break;
      case 'after_meal':
        meal = '식후';
        break;
      default:
        meal = '공복';
    }

    final hh = r.recordedAt.hour.toString().padLeft(2, '0');
    final mm = r.recordedAt.minute.toString().padLeft(2, '0');
    return '$period $meal $hh:$mm';
  }

  // 혈당 기록 카드 위젯
  Widget _recordTile(Size size, _BloodSugarRecord record) {
    final deleting = _deletingIds.contains(record.id);
    final valueColor = _valueColor(record.bloodSugar);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Container(
        width: size.width * 0.9,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(width: 1.2, color: const Color(0xFFE5E5E5)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 42,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: valueColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(width: 12),

            if (record.menuName != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 40,
                  height: 40,
                  color: const Color(0xFFF1F1F1),
                  child: (record.imageUrl?.isNotEmpty ?? false)
                      ? CachedNetworkImage(
                          imageUrl: record.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.coffee,
                            size: 18,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(Icons.coffee, size: 18, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 10),
            ],

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.menuName != null)
                    Text(
                      record.menuName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  Text(
                    _timingLabel(record),
                    style: const TextStyle(
                      color: Color(0xFFA9A9A9),
                      fontSize: 14,
                      fontFamily: 'KoPubDotum Medium',
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.42,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${record.bloodSugar}',
                        style: TextStyle(
                          color: valueColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.72,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'mg/dL',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (record.medication || record.exercise != 'none')
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (record.medication) const _RecordBadge(text: '투약'),
                          if (record.exercise != 'none')
                            _RecordBadge(
                              text: record.exercise == 'intense'
                                  ? '격한운동'
                                  : '가벼운운동',
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            GestureDetector(
              onTap: deleting ? null : () => _deleteRecord(record),
              child: deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Image.asset(
                      'images/bloodSugarNote/cancel.png',
                      width: 18,
                      fit: BoxFit.contain,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordBadge extends StatelessWidget {
  final String text;
  const _RecordBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF187100),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
