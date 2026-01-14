import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/db_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class FarmScreenV1 extends StatefulWidget {
  const FarmScreenV1({super.key});

  @override
  State<FarmScreenV1> createState() => _FarmScreenV1State();
}

class _FarmScreenV1State extends State<FarmScreenV1> {
  final db = DbHelper();

  // ✅ 프로필 관련 변수들
  String _userName = "농부";
  String _statusMessage = "오늘도 부지런히 알을 키워요";
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "농부";
      _statusMessage = prefs.getString('user_status') ?? "오늘도 부지런히 꿈을 키워요";

      String? imagePath = prefs.getString('user_image_path');
      if (imagePath != null && File(imagePath).existsSync()) {
        _profileImage = File(imagePath);
      }
    });
  }

  Future<void> _saveUserProfile(String name, String status, String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_status', status);
    if (imagePath != null) {
      await prefs.setString('user_image_path', imagePath);
    }

    setState(() {
      _userName = name;
      _statusMessage = status;
      if (imagePath != null) {
        _profileImage = File(imagePath);
      }
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

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final statusController = TextEditingController(text: _statusMessage);
    File? tempImage = _profileImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("프로필 수정", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // 1. 이미지 선택
                    GestureDetector(
                      onTap: () async {
                        final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setStateDialog(() {
                            tempImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white30, width: 2),
                              color: Colors.white10,
                              image: tempImage != null
                                  ? DecorationImage(
                                image: FileImage(tempImage!),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: tempImage == null
                                ? const Center(child: Text("👨🏻‍🌾", style: TextStyle(fontSize: 50)))
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.brown,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. 이름 입력
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.brown,
                      decoration: const InputDecoration(
                        labelText: "이름",
                        labelStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.brown)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 3. 상태 메시지 입력
                    TextField(
                      controller: statusController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.brown,
                      decoration: const InputDecoration(
                        labelText: "상태 메시지",
                        labelStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.brown)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("취소", style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      _saveUserProfile(
                        nameController.text,
                        statusController.text,
                        tempImage?.path,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("저장", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGoals = db.allGoals;
    final now = DateTime.now();

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

    bool isEmpty = allGoals.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      resizeToAvoidBottomInset: false,

      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 240,
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

                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 5),

                            // 🔥 수정 팝업 트리거 (사진, 이름, 메시지 전체 영역)
                            GestureDetector(
                              onTap: _showEditProfileDialog,
                              child: Column(
                                children: [
                                  // 프로필 이미지
                                  Stack(
                                    children: [
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white24, width: 2),
                                          color: Colors.white.withOpacity(0.1),
                                          image: _profileImage != null
                                              ? DecorationImage(
                                            image: FileImage(_profileImage!),
                                            fit: BoxFit.cover,
                                          )
                                              : null,
                                        ),
                                        child: _profileImage == null
                                            ? const Center(
                                          child: Text("👨🏻‍🌾", style: TextStyle(fontSize: 45)),
                                        )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2C2C2C),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white30, width: 1.5),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            size: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // 🔥 [수정] 이름 옆 연필 버튼 제거 (Text만 남김)
                                  Text(
                                    _userName,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),

                                  const SizedBox(height: 5),

                                  // 상태 메시지
                                  Text(
                                    _statusMessage,
                                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // 통계
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

                // 하단 리스트
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 450).clamp(0.0, double.infinity),
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF121212),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isEmpty ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        if (growingGoals.isNotEmpty) ...[
                          _buildSectionTitle("🌱 둥지"),
                          const SizedBox(height: 15),
                          ...growingGoals.map((g) => _buildGrowingCard(g)).toList(),
                          const SizedBox(height: 30),
                        ],

                        if (successGoals.isNotEmpty) ...[
                          _buildSectionTitle("🐓 닭이 되었닭!"),
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

                        if (failedGoals.isNotEmpty) ...[
                          _buildSectionTitle("🍳 계란후라이가 되었닭..."),
                          const SizedBox(height: 15),
                          GridView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.8,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: failedGoals.length,
                            itemBuilder: (context, index) => _buildFailedCard(failedGoals[index]),
                          ),
                          const SizedBox(height: 30),
                        ],

                        if (isEmpty) _buildEmptyUI(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 위젯들 ---

  Widget _buildEmptyUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Text("🏚️", style: TextStyle(fontSize: 50)),
          ),
          const SizedBox(height: 20),
          const Text(
            "농장이 아직 고요하닭...",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 10),
          const Text(
            "둥지에서 알을 깨워\n이곳 농장을 북적이게 만들어주세요!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

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
                const Text("분발해야해요!", style: TextStyle(fontSize: 10, color: Colors.white24)),
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