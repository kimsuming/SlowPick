import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// 인증 결과를 담는 간단한 DTO
class AuthResult {
  final bool success;
  final String? errorMessage;
  const AuthResult.ok() : success = true, errorMessage = null;
  const AuthResult.fail(this.errorMessage) : success = false;
}

/// Cognito 기반 인증을 앱 전반에서 관리하는 싱글톤 서비스.
/// 화면 코드는 이 클래스만 호출하고, Amplify API는 여기서만 사용합니다.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const bool _useMock = false;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // ────────────────────────────────────────────────────
  // 앱 시작 시 세션 복원
  // ────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_useMock) return;
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      _isLoggedIn = session.isSignedIn;
    } catch (_) {
      _isLoggedIn = false;
    }
  }

  // ────────────────────────────────────────────────────
  // 닉네임 조회
  // ────────────────────────────────────────────────────

  Future<String> fetchNickname() async {
    if (_useMock) return '테스트 유저';
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      return attributes
              .where((a) => a.userAttributeKey == CognitoUserAttributeKey.nickname)
              .firstOrNull
              ?.value ??
          '';
    } on AuthException {
      return '';
    }
  }

  // ────────────────────────────────────────────────────
  // 회원가입
  // ────────────────────────────────────────────────────

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    if (_useMock) return const AuthResult.ok();
    try {
      await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
            CognitoUserAttributeKey.nickname: nickname,
          },
        ),
      );
      return const AuthResult.ok();
    } on UsernameExistsException {
      return const AuthResult.fail('이미 사용 중인 이메일입니다.');
    } on InvalidPasswordException {
      return const AuthResult.fail(
          '비밀번호는 8자 이상, 특수문자를 1개 이상 포함해야 합니다.');
    } on AuthException catch (e) {
      return AuthResult.fail(_parseMessage(e.message));
    }
  }

  // ────────────────────────────────────────────────────
  // 이메일 인증 코드 확인
  // ────────────────────────────────────────────────────

  Future<AuthResult> confirmSignUp({
    required String email,
    required String code,
  }) async {
    if (_useMock) return const AuthResult.ok();
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: code,
      );
      if (result.isSignUpComplete) return const AuthResult.ok();
      return const AuthResult.fail('인증을 완료할 수 없습니다. 다시 시도해주세요.');
    } on CodeMismatchException {
      return const AuthResult.fail('인증 코드가 올바르지 않습니다.');
    } on ExpiredCodeException {
      return const AuthResult.fail('인증 코드가 만료되었습니다. 코드를 재전송해주세요.');
    } on AuthException catch (e) {
      return AuthResult.fail(_parseMessage(e.message));
    }
  }

  // ────────────────────────────────────────────────────
  // 인증 코드 재전송
  // ────────────────────────────────────────────────────

  Future<AuthResult> resendConfirmationCode({required String email}) async {
    if (_useMock) return const AuthResult.ok();
    try {
      await Amplify.Auth.resendSignUpCode(username: email);
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_parseMessage(e.message));
    }
  }

  // ────────────────────────────────────────────────────
  // 로그인
  // ────────────────────────────────────────────────────

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (_useMock) {
      _isLoggedIn = true;
      return const AuthResult.ok();
    }
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      if (result.isSignedIn) {
        _isLoggedIn = true;
        return const AuthResult.ok();
      }
      return const AuthResult.fail('로그인을 완료할 수 없습니다. 다시 시도해주세요.');
    } on UserNotFoundException {
      return const AuthResult.fail('존재하지 않는 계정입니다.');
    } on UserNotConfirmedException {
      // 이메일 미인증 상태 → 호출자가 ConfirmSignupScreen으로 보내야 함
      return const AuthResult.fail('__UNCONFIRMED__');
    } on AuthException catch (e) {
      return AuthResult.fail(_parseMessage(e.message));
    }
  }

  // ────────────────────────────────────────────────────
  // 로그아웃
  // ────────────────────────────────────────────────────

  Future<void> signOut() async {
    if (!_useMock) await Amplify.Auth.signOut();
    _isLoggedIn = false;
  }

  // ────────────────────────────────────────────────────
  // 내부 유틸
  // ────────────────────────────────────────────────────

  /// Cognito 원문 에러 메시지를 사용자 친화적으로 변환
  String _parseMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('network') || lower.contains('socket')) return '네트워크 연결을 확인해주세요.';
    if (lower.contains('incorrect username or password') || lower.contains('not authorized')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (lower.contains('password')) return '비밀번호 형식이 올바르지 않습니다.';
    if (lower.contains('email')) return '이메일 형식이 올바르지 않습니다.';
    return '오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  }
}
