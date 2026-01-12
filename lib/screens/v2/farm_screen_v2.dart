import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/db_helper.dart';
import '../../models/goal_model.dart';

class FarmScreenV2 extends StatefulWidget {
  const FarmScreenV2({super.key});

  @override
  State<FarmScreenV2> createState() => _FarmScreenV2State();
}

class _FarmScreenV2State extends State<FarmScreenV2> {
  final db = DbHelper();
  String _userName = "사용자";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "사용자";
    });
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    setState(() {
      _userName = name;
    });
  }

  void _showNameDialog() {
    final controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("사용자 이름 설정", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "이름을 입력하세요",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFarmEmpty = db.completedFarm.isEmpty && db.activeGoals.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: Colors.white,
            title: GestureDetector(
              onTap: _showNameDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      "$_userName님의 목표 대시보드",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_outlined, size: 20, color: Colors.black26),
                ],
              ),
            ),
            centerTitle: false,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: isFarmEmpty
                ? SliverFillRemaining(hasScrollBody: false, child: _buildEmptyUI())
                : SliverList(
              delegate: SliverChildListDelegate([
                _buildSummaryStats(),
                const SizedBox(height: 32),

                _buildSectionHeader("진행 중인 목표", db.activeGoals.length, Colors.blueAccent),
                ...db.activeGoals.map((g) => _buildGoalItem(g, false)).toList(),

                const SizedBox(height: 32),

                _buildSectionHeader("달성 완료 항목", db.completedFarm.length, Colors.green),
                ...db.completedFarm.map((g) => _buildGoalItem(g, true)).toList(),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statColumn("완료한 목표", "${db.completedFarm.length}"),
          Container(width: 1, height: 40, color: Colors.white24),
          _statColumn("진행 중인 목표", "${db.activeGoals.length}"),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text("$count", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(Goal goal, bool isDone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(isDone ? "✅" : goal.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(
                  isDone ? "목표를 성공적으로 달성했습니다." : "현재 달성률 ${(goal.progress * 100).toInt()}%",
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isDone)
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28)
          else
            SizedBox(
              width: 36, height: 36,
              child: CircularProgressIndicator(
                value: goal.progress,
                strokeWidth: 4,
                backgroundColor: Colors.grey.shade100,
                color: Colors.blueAccent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          Text("기록된 데이터가 없습니다.", style: TextStyle(color: Colors.black26, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}