import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// v1 화면들 import (클래스명 끝에 V1이 붙은 버전)
import 'screens/v1/home_screen_v1.dart';
import 'screens/v1/farm_screen_v1.dart';
import 'screens/v1/gallery_screen_v1.dart';

// v2 화면들 import (클래스명 끝에 V2가 붙은 버전)
import 'screens/v2/home_screen_v2.dart';
import 'screens/v2/farm_screen_v2.dart';
import 'screens/v2/gallery_screen_v2.dart';

// 테마 상태를 관리하는 전역 노티파이어
final ValueNotifier<bool> isModernTheme = ValueNotifier<bool>(true);

void main() => runApp(const CozyFarmApp());

class CozyFarmApp extends StatelessWidget {
  const CozyFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isModernTheme,
      builder: (context, isModern, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Floweggo',
          // 현대적인 테마(v2)와 클래식한 테마(v1) 분기
          theme: isModern ? _modernTheme() : _classicTheme(),
          home: const MainNavigation(),
        );
      },
    );
  }

  // 모던 테마 (Version 2 전용)
  ThemeData _modernTheme() => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFFDFCFB),
    colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE67E22),
        primary: const Color(0xFFD35400)
    ),
    textTheme: GoogleFonts.notoSansKrTextTheme(),
  );

  // 클래식 테마 (Version 1 전용)
  ThemeData _classicTheme() => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFFFF9C4),
    fontFamily: 'Pretendard', // v1에서 사용하던 기본 폰트 적용
  );
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 1; // 기본적으로 홈(인큐베이터/부화장) 탭 선택

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isModernTheme,
      builder: (context, isModern, child) {
        // 현재 테마에 따라 표시할 페이지 리스트 결정
        final List<Widget> pages = isModern
            ? [const GalleryScreenV2(), const HomeScreenV2(), const FarmScreenV2()]
            : [const GalleryScreenV1(), const HomeScreenV1(), const FarmScreenV1()];

        return Scaffold(
          // v1의 배경 이미지가 바닥까지 보이도록 설정
          extendBody: !isModern,

          body: pages[_index],

          // 테마 전환용 플로팅 버튼
          floatingActionButton: FloatingActionButton.small(
            onPressed: () => isModernTheme.value = !isModernTheme.value,
            backgroundColor: isModern ? const Color(0xFFD35400) : Colors.brown,
            child: Icon(
                isModern ? Icons.history : Icons.history,
                color: Colors.white
            ),
          ),

          // 테마에 따른 내비게이션 바 분기
          bottomNavigationBar: isModern ? _buildModernNav() : _buildClassicNav(),
        );
      },
    );
  }

  // Version 2: Material 3 스타일의 깔끔한 내비게이션 바
  Widget _buildModernNav() => NavigationBar(
    selectedIndex: _index,
    onDestinationSelected: (i) => setState(() => _index = i),
    destinations: const [
      NavigationDestination(icon: Icon(Icons.auto_awesome_motion_rounded), label: "기록이닭"),
      NavigationDestination(icon: Icon(Icons.egg_rounded), label: "부화장이닭"),
      NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: "농장이닭"),
    ],
  );

  // Version 1: 커스텀 그라데이션이 적용된 클래식 내비게이션 바
  Widget _buildClassicNav() => Container(
    height: 85,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.85),
        ],
      ),
    ),
    child: SafeArea(
      top: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildV1NavItem(0, Icons.photo_library_outlined, Icons.photo_library, "성장기록"),
          _buildV1NavItem(1, Icons.egg_outlined, Icons.egg_rounded, "인큐베이터", isMain: true),
          _buildV1NavItem(2, Icons.agriculture_outlined, Icons.agriculture, "나의 농장"),
        ],
      ),
    ),
  );

  // v1 내비게이션 전용 아이템 빌더
  Widget _buildV1NavItem(int index, IconData icon, IconData activeIcon, String label, {bool isMain = false}) {
    bool isSelected = _index == index;
    const Color activeColor = Color(0xFF66BB6A);
    const Color inactiveColor = Colors.white60;

    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? activeColor : inactiveColor,
            size: isMain ? 32 : 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}