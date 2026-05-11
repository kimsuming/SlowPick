import 'package:flutter/material.dart';
import 'package:slowpick/screen/confirm_signup_screen.dart';
import 'package:slowpick/service/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();

  bool _obscurePw = true;
  bool _obscurePwConfirm = true;
  bool _isLoading = false;

  bool _step1Done = false;
  bool _step2Done = false;
  bool _step3Done = false;

  bool get _allDone => _step1Done && _step2Done && _step3Done;

  static const _pointColor = Color(0xFF74AE31);
  static const _fieldFill = Color(0xFFF2F2F2);
  static const _hintColor = Color(0xFFAAAAAA);

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_updateSteps);
    _passwordCtrl.addListener(_updateSteps);
    _passwordConfirmCtrl.addListener(_updateSteps);
    _nicknameCtrl.addListener(_updateSteps);
  }

  void _updateSteps() {
    setState(() {
      _step1Done = _validateEmail(_emailCtrl.text) == null;
      _step2Done = _validatePassword(_passwordCtrl.text) == null &&
          _validatePasswordConfirm(_passwordConfirmCtrl.text) == null;
      _step3Done = _validateNickname(_nicknameCtrl.text) == null;
    });
  }

  @override
  void dispose() {
    _emailCtrl.removeListener(_updateSteps);
    _passwordCtrl.removeListener(_updateSteps);
    _passwordConfirmCtrl.removeListener(_updateSteps);
    _nicknameCtrl.removeListener(_updateSteps);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  // ─── 유효성 검사 ───────────────────────────────────────

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return '이메일을 입력해주세요.';
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(v.trim())) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return '비밀번호를 입력해주세요.';
    if (v.length < 8) return '비밀번호는 최소 8자 이상이어야 합니다.';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~]').hasMatch(v)) {
      return '특수문자를 1개 이상 포함해야 합니다.';
    }
    return null;
  }

  String? _validatePasswordConfirm(String? v) {
    if (v == null || v.isEmpty) return '비밀번호 확인을 입력해주세요.';
    if (v != _passwordCtrl.text) return '비밀번호가 일치하지 않습니다.';
    return null;
  }

  String? _validateNickname(String? v) {
    if (v == null || v.trim().isEmpty) return '닉네임을 입력해주세요.';
    return null;
  }

  // ─── 회원가입 요청 ──────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.instance.signUp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      nickname: _nicknameCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmSignupScreen(email: _emailCtrl.text.trim()),
        ),
      );
    } else {
      _showError(result.errorMessage!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── UI ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          '회원가입',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontFamily: 'KoPubDotum',
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // 단계 안내
                _buildStepIndicator(),

                const SizedBox(height: 32),

                // 이메일
                _buildLabel('이메일'),
                const SizedBox(height: 6),
                _buildFormField(
                  controller: _emailCtrl,
                  hint: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),

                const SizedBox(height: 20),

                // 비밀번호
                _buildLabel('비밀번호'),
                const SizedBox(height: 4),
                _buildPasswordHint(),
                const SizedBox(height: 6),
                _buildFormField(
                  controller: _passwordCtrl,
                  hint: '비밀번호 입력',
                  obscure: _obscurePw,
                  validator: _validatePassword,
                  suffix: _visibilityToggle(
                    visible: !_obscurePw,
                    onTap: () => setState(() => _obscurePw = !_obscurePw),
                  ),
                ),

                const SizedBox(height: 20),

                // 비밀번호 확인
                _buildLabel('비밀번호 확인'),
                const SizedBox(height: 6),
                _buildFormField(
                  controller: _passwordConfirmCtrl,
                  hint: '비밀번호 재입력',
                  obscure: _obscurePwConfirm,
                  validator: _validatePasswordConfirm,
                  suffix: _visibilityToggle(
                    visible: !_obscurePwConfirm,
                    onTap: () => setState(
                        () => _obscurePwConfirm = !_obscurePwConfirm),
                  ),
                ),

                const SizedBox(height: 20),

                // 닉네임
                _buildLabel('닉네임'),
                const SizedBox(height: 6),
                _buildFormField(
                  controller: _nicknameCtrl,
                  hint: '앱에서 사용할 이름',
                  validator: _validateNickname,
                ),

                const SizedBox(height: 36),

                // 회원가입 버튼
                _buildGradientButton(),

                const SizedBox(height: 20),

                // 로그인 화면으로
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: const TextSpan(
                        text: '이미 계정이 있으신가요?  ',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 13,
                          fontFamily: 'KoPubDotum',
                        ),
                        children: [
                          TextSpan(
                            text: '로그인',
                            style: TextStyle(
                              color: _pointColor,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: _pointColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 위젯 헬퍼 ───────────────────────────────────────────

  Widget _buildStepIndicator() {
    final steps = [_step1Done, _step2Done, _step3Done];
    const labels = ['이메일 작성', '비밀번호 확인', '닉네임 작성'];
    final doneCount = steps.where((s) => s).length;
    final nextIdx = steps.indexWhere((s) => !s);
    final currentLabel = nextIdx >= 0 ? labels[nextIdx] : '모두 완료';

    return Row(
      children: [
        ...List.generate(3, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: steps[i] ? _pointColor : const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        Text(
          '$doneCount / 3  $currentLabel',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
            fontFamily: 'KoPubDotum',
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontFamily: 'KoPubDotum',
        fontWeight: FontWeight.w500,
        color: Color(0xFF555555),
      ),
    );
  }

  Widget _buildPasswordHint() {
    return const Text(
      '8자 이상, 특수문자(!@#\$ 등) 1개 이상 포함',
      style: TextStyle(
        fontSize: 11,
        color: _hintColor,
        fontFamily: 'KoPubDotum',
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
        fontSize: 15,
        fontFamily: 'KoPubDotum',
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: _hintColor,
          fontSize: 15,
          fontFamily: 'KoPubDotum',
          fontWeight: FontWeight.w300,
        ),
        filled: true,
        fillColor: _fieldFill,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: const TextStyle(fontSize: 11, fontFamily: 'KoPubDotum'),
      ),
    );
  }

  Widget _visibilityToggle({
    required bool visible,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: _hintColor,
        size: 20,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildGradientButton() {
    return GestureDetector(
      onTap: (_isLoading || !_allDone) ? null : _submit,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: (_isLoading || !_allDone)
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
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                '회원가입',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'KoPubDotum',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}
