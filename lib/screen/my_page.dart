import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/test/button_UI_test.dart';
import 'package:carousel_slider/carousel_slider.dart';

class MyPageScreen extends StatelessWidget {
  MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        //바텀 바
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
        title: const Text('내 정보'),
        centerTitle: true,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w500,
          fontFamily: 'KoPubDotum',
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필
            _buildProfileSection(),

            // 도전과제 섹션 위젯
            _challengeSection(),

            Container(height: 7, color: const Color(0xFFF5F5F5)), // 구분선

            _serviceSection(),

            Container(height: 2, color: const Color(0xFFF5F5F5)), // 구분선

            _alarmSection(),

            Container(height: 2, color: const Color(0xFFF5F5F5)), // 구분선

            _customerSupportSection(),

            Container(height: 2, color: const Color(0xFFF5F5F5)), // 구분선

            _accountManagementSection(),

            Container(height: 2, color: const Color(0xFFF5F5F5)), // 구분선

            _buildMenuItem(
              context,
              '앱 버전 정보',
              Icons.info_outline,
              trailingText: 'v1.0.0',
            ),

            const SizedBox(height: 20),

            // 로그아웃 버튼
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 프로필 섹션 위젯
  Widget _buildProfileSection() {
    return Container(
      color: Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 2,
                offset: Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                // 프로필 상단
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // 프로필 이미지 (임시)
                        Container(
                          width: 85,
                          height: 85,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEEEEEE),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 55,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // 이름 및 등급
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '유레카',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'KoPubDotum',
                                letterSpacing: -1,
                              ),
                            ),

                            Row(
                              children: [
                                Image(
                                  image: AssetImage(
                                    'images/myPage/noto_seedling.png',
                                  ),
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '초보당 회원',
                                  style: TextStyle(
                                    color: const Color(0xFF73AD31),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -1.70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 수정 버튼
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              '건강 정보 입력하기',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF999999),
                                fontFamily: 'KoPubDotum',
                                letterSpacing: -1.70,
                              ),
                            ),

                            // 수정 버튼 (화살표)
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 11),

                // 해시태그 박스
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Color(0xFFF6FFE4),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Color(0xFFB8DE8C), width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(11.0),
                      child: Text(
                        '# 당뇨 전단계  # 땅콩 , 키위 알러지  # 카페인 민감군 ',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: const Color(0xFF187100),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -1.70,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6),

                // 두 번째 해시태그 박스
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF7E7),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Color(0xFFEFCFA8), width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(11.0),
                      child: Text(
                        '# 다이어트 167cm , 70kg | 목표 체중 : 58kg',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: const Color(0xFF714200),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -1.70,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 도전과제 섹션 위젯
  Widget _challengeSection() {
    return SizedBox(
      height: 111,

      child: Row(
        children: [
          SizedBox(width: 20),

          Container(
            alignment: Alignment.center,
            child: Text(
              "도전과제!",
              style: TextStyle(
                color: const Color(0xFF999999),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ),

          SizedBox(width: 17),

          Expanded(
            child: CarouselSlider(
              options: CarouselOptions(
                height: 84,
                viewportFraction: 0.34,
                enableInfiniteScroll: false, // 무한 스크롤 비활성화
                padEnds: false,
              ),
              items: challengeTexts.map((text) {
                return Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Color(0xFFDDDDDD), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 체크 아이콘
                        Icon(
                          Icons.check_circle_outlined,
                          color: Color(0xFF74AE31),
                          size: 16,
                        ),
                        SizedBox(height: 4),
                        // 도전과제 텍스트
                        Padding(
                          padding: const EdgeInsets.only(left: 3.0),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 도전과제 리스트
  final List<String> challengeTexts = [
    '내 건강 정보\n입력해보기',
    '슬로우 노트\n작성해보기',
    '나만의 레시피\n만들기',
    '카페인 줄이기',
    '채소 섭취하기',
  ];

  Widget _serviceSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 20),
            child: Row(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 28,
                  color: Color(0xFFBBBBBB),
                ),
                SizedBox(width: 3),
                Text(
                  '서비스 소식',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFBBBBBB),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.20,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () => {},
            child: Padding(
              padding: const EdgeInsets.only(left: 35, top: 16),
              child: Text(
                '공지사항',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.26,
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: () => {},
            child: Padding(
              padding: const EdgeInsets.only(left: 35, top: 16),
              child: Text(
                '이벤트',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.26,
                ),
              ),
            ),
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _alarmSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 20),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 25,
                  color: Color(0xFFBBBBBB),
                ),
                SizedBox(width: 3),
                Text(
                  '알림 설정',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFBBBBBB),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.20,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () => {},
            child: Padding(
              padding: const EdgeInsets.only(left: 35, top: 16),
              child: Text(
                '맟춤 알림 설정',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.26,
                ),
              ),
            ),
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _customerSupportSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 20),
            child: Row(
              children: [
                Icon(Icons.support_agent, size: 25, color: Color(0xFFBBBBBB)),
                SizedBox(width: 3),
                Text(
                  '고객지원',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFBBBBBB),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.20,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () => {},
            child: Padding(
              padding: const EdgeInsets.only(left: 35, top: 16),
              child: Text(
                '1 : 1 문의 넣기',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.26,
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: () => {},
            child: Padding(
              padding: const EdgeInsets.only(left: 35, top: 16),
              child: Text(
                '챗봇 이용하기',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.26,
                ),
              ),
            ),
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _accountManagementSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 20),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 25, color: Color(0xFFBBBBBB)),
                SizedBox(width: 3),
                Text(
                  '계정 관리',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFBBBBBB),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.20,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () => {},
            child: Padding(
              padding: const EdgeInsets.only(left: 35, top: 16),
              child: Text(
                '로그인 연동 계정 관리',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.26,
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: () => {},
            child: Padding(
              padding: const EdgeInsets.only(left: 35, top: 16),
              child: Text(
                '로그아웃',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.26,
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: () => {},
            child: Padding(
              padding: const EdgeInsets.only(left: 35, top: 16),
              child: Text(
                '회원탈퇴',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.26,
                ),
              ),
            ),
          ),

          SizedBox(height: 24),
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
