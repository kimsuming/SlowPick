import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreen();
}

class _MenuScreen extends State<MenuScreen> {
  // 보기 모드 상태 변수 (true: 그리드(2열), false: 리스트(1열))
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    // 반응형 크기 계산
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // 그리드 뷰용 비율 계산
    final double gridAspectRatio = (screenWidth / 2) / (screenHeight * 0.38);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('전체 메뉴'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          // 보기 모드 전환 버튼
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: Colors.black54,
            ),
            tooltip: _isGridView ? '리스트로 보기' : '그리드로 보기',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menus').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('저장된 메뉴가 없습니다.'));
          }

          final docs = snapshot.data!.docs;

          // 모드에 따라 다른 뷰 반환
          if (_isGridView) {
            // 1. 기존 그리드 뷰 (2열)
            return GridView.builder(
              padding: EdgeInsets.all(screenWidth * 0.04),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: gridAspectRatio,
                crossAxisSpacing: screenWidth * 0.04,
                mainAxisSpacing: screenWidth * 0.04,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _buildGridCard(context, data);
              },
            );
          } else {
            // 2. 새로운 리스트 뷰 (1열, 가로 배치)
            return ListView.separated(
              padding: EdgeInsets.all(screenWidth * 0.04),
              itemCount: docs.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: screenHeight * 0.02), // 아이템 간 간격
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _buildListCard(context, data);
              },
            );
          }
        },
      ),
    );
  }

  // ==========================================
  // 1. 그리드형 카드 위젯 (기존 디자인 유지)
  // ==========================================
  Widget _buildGridCard(BuildContext context, Map<String, dynamic> data) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final String name = data['menu_name'] ?? '이름 없음';
    final String imageUrl = data['menu_image_url'] ?? '';
    final int kcal = data['nutrition']?['calories_kcal'] ?? 0;
    final num sugar = data['nutrition']?['sugar_g'] ?? 0;
    final String allergy = "정보 없음";

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: screenHeight * 0.2,
                color: const Color(0xFFF1F1F1),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : const Icon(Icons.coffee, size: 50, color: Colors.grey),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: _buildHeartIcon(),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'KoPubDotum',
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        '[ ${kcal}Kcal ]  8,700~',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: screenWidth * 0.032,
                          fontFamily: 'KoPubDotum',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNutritionBadge(screenWidth, '당 ${sugar}g',
                          const Color(0xFFFFE0E1), const Color(0xFFEF4444)),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        '알레르기: $allergy',
                        style: TextStyle(
                          color: const Color(0xFF7B7B7B),
                          fontSize: screenWidth * 0.028,
                          fontFamily: 'KoPubDotum',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. 리스트형 카드 위젯 (새로운 디자인)
  // ==========================================
  Widget _buildListCard(BuildContext context, Map<String, dynamic> data) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // 리스트 카드의 높이는 고정값이나 비율로 적절히 작게 설정
    final double cardHeight = 110.0; // 픽셀 단위로 적절히 고정하거나 비율 사용 가능

    final String name = data['menu_name'] ?? '이름 없음';
    final String imageUrl = data['menu_image_url'] ?? '';
    final int kcal = data['nutrition']?['calories_kcal'] ?? 0;
    final num sugar = data['nutrition']?['sugar_g'] ?? 0;
    // DB에 없는 데이터 임시 처리 (3개 보여주기 위함)
    final num protein = 12; // 예시 데이터
    final num fat = 5; // 예시 데이터

    return Container(
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 좌측 이미지
          Container(
            width: cardHeight, // 정사각형 비율
            height: cardHeight,
            color: const Color(0xFFF1F1F1),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  )
                : const Icon(Icons.coffee, size: 40, color: Colors.grey),
          ),

          // 우측 정보 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 상단: 이름 + 가격/칼로리 + 하트
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: screenWidth * 0.042,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'KoPubDotum',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '8,700원  |  ${kcal}Kcal',
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                color: Colors.black54,
                                fontFamily: 'KoPubDotum',
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildHeartIcon(size: 24),
                    ],
                  ),

                  // 하단: 영양 성분 3개 (Row로 배치)
                  Row(
                    children: [
                      _buildMiniBadge('당 ${sugar}g'),
                      const SizedBox(width: 6),
                      _buildMiniBadge('단백질 ${protein}g'),
                      const SizedBox(width: 6),
                      _buildMiniBadge('지방 ${fat}g'),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 공통: 하트 아이콘
  Widget _buildHeartIcon({double size = 30}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white70,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.favorite_border,
        size: size * 0.6,
        color: Colors.black54,
      ),
    );
  }

  // 공통: 영양성분 뱃지 (그리드용 - 조금 큼)
  Widget _buildNutritionBadge(
      double screenWidth, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: bgColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: textColor),
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: screenWidth * 0.03,
          fontWeight: FontWeight.bold,
          fontFamily: 'KoPubDotum',
        ),
      ),
    );
  }

  // 공통: 영양성분 미니 뱃지 (리스트용 - 작고 심플하게)
  Widget _buildMiniBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 11,
          fontFamily: 'KoPubDotum',
        ),
      ),
    );
  }
}