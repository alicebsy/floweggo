import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/farm_screen.dart';
import 'models/goal_model.dart'; // Goal 모델 임포트 확인

void main() => runApp(const FlowEggoApp());

class FlowEggoApp extends StatelessWidget {
  const FlowEggoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.notoSansKr(letterSpacing: -0.8, fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.notoSansKr(letterSpacing: -0.8, fontWeight: FontWeight.bold),
          bodyLarge: GoogleFonts.notoSansKr(letterSpacing: -0.5),
          bodyMedium: GoogleFonts.notoSansKr(letterSpacing: -0.5),
          titleMedium: GoogleFonts.notoSansKr(letterSpacing: -0.7, fontWeight: FontWeight.w600),
        ).apply(
          bodyColor: const Color(0xFF1D1D1F),
          displayColor: const Color(0xFF1D1D1F),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 1;

  // 핵심: 데이터를 Root에서 관리하여 탭 이동 시에도 유지함
  List<Goal> goalList = [];

  // 데이터 변경 시 화면을 다시 그리기 위한 함수
  void _updateData() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 탭별 페이지 구성 (데이터와 업데이트 함수 전달)
    final List<Widget> _pages = [
      GalleryScreen(goals: goalList),
      HomeScreen(goals: goalList, onUpdate: _updateData),
      const FarmScreen(),
    ];

    return Scaffold(
      // IndexedStack은 자식 위젯들의 상태(스크롤, 입력 데이터 등)를 메모리에 유지합니다.
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.orange,
          unselectedItemColor: const Color(0xFF8E8E93),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: -0.3),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: -0.3),
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined, size: 22), activeIcon: Icon(Icons.photo_library), label: '갤러리'),
            BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 22), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.eco_outlined, size: 22), activeIcon: Icon(Icons.eco), label: '나의 농장'),
          ],
        ),
      ),
    );
  }
}