import 'package:flutter/material.dart';
import 'package:slowpick/test/menu_tset1.dart';
import 'package:slowpick/test/menu_tset2.dart';
import 'package:slowpick/test/menu_tset3.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

class ButtonUiTest extends StatelessWidget {
  const ButtonUiTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SlowPick',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('SlowPick Home')),

      bottomNavigationBar: Container(
        //바텀 바
        color: Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 테스트 1번
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuScreen1()),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('1번 화면'),
            ),

            const SizedBox(height: 40), // 간격 띄우기

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuScreen2()),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('2번 화면'),
            ),

            const SizedBox(height: 40), // 간격 띄우기

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuScreen3()),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('3번 화면'),
            ),

            const SizedBox(height: 40), // 간격 띄우기
          ],
        ),
      ),
    );
  }
}
