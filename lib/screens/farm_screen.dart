import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/goal_model.dart';

class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  final db = DbHelper();
  String _userName = "초록 농부";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // ----------------------------------------------------------------------
  // 1. 사용자 이름 관리 기능 (기존 로직 유지)
  // ----------------------------------------------------------------------
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "초록 농부";
    });
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    setState(() {
      _userName = name;
    });
  }

  // 이름 수정 다이얼로그 (최신 스타일로 변경)
  void _showNameDialog() {
    final controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("이름을 정해달닭! ✍️", style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "새로운 이름을 입력해주세닭",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _saveUserName(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD35400),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("확인이닭"),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // 2. UI 구성 (최신 디자인 + "~이닭!" 컨셉)
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    bool isFarmEmpty = db.completedFarm.isEmpty && db.activeGoals.isEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 대형 앱바: 사용자 이름 표시 및 수정 기능 연동
          SliverAppBar.large(
            backgroundColor: const Color(0xFFFDFCFB),
            title: GestureDetector(
              onTap: _showNameDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("$_userName님의 농장이닭!", style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_rounded, size: 20, color: Colors.black26),
                ],
              ),
            ),
            centerTitle: false,
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            sliver: isFarmEmpty
                ? SliverFillRemaining(hasScrollBody: false, child: _buildEmptyUI())
                : SliverList(
              delegate: SliverChildListDelegate([
                _buildFarmStats(),
                const SizedBox(height: 35),

                _buildSectionHeader("🐣 부화 진행 중이닭", db.activeGoals.length),
                if (db.activeGoals.isEmpty)
                  _buildNoItemCard("아직 키우고 있는 알이 없닭!")
                else
                  ...db.activeGoals.map((g) => _buildFarmItem(g, false)).toList(),

                const SizedBox(height: 35),

                _buildSectionHeader("🐓 다 컸닭! 장하닭!", db.completedFarm.length),
                if (db.completedFarm.isEmpty)
                  _buildNoItemCard("성공해서 농장을 채워달닭!")
                else
                  ...db.completedFarm.map((g) => _buildFarmItem(g, true)).toList(),

                const SizedBox(height: 50),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // 상단 통계 카드
  Widget _buildFarmStats() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE67E22), Color(0xFFD35400)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: const Color(0xFFD35400).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("가족이 된 닭", "${db.completedFarm.length}마리"),
          _statItem("진행 중인 알", "${db.activeGoals.length}개"),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
            child: Text(count.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 농장 아이템 카드 (최신 스타일)
  Widget _buildFarmItem(Goal goal, bool isDone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: Text(isDone ? "🐓" : goal.emoji, style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(
                  isDone ? "우리 농장의 늠름한 일꾼이닭!" : "${goal.temperature.toInt()}% 부화 중이닭",
                  style: const TextStyle(color: Colors.black45, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (isDone)
            const Icon(Icons.stars_rounded, color: Colors.amber, size: 32)
          else
            SizedBox(
              width: 44, height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: goal.progress,
                    strokeWidth: 5,
                    backgroundColor: const Color(0xFFF1F3F5),
                    color: const Color(0xFFE67E22),
                  ),
                  Text("${(goal.progress * 100).toInt()}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoItemCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.black.withOpacity(0.05), style: BorderStyle.solid),
      ),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.black26, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildEmptyUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("🍃", style: TextStyle(fontSize: 60)),
        const SizedBox(height: 20),
        const Text("둥지가 텅 비었닭!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text("목표를 달성해서 농장을\n멋진 닭들로 채워달닭!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
      ],
    );
  }
}