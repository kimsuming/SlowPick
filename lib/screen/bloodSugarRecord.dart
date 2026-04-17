import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/screen/bloodSugarNote.dart';

class BloodSugarRecord extends StatefulWidget {
  const BloodSugarRecord({super.key});

  @override
  State<BloodSugarRecord> createState() => _BloodSugarRecordState();
}

class _BloodSugarRecordState extends State<BloodSugarRecord> {
  TimeOfDay selectedTime = TimeOfDay(hour: 00, minute: 00);
  String selectedValue = '아침 식전';
  bool insulin = true;
  bool medicine = false;

  // 시간 선택 함수
  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      bottomNavigationBar: Container(
        //바텀 바
        color: Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),

      appBar: AppBar(
        title: const Text('혈당 기록 추가하기'),
        centerTitle: true,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Color(0xFF242526),
          fontSize: 20,
          fontFamily: 'KoPubDotum Medium',
          letterSpacing: -1.30,
        ),
        automaticallyImplyLeading: false,
      ),

      backgroundColor: Color(0xFFF6F6F6),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                SizedBox(height: 20),

                _time(size),

                SizedBox(height: 20),

                _timeZone(size),

                SizedBox(height: 20),

                _bloodSugarLevel(size),

                SizedBox(height: 20),

                _insulin(size),

                SizedBox(height: 20),

                _medicine(size),

                SizedBox(height: 72),

                _addButton(size),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 시간
  Widget _time(size) {
    return Container(
      width: size.width * 0.9,
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 8,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text(
                '시간',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.60,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 21.0),
              child: GestureDetector(
                onTap: () => _pickTime(context), //클릭 시 실행
                child: Row(
                  children: [
                    Text(
                      selectedTime.format(context), //시간 표시
                      style: TextStyle(
                        color: const Color(0xFF242526),
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.84,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 시간대
  Widget _timeZone(size) {
    return Container(
      width: size.width * 0.9,
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 8,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text(
                '시간대',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.60,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 21.0),
              child: DropdownButton<String>(
                value: selectedValue,
                underline: SizedBox(),
                items: ['아침 식전', '아침 식후', '점심 식전', '점심 식후']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: const Color(0xFF242526),
                            fontSize: 26,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.78,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedValue = newValue!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 혈당 수치
  Widget _bloodSugarLevel(size) {
    return Container(
      width: size.width * 0.9,
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 8,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text(
                '혈당 수치',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.60,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 21.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF242526),
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -0.84,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.only(bottom: 4),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 2),
                  Text(
                    'mg/dL',
                    style: TextStyle(
                      color: const Color(0xFF242526),
                      fontSize: 23,
                      fontFamily: 'KoPubDotum Light',
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.69,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 인슐린 투여
  Widget _insulin(size) {
    return Container(
      width: size.width * 0.9,
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 8,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text(
                '인슐린 투여',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.60,
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                setState(() {
                  insulin = !insulin;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Icon(
                  insulin ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 38,
                  color: Color(0xFFBBBBBB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 약 복용
  Widget _medicine(size) {
    return Container(
      width: size.width * 0.9,
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 8,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text(
                '약 복용',
                style: TextStyle(
                  color: const Color(0xFF999999),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.60,
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                setState(() {
                  medicine = !medicine;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Icon(
                  medicine ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 38,
                  color: Color(0xFFBBBBBB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton(size) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BloodSugarNote()),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: const Color(0xFFBBBBBB), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 65),
            ),
            child: Text(
              '취소',
              style: TextStyle(
                color: const Color(0xFF999999),
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.54,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFBBBBBB),
              side: BorderSide(color: const Color(0xFFBBBBBB), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 50),
            ),
            child: Text(
              '추가하기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
