import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slowpick/service/api_client.dart';
import 'package:slowpick/service/user_service.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

class MypageInput extends StatefulWidget {
  const MypageInput({super.key});

  @override
  State<MypageInput> createState() => _MypageInputState();
}

class _MypageInputState extends State<MypageInput> {
  // ── 컨트롤러 ──────────────────────────────────────────────
  final _nicknameCtrl      = TextEditingController();
  final _heightCtrl        = TextEditingController();
  final _weightCtrl        = TextEditingController();
  final _targetWeightCtrl  = TextEditingController();

  // ── 당뇨 (선택없음 ↔ 나머지 상호배타) ───────────────────
  bool _diabetes1   = false;
  bool _diabetes2   = false;
  bool _diabetesPre = false;
  bool _diabetesNone = false;

  // ── 유제품 (섭취가능 ↔ 섭취불가능 상호배타, 유당불내증 독립) ──
  bool _dairyEdible    = false;
  bool _dairyInedible  = false;
  bool _lactose        = false;

  // ── 카페인 (섭취가능 ↔ 섭취불가능 상호배타) ─────────────
  bool _caffeineEdible   = false;
  bool _caffeineInedible = false;

  // ── 고카페인 위험군 (모두 독립 복수 선택) ──────────────
  bool _riskPregnant     = false;
  bool _riskHypertension = false;
  bool _riskMinor        = false;

  // ── 알러지 ───────────────────────────────────────────────
  List<String> _selectedAllergies  = [];
  List<String> _availableAllergens = [];

  // ── UI 상태 ───────────────────────────────────────────────
  bool _isLoading = true;
  bool _isSaving  = false;

  static const Color _green      = Color(0xFF74AE31);
  static const Color _lightGreen = Color(0xFF73AD31);
  static const Color _fieldFill  = Color(0xFFEDEDED);

  // ─────────────────────────────────────────────────────────
  // 생명주기
  // ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _heightCtrl.addListener(_onBodyChanged);
    _weightCtrl.addListener(_onBodyChanged);
    _loadData();
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // 데이터 로드
  // ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      final profileFuture  = UserService.fetchProfile();
      final allergenFuture = UserService.fetchMenuAllergens();

      final profile  = await profileFuture;
      final allergens = await allergenFuture;

      if (!mounted) return;
      setState(() {
        _availableAllergens = allergens;

        if (profile != null) {
          _nicknameCtrl.text = (profile['nickname'] as String?) ?? '';

          final h = profile['health'] as Map<String, dynamic>? ?? {};
          _diabetes1          = h['diabetes_type1']           == true;
          _diabetes2          = h['diabetes_type2']           == true;
          _diabetesPre        = h['diabetes_pre']             == true;
          _diabetesNone       = !_diabetes1 && !_diabetes2 && !_diabetesPre;
          _dairyEdible        = h['dairy_edible']             == true;
          _dairyInedible      = h['dairy_inedible']           == true;
          _lactose            = h['dairy_lactose_intolerant'] == true;
          _caffeineEdible     = h['caffeine_edible']          == true;
          _caffeineInedible   = h['caffeine_inedible']        == true;
          _riskPregnant       = h['risk_pregnant']            == true;
          _riskHypertension   = h['risk_hypertension']        == true;
          _riskMinor          = h['risk_minor']               == true;

          if (h['height_cm'] != null) {
            _heightCtrl.text = h['height_cm'].toString();
          }
          if (h['weight_kg'] != null) {
            _weightCtrl.text = h['weight_kg'].toString();
          }
          if (h['target_weight_kg'] != null) {
            _targetWeightCtrl.text = h['target_weight_kg'].toString();
          }

          _selectedAllergies =
              List<String>.from(profile['allergies'] ?? []);
        }

        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // 저장
  // ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await UserService.saveProfile({
        'nickname': _nicknameCtrl.text.trim(),
        'health': {
          'diabetes_type1':           _diabetes1,
          'diabetes_type2':           _diabetes2,
          'diabetes_pre':             _diabetesPre,
          'dairy_edible':             _dairyEdible,
          'dairy_inedible':           _dairyInedible,
          'dairy_lactose_intolerant': _lactose,
          'caffeine_edible':          _caffeineEdible,
          'caffeine_inedible':        _caffeineInedible,
          'risk_pregnant':            _riskPregnant,
          'risk_hypertension':        _riskHypertension,
          'risk_minor':               _riskMinor,
          'height_cm':    double.tryParse(_heightCtrl.text.trim()),
          'weight_kg':    double.tryParse(_weightCtrl.text.trim()),
          'target_weight_kg': double.tryParse(_targetWeightCtrl.text.trim()),
        },
        'allergies': _selectedAllergies,
      });
      _showSnack('저장되었습니다.', isError: false);
    } on UnauthorizedException {
      _showSnack('인증이 만료되었습니다. 다시 로그인해주세요.');
    } catch (e) {
      debugPrint('[저장 오류] $e');
      _showSnack('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // 체크박스 토글 (상호배타 로직 포함)
  // ─────────────────────────────────────────────────────────

  void _toggleDiabetes(String key) {
    setState(() {
      switch (key) {
        case 'type1':
          _diabetes1 = !_diabetes1;
          if (_diabetes1) _diabetesNone = false;
        case 'type2':
          _diabetes2 = !_diabetes2;
          if (_diabetes2) _diabetesNone = false;
        case 'pre':
          _diabetesPre = !_diabetesPre;
          if (_diabetesPre) _diabetesNone = false;
        case 'none':
          _diabetesNone = !_diabetesNone;
          if (_diabetesNone) {
            _diabetes1 = _diabetes2 = _diabetesPre = false;
          }
      }
    });
  }

  void _toggleDairy(String key) {
    setState(() {
      switch (key) {
        case 'edible':
          _dairyEdible = !_dairyEdible;
          if (_dairyEdible) _dairyInedible = false;   // 상호배타
        case 'inedible':
          _dairyInedible = !_dairyInedible;
          if (_dairyInedible) _dairyEdible = false;   // 상호배타
        case 'lactose':
          _lactose = !_lactose;                        // 독립 선택
      }
    });
  }

  void _toggleCaffeine(String key) {
    setState(() {
      switch (key) {
        case 'edible':
          _caffeineEdible = !_caffeineEdible;
          if (_caffeineEdible) _caffeineInedible = false;   // 상호배타
        case 'inedible':
          _caffeineInedible = !_caffeineInedible;
          if (_caffeineInedible) _caffeineEdible = false;   // 상호배타
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  // 알러지 토글
  // ─────────────────────────────────────────────────────────

  void _toggleAllergen(String allergen) {
    setState(() {
      if (_selectedAllergies.contains(allergen)) {
        _selectedAllergies.remove(allergen);
      } else {
        _selectedAllergies.add(allergen);
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  // BMI
  // ─────────────────────────────────────────────────────────

  void _onBodyChanged() => setState(() {});

  double? get _bmi {
    final h = double.tryParse(_heightCtrl.text.trim());
    final w = double.tryParse(_weightCtrl.text.trim());
    if (h == null || w == null || h <= 0) return null;
    return w / ((h / 100) * (h / 100));
  }

  // ─────────────────────────────────────────────────────────
  // 스낵바
  // ─────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : _green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 빌드
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      appBar: AppBar(
        title: const Text('내 정보 입력하기'),
        centerTitle: true,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Color(0xFF242526),
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontFamily: 'KoPubDotum',
          letterSpacing: -1.30,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _green),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileSection(),
                  _divider(),
                  _diabetesSection(),
                  _divider(),
                  _dairySection(),
                  _divider(),
                  _allergySection(),
                  _divider(),
                  _caffeineSection(),
                  _divider(),
                  _dietSection(),
                  _divider(),
                  _saveButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _divider() => Container(height: 8, color: const Color(0xFFF5F5F5));

  // ─────────────────────────────────────────────────────────
  // 섹션: 프로필
  // ─────────────────────────────────────────────────────────

  Widget _profileSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자유롭게 닉네임을 입력해주세요!',
            style: TextStyle(
              color: _lightGreen,
              fontSize: 12,
              fontFamily: 'KoPubDotum',
              fontWeight: FontWeight.w500,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '프로필',
            style: TextStyle(
              color: Color(0xFF242526),
              fontSize: 21,
              fontFamily: 'KoPubDotum',
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Image.asset(
              'images/myPage/profileImage.png',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 21),
          Center(
            child: Container(
              width: 188,
              height: 44,
              decoration: BoxDecoration(
                color: _fieldFill,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _nicknameCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'KoPubDotum',
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: '닉네임 입력',
                  hintStyle: TextStyle(
                    color: Color(0xFFBBBBBB),
                    fontSize: 16,
                    fontFamily: 'KoPubDotum',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 섹션: 당뇨 정보
  // 선택없음 ↔ 나머지 항목 상호배타
  // 1형·2형·전단계는 복수 선택 가능
  // ─────────────────────────────────────────────────────────

  Widget _diabetesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '건강 정보를 입력해서 맞춤 추천을 받아보아요!',
            style: TextStyle(
              color: _lightGreen,
              fontSize: 12,
              fontFamily: 'KoPubDotum',
              fontWeight: FontWeight.w500,
              letterSpacing: -1,
            ),
          ),
          _sectionTitle('당뇨 정보'),
          const SizedBox(height: 16),
          _checkbox('1형 당뇨',    _diabetes1,    () => _toggleDiabetes('type1')),
          _checkbox('2형 당뇨',    _diabetes2,    () => _toggleDiabetes('type2')),
          _checkbox('당뇨 전 단계', _diabetesPre,  () => _toggleDiabetes('pre')),
          _checkbox('선택 없음',   _diabetesNone, () => _toggleDiabetes('none')),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 섹션: 유제품 정보
  // 섭취가능 ↔ 섭취불가능 상호배타 / 유당불내증 독립
  // ─────────────────────────────────────────────────────────

  Widget _dairySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 27),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('유제품 정보'),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '* 유당불내증은 사람마다 반응이 달라요.\n   선택 시 참고 정보로만 활용돼요.',
                  style: TextStyle(
                    color: _lightGreen,
                    fontSize: 12,
                    fontFamily: 'KoPubDotum',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _checkbox('섭취 가능',  _dairyEdible,   () => _toggleDairy('edible')),
          _checkbox('섭취 불가능', _dairyInedible, () => _toggleDairy('inedible')),
          _checkbox('유당불내증', _lactose,        () => _toggleDairy('lactose'),
              hint: '(독립 선택 가능)'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 섹션: 알러지 정보
  // ─────────────────────────────────────────────────────────

  Widget _allergySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 27),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('알러지 정보'),
          const SizedBox(height: 14),
          if (_availableAllergens.isEmpty)
            const Text(
              '알러지 목록을 불러오는 중...',
              style: TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 13,
                fontFamily: 'KoPubDotum',
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableAllergens
                  .map((a) => _allergenToggleChip(a))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 섹션: 카페인 정보
  // 섭취가능 ↔ 섭취불가능 상호배타
  // ─────────────────────────────────────────────────────────

  Widget _caffeineSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 27),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('카페인 정보'),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '* 카페인은 사람에 따라 영향을 다르게 줄 수 있어요.\n   선택 시 참고 정보로만 활용돼요.',
                  style: TextStyle(
                    color: _lightGreen,
                    fontSize: 12,
                    fontFamily: 'KoPubDotum',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _checkbox('섭취 가능',  _caffeineEdible,   () => _toggleCaffeine('edible')),
          _checkbox('섭취 불가능', _caffeineInedible, () => _toggleCaffeine('inedible')),
          const SizedBox(height: 28),
          _sectionTitle('고카페인 정보'),
          const SizedBox(height: 16),
          _checkbox('임신 / 임신 가능성', _riskPregnant,
              () => setState(() => _riskPregnant = !_riskPregnant)),
          _checkbox('고혈압 및 기타 질환', _riskHypertension,
              () => setState(() => _riskHypertension = !_riskHypertension)),
          _checkbox('미성년자', _riskMinor,
              () => setState(() => _riskMinor = !_riskMinor)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 섹션: 다이어트 정보
  // ─────────────────────────────────────────────────────────

  Widget _dietSection() {
    final bmi = _bmi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 27),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('다이어트 정보'),
          const SizedBox(height: 22),

          Row(
            children: [
              // 신장 / 체중 입력
              Column(
                children: [
                  _numberField(_heightCtrl, '신장 (cm)'),
                  const SizedBox(height: 7),
                  _numberField(_weightCtrl, '체중 (kg)'),
                ],
              ),
              const SizedBox(width: 8),

              // BMI 표시
              Container(
                width: 160,
                height: 81,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      width: 1.5, color: const Color(0xFFEDEDED)),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '나의 BMI',
                      style: TextStyle(
                        color: Color(0xFFA9A9A9),
                        fontSize: 13,
                        fontFamily: 'KoPubDotum',
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      bmi != null ? bmi.toStringAsFixed(1) : '--',
                      style: TextStyle(
                        color: bmi != null
                            ? _bmiColor(bmi)
                            : const Color(0xFFA9A9A9),
                        fontSize: 30,
                        fontFamily: 'KoPubDotum',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 목표 체중
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '목표 체중 : ',
                style: TextStyle(
                  color: Color(0xFF242526),
                  fontSize: 15,
                  fontFamily: 'KoPubDotum',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(
                width: 90,
                height: 36,
                child: TextField(
                  controller: _targetWeightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,3}\.?\d{0,1}')),
                  ],
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'KoPubDotum',
                  ),
                  decoration: InputDecoration(
                    hintText: 'kg',
                    hintStyle: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: _fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 저장 버튼 (하단)
  // ─────────────────────────────────────────────────────────

  Widget _saveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 12),
      child: GestureDetector(
        onTap: _isSaving ? null : _save,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: _isSaving
                ? const LinearGradient(
                    colors: [Color(0xFFCCCCCC), Color(0xFFCCCCCC)])
                : const LinearGradient(
                    colors: [Color(0xFF81DB60), Color(0xFFBCEC81)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  '저장',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontFamily: 'KoPubDotum',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 공용 위젯 헬퍼
  // ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF242526),
        fontSize: 21,
        fontFamily: 'KoPubDotum',
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
    );
  }

  Widget _checkbox(String label, bool value, VoidCallback onTap,
      {String? hint}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(
              value
                  ? Icons.check_box_outlined
                  : Icons.check_box_outline_blank,
              size: 20,
              color: value ? _green : const Color(0xFFCCCCCC),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF242526),
                fontSize: 17,
                fontFamily: 'KoPubDotum',
                fontWeight: FontWeight.w500,
                letterSpacing: -1,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(width: 6),
              Text(
                hint,
                style: const TextStyle(
                  color: Color(0xFF73AD31),
                  fontSize: 11,
                  fontFamily: 'KoPubDotum',
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _allergenToggleChip(String allergen) {
    final isSelected = _selectedAllergies.contains(allergen);
    return GestureDetector(
      onTap: () => _toggleAllergen(allergen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: ShapeDecoration(
          color: isSelected ? const Color(0xFFF6FFE4) : Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: isSelected ? const Color(0xFFB8DE8D) : const Color(0xFFDDDDDD),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Text(
          allergen,
          style: TextStyle(
            color: isSelected ? _lightGreen : const Color(0xFF888888),
            fontSize: 13,
            fontFamily: 'KoPubDotum',
            fontWeight: FontWeight.w500,
            letterSpacing: -0.24,
          ),
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController ctrl, String hint) {
    return Container(
      width: 160,
      height: 37,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1.5, color: const Color(0xFFEDEDED)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(r'^\d{0,3}\.?\d{0,1}')),
        ],
        style: const TextStyle(
          fontSize: 13,
          fontFamily: 'KoPubDotum',
          fontWeight: FontWeight.w500,
          color: Color(0xFF242526),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFA9A9A9),
            fontSize: 13,
            fontFamily: 'KoPubDotum',
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        ),
      ),
    );
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blueAccent;
    if (bmi < 23.0) return _green;
    if (bmi < 25.0) return Colors.orange;
    return Colors.redAccent;
  }
}
