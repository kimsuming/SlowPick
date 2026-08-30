import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:slowpick/models/blood_sugar_record.dart';
import 'package:slowpick/widget/blood_sugar_graph.dart';
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

class _BloodSugarNoteState extends State<BloodSugarNote> {
  static const Color _accent = Color(0xFF10B981);
  static const Color _textDark = Color(0xFF242526);
  static const Color _muted = Color(0xFF9A9A9A);
  static const String _defaultNoteTitle = '거부기의 혈당 노트';

  List<BloodSugarRecord> _records = [];
  bool _isLoading = true;
  String? _error;
  int _selectedDateIndex = 0;
  final Set<int> _deletingIds = {};
  final Set<String> _savingFollowupKeys = {};
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
      final parsed = raw.map(BloodSugarRecord.fromJson).toList()
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

  List<DateTime> _recordDates([List<BloodSugarRecord>? source]) {
    final list = source ?? _records;
    final set = <DateTime>{for (final r in list) r.day};
    return set.toList()..sort();
  }

  Future<void> _deleteRecord(BloodSugarRecord record) async {
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

  Future<void> _editFollowup(BloodSugarRecord record, int offsetMinutes) async {
    final controller = TextEditingController(
      text: record.followups[offsetMinutes]?.bloodSugar.toString() ?? '',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$offsetMinutes분 후 혈당 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '예: 132', suffixText: 'mg/dL'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null) return;
              Navigator.pop(ctx, value);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (result == null) return;

    final key = '${record.id}_$offsetMinutes';
    setState(() => _savingFollowupKeys.add(key));
    try {
      await BloodSugarService.addFollowup(
        recordId: record.id,
        offsetMinutes: offsetMinutes,
        bloodSugar: result,
      );
      if (!mounted) return;
      setState(() {
        record.followups[offsetMinutes] =
            BloodSugarFollowup(bloodSugar: result, recordedAt: DateTime.now());
        _savingFollowupKeys.remove(key);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingFollowupKeys.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장에 실패했어요. ($e)')),
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
        BloodSugarGraph(records: _records),
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

  // 혈당 기록 카드 위젯
  Widget _recordTile(Size size, BloodSugarRecord record) {
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
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final offset in const [30, 60, 120])
                          _followupChip(record, offset),
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

  // 30/60/120분 후 혈당 입력 칩
  Widget _followupChip(BloodSugarRecord record, int offsetMinutes) {
    final entry = record.followups[offsetMinutes];
    final saving =
        _savingFollowupKeys.contains('${record.id}_$offsetMinutes');
    final due = DateTime.now()
        .isAfter(record.recordedAt.add(Duration(minutes: offsetMinutes)));

    if (saving) {
      return _chipShell(
        label: '저장 중',
        background: const Color(0xFFF5F5F5),
        border: const Color(0xFFE0E0E0),
        textColor: _muted,
        trailing: const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }

    if (entry != null) {
      return _chipShell(
        label: '$offsetMinutes분후 ${entry.bloodSugar}',
        background: const Color(0xFFF0FDF0),
        border: const Color(0xFFCCEFCC),
        textColor: const Color(0xFF187100),
      );
    }

    if (due) {
      return GestureDetector(
        onTap: () => _editFollowup(record, offsetMinutes),
        child: _chipShell(
          label: '$offsetMinutes분 후 입력',
          background: Colors.white,
          border: _accent,
          textColor: _accent,
        ),
      );
    }

    return _chipShell(
      label: '$offsetMinutes분 후',
      background: const Color(0xFFFAFAFA),
      border: const Color(0xFFEDEDED),
      textColor: const Color(0xFFBBBBBB),
    );
  }

  Widget _chipShell({
    required String label,
    required Color background,
    required Color border,
    required Color textColor,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing,
          ],
        ],
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
