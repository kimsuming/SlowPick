import 'package:flutter/material.dart';
import 'package:slowpick/screen/home_screen.dart';
import 'package:slowpick/screen/search.dart';

class BottomBarNew extends StatelessWidget {
  const BottomBarNew({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Color(0xFFFCFCFC),
        border: Border(top: BorderSide(color: Color(0xFFE1E1E1), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 홈 버튼
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("images/main_icon/home.png", width: 30, height: 30),
                SizedBox(height: 4),
                Text(
                  '홈',
                  style: TextStyle(
                    color: Color(0xFF73AD31),
                    fontSize: 13,
                    fontFamily: 'NEXON Lv1 Gothic',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // 커뮤니티 버튼
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "images/main_icon/la_speakap.png",
                  width: 30,
                  height: 30,
                ),
                SizedBox(height: 4),
                Text(
                  '커뮤니티',
                  style: TextStyle(
                    color: Color(0xFF73AD31),
                    fontSize: 13,
                    fontFamily: 'NEXON Lv1 Gothic',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // 중앙 버튼
          GestureDetector(
            onTap: () {
              print("좋아요 클릭"); // 나중에 화면 이동 가능
            },
            child: Image.asset(
              "images/main_icon/crown.png",
              width: 50,
              height: 50,
            ),
          ),

          // 좋아요 버튼
          GestureDetector(
            onTap: () {
              print("좋아요 클릭"); // 나중에 화면 이동 가능
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "images/main_icon/bookmark.png",
                  width: 30,
                  height: 30,
                ),
                SizedBox(height: 4),
                Text(
                  '좋아요',
                  style: TextStyle(
                    color: Color(0xFF73AD31),
                    fontSize: 13,
                    fontFamily: 'NEXON Lv1 Gothic',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // 내 정보 버튼
          GestureDetector(
            onTap: () {
              print("내 정보 클릭"); // 나중에 화면 이동 가능
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "images/main_icon/mypage.png",
                  width: 30,
                  height: 30,
                ),
                SizedBox(height: 4),
                Text(
                  '내 정보',
                  style: TextStyle(
                    color: Color(0xFF73AD31),
                    fontSize: 13,
                    fontFamily: 'NEXON Lv1 Gothic',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
