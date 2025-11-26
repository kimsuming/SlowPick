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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SlowPick',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const MenuListScreen(),
    );
  }
}

class MenuListScreen extends StatelessWidget {
  const MenuListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SlowPick 메뉴 리스트'),
        backgroundColor: Colors.greenAccent,
      ),
      // 3. StreamBuilder: 데이터의 흐름을 감시하다가 화면을 다시 그려줌
      body: StreamBuilder<QuerySnapshot>(
        // (A) 데이터 흐름에서 instance(연결된 데이터 습득), collection(menus 찾기), snapshots(내용 받기)
        stream: FirebaseFirestore.instance.collection('menus').snapshots(),

        // (B) 상황별 화면 그리기
        builder: (context, snapshot) {
          // 1. 로딩 중일 때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
          }

          // 2. 에러가 났을 때
          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }

          // 3. 데이터가 없을 때
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('저장된 메뉴가 없습니다.'));
          }

          // 4. 데이터가 잘 왔을 때 (ListView로 보여주기)
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // 각 문서(Document)의 데이터를 Map 형태로 가져옵니다.
              final data = docs[index].data() as Map<String, dynamic>;

              // 필드값 가져오기 (우리가 DB에 넣은 키값 그대로 사용)
              final String name = data['menu_name'] ?? '이름 없음';
              final String brand = data['brand_name'] ?? '브랜드 없음';
              final int kcal = data['nutrition']?['calories_kcal'] ?? 0;
              final String imageUrl = data['menu_image_url'] ?? 0;

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl, // DB에서 가져온 URL
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,

                    // 1. 로딩 중일 때 보여줄 것
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(color: Colors.greenAccent),

                    // 2. 에러 났을 때 보여줄 것
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('$brand | $kcal kcal'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              );
            },
          );
        },
      ),
    );
  }
}
