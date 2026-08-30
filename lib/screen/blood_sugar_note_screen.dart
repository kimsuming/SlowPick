import 'package:flutter/material.dart';
import 'package:slowpick/models/blood_sugar_record.dart';
import 'package:slowpick/screen/mainNote.dart';
import 'package:slowpick/service/blood_sugar_service.dart';
import 'package:slowpick/widget/blood_sugar_graph.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

// blood_sugar_check_record.dart에서 "완료"를 눌러 기록을 저장한 직후 보여주는 결과 화면.
// 저장은 이미 check_record 쪽에서 끝난 상태로 넘어오므로, 여기서는 서버에 반영된
// 최신 기록을 다시 불러와 보여주기만 한다. 이전 단계(기록 입력 폼)로 되돌아갈 이유가
// 없으므로 back 버튼 대신 하단 "완료" 버튼으로 노트 홈(mainNote)까지 스택을 정리하고 나간다.
class BloodSugarNoteScreen extends StatefulWidget {
  const BloodSugarNoteScreen({super.key});

  @override
  State<BloodSugarNoteScreen> createState() => _BloodSugarNoteScreenState();
}

class _BloodSugarNoteScreenState extends State<BloodSugarNoteScreen> {
  static const Color _textColor = Color(0xFF242526);
  static const Color _muted = Color(0xFF9A9A9A);

  List<BloodSugarRecord> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final raw = await BloodSugarService.fetchRecords();
      final parsed = raw.map(BloodSugarRecord.fromJson).toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      if (!mounted) return;
      setState(() {
        _records = parsed;
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

  Color _valueColor(int v) {
    if (v >= 180) return const Color(0xFFD40707);
    if (v >= 140) return const Color(0xFFF4AF31);
    return const Color(0xFF187100);
  }

  String _timingLabel(BloodSugarRecord r) {
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

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}년 $mm월 $dd일';
  }

  String _feedbackMessage(int latestValue) {
    if (latestValue >= 180) {
      return '혈당이 조금 높아요.\n식습관과 컨디션을 살펴봐 주세요.';
    }
    if (latestValue < 70) {
      return '혈당이 조금 낮아요.\n컨디션을 주의 깊게 살펴봐 주세요.';
    }
    return '혈당이 안정적인 범위예요.\n꾸준한 기록, 좋아요!';
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
            const Padding(
              padding: EdgeInsets.only(top: 22, left: 15, bottom: 15),
              child: Text(
                '거부기의 혈당 노트',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.24,
                ),
              ),
            ),

            Container(height: 1, color: const Color(0xFFEDEDED)),

            Expanded(child: _body()),

            _completeButton(),
          ],
        ),
      ),
    );
  }

  // mainNote로 돌아가며 그 사이에 쌓인 화면(브랜드 선택·촬영·검색·기록 입력 등)을 모두 정리한다.
  void _handleCompleteExit() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const mainNote()),
      (route) => false,
    );
  }

  Widget _completeButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GestureDetector(
        onTap: _handleCompleteExit,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(0.00, 0.50),
              end: Alignment(1.00, 0.50),
              colors: [Color(0xFFB5F369), Color(0xFF7BF15B)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              '완료',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
    if (_records.isEmpty) {
      return const Center(
        child: Text(
          '저장된 혈당 기록이 없어요.',
          style: TextStyle(color: _muted, fontSize: 15),
        ),
      );
    }

    final latest = _records.last;
    final todayRecords = _records.where((r) => r.day == latest.day).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final todayValues = todayRecords.map((r) => r.bloodSugar).toList();
    final highest = todayValues.reduce((a, b) => a > b ? a : b);
    final lowest = todayValues.reduce((a, b) => a < b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _formatDate(latest.recordedAt),
              style: const TextStyle(color: _textColor, fontSize: 16),
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              _feedbackMessage(latest.bloodSugar),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textColor,
                fontSize: 17,
                height: 1.35,
              ),
            ),
          ),

          const SizedBox(height: 18),

          BloodSugarGraph(records: _records, initialCount: 6, adjustable: false),

          const SizedBox(height: 8),

          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              '최근 6일간의 혈당 기록',
              style: TextStyle(color: Color(0xFF999999), fontSize: 14),
            ),
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: BloodSugarSummaryCard(
                  title: '오늘 최고 혈당',
                  value: highest,
                  valueColor: _valueColor(highest),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: BloodSugarSummaryCard(
                  title: '오늘 최저 혈당',
                  value: lowest,
                  valueColor: _valueColor(lowest),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          for (final record in todayRecords) ...[
            BloodSugarRecordTile(
              label: _timingLabel(record),
              value: record.bloodSugar,
              valueColor: _valueColor(record.bloodSugar),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class BloodSugarSummaryCard extends StatelessWidget {
  final String title;
  final int value;
  final Color valueColor;

  const BloodSugarSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF242526),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$value',
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: ' mg/dL',
                  style: TextStyle(
                    color: Color(0xFF242526),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BloodSugarRecordTile extends StatelessWidget {
  final String label;
  final int value;
  final Color valueColor;

  const BloodSugarRecordTile({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: 1.5,
          color: const Color(0xFFCCCCCC),
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFA9A9A9),
              fontSize: 17,
            ),
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$value',
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: ' mg/dL',
                  style: TextStyle(
                    color: Color(0xFF242526),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
