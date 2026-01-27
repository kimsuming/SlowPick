import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screen/menu_all.dart';
import 'screen/search.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SlowPick',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 검색 화면으로 이동하는 함수
  void _navigateToSearch(BuildContext context, String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // query를 SearchScreen으로 전달합니다.
        builder: (context) => SearchScreen(initialQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('SlowPick Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 전체 메뉴로 이동 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
              child: const Text('전체 메뉴로 이동'),
            ),

            const SizedBox(height: 40), // 간격 띄우기

            // 2. 자동 완성 검색바 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "어떤 메뉴를 찾으세요?",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // Firestore에서 메뉴 이름을 실시간으로 가져와서 자동완성 소스로 사용
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('menus')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(
                          height: 50,
                          child: Center(child: Text("데이터 불러오는 중...")),
                        );
                      }

                      // DB에서 모든 메뉴의 이름만 뽑아서 리스트로 만듦
                      final List<String> menuNames = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['menu_name'] as String? ?? '';
                      }).where((name) => name.isNotEmpty).toList();

                      // Flutter가 제공하는 자동완성 위젯 사용
                      return Autocomplete<String>(
                        // (1) 사용자가 입력한 텍스트에 맞는 옵션 걸러내기
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return const Iterable<String>.empty();
                          }
                          return menuNames.where((String option) {
                            return option
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        // (2) 추천 검색어를 클릭했을 때 동작
                        onSelected: (String selection) {
                          _navigateToSearch(context, selection);
                        },
                        // (3) 입력창(TextField) 디자인
                        fieldViewBuilder: (context, textEditingController,
                            focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            // 키보드에서 엔터(완료) 눌렀을 때 동작
                            onSubmitted: (String value) {
                              _navigateToSearch(context, value);
                            },
                            decoration: InputDecoration(
                              hintText: '메뉴 이름 검색',
                              prefixIcon:
                                  const Icon(Icons.search, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 20),
                              // 그림자 효과를 위해 테두리 설정
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade300, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                    color: Colors.blue, width: 2),
                              ),
                            ),
                          );
                        },
                        // (4) 자동완성 목록이 표시되는 디자인 (선택 사항)
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(15),
                              child: SizedBox(
                                width: screenWidth - 60, // 검색창 너비와 맞춤
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final String option =
                                        options.elementAt(index);
                                    return ListTile(
                                      title: Text(option),
                                      leading: const Icon(Icons.restaurant_menu,
                                          size: 18, color: Colors.grey),
                                      onTap: () {
                                        onSelected(option);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}