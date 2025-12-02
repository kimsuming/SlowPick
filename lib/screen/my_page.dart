import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/test/button_UI_test.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('내 정보'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'KoPubDotum',
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // 설정 페이지 이동
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ButtonUiTest()),
              );
            },
          ),
        ],
      ),

      bottomNavigationBar: Container(
        //바텀 바
        color: Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 프로필
            _buildProfileSection(),

            const SizedBox(height: 30),

            Container(height: 8, color: const Color(0xFFF5F5F5)), // 구분선

            // 메뉴 리스트
            _buildMenuItem(context, '내 리뷰 관리', Icons.rate_review_outlined),
            _buildMenuItem(context, '최근 본 메뉴', Icons.history),

            Container(height: 8, color: const Color(0xFFF5F5F5)), // 구분선

            _buildMenuItem(context, '고객센터', Icons.support_agent),
            _buildMenuItem(
              context,
              '앱 버전 정보',
              Icons.info_outline,
              trailingText: 'v1.0.0',
            ),

            const SizedBox(height: 20),
            // 로그아웃 버튼
            TextButton(
              onPressed: () {
                // 로그아웃 로직
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 프로필 이미지 (임시)
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEEEEEE),
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.grey),
          ),
          const SizedBox(width: 20),
          // 이름 및 이메일
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '유레카',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'KoPubDotum',
                ),
              ),
              SizedBox(height: 4),
              Text(
                'slowpick@example.com',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'KoPubDotum',
                ),
              ),
            ],
          ),
          const Spacer(),
          // 수정 버튼 (화살표)
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon, {
    String? trailingText,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontFamily: 'KoPubDotum'),
      ),
      trailing: trailingText != null
          ? Text(
              trailingText,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            )
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // 메뉴 클릭 시 이동 로직
      },
    );
  }
}
