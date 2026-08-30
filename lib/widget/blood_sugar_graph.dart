import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:slowpick/models/blood_sugar_record.dart';

// bloodSugarNote.dart의 혈당 추이 그래프를 다른 화면(blood_sugar_note_screen 등)에서도
// 재사용할 수 있도록 뽑아낸 위젯. records는 오래된 순(오름차순)으로 전달해야 한다.
class BloodSugarGraph extends StatefulWidget {
  final List<BloodSugarRecord> records;
  final int initialCount;
  // false면 +/- 표시 개수 조절 버튼 없이 initialCount개만 고정으로 보여준다.
  final bool adjustable;

  const BloodSugarGraph({
    super.key,
    required this.records,
    this.initialCount = 6,
    this.adjustable = true,
  });

  @override
  State<BloodSugarGraph> createState() => _BloodSugarGraphState();
}

class _BloodSugarGraphState extends State<BloodSugarGraph> {
  static const Color _accent = Color(0xFF10B981);
  static const Color _muted = Color(0xFF9A9A9A);

  late int _graphCount;

  @override
  void initState() {
    super.initState();
    _graphCount = widget.initialCount.clamp(
      1,
      widget.records.isEmpty ? 1 : widget.records.length,
    );
  }

  List<BloodSugarRecord> get _graphRecords {
    final total = widget.records.length;
    final count = _graphCount.clamp(1, total);
    return widget.records.sublist(total - count);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(15, 4, 15, 0),
        child: Container(
          height: 190,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(width: 1, color: const Color(0xFFEDEDED)),
          ),
          child: const Text(
            '아직 표시할 혈당 기록이 없어요',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
        ),
      );
    }

    final spots = _graphRecords;
    final total = widget.records.length;
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
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < spots.length; i++)
                          FlSpot(i.toDouble(), spots[i].bloodSugar.toDouble()),
                      ],
                      curveSmoothness: 0.2,
                      isCurved: true,
                      color: _accent,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
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
            if (widget.adjustable) ...[
              const SizedBox(height: 6),
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
}
