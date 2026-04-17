import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

class MypageInput extends StatefulWidget {
  const MypageInput({super.key});

  @override
  State<MypageInput> createState() => _MypageInputState();
}

class _MypageInputState extends State<MypageInput> {
  // 당뇨 정보 체크박스 상태
  bool type1Diabetes = false;
  bool type2Diabetes = true;
  bool preDiabetes = false;
  bool notApplicable = false;

  // 유제품 정보 체크박스 상태
  bool edible = false;
  bool inedible = false;
  bool lactoseIntolerance = false;

  // 카페인 정보 체크박스 상태
  bool caffeineEdible = false;
  bool caffeineInedible = false;

  // 고카페인 위험군 체크박스 상태
  bool pregnancy = false;
  bool otherDiseases = false;
  bool minor = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        //바텀 바
        color: Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),

      //배경 색상
      backgroundColor: Colors.white,

      //앱바
      appBar: AppBar(
        title: const Text('내 정보 입력하기'),
        centerTitle: true,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Color(0xFF242526),
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontFamily: 'KoPubDotum Medium',
          letterSpacing: -1.30,
        ),
      ),

      //본문
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //프로필 정보 수정
            _profileInformation(),

            //구분선
            Container(height: 8, color: const Color(0xFFF5F5F5)),

            _diabetesInformation(),

            //구분선
            Container(height: 8, color: const Color(0xFFF5F5F5)),

            _dairyInformation(),

            //구분선
            Container(height: 8, color: const Color(0xFFF5F5F5)),

            _allergyInformation(),

            //구분선
            Container(height: 8, color: const Color(0xFFF5F5F5)),

            _caffeineInformation(),

            //구분선
            Container(height: 8, color: const Color(0xFFF5F5F5)),

            _dietInformation(),
          ],
        ),
      ),
    );
  }

  // 프로필 정보
  Widget _profileInformation() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 기본값
              children: [
                Text(
                  '자유롭게 닉네임을 입력해주세요!',
                  style: TextStyle(
                    color: const Color(0xFF73AD31),
                    fontSize: 12,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),

                SizedBox(height: 8),

                //프로필 & 저장
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '프로필',
                      style: TextStyle(
                        color: const Color(0xFF242526),
                        fontSize: 21,
                        fontFamily: 'KoPubDotum Bold',
                        fontWeight: FontWeight.w700,
                        height: 0.95,
                        letterSpacing: -1,
                      ),
                    ),

                    //저장 박스
                    Container(
                      width: 43,
                      height: 30,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6FFE4),
                        border: Border.all(
                          width: 1,
                          color: const Color(0xFFB8DE8D),
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),

                      //저장 텍스트
                      child: Center(
                        child: Text(
                          '저장',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF73AD31),
                            fontSize: 15,
                            fontFamily: 'KoPubDotum Medium',
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 여백
            SizedBox(height: 22),

            // 프로필 이미지
            Image.asset(
              'images/myPage/profileImage.png',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),

            // 여백
            SizedBox(height: 21),

            // 닉네임 입력 박스
            Container(
              width: 188,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDED),
                borderRadius: BorderRadius.circular(15),
              ),

              //저장 텍스트
              child: Center(
                child: TextField(
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '닉네임 입력',
                    hintStyle: TextStyle(
                      color: const Color(0xFFBBBBBB),
                      fontSize: 16,
                      fontFamily: 'KoPubDotum Medium',
                      fontWeight: FontWeight.w500,
                      letterSpacing: -1,
                    ),

                    border: InputBorder.none, // 밑줄 제거
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 당뇨 정보
  Widget _diabetesInformation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 27.0, vertical: 19.0),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //건강정보 입력 추천
            Text(
              '건강 정보를 입력해서 맞춤 추천을 받아보아요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF73AD31),
                fontSize: 12,
                fontFamily: 'KoPubDotum Medium',
                fontWeight: FontWeight.w500,
                letterSpacing: -1,
              ),
            ),

            //당뇨 정보
            Text(
              '당뇨 정보',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF242526),
                fontSize: 21,
                fontFamily: 'KoPubDotum Bold',
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),

            SizedBox(height: 23),

            //1형 당뇨 체크박스
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      type1Diabetes = !type1Diabetes;
                    });
                  },
                  child: Icon(
                    type1Diabetes
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: type1Diabetes
                        ? Color(0xFF74AE31)
                        : Color(0xFFCCCCCC),
                  ),
                ),

                SizedBox(width: 8),

                Text(
                  '1형 당뇨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 17,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            //2형 당뇨 체크박스
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      type2Diabetes = !type2Diabetes;
                    });
                  },
                  child: Icon(
                    type2Diabetes
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: type2Diabetes
                        ? Color(0xFF74AE31)
                        : Color(0xFFCCCCCC),
                  ),
                ),

                SizedBox(width: 8),

                Text(
                  '2형 당뇨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 17,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            //당뇨 전 단계 체크박스
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      preDiabetes = !preDiabetes;
                    });
                  },
                  child: Icon(
                    preDiabetes
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: preDiabetes ? Color(0xFF74AE31) : Color(0xFFCCCCCC),
                  ),
                ),

                SizedBox(width: 8),

                Text(
                  '당뇨 전 단계',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 17,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            //선택 없음 체크박스
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      notApplicable = !notApplicable;
                    });
                  },
                  child: Icon(
                    notApplicable
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: notApplicable
                        ? Color(0xFF74AE31)
                        : Color(0xFFCCCCCC),
                  ),
                ),

                SizedBox(width: 8),

                Text(
                  '선택 없음',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 17,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 유제품 정보
  Widget _dairyInformation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 29.0, vertical: 27.0),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 유제품 정보
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '유제품 정보',
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 21,
                    fontFamily: 'KoPubDotum Bold',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),

                SizedBox(width: 3),

                Text(
                  '* 유당불내증은 사람마다 반응이 달라요.\n   선택 시 참고 정보로만 활용돼요.',
                  style: TextStyle(
                    color: const Color(0xFF73AD31),
                    fontSize: 12,
                    fontFamily: 'KoPubDotum Light',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            SizedBox(height: 23),

            //섭취가능 체크박스
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      edible = !edible;
                    });
                  },
                  child: Icon(
                    edible
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: edible ? Color(0xFF74AE31) : Color(0xFFCCCCCC),
                  ),
                ),

                SizedBox(width: 8),

                Text(
                  '섭취 가능',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 17,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            //섭취 불가능 체크박스
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      inedible = !inedible;
                    });
                  },
                  child: Icon(
                    inedible
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: inedible ? Color(0xFF74AE31) : Color(0xFFCCCCCC),
                  ),
                ),

                SizedBox(width: 8),

                Text(
                  '섭취 불가능',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 17,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            //유당불내증 체크박스
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      lactoseIntolerance = !lactoseIntolerance;
                    });
                  },
                  child: Icon(
                    lactoseIntolerance
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: lactoseIntolerance
                        ? Color(0xFF74AE31)
                        : Color(0xFFCCCCCC),
                  ),
                ),

                SizedBox(width: 8),

                Text(
                  '유당불내증',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 17,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // 알러지 정보
  Widget _allergyInformation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 29.0, vertical: 27.0),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '알러지 정보',
              style: TextStyle(
                color: const Color(0xFF242526),
                fontSize: 21,
                fontFamily: 'KoPubDotum Bold',
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),

            SizedBox(height: 11),

            Row(
              children: [
                Container(
                  height: 21,
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF6FFE4),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: const Color(0xFFB8DE8D),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  child: Row(
                    children: [
                      Icon(
                        Icons.close,
                        color: const Color(0xFFB8DE8D),
                        size: 17,
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '키위',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF73AD31),
                            fontSize: 12,
                            fontFamily: 'KoPubDotum Medium',
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 11),

            //입력창
            Container(
              width: 256,
              height: 32,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDDDDD), width: 1.37),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: '직접 입력해서 추가해주세요!',

                  hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),

                  filled: true,
                  fillColor: Colors.white,

                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 0,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Color(0xFF73AD31)),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // 카페인 정보
  Widget _caffeineInformation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 29.0, vertical: 27.0),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카페인 정보
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '카페인 정보',
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 21,
                    fontFamily: 'KoPubDotum Bold',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),

                SizedBox(width: 3),

                Text(
                  '* 카페인은 사람에 따라 영향을 다르게 줄 수 있어요. \n 선택 시 참고 정보로만 활용돼요.',
                  style: TextStyle(
                    color: const Color(0xFF73AD31),
                    fontSize: 12,
                    fontFamily: 'KoPubDotum Light',
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            SizedBox(height: 23),

            // 카페인 섭취 가능 체크박스
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      caffeineEdible = !caffeineEdible;
                    });
                  },
                  child: Icon(
                    caffeineEdible
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: caffeineEdible
                        ? Color(0xFF74AE31)
                        : Color(0xFFCCCCCC),
                  ),
                ),

                SizedBox(width: 8),

                Text(
                  '섭취 가능',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 17,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            // 카페인 섭취 불가능 체크박스
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      caffeineInedible = !caffeineInedible;
                    });
                  },
                  child: Icon(
                    caffeineInedible
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: caffeineInedible
                        ? Color(0xFF74AE31)
                        : Color(0xFFCCCCCC),
                  ),
                ),

                SizedBox(width: 8),

                Text(
                  '섭취 불가능',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 17,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            SizedBox(height: 40),

            // 고카페인 위험군
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '고카페인 정보',
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 21,
                    fontFamily: 'KoPubDotum Bold',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            SizedBox(height: 23),

            // 임신 가능성 체크박스
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pregnancy = !pregnancy;
                    });
                  },
                  child: Icon(
                    pregnancy
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: pregnancy ? Color(0xFF74AE31) : Color(0xFFCCCCCC),
                  ),
                ),

                SizedBox(width: 8),

                Text(
                  '임신/ 임신 가능성',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 17,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            // 기타질환 체크박스
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      otherDiseases = !otherDiseases;
                    });
                  },
                  child: Icon(
                    otherDiseases
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: otherDiseases
                        ? Color(0xFF74AE31)
                        : Color(0xFFCCCCCC),
                  ),
                ),

                SizedBox(width: 8),

                Text(
                  '고혈압 및 기타 질환',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 17,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            // 미성년자 체크박스
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      minor = !minor;
                    });
                  },
                  child: Icon(
                    minor
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: minor ? Color(0xFF74AE31) : Color(0xFFCCCCCC),
                  ),
                ),

                SizedBox(width: 8),

                Text(
                  '미성년자',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 17,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 다이어트 정보
  Widget _dietInformation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 29.0, vertical: 27.0),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '다이어트 정보',
              style: TextStyle(
                color: const Color(0xFF242526),
                fontSize: 21,
                fontFamily: 'KoPubDotum Bold',
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),

            SizedBox(height: 22),

            Row(
              children: [
                Column(
                  children: [
                    // 신장 선택
                    Container(
                      width: 160,
                      height: 37,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          width: 1.5,
                          color: const Color(0xFFEDEDED),
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 9),
                          Text(
                            '신장',
                            style: TextStyle(
                              color: const Color(0xFFA9A9A9),
                              fontSize: 13,
                              fontFamily: 'KoPubDotum Medium',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -1,
                            ),
                          ),

                          SizedBox(width: 7),

                          Text(
                            '선택하기',
                            style: TextStyle(
                              color: const Color(0xFF73AD31),
                              fontSize: 13,
                              fontFamily: 'KoPubDotum Light',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 7),

                    // 체중 선택
                    Container(
                      width: 160,
                      height: 37,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          width: 1.5,
                          color: const Color(0xFFEDEDED),
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),

                      child: Row(
                        children: [
                          SizedBox(width: 9),
                          Text(
                            '체중',
                            style: TextStyle(
                              color: const Color(0xFFA9A9A9),
                              fontSize: 13,
                              fontFamily: 'KoPubDotum Medium',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -1,
                            ),
                          ),

                          SizedBox(width: 7),

                          Text(
                            '선택하기',
                            style: TextStyle(
                              color: const Color(0xFF73AD31),
                              fontSize: 13,
                              fontFamily: 'KoPubDotum Light',
                              fontWeight: FontWeight.w300,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(width: 8),

                // 나의 BMI 계산
                Container(
                  width: 160,
                  height: 81,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      width: 1.5,
                      color: const Color(0xFFEDEDED),
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 9),
                      Text(
                        '나의 BMI',
                        style: TextStyle(
                          color: const Color(0xFFA9A9A9),
                          fontSize: 13,
                          fontFamily: 'KoPubDotum Medium',
                          fontWeight: FontWeight.w500,
                          letterSpacing: -1,
                        ),
                      ),

                      Text(
                        '00.00',
                        style: TextStyle(
                          color: const Color(0xFFA9A9A9),
                          fontSize: 30,
                          fontFamily: 'KoPubDotum Medium',
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '목표 체중 : ',
                  style: TextStyle(
                    color: const Color(0xFF242526),
                    fontSize: 15,
                    fontFamily: 'KoPubDotum Medium',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1,
                  ),
                ),

                SizedBox(width: 5),

                Container(
                  width: 100,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: const Color(0xFFBBBBBB),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
