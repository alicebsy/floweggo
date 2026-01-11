import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import '../database/db_helper.dart';
import '../models/goal_model.dart';
import '../screens/image_check_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  final db = DbHelper();
  final ImagePicker _picker = ImagePicker();

  // 현재 몇 번째 페이지인지 확인하기 위한 변수 (화살표 표시용)
  int _currentPage = 0;

  // ----------------------------------------------------------------------
  // 1. 목표 수정 팝업
  // ----------------------------------------------------------------------
  void _showEditGoalDialog(int index, Goal goal) {
    final nameController = TextEditingController(text: goal.name);
    final periodController = TextEditingController(text: goal.period.toString());
    String selectedFreq = goal.frequency;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setST) => AlertDialog(
          title: const Text("수정이닭! ✏️"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "목표 이름")),
                TextField(controller: periodController, decoration: const InputDecoration(labelText: "목표 기간(일)"), keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                const Align(alignment: Alignment.centerLeft, child: Text("빈도", style: TextStyle(fontSize: 12, color: Colors.grey))),
                DropdownButton<String>(
                  value: ["매일", "격일", "주 3회"].contains(selectedFreq) ? selectedFreq : "매일",
                  isExpanded: true,
                  items: ["매일", "격일", "주 3회"].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setST(() => selectedFreq = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  goal.name = nameController.text;
                  goal.period = int.parse(periodController.text);
                  goal.frequency = selectedFreq;
                  goal.temperature = (goal.currentDays / goal.period) * 100;
                });
                Navigator.pop(context);
              },
              child: const Text("수정 완료"),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // 2. 새 알 입양 팝업
  // ----------------------------------------------------------------------
  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final periodController = TextEditingController(text: "30");
    String selectedFreq = "매일";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setST) => AlertDialog(
          title: const Text("입양할닭! 🐣"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "목표 이름")),
                TextField(controller: periodController, decoration: const InputDecoration(labelText: "목표 기간(일)"), keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                const Align(alignment: Alignment.centerLeft, child: Text("빈도", style: TextStyle(fontSize: 12, color: Colors.grey))),
                DropdownButton<String>(
                  value: selectedFreq,
                  isExpanded: true,
                  items: ["매일", "격일", "주 3회"].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setST(() => selectedFreq = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    db.addGoal(Goal(
                      id: DateTime.now().toString(),
                      name: nameController.text,
                      period: int.parse(periodController.text),
                      frequency: selectedFreq,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("입양"),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // 3. 인증 기능
  // ----------------------------------------------------------------------
  void _showImageSourceSheet(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 15),
            const Text("인증 방법을 선택해주세닭!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.brown),
              title: const Text("카메라로 촬영"),
              onTap: () { Navigator.pop(context); _handleAuth(index, ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.brown),
              title: const Text("갤러리에서 선택"),
              onTap: () { Navigator.pop(context); _handleAuth(index, ImageSource.gallery); },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAuth(int index, ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    if (!mounted) return;
    // pcw의 AI 검열 화면으로 이동하여 인증 수행
    final String? resultDesc = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCheckScreen(
          imagePath: image.path,
          goal: db.activeGoals[index], // bsy 모델 객체 전달
        ),
      ),
    );

    // 인증 성공 시(설명 텍스트가 반환됨) DB 업데이트
    if (resultDesc != null) {
      setState(() {
        db.recordProgress(index, image.path, resultDesc);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("인증 성공! 온도가 올라갔닭 🔥"))
      );
    }


    // 기존 인증 코드
/*    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.brown),
            SizedBox(height: 20),
            Text("AI로 확인 중...", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );

    Timer(const Duration(seconds: 2), () {
      Navigator.pop(context);
      setState(() { db.recordProgress(index, image.path, image.); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("인증 성공! 온도가 올라갔닭 🔥")));
    }*/
  }

  // ----------------------------------------------------------------------
  // 4. UI 구성
  // ----------------------------------------------------------------------
  Widget _buildEmptyUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🛖", style: TextStyle(fontSize: 100)),
          const SizedBox(height: 20),
          const Text("둥지가 텅 비었닭!\n새 알을 입양해 주세요.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10)])),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _showAddGoalDialog, child: const Text("+ 새로운 알 입양하기")),
        ],
      ),
    );
  }

  Widget _buildTempBar(Goal goal) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("온도", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("${goal.temperature.toInt()}°C / 100°C", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 280,
          height: 18,
          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: goal.progress, color: Colors.orangeAccent, backgroundColor: Colors.transparent),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: Image.asset('assets/images/sum.png', fit: BoxFit.cover)),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: db.activeGoals.isEmpty
                      ? _buildEmptyUI()
                  // 🔥 [핵심 수정] PageView와 화살표를 겹치기 위해 Stack 사용
                      : Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: db.activeGoals.length,
                        onPageChanged: (index) {
                          // 페이지가 넘어갈 때 현재 페이지 번호 업데이트 (화살표 표시 여부 결정)
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final goal = db.activeGoals[index];
                          return Column(
                            children: [
                              const SizedBox(height: 40),
                              const Spacer(flex: 4), // 넉넉한 상단 여백

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      goal.name,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        shadows: [Shadow(blurRadius: 10)],
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(onPressed: () => _showEditGoalDialog(index, goal), icon: const Icon(Icons.edit, color: Colors.white70, size: 24)),
                                  IconButton(onPressed: () { setState(() => db.activeGoals.removeAt(index)); }, icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 24)),
                                ],
                              ),

                              const SizedBox(height: 10),
                              Text("D-${goal.period - goal.currentDays} (${goal.frequency})", style: const TextStyle(fontSize: 18, color: Colors.white70)),

                              const Spacer(flex: 1),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(goal.emoji, style: const TextStyle(fontSize: 140)),
                              ),
                              const Spacer(flex: 1),
                              _buildTempBar(goal),
                              const Spacer(flex: 2),

                              ElevatedButton.icon(
                                onPressed: () => _showImageSourceSheet(index),
                                icon: const Icon(Icons.local_fire_department),
                                label: const Text("🔥 온도 높이기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.brown, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                              ),

                              const SizedBox(height: 15),

                              TextButton(
                                onPressed: _showAddGoalDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                                  child: const Text("+ 다른 알 입양하기", style: TextStyle(color: Colors.white, fontSize: 14)),
                                ),
                              ),
                              const Spacer(flex: 2),
                            ],
                          );
                        },
                      ),

                      // 🔥 [왼쪽 화살표] 첫 번째 페이지가 아닐 때만 보임
                      if (_currentPage > 0)
                        Positioned(
                          left: 10,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 40),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),

                      // 🔥 [오른쪽 화살표] 마지막 페이지가 아닐 때만 보임
                      if (_currentPage < db.activeGoals.length - 1)
                        Positioned(
                          right: 10,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 40),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),
                    ],
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