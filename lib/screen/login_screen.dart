import 'package:flutter/material.dart';
import 'package:slowpick/screen/confirm_signup_screen.dart';
import 'package:slowpick/screen/my_page.dart';
import 'package:slowpick/screen/signup_screen.dart';
import 'package:slowpick/service/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const Color _pointColor = Color(0xFF74AE31);
  static const Color _gradientStart = Color(0xFF81DB60);
  static const Color _gradientEnd = Color(0xFFBCEC81);
  static const Color _fieldFill = Color(0xFFF2F2F2);
  static const Color _hintColor = Color(0xFFAAAAAA);

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  // ─── 로그인 로직 ─────────────────────────────────────────

  Future<void> _signIn() async {
    final email = _idController.text.trim();
    final password = _pwController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('이메일과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.instance.signIn(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MyPageScreen()),
      );
    } else if (result.errorMessage == '__UNCONFIRMED__') {
      // 이메일 미인증 상태 → 인증 화면으로 이동
      _showSnack('이메일 인증이 필요합니다. 인증 코드를 확인해주세요.');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmSignupScreen(email: email),
        ),
      );
    } else {
      _showSnack(result.errorMessage!);
    }
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

  // ─── UI ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 90),

              // 로고
              Center(
                child: Image.asset(
                  'images/SlowPick_logo.png',
                  width: 280,
                ),
              ),

              const SizedBox(height: 55),

              // 아이디 입력
              _buildTextField(
                controller: _idController,
                hint: '이메일',
                keyboardType: TextInputType.emailAddress,
                obscure: false,
              ),

              const SizedBox(height: 12),

              // 비밀번호 입력
              _buildTextField(
                controller: _pwController,
                hint: '비밀번호',
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _hintColor,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 8),

              // 아이디 찾기 | 비밀번호 찾기
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextLink('아이디 찾기', onTap: () {}),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '|',
                        style: TextStyle(color: _hintColor, fontSize: 12),
                      ),
                    ),
                    _buildTextLink('비밀번호 찾기', onTap: () {}),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 로그인 버튼
              _buildGradientButton(),

              const SizedBox(height: 34),

              // 아직 회원이 아니신가요?
              Center(
                child: Text(
                  '아직 회원이 아니신가요?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontFamily: 'KoPubDotum',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 회원가입하기 버튼
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _pointColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '회원가입하기',
                  style: TextStyle(
                    color: _pointColor,
                    fontSize: 15,
                    fontFamily: 'KoPubDotum',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // 간편로그인 구분선
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFDDDDDD))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '간편 로그인',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontFamily: 'KoPubDotum',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFDDDDDD))),
                ],
              ),

              const SizedBox(height: 20),

              // 소셜 로그인 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    logoPath: 'images/google_logo.png',
                    label: 'Google',
                    backgroundColor: Colors.white,
                    borderColor: const Color(0xFFDDDDDD),
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    logoPath: 'images/kakao_logo.png',
                    label: 'Kakao',
                    backgroundColor: const Color(0xFFFEE500),
                    borderColor: const Color(0xFFFEE500),
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 위젯 헬퍼 ───────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
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

  Widget _buildTextLink(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: _pointColor,
          fontSize: 15,
          fontFamily: 'KoPubDotum',
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildGradientButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _signIn,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? const LinearGradient(
                  colors: [Color(0xFFCCCCCC), Color(0xFFCCCCCC)])
              : const LinearGradient(
                  colors: [_gradientStart, _gradientEnd],
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
                '로그인',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'KoPubDotum',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String logoPath,
    required String label,
    required Color backgroundColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              logoPath,
              width: 22,
              height: 22,
              errorBuilder: (_, __, ___) => const SizedBox(
                width: 22,
                height: 22,
                child: Icon(Icons.image_not_supported_outlined,
                    size: 18, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'KoPubDotum',
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
