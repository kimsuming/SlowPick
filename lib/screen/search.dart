import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

/*예시*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SlowPick 메뉴'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white, // 배경색
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

          // GridView로 변경하여 카드 디자인 적용
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2열로 배치
              childAspectRatio: 196 / 350, // Figma 디자인 비율 (가로/세로)
              crossAxisSpacing: 16, // 가로 간격
              mainAxisSpacing: 16, // 세로 간격
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              // 데이터 추출 (없을 경우 기본값 설정)
              final String name = data['menu_name'] ?? '이름 없음';
              final String imageUrl = data['menu_image_url'] ?? '';
              final int kcal = data['nutrition']?['calories_kcal'] ?? 0;
              final num sugar =
                  data['nutrition']?['sugar_g'] ?? 0; // int or double

              // 알레르기 정보는 현재 크롤러에서 가져오지 않았으므로 예시 텍스트 처리
              final String allergy = "정보 없음";

              return _buildMenuCard(name, kcal, sugar, allergy, imageUrl);
            },
          );
        },
      ),
    );
  }

  // Figma 디자인을 그대로 옮긴 위젯
  Widget _buildMenuCard(
    String name,
    int kcal,
    num sugar,
    String allergy,
    String imageUrl,
  ) {
    return Container(
      // width, height는 GridView 비율에 따라 자동 조정됨
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white, // 카드 배경색
      ),
      child: Stack(
        children: [
          // 1. 메뉴 이름
          Positioned(
            left: 8,
            top: 202,
            right: 8, // 글자가 길어지면 잘리지 않게 오른쪽 여백 추가
            child: Text(
              name,
              maxLines: 2, // 두 줄까지만 표시
              overflow: TextOverflow.ellipsis, // 넘치면 ... 처리
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'KoPubDotum', // 폰트가 없으면 기본 폰트로 나옴
                fontWeight: FontWeight.w500, // Medium
                height: 1.25,
                letterSpacing: -0.64,
              ),
            ),
          ),

          // 2. 칼로리 및 가격 (가격은 DB에 없으므로 칼로리만 표시하거나 임시 가격 표시)
          Positioned(
            left: 8,
            top: 244, // 이름이 두 줄일 수 있어서 위치를 살짝 조정함 (기존 224 -> 244)
            child: Text(
              '[ ${kcal}Kcal ]  8,700~',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'KoPubDotum',
                fontWeight: FontWeight.w400, // Light
                height: 1.25,
                letterSpacing: -0.64,
              ),
            ),
          ),

          // 3. 당류 배지 (Badge)
          Positioned(
            left: 5,
            top: 267,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: ShapeDecoration(
                color: const Color(0xFFFFE0E1),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: Color(0xFFFF7D7F)),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                '당 ${sugar}g',
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 13,
                  fontFamily: 'KoPubDotum',
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ),
          ),

          // 4. 메뉴 이미지 (가장 중요!)
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 195, // Grid 셀 크기에 맞춤
              height: 195,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1), // 이미지 로딩 전 회색 배경
                //borderRadius: BorderRadius.circular(12), // 둥근 모서리 (선택)
              ),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover, // 이미지를 꽉 차게 (마스킹 효과 대체)
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.greenAccent,
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : const Icon(Icons.coffee, size: 50, color: Colors.grey),
            ),
          ),

          // 5. 하트 아이콘 (찜하기 - 현재 기능 없으므로 UI만)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white70, // 반투명 배경
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 20,
                color: Colors.black54,
              ),
            ),
          ),

          // 6. 알레르기 정보
          Positioned(
            left: 8,
            //top: 175, // top 좌표 대신 bottom 사용 (유동적 배치를 위해)
            bottom: 1,
            child: Text(
              '알레르기: $allergy',
              style: const TextStyle(
                color: Color(0xFF7B7B7B),
                fontSize: 12,
                fontFamily: 'KoPubDotum',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
