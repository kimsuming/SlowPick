import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slowpick/screen/login_screen.dart';
import 'package:slowpick/service/auth_service.dart';

class ConfirmSignupScreen extends StatefulWidget {
  final String email;
  const ConfirmSignupScreen({super.key, required this.email});

  @override
  State<ConfirmSignupScreen> createState() => _ConfirmSignupScreenState();
}

class _ConfirmSignupScreenState extends State<ConfirmSignupScreen> {
  final List<TextEditingController> _codeCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0; // 초 단위 재전송 쿨다운

  static const _pointColor = Color(0xFF74AE31);

  @override
  void dispose() {
    for (final c in _codeCtrl) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _fullCode =>
      _codeCtrl.map((c) => c.text).join();

  // ─── 인증 코드 확인 ─────────────────────────────────────

  Future<void> _confirm() async {
    if (_fullCode.length < 6) {
      _showSnack('인증 코드 6자리를 모두 입력해주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.instance.confirmSignUp(
      email: widget.email,
      code: _fullCode,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _showSnack('이메일 인증이 완료되었습니다!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      _showSnack(result.errorMessage!, isError: true);
    }
  }

  // ─── 코드 재전송 ────────────────────────────────────────

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() => _isResending = true);

    final result = await AuthService.instance.resendConfirmationCode(
      email: widget.email,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result.success) {
      _showSnack('인증 코드를 재전송했습니다.');
      _startCooldown();
    } else {
      _showSnack(result.errorMessage!, isError: true);
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : _pointColor,
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
          '이메일 인증',
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // 단계 안내
              _buildStepIndicator(),

              const SizedBox(height: 40),

              // 안내 문구
              const Text(
                '인증 코드를 입력해주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'KoPubDotum',
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'KoPubDotum',
                    color: Color(0xFF888888),
                  ),
                  children: [
                    TextSpan(text: widget.email),
                    const TextSpan(text: '\n으로 발송된 6자리 코드를 입력해주세요.'),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 6칸 코드 입력
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _buildCodeBox(i)),
              ),

              const SizedBox(height: 36),

              // 확인 버튼
              _buildConfirmButton(),

              const SizedBox(height: 24),

              // 재전송
              Center(
                child: GestureDetector(
                  onTap: _resendCooldown > 0 || _isResending ? null : _resend,
                  child: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _pointColor,
                          ),
                        )
                      : Text(
                          _resendCooldown > 0
                              ? '재전송 가능까지 $_resendCooldown초'
                              : '코드를 받지 못하셨나요?  재전송',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'KoPubDotum',
                            color: _resendCooldown > 0
                                ? const Color(0xFFAAAAAA)
                                : _pointColor,
                            decoration: _resendCooldown > 0
                                ? TextDecoration.none
                                : TextDecoration.underline,
                            decorationColor: _pointColor,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 위젯 헬퍼 ───────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: _pointColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: _pointColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          '2 / 2  이메일 인증',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
            fontFamily: 'KoPubDotum',
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBox(int index) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextFormField(
        controller: _codeCtrl[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: const TextStyle(
          fontSize: 22,
          fontFamily: 'KoPubDotum',
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF2F2F2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _pointColor, width: 1.5),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          // 6자리 모두 입력되면 자동 확인 시도
          if (_fullCode.length == 6) _confirm();
        },
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _confirm,
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
            : const Text(
                '인증 완료',
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
