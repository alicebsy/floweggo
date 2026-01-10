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
      theme: ThemeData(scaffoldBackgroundColor: const Color(0xFFFFF9C4)),
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
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: "성장기록"),
          BottomNavigationBarItem(icon: Icon(Icons.egg), label: "인큐베이터"),
          BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: "나의 농장"),
        ],
      ),
    );
  }
}