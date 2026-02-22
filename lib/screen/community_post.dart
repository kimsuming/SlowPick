import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

class CommunityPost extends StatefulWidget {
  const CommunityPost({super.key});

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 슬로우 커뮤니티 제목
            Text(
              '슬로우 커뮤니티',
              style: TextStyle(
                color: Colors.black,
                fontSize: 27,
                fontWeight: FontWeight.w500,
                letterSpacing: -1.70,
              ),
            ),

            Text(
              'Slow Community',
              style: TextStyle(
                color: Color(0xFF718F74),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.50,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent, // 중요
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(1.00, 0.50),
              end: Alignment(0.00, 0.50),
              colors: [Color(0xFFA2F43D), Color(0xFFD5FF72)],
            ),
          ),
        ),

        toolbarHeight: 76,

        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: 50),
            onPressed: () {},
          ),
        ],
      ),

      bottomNavigationBar: Container(
        //바텀 바
        color: Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(1.00, 0.50),
            end: Alignment(0.00, 0.50),
            colors: [Color(0xFFA2F43D), Color(0xFFD5FF72)],
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // 뒤로가기 & 등록
              _topBar(),
              Container(height: 1.5, color: const Color(0xFFE2E2E2)), // 구분선

              SizedBox(height: 32),
              //본문
              _textField(),

              SizedBox(height: 50),

              //북마크, 추천, 싫어요 버튼
              _buttons(),

              SizedBox(height: 8),

              // 댓글 수
              _commentCount(),

              // 댓글 텍스트
              _commentTextF(),

              // 답글 텍스트
              _commentTextS(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black,
                      size: 25,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 7),
              Text(
                '치이카와 콜라보 제품 사보신분',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              '한글  l  조회 82  l  추천 13  l  2026.01.01 14:32',
              style: TextStyle(
                color: const Color(0xFF73AD31),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField() {
    return Text(
      '치이카와 텀블러 온도 잘 유지되나요\n저번에 마루 텀블러 샀는데 불량인지 온도 유지가\n전혀 안돼서요 ㅠㅠ',
      style: TextStyle(
        color: Colors.black,
        fontSize: 17,
        fontFamily: 'KoPubDotum Medium',
        fontWeight: FontWeight.w400,
        letterSpacing: -1,
      ),
    );
  }

  Widget _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        //북마크
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFBBBBBB), width: 1),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.bookmark_outline,
                  color: Color(0xFF74AE31),
                  size: 22,
                ),
                Text(
                  '북마크',
                  style: TextStyle(
                    color: const Color(0xFF3F3F3F),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 4),
        //추천
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFBBBBBB), width: 1),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Icon(
                    Icons.thumb_up_outlined,
                    color: Color(0xFFEECC55),
                    size: 22,
                  ),
                ),
                Text(
                  '추천',
                  style: TextStyle(
                    color: const Color(0xFF3F3F3F),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),

                SizedBox(width: 4),

                Text(
                  '0',
                  style: TextStyle(
                    color: const Color(0xFFAD5C31),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 4),
        //싫어요
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFBBBBBB), width: 1),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Icon(
                    Icons.thumb_down_outlined,
                    color: Color(0xFF906BDA),
                    size: 22,
                  ),
                ),
                Text(
                  '싫어요',
                  style: TextStyle(
                    color: const Color(0xFF3F3F3F),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _commentCount() {
    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            border: Border.all(width: 1.5, color: const Color(0xFFE2E2E2)),
          ),
          child: Row(
            children: [
              SizedBox(width: 12),
              Text(
                '댓글',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.24,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '2',
                style: TextStyle(
                  color: const Color(0xFFAD5C31),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _commentTextF() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD7D7D7), width: 1.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(width: 10),
                  //게시글 제목
                  Text(
                    '잘돼요! 아마 그건 불량 아닐까요? ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),

              // 작성자이름 /시간
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  '랄랄라 l 2026.01.01 14:33',
                  style: TextStyle(
                    color: const Color(0xFFA7A7A7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.54,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),

          // 답글 & 좋아요 버튼
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(width: 10),
                    Icon(
                      Icons.subdirectory_arrow_right,
                      color: Color(0xFFBBBBBB),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 18,
                      color: const Color(0xFFCCCCCC),
                    ), // 구분선
                    SizedBox(width: 10),
                    Icon(Icons.thumb_up, color: Color(0xFFBBBBBB), size: 22),
                    SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentTextS() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD7D7D7), width: 1.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 10),
          Icon(
            Icons.subdirectory_arrow_right,
            color: Color(0xFFBBBBBB),
            size: 22,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(width: 10),
                  //게시글 제목
                  Text(
                    '잘돼요! 아마 그건 불량 아닐까요? ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),

              // 작성자이름 / 조회수 / 추천수 /시간
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  '랄랄라 l 2026.01.01 14:33',
                  style: TextStyle(
                    color: const Color(0xFFA7A7A7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.54,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
