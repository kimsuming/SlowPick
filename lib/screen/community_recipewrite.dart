import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/screen/community_recipe.dart';

class CommunityRecipewrite extends StatefulWidget {
  const CommunityRecipewrite({super.key});

  @override
  State<CommunityRecipewrite> createState() => _CommunityRecipewriteState();
}

class _CommunityRecipewriteState extends State<CommunityRecipewrite> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

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
        elevation: 0,
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

      body: SingleChildScrollView(
        child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topBar(),

                Container(height: 1.5, color: const Color(0xFFD7D7D7)), // 구분선
                //제목 & 태그 & 내용 입력
                _communityTextField(),

                //이미지 첨부
                _imageAttach(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF197100), // 초록색
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Text(
              '등록',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF73AD31),
                fontSize: 19,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _communityTextField() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //대표 이미지 지정
          Text(
            '대표 이미지 지정',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.50,
            ),
          ),
          //추가 아이콘
          Icon(Icons.add_box, color: Color(0xEEEEEEEE), size: 100),

          //제목 입력
          Text(
            '제목',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.50,
            ),
          ),

          SizedBox(height: 5),

          SizedBox(
            height: 40,
            child: TextField(
              controller: _titleController,
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.2, // ⭐ 입력 텍스트 라인 높이 고정
              ),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '제목을 입력해주세요',
                hintStyle: TextStyle(color: Color.fromRGBO(176, 176, 176, 1)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 1.50, color: Color(0xFFC6C6C6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF187100)),
                ),
              ),
            ),
          ),

          SizedBox(height: 20),

          //키워드 입력
          Text(
            '태그',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.50,
            ),
          ),

          SizedBox(height: 5),

          SizedBox(
            height: 40,
            child: TextField(
              controller: _tagController,
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.2, // ⭐ 입력 텍스트 라인 높이 고정
              ),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '태그를 입력해주세요',
                hintStyle: TextStyle(color: Color.fromRGBO(176, 176, 176, 1)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 1.50, color: Color(0xFFC6C6C6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF187100)),
                ),
              ),
            ),
          ),

          SizedBox(height: 20),

          //내용 입력
          Text(
            '내용',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.50,
            ),
          ),

          SizedBox(height: 5),

          TextField(
            controller: _contentController,
            maxLines: 7,
            decoration: const InputDecoration(
              isDense: true,
              hintText: '내용을 입력해주세요',
              hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 1.50, color: Color(0xFFC6C6C6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF187100)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageAttach() {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Container(
        width: 128,
        height: 39,
        decoration: BoxDecoration(
          color: Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_box, color: Colors.black, size: 23),
            SizedBox(width: 3),
            Text(
              '이미지 첨부',
              style: TextStyle(
                color: const Color(0xFF212121),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.33,
                letterSpacing: 0.50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
