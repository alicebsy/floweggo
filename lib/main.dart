import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      theme: ThemeData(
        useMaterial3: true,
        // 따뜻하고 세련된 크림색 배경
        scaffoldBackgroundColor: const Color(0xFFFDFCFB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE67E22),
          primary: const Color(0xFFD35400),
          surface: Colors.white,
        ),
        // 둥글둥글하면서 가독성 좋은 폰트
        textTheme: GoogleFonts.notoSansKrTextTheme().apply(
          bodyColor: const Color(0xFF4E342E),
          displayColor: const Color(0xFF4E342E),
        ),
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
  int _index = 1;
  final _pages = [const GalleryScreen(), const HomeScreen(), const FarmScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 25)],
        ),
        child: NavigationBar(
          height: 75,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          indicatorColor: const Color(0xFFFDF2E9),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_motion_rounded, color: Colors.grey),
              selectedIcon: Icon(Icons.auto_awesome_motion_rounded, color: Color(0xFFD35400)),
              label: "성장기록이닭",
            ),
            NavigationDestination(
              icon: Icon(Icons.egg_rounded, color: Colors.grey),
              selectedIcon: Icon(Icons.egg_rounded, color: Color(0xFFD35400)),
              label: "부화장이닭",
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded, color: Colors.grey),
              selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFFD35400)),
              label: "농장이닭",
            ),
          ],
        ),
      ),
    );
  }
}