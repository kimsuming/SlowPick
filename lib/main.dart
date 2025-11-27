import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'firebase_options.dart'; // flutterfire configure로 생성된 파일

void main() async {
  // 1. 플러터 엔진과 위젯 바인딩을 미리 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 파이어베이스 연결
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'SlowPick');
  }
}
