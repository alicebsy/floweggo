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
  // 카드 양옆이 살짝 보이도록 설정 (0.88)
  final PageController _pageController = PageController(viewportFraction: 0.88);
  final db = DbHelper();
  final ImagePicker _picker = ImagePicker();
  int _currentPage = 0;

  // ----------------------------------------------------------------------
  // 1. 목표 수정 팝업 (기능 유지)
  // ----------------------------------------------------------------------
  void _showEditGoalDialog(int index, Goal goal) {
    final nameController = TextEditingController(text: goal.name);
    final periodController = TextEditingController(text: goal.period.toString());
    String selectedFreq = goal.frequency;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setST) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: const Text("수정이닭! ✏️", style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "목표 이름",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: periodController,
                  decoration: InputDecoration(
                    labelText: "목표 기간(일)",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                const Align(alignment: Alignment.centerLeft, child: Text("빈도 선택이닭", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold))),
                DropdownButton<String>(
                  value: ["매일", "격일", "주 3회"].contains(selectedFreq) ? selectedFreq : "매일",
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: ["매일", "격일", "주 3회"].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setST(() => selectedFreq = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.grey))),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD35400), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: const Text("입양할닭! 🐣", style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "어떤 알을 키울 거냐닭?",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: periodController,
                  decoration: InputDecoration(
                    labelText: "목표 기간(일)",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                DropdownButton<String>(
                  value: selectedFreq,
                  isExpanded: true,
                  underline: const SizedBox(),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD35400), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text("입양하기"),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text("인증 방법을 선택해주세닭!", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 10),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFFDF2E9), child: Icon(Icons.camera_alt, color: Color(0xFFD35400))),
              title: const Text("카메라로 촬영이닭"),
              onTap: () { Navigator.pop(context); _handleAuth(index, ImageSource.camera); },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFFDF2E9), child: Icon(Icons.photo_library, color: Color(0xFFD35400))),
              title: const Text("갤러리에서 선택이닭"),
              onTap: () { Navigator.pop(context); _handleAuth(index, ImageSource.gallery); },
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAuth(int index, ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;
    if (!mounted) return;

    final String? resultDesc = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCheckScreen(
          imagePath: image.path,
          goal: db.activeGoals[index],
        ),
      ),
    );

    if (resultDesc != null) {
      setState(() {
        db.recordProgress(index, image.path, resultDesc);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("인증 성공! 온도가 올라갔닭 🔥"), behavior: SnackBarBehavior.floating)
      );
    }
  }

  // ----------------------------------------------------------------------
  // 4. UI 구성 (오버플로우 해결 버전)
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("부화장이닭! 🥚", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _showAddGoalDialog, icon: const Icon(Icons.add_circle_outline_rounded, size: 28)),
          const SizedBox(width: 10),
        ],
      ),
      body: db.activeGoals.isEmpty
          ? _buildEmptyUI()
          : Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: db.activeGoals.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final goal = db.activeGoals[index];
              return _buildGoalCard(goal, index);
            },
          ),
          // 화살표
          if (_currentPage > 0)
            _buildNavArrow(Icons.arrow_back_ios_new_rounded, Alignment.centerLeft,
                    () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
          if (_currentPage < db.activeGoals.length - 1)
            _buildNavArrow(Icons.arrow_forward_ios_rounded, Alignment.centerRight,
                    () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 40, offset: const Offset(0, 15))],
      ),
      // 🔥 [해결] 공간이 부족할 경우 스크롤이 가능하도록 감쌈
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFFDF2E9), borderRadius: BorderRadius.circular(20)),
                  child: Text("D-${goal.period - goal.currentDays} 남았닭", style: const TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                Row(
                  children: [
                    IconButton(onPressed: () => _showEditGoalDialog(index, goal), icon: const Icon(Icons.edit_note_rounded, color: Colors.grey, size: 26), constraints: const BoxConstraints(), padding: EdgeInsets.zero),
                    const SizedBox(width: 8),
                    IconButton(onPressed: () { setState(() => db.activeGoals.removeAt(index)); }, icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 22), constraints: const BoxConstraints(), padding: EdgeInsets.zero),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 🔥 [해결] 이모지가 너무 크면 자동으로 줄어들게 처리
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(goal.emoji, style: const TextStyle(fontSize: 110)),
            ),
            const SizedBox(height: 15),
            Text(goal.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text("${goal.frequency} 지키고 있닭!", style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            _buildGrowthBar(goal),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showImageSourceSheet(index),
                icon: const Icon(Icons.local_fire_department_rounded, size: 20),
                label: const Text("🔥 온도 높이기닭!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2D2D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthBar(Goal goal) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("성장 에너지닭!", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black54)),
            Text("${goal.temperature.toInt()}%", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD35400), fontSize: 18)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: LinearProgressIndicator(
            value: goal.progress,
            minHeight: 12,
            backgroundColor: const Color(0xFFF1F3F5),
            color: const Color(0xFFE67E22),
          ),
        ),
      ],
    );
  }

  Widget _buildNavArrow(IconData icon, Alignment alignment, VoidCallback onTap) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: IconButton(icon: Icon(icon, color: Colors.black12, size: 30), onPressed: onTap),
      ),
    );
  }

  Widget _buildEmptyUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🛖", style: TextStyle(fontSize: 80)),
          const SizedBox(height: 20),
          const Text("둥지가 텅 비었닭!\n새로운 알을 입양해 보겠닭?", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _showAddGoalDialog,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD35400), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            child: const Text("+ 새 알 입양하기닭"),
          ),
        ],
      ),
    );
  }
}