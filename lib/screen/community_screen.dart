import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('커뮤니티'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'KoPubDotum',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      // 글쓰기 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 글쓰기 화면 이동
        },
        backgroundColor: const Color(0xFFE1F0CE),
        child: const Icon(Icons.edit, color: Colors.black87),
      ),

      bottomNavigationBar: Container(
        //바텀 바
        color: Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
    );
  }
}
