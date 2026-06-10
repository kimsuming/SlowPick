import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:slowpick/screen/splash_screen.dart';
import 'firebase_options.dart';
import 'amplify_outputs.dart';

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(amplifyConfig);
  } on AmplifyAlreadyConfiguredException {
    // 핫 리스타트 시 이미 구성된 상태
  } catch (e) {
    // amplify_outputs.dart에 실제 Cognito 설정이 없으면 이 경로로 진입
    safePrint('Amplify 설정 실패 (amplify_outputs.dart를 확인하세요): $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _configureAmplify();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SlowPick',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF74AE31),
          secondary: Color(0xFF74AE31),
        ),
        fontFamily: 'KoPubDotum',
      ),
      home: const SplashScreen(),
    );
  }
}
