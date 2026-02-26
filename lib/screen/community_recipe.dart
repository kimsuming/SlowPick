import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/screen/community_screen.dart';
import 'package:slowpick/screen/community_recipewrite.dart';

class CommunityRecipe extends StatefulWidget {
  const CommunityRecipe({super.key});

  @override
  State<CommunityRecipe> createState() => _CommunityRecipeState();
}

class _CommunityRecipeState extends State<CommunityRecipe> {
  bool isLiked = false;
  bool allPosts = true;
  bool popularPosts = false;
  bool myRegisteredPosts = false;
  bool favoritePosts = false;

  int currentPage = 1;
  final int totalPage = 5;

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
                color: const Color(0xFF718F74),
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
            icon: const Icon(Icons.settings, color: Colors.white, size: 50),
            onPressed: () {},
          ),
        ],
      ),
      // 레시피글쓰기 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommunityRecipewrite(),
            ),
          );
        },
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF187100),
        child: const Icon(
          Icons.add_box_outlined,
          color: Colors.white,
          size: 30,
        ),
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
              children: [
                //소통&레시피 창 선택 버튼
                _communicationRecipeSelector(),

                //게시글 검색바
                _searchBar(),

                //공지바
                _noticeBar(),

                //인기 레시피
                _recommendedRecipeNotice(),

                SizedBox(height: 19),

                //전체글 & 인기글 & 내등록 & 찜 선택 버튼
                _postFilterTab(),

                SizedBox(height: 20),

                //게시글 형식
                _postListItem(),
                //게시글 형식
                _postListItem(),
                //게시글 형식
                _postListItem(),
                //게시글 형식
                _postListItem(),
                //게시글 형식
                _postListItem(),
                //게시글 형식
                _postListItem(),
                //게시글 형식
                _postListItem(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _communicationRecipeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        //소통버튼
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CommunityScreen()),
            );
          },
          child: SizedBox(
            width: 150,
            height: 50,
            child: Center(
              child: Text(
                '소통',
                style: TextStyle(
                  color: const Color(0xFFB5B5B5),
                  fontSize: 20,
                  fontFamily: 'KoPubDotum Medium',
                  fontWeight: FontWeight.w400,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: 30),

        //레시피 버튼
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CommunityRecipe()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            width: 140,
            height: 50,
            child: Center(
              child: Text(
                '레시피',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: 'KoPubDotum Medium',
                  fontWeight: FontWeight.w400,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 22.0,
        right: 22.0,
        top: 17,
        bottom: 8,
      ),
      child: Container(
        height: 41,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFFC1D350), width: 2),
        ),
        child: Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.search, color: Color(0xFFC1D350)),
              onPressed: () {
                // 음성 검색
              },
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),

            IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.mic, color: Color(0xFFC1D350)),
              onPressed: () {
                // 음성 검색
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _noticeBar() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 2, left: 4),
              child: Icon(
                Icons.campaign_outlined,
                color: const Color(0xFF666666),
                size: 40,
              ),
            ),
            Text(
              '필독!',
              style: TextStyle(
                color: const Color(0xFF666666),
                fontSize: 23,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.70,
              ),
            ),

            SizedBox(width: 6),

            Text(
              '[ 슬로우 커뮤니티 소통 공지 ]',
              style: TextStyle(
                color: const Color(0xFFA5A5A5),
                fontSize: 17,
                fontWeight: FontWeight.w400,
                height: 1.33,
                letterSpacing: -1.70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendedRecipeNotice() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 2, left: 8),
              child: Icon(
                Icons.thumb_up_outlined,
                color: const Color(0xFF666666),
                size: 28,
              ),
            ),

            SizedBox(width: 5),

            Text(
              '3월 인기 레시피 바로 보러가기',
              style: TextStyle(
                color: const Color(0xFF666666),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postFilterTab() {
    return Row(
      children: [
        SizedBox(width: 15),

        //전체글 버튼
        GestureDetector(
          onTap: () {
            setState(() {
              allPosts = true;
              popularPosts = false;
              myRegisteredPosts = false;
              favoritePosts = false;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: allPosts ? Color(0xFFAEAEAE) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Color(0xFFAEAEAE), width: 2),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  '전체글',
                  style: TextStyle(
                    color: allPosts ? Colors.white : Color(0xFFAEAEAE),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.70,
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: 5),

        //인기 버튼
        GestureDetector(
          onTap: () {
            setState(() {
              allPosts = false;
              popularPosts = true;
              myRegisteredPosts = false;
              favoritePosts = false;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: popularPosts ? Color(0xFFAEAEAE) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Color(0xFFAEAEAE), width: 2),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  '인기',
                  style: TextStyle(
                    color: popularPosts ? Colors.white : Color(0xFFAEAEAE),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.70,
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: 5),

        //내 등록 버튼
        GestureDetector(
          onTap: () {
            setState(() {
              allPosts = false;
              popularPosts = false;
              myRegisteredPosts = true;
              favoritePosts = false;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: myRegisteredPosts ? Color(0xFFAEAEAE) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Color(0xFFAEAEAE), width: 2),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  '내 등록',
                  style: TextStyle(
                    color: myRegisteredPosts ? Colors.white : Color(0xFFAEAEAE),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.70,
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: 5),

        //찜 버튼
        GestureDetector(
          onTap: () {
            setState(() {
              allPosts = false;
              popularPosts = false;
              myRegisteredPosts = false;
              favoritePosts = true;
            });
          },
          child: Container(
            width: 49,
            decoration: BoxDecoration(
              color: favoritePosts ? Color(0xFFAEAEAE) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Color(0xFFAEAEAE), width: 2),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  '찜',
                  style: TextStyle(
                    color: favoritePosts ? Colors.white : Color(0xFFAEAEAE),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.70,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _postListItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            bottom: BorderSide(color: Color(0xFFD7D7D7), width: 1.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 2,
              offset: Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      //게시글 제목
                      Text(
                        '5년차 헬스 트레이너의 말차 다이어트',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          letterSpacing: -1.70,
                        ),
                      ),

                      //태그 목록
                      Text(
                        '#스타벅스 #다이어트 #말차',
                        style: TextStyle(
                          color: const Color(0xFF73AD31),
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -1.70,
                        ),
                      ),
                    ],
                  ),

                  // 작성자이름 / 조회수 / 추천수
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '헬스짱 l 조회 224 l 추천 368',
                        style: TextStyle(
                          color: const Color(0xFFA7A7A7),
                          fontSize: 13,
                          fontFamily: 'KoPubDotum Medium',
                          fontWeight: FontWeight.w400,
                          height: 1.54,
                          letterSpacing: -1,
                        ),
                      ),

                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.black26,
                          size: 23,
                        ),
                        onPressed: () {
                          setState(() {
                            isLiked = !isLiked;
                          });
                        },
                      ),
                    ],
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
