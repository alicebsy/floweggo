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
  String _userName = "농부";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "농부";
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("이름 변경"),
        content: TextField(
          controller: controller,
          cursorColor: Colors.blueAccent,
          decoration: const InputDecoration(
            hintText: "이름을 입력하세요",
            filled: true,
            fillColor: Color(0xFFF0F4F8),
            border: InputBorder.none,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _saveUserName(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text("확인", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGoals = db.allGoals;
    final now = DateTime.now();

    final successGoals = allGoals.where((goal) => goal.temperature >= 100).toList();
    final growingGoals = allGoals.where((goal) {
      if (goal.temperature >= 100) return false;
      DateTime start; 
      try { start = DateTime.parse(goal.id); } catch(e) { start = DateTime.now(); }
      DateTime end = start.add(Duration(days: goal.period));
      return now.isBefore(end) || now.isAtSameMomentAs(end);
    }).toList();
    final failedGoals = allGoals.where((goal) {
      if (goal.temperature >= 100) return false;
      DateTime start; 
      try { start = DateTime.parse(goal.id); } catch(e) { start = DateTime.now(); }
      DateTime end = start.add(Duration(days: goal.period));
      return now.isAfter(end);
    }).toList();

    bool isFarmEmpty = growingGoals.isEmpty && successGoals.isEmpty && failedGoals.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            expandedHeight: 320,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 50),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                      color: Colors.white,
                    ),
                    child: const Text("👨🏻‍🌾", style: TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showNameDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$_userName님",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit_outlined, size: 20, color: Colors.black38),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildSummaryStats(
                        growing: growingGoals.length,
                        success: successGoals.length,
                        failed: failedGoals.length
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: isFarmEmpty
                ? SliverFillRemaining(hasScrollBody: false, child: _buildEmptyUI())
                : SliverList(
              delegate: SliverChildListDelegate([
                // 🔥 [수정] 각 섹션에 맞는 전용 위젯 호출
                if (growingGoals.isNotEmpty) ...[
                   _buildSectionHeader("진행 중인 목표", growingGoals.length, Colors.green),
                  ...growingGoals.reversed.map((g) => _buildGrowingCard(g)).toList(),
                ],
                if (successGoals.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader("달성 완료 항목", successGoals.length, Colors.brown),
                  ...successGoals.reversed.map((g) => _buildSuccessCard(g)).toList(),
                ],
                if (failedGoals.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader("실패한 목표", failedGoals.length, Colors.redAccent),
                  ...failedGoals.reversed.map((g) => _buildFailedCard(g)).toList(),
                ],
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats({required int growing, required int success, required int failed}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.brown,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statColumn("진행 중", "$growing", Colors.white),
          _statColumn("성공", "$success", Colors.lightGreenAccent),
          _statColumn("실패", "$failed", Colors.red[200]!),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: valueColor, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
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

  // 🔥 [삭제] _buildGoalItem 함수는 아래 3개의 함수로 분리되었습니다.
  // Widget _buildGoalItem(Goal_v2 goal, bool isDone, {bool isFailed = false}) { ... }

  // 🔥 [신규] 진행 중인 목표 카드
  Widget _buildGrowingCard(Goal goal) {
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
            child: Text(goal.emoji2, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 4),
                Text("현재 달성률 ${(goal.progress * 100).toInt()}%", style: const TextStyle(color: Colors.black45, fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            width: 36, height: 36,
            child: CircularProgressIndicator(
              value: goal.progress,
              strokeWidth: 4,
              backgroundColor: Colors.grey.shade100,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 [신규] 성공한 목표 카드
  Widget _buildSuccessCard(Goal goal) {
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
            child: const Text("🏵️", style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("목표 달성!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                SizedBox(height: 4),
                Text("성공적으로 완수했습니다.", style: TextStyle(color: Colors.black45, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 🔥 [신규] 실패한 목표 카드
  Widget _buildFailedCard(Goal goal) {
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
            child: const Text("🥀", style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("기간 만료", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                SizedBox(height: 4),
                Text("도전 기간이 만료되었습니다.", style: TextStyle(color: Colors.black45, fontSize: 13)),
              ],
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
