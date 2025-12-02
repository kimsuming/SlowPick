import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:slowpick/screen/home_screen.dart';
import 'package:slowpick/screen/search.dart';
import 'firebase_options.dart'; // flutterfire configure로 생성된 파일

void main() async {
  // 1. 플러터 엔진과 위젯 바인딩을 미리 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 파이어베이스 연결
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. 앱 실행
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
      ),
      home: DefaultTabController(
        length: 5,
        child: Scaffold(
          backgroundColor: Color(0xFFFCFCFC),
          body: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              HomeScreen(),
              SearchScreen(),
              Container(child: Center(child: Text('save'))),
              Container(child: Center(child: Text('more'))),
              Container(child: Center(child: Text('test'))),
            ],
          ),
        ),
      ),
    );
  }
}
