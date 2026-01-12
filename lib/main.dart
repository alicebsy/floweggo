import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/farm_screen.dart';
import 'screens/gallery_screen.dart';

void main() => runApp(const CozyFarmApp());

class CozyFarmApp extends StatelessWidget {
  const CozyFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // 앱 전체 기본 폰트 및 테마 설정
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFF9C4),
        fontFamily: 'Pretendard',
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 1; // 1: 홈(인큐베이터)부터 시작

  // 각 탭에 연결될 화면들
  final _pages = [
    const GalleryScreen(),
    const HomeScreen(),
    const FarmScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔥 [핵심] 배경 이미지가 바닥 끝까지 보이도록 확장
      extendBody: true,

      body: _pages[_index],

      // ✨ 자연스럽게 스며드는 그라데이션 내비게이션 바
      bottomNavigationBar: Container(
        height: 85, // 그라데이션이 부드럽게 퍼질 충분한 높이
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,             // 위쪽: 투명 (배경 보임)
              Colors.black.withOpacity(0.85), // 아래쪽: 진한 어둠 (텍스트 가독성)
            ],
            stops: const [0.0, 1.0], // 부드럽게 이어짐
          ),
        ),
        child: SafeArea(
          top: false, // 상단은 무시 (그라데이션 영역)
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.photo_library_outlined, Icons.photo_library, "성장기록"),
                _buildNavItem(1, Icons.egg_outlined, Icons.egg_rounded, "인큐베이터", isMain: true),
                _buildNavItem(2, Icons.agriculture_outlined, Icons.agriculture, "나의 농장"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 버튼 아이템 빌더
  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, {bool isMain = false}) {
    bool isSelected = _index == index;

    // 🎨 색상 테마: 어두운 배경 위에서 빛나는 느낌
    const Color activeColor = Color(0xFF66BB6A); // 새싹 그린 (형광빛 느낌으로 강조)
    const Color inactiveColor = Colors.white60;  // 은은한 화이트

    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘 애니메이션
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0, // 선택 시 살짝 커짐
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: isMain ? 32 : 26, // 중앙 아이콘은 조금 더 크게
                shadows: isSelected
                    ? [BoxShadow(color: activeColor.withOpacity(0.6), blurRadius: 12)] // 선택 시 빛나는 효과
                    : null,
              ),
            ),
            const SizedBox(height: 5),
            // 텍스트 라벨
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                shadows: [
                  BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 4), // 텍스트 뒤 그림자로 가독성 확보
                ],
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
 }