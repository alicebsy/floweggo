import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/db_helper.dart';

class FarmScreenV1 extends StatefulWidget {
  const FarmScreenV1({super.key});

  @override
  State<FarmScreenV1> createState() => _FarmScreenV1State();
}

class _FarmScreenV1State extends State<FarmScreenV1> {
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

  void _deleteGoal(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("기록 삭제", style: TextStyle(color: Colors.white)),
        content: const Text("이 기록을 완전히 지우시겠습니까?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              db.deleteGoal(id);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showNameDialog() {
    final controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("이름 변경", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.brown,
          decoration: const InputDecoration(
            hintText: "이름을 입력하세요",
            filled: true,
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.brown)),
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
            child: const Text("확인", style: TextStyle(color: Colors.brown)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGoals = db.allGoals;
    final now = DateTime.now();

    // 데이터 분류
    final successGoals = allGoals.where((goal) => goal.temperature >= 100).toList().reversed.toList();
    final growingGoals = allGoals.where((goal) {
      if (goal.temperature >= 100) return false;
      DateTime start;
      try { start = DateTime.parse(goal.id); } catch(e) { start = DateTime.now(); }
      DateTime end = start.add(Duration(days: goal.period));
      return now.isBefore(end) || now.isAtSameMomentAs(end);
    }).toList().reversed.toList();
    final failedGoals = allGoals.where((goal) {
      if (goal.temperature >= 100) return false;
      DateTime start;
      try { start = DateTime.parse(goal.id); } catch(e) { start = DateTime.now(); }
      DateTime end = start.add(Duration(days: goal.period));
      return now.isAfter(end);
    }).toList().reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---------------------------------------------------------
            // 1. 상단 프로필 헤더 (기존 디자인 유지)
            // ---------------------------------------------------------
            Stack(
              children: [
                // 배경
                Container(
                  height: 250, // 🔥 높이 유지
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/bg_farm.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(color: Colors.black.withOpacity(0.6)),
                  ),
                ),

                // 내용
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 5), // 상단 여백 약간 축소
                        // 프로필 이미지
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: const Text("👨🏻‍🌾", style: TextStyle(fontSize: 50)),
                        ),
                        const SizedBox(height: 10),

                        // 이름
                        GestureDetector(
                          onTap: _showNameDialog,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _userName,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.edit, color: Colors.white54, size: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text("오늘도 부지런히 꿈을 키워요", style: TextStyle(color: Colors.white60, fontSize: 13)),

                        const SizedBox(height: 30), // 간격 약간 조정

                        // 📊 통계
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem("자라는 중", growingGoals.length.toString(), Colors.greenAccent),
                            _buildVerticalDivider(),
                            _buildStatItem("성공", successGoals.length.toString(), Colors.amberAccent),
                            _buildVerticalDivider(),
                            _buildStatItem("실패", failedGoals.length.toString(), Colors.redAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ---------------------------------------------------------
            // 2. 하단 리스트 영역 (위로 쭉 올림!)
            // ---------------------------------------------------------
            Transform.translate(
              // 🔥 [수정] offset -20 -> -60으로 변경하여 더 위로 올림
              offset: const Offset(0, -60),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                // 🔥 [수정] top 패딩을 30 -> 10으로 줄여서 내부 내용도 위로 붙임
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // 1. Growing
                    if (growingGoals.isNotEmpty) ...[
                      _buildSectionTitle("🌱 인큐베이터"),
                      const SizedBox(height: 15),
                      ...growingGoals.map((g) => _buildGrowingCard(g)).toList(),
                      const SizedBox(height: 30),
                    ],

                    // 2. Success (멘트 수정 적용)
                    if (successGoals.isNotEmpty) ...[
                      _buildSectionTitle("🐓 닭이 되었닭!"), // 멘트 수정
                      const SizedBox(height: 15),
                      GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: successGoals.length,
                        itemBuilder: (context, index) => _buildSuccessCard(successGoals[index]),
                      ),
                      const SizedBox(height: 30),
                    ],

                    // 3. Failed (멘트 수정 적용)
                    if (failedGoals.isNotEmpty) ...[
                      _buildSectionTitle("🍳 계란후라이가 되었닭..."), // 멘트 수정
                      const SizedBox(height: 15),
                      ...failedGoals.map((g) => _buildFailedCard(g)).toList(),
                    ],

                    // 4. 텅 비었을 때
                    if (allGoals.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 50),
                          child: Column(
                            children: const [
                              Icon(Icons.inbox, size: 50, color: Colors.white24),
                              SizedBox(height: 15),
                              Text("기록된 목표가 없어요.", style: TextStyle(color: Colors.white38)),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 위젯들 ---

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.white24);
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  // 🌱 성장 중 카드
  Widget _buildGrowingCard(var goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                child: Text(goal.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text("D-${goal.period - goal.currentDays} 남음", style: const TextStyle(fontSize: 12, color: Colors.greenAccent)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteGoal(goal.id),
                icon: const Icon(Icons.more_horiz, color: Colors.white30),
              )
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: Colors.black,
              color: Colors.greenAccent,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text("${goal.temperature.toInt()}℃ 달성 중", style: const TextStyle(fontSize: 11, color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  // 🐓 성공 카드
  Widget _buildSuccessCard(var goal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text("🐓", style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(goal.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text("성공!", style: TextStyle(fontSize: 10, color: Colors.amberAccent)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _deleteGoal(goal.id),
            child: const Icon(Icons.close, size: 14, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  // 🍳 실패 카드
  Widget _buildFailedCard(var goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Text("🍳", style: TextStyle(fontSize: 22)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: const TextStyle(color: Colors.white38, decoration: TextDecoration.lineThrough, decorationColor: Colors.white12),
                ),
                const SizedBox(height: 2),
                const Text("너무 뜨거웠나봐요..", style: TextStyle(fontSize: 10, color: Colors.white24)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _deleteGoal(goal.id),
            child: const Icon(Icons.close, size: 16, color: Colors.white24),
          ),
        ],
      ),
    );
  }
}