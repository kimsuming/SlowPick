import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

class BloodSugarNoteScreen extends StatelessWidget {
  const BloodSugarNoteScreen({super.key});

  static const Color textColor = Color(0xFF242526);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        title: const Text(
          '거부기의 혈당 노트',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(15, 18, 15, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  '2026년 01월 10일',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              const Center(
                child: Text(
                  '3일간 고혈당이 지속되고 있어요!\n특별한 관리가 필요해요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    height: 1.35,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                height: 183,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  image: const DecorationImage(
                    image: NetworkImage('https://imgur.com/xlOj9VO.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                '최근 6일간의 혈당 기록',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 32),

              const Row(
                children: [
                  Expanded(
                    child: BloodSugarSummaryCard(
                      title: '최고 혈당',
                      value: 175,
                      valueColor: Color(0xFF99000F),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: BloodSugarSummaryCard(
                      title: '최저 혈당',
                      value: 100,
                      valueColor: Color(0xFF000099),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const BloodSugarRecordTile(
                label: '식후 19:38',
                value: 175,
                valueColor: Color(0xFFD40707),
              ),

              const SizedBox(height: 16),

              const BloodSugarRecordTile(
                label: '공복 14:40',
                value: 100,
                valueColor: Color(0xFF73AD31),
              ),

              const SizedBox(height: 36),

              Center(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    '기록 추가하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 34,
                      vertical: 14,
                    ),
                    backgroundColor: const Color(0xFF81DB60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BloodSugarSummaryCard extends StatelessWidget {
  final String title;
  final int value;
  final Color valueColor;

  const BloodSugarSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF242526),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$value',
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: ' mg/dL',
                  style: TextStyle(
                    color: Color(0xFF242526),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

class BloodSugarRecordTile extends StatelessWidget {
  final String label;
  final int value;
  final Color valueColor;

  const BloodSugarRecordTile({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: 1.5,
          color: const Color(0xFFCCCCCC),
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFA9A9A9),
              fontSize: 17,
            ),
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$value',
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: ' mg/dL',
                  style: TextStyle(
                    color: Color(0xFF242526),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.more_vert,
            size: 20,
            color: Color(0xFF999999),
          ),
        ],
      ),
    );
  }
}
