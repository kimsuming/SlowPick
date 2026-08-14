import 'dart:async';
import 'package:flutter/material.dart';
import 'package:slowpick/service/auth_service.dart';

class FindPasswordScreen extends StatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  State<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  bool _isStep2 = false;
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  static const int _cooldownSeconds = 60;

  static const Color _pointColor = Color(0xFF74AE31);
  static const Color _fieldFill = Color(0xFFF2F2F2);
  static const Color _hintColor = Color(0xFFAAAAAA);

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack('이메일을 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.instance.resetPassword(email: email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _startCooldown();
      if (!_isStep2) {
        setState(() => _isStep2 = true);
      } else {
        _showSnack('인증 코드를 재전송했습니다. 이메일을 확인해주세요.');
      }
    } else {
      _showSnack(result.errorMessage!);
    }
  }

  Future<void> _confirmReset() async {
    final code = _codeCtrl.text.trim();
    final newPw = _newPwCtrl.text;
    final confirmPw = _confirmPwCtrl.text;

    if (code.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
      _showSnack('모든 항목을 입력해주세요.');
      return;
    }
    if (newPw != confirmPw) {
      _showSnack('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.instance.confirmResetPassword(
      email: _emailCtrl.text.trim(),
      code: code,
      newPassword: newPw,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _showSuccessDialog();
    } else {
      _showSnack(result.errorMessage!);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '비밀번호 변경 완료',
          style: TextStyle(
            fontFamily: 'KoPubDotum',
            fontWeight: FontWeight.w500,
            fontSize: 17,
          ),
        ),
        content: const Text(
          '비밀번호가 성공적으로 변경되었습니다.\n새 비밀번호로 로그인해주세요.',
          style: TextStyle(
            fontFamily: 'KoPubDotum',
            fontWeight: FontWeight.w300,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 로그인 화면으로
            },
            child: const Text(
              '로그인 화면으로',
              style: TextStyle(
                color: _pointColor,
                fontFamily: 'KoPubDotum',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: Colors.black87,
          onPressed: () {
            if (_isStep2) {
              setState(() => _isStep2 = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          '비밀번호 찾기',
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _isStep2 ? _buildStep2() : _buildStep1(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        _buildStepHeader('1단계', '이메일 입력'),
        const SizedBox(height: 12),
        const Text(
          '가입 시 사용한 이메일을 입력하면\n비밀번호 재설정 코드를 전송해드립니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            fontFamily: 'KoPubDotum',
            fontWeight: FontWeight.w300,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),
        _buildTextField(
          controller: _emailCtrl,
          hint: '이메일 입력',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildGradientButton(label: '인증 코드 전송', onTap: _sendCode),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        _buildStepHeader('2단계', '새 비밀번호 설정'),
        const SizedBox(height: 12),
        Text(
          '${_emailCtrl.text.trim()}으로\n전송된 인증 코드를 입력해주세요.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            fontFamily: 'KoPubDotum',
            fontWeight: FontWeight.w300,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        _buildLabel('인증 코드'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _codeCtrl,
          hint: '이메일로 받은 인증 코드',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _buildLabel('새 비밀번호'),
        const SizedBox(height: 4),
        const Text(
          '8자 이상, 대·소문자·숫자·특수문자 각 1개 이상',
          style: TextStyle(
            fontSize: 11,
            color: _hintColor,
            fontFamily: 'KoPubDotum',
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _newPwCtrl,
          hint: '새 비밀번호 입력',
          obscure: _obscureNew,
          suffix: IconButton(
            icon: Icon(
              _obscureNew
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _hintColor,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureNew = !_obscureNew),
          ),
        ),
        const SizedBox(height: 20),
        _buildLabel('새 비밀번호 확인'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _confirmPwCtrl,
          hint: '새 비밀번호 재입력',
          obscure: _obscureConfirm,
          suffix: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _hintColor,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 24),
        _buildGradientButton(label: '비밀번호 변경', onTap: _confirmReset),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: (_isLoading || _resendCooldown > 0) ? null : _sendCode,
            child: Text(
              _resendCooldown > 0
                  ? '재전송 대기 ($_resendCooldown초)'
                  : '인증 코드 재전송',
              style: TextStyle(
                color: (_isLoading || _resendCooldown > 0)
                    ? _hintColor
                    : _pointColor,
                fontSize: 13,
                fontFamily: 'KoPubDotum',
                fontWeight: FontWeight.w400,
                decoration: (_resendCooldown > 0)
                    ? TextDecoration.none
                    : TextDecoration.underline,
                decorationColor: _pointColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStepHeader(String step, String title) {
    return Column(
      children: [
        Text(
          step,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888888),
            fontFamily: 'KoPubDotum',
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            color: Colors.black87,
            fontFamily: 'KoPubDotum',
            fontWeight: FontWeight.w500,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'KoPubDotum',
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: _hintColor,
          fontSize: 16,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: _isLoading
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
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'KoPubDotum',
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
