import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/screen/home_screen.dart';

class LikedmenuScreen extends StatefulWidget {
  const LikedmenuScreen({super.key});

  @override
  State<LikedmenuScreen> createState() => _LikedmenuScreenState();
}

class _LikedmenuScreenState extends State<LikedmenuScreen> {
  bool fullSeeIsPressed = true;
  bool categorySeePressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //바텀 바
      bottomNavigationBar: Container(
        color: Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Color(0xFF808080),
            size: 40,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
        title: const Text('찜'),
        centerTitle: true,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w500,
          fontFamily: 'KoPubDotum',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF808080), size: 30),
            onPressed: () {},
          ),
        ],
      ),

      // 본문
      body: Column(
        children: [
          Center(child: _categoryFilter()),

          SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.only(left: 20.0, bottom: 10.0),
            alignment: Alignment.centerLeft,
            child: Text(
              "총 n개",
              style: TextStyle(
                color: const Color(0xFFB7B7B7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.25,
                letterSpacing: -1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5), // 배경 색상
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 전체 보기 버튼
            GestureDetector(
              onTap: () {
                setState(() {
                  fullSeeIsPressed = true;
                  categorySeePressed = false;
                });
              },
              child: Container(
                width: 150,
                height: 50,
                decoration: BoxDecoration(
                  color: fullSeeIsPressed ? Colors.white : Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '전체',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),

            SizedBox(width: 8),

            // 카테고리별 보기 버튼
            GestureDetector(
              onTap: () {
                setState(() {
                  fullSeeIsPressed = false;
                  categorySeePressed = true;
                });
              },
              child: Container(
                width: 150,
                height: 50,
                decoration: BoxDecoration(
                  color: categorySeePressed ? Colors.white : Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '카테고리별 보기',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
