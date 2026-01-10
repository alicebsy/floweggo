import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';

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

  void _showNameDialog() {
    final controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("이름을 설정하세요", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "새로운 이름을 입력해주세요",
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text("취소", style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _saveUserName(controller.text);
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text("확인", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🐔 농장이 완전히 비었는지 확인
    bool isFarmEmpty = db.completedFarm.isEmpty && db.activeGoals.isEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ---------------------------------------------------------
          // 1. 배경 이미지
          // ---------------------------------------------------------
          SizedBox.expand(
            child: Opacity(
              // 🔥 [수정됨] 농장이 비어있으면(1.0) 선명하게, 뭐라도 있으면(0.5) 흐리게
              opacity: isFarmEmpty ? 1.0 : 0.5,
              child: Image.asset(
                'assets/images/farm_inside.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ---------------------------------------------------------
          // 2. 내용물
          // ---------------------------------------------------------
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 10),

                // 🧢 [헤더]
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("👨🏻‍🌾", style: TextStyle(fontSize: 45)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _showNameDialog,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "님의 농장",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit, color: Colors.white70, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                // 🔄 [분기점] 농장이 비었을 때 vs 닭이 있을 때
                if (isFarmEmpty) ...[
                  // 💨 1. 텅 빈 농장 화면 (배경이 선명하므로 그림자를 강하게 줌)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // "휑~" 텍스트와 바람 아이콘
                        const Text(
                          "🍃 휑~",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // 선명한 흰색
                            fontStyle: FontStyle.italic,
                            shadows: [Shadow(blurRadius: 15, color: Colors.black)], // 그림자 강화
                          ),
                        ),
                        const Icon(
                          Icons.air,
                          size: 100,
                          color: Colors.white70,
                          shadows: [Shadow(blurRadius: 15, color: Colors.black)], // 그림자 강화
                        ),

                        const SizedBox(height: 40),

                        // 메인 문구
                        const Text(
                          "아직은 조용한 농장이닭!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 15, color: Colors.black)], // 그림자 강화
                          ),
                        ),
                        const SizedBox(height: 15),

                        // 서브 문구 (박스 제거됨)
                        const Text(
                          "목표를 달성해서 이곳을\n멋진 닭들로 채워주세요",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white, // 흰색으로 변경
                            height: 1.5,
                            shadows: [Shadow(blurRadius: 10, color: Colors.black)], // 가독성을 위해 그림자 추가
                          ),
                        ),
                      ],
                    ),
                  )
                ] else ...[
                  // 🐔 2. 닭이 있을 때 보이는 화면

                  // 🏆 성공이닭
                  const Text(
                    "🏆 성공이닭",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                      shadows: [Shadow(blurRadius: 5, color: Colors.black45)],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: db.completedFarm.isEmpty
                        ? const Center(
                      child: Text(
                        "아직 성공한 닭이 없어요.",
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                        : Column(
                      children: db.completedFarm.map((g) => ListTile(
                        leading: const Text("🐓", style: TextStyle(fontSize: 30)),
                        title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.verified, color: Colors.blue),
                      )).toList(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🌱 자라나는 중이닭
                  const Text(
                    "🌱 자라나는 중이닭",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightGreenAccent,
                      shadows: [Shadow(blurRadius: 5, color: Colors.black45)],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: db.activeGoals.isEmpty
                        ? const Center(
                      child: Text(
                        "키우고 있는 알이 없어요.",
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                        : Column(
                      children: db.activeGoals.map((g) => Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Text(g.emoji, style: const TextStyle(fontSize: 30)),
                            title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${g.temperature.toInt()}°C (D-${g.period - g.currentDays})"),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    value: g.progress,
                                    minHeight: 8,
                                    color: Colors.green,
                                    backgroundColor: Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                        ],
                      )).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}