import 'dart:io'; // 파일 처리를 위해 필요
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 갤러리 접근을 위해 필요
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

  // ✅ 프로필 상태 변수
  String _userName = "농부";
  String _userBio = "오늘도 풍년을 기원합니다!";
  String? _profileImagePath; // 이미지 경로 저장용

  final ImagePicker _picker = ImagePicker(); // 이미지 선택기

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // ✅ 데이터 로드
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "농부";
      _userBio = prefs.getString('user_bio') ?? "오늘도 풍년을 기원합니다!";
      _profileImagePath = prefs.getString('user_image_path'); // 저장된 이미지 경로 불러오기
    });
  }

  // ✅ 데이터 저장
  Future<void> _saveUserProfile(String name, String bio, String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_bio', bio);
    if (imagePath != null) {
      await prefs.setString('user_image_path', imagePath);
    }

    setState(() {
      _userName = name;
      _userBio = bio;
      _profileImagePath = imagePath;
    });
  }

  void _deleteGoal(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("기록 삭제", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("이 성장 기록을 영구적으로 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              db.deleteGoal(id);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ [수정됨] 갤러리 이미지 선택 팝업 (StatefulBuilder 사용)
  void _showProfileEditDialog() {
    final nameController = TextEditingController(text: _userName);
    final bioController = TextEditingController(text: _userBio);
    String? tempImagePath = _profileImagePath; // 팝업 내 임시 이미지 경로

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // 팝업 내부 상태(이미지 미리보기) 갱신을 위해 사용
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Center(child: Text("프로필 수정", style: TextStyle(fontWeight: FontWeight.bold))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // 1. 프로필 사진 선택 (터치 시 갤러리 열기)
                    GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setStateDialog(() {
                            tempImagePath = image.path; // 미리보기 업데이트
                          });
                        }
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                              image: tempImagePath != null
                                  ? DecorationImage(
                                image: FileImage(File(tempImagePath!)),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: tempImagePath == null
                                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. 이름 입력
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "이름",
                        filled: true,
                        fillColor: const Color(0xFFF0F4F8),
                        border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(12)
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. 한줄 소개 입력
                    TextField(
                      controller: bioController,
                      decoration: InputDecoration(
                        labelText: "한줄 소개",
                        filled: true,
                        fillColor: const Color(0xFFF0F4F8),
                        border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(12)
                        ),
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
                    _saveUserProfile(
                        nameController.text,
                        bioController.text,
                        tempImagePath
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("완료", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
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
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              child:Column(
                children: [
                  // ✅ [수정됨] 프로필 상단 영역 (사진 선택, 회색 연필, 화살표 제거)
                  GestureDetector(
                    onTap: _showProfileEditDialog, // 전체 영역 터치 시 수정 팝업
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                                border: Border.all(color: Colors.grey.shade200, width: 1),
                                image: _profileImagePath != null
                                    ? DecorationImage(
                                  image: FileImage(File(_profileImagePath!)),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: _profileImagePath == null
                                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                  : null,
                            ),
                            // ✅ 회색 연필 아이콘
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400, // 파란색 -> 회색 변경
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(Icons.edit, size: 12, color: Colors.white),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ✅ 이름 (옆에 화살표 삭제됨)
                        Text(
                          _userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _userBio.isEmpty ? "한줄 소개를 입력하세요" : _userBio,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
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
                ],
              ),
            ),
          ),

          if (isFarmEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyUI(),
            )
          else...[
            // 🌱 진행 중인 목표
            if (growingGoals.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                sliver: SliverToBoxAdapter(child: _buildSectionHeader("진행 중인 목표", growingGoals.length, Colors.green)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildGrowingCard(growingGoals.reversed.toList()[index]),
                    childCount: growingGoals.length,
                  ),
                ),
              ),
            ],

            // 🌹 성공한 목표
            if (successGoals.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                sliver: SliverToBoxAdapter(child: _buildSectionHeader("달성 완료 항목", successGoals.length, Colors.brown)),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(15),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildSuccessCard(successGoals.reversed.toList()[index]),
                    childCount: successGoals.length,
                  ),
                ),
              ),
            ],

            // 🥀 실패한 목표
            if (failedGoals.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                sliver: SliverToBoxAdapter(child: _buildSectionHeader("실패한 목표", failedGoals.length, Colors.redAccent)),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(15),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildFailedCard(failedGoals.reversed.toList()[index]),
                    childCount: failedGoals.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ]
        ],
      ),
    );
  }

  Widget _buildSummaryStats({required int growing, required int success, required int failed}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.brown,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statColumn("진행 중", "$growing", Colors.green),
          _buildVerticalDivider(),
          _statColumn("성공", "$success", Colors.white),
          _buildVerticalDivider(),
          _statColumn("실패", "$failed", Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade100);
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

  Widget _buildGrowingCard(Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Text(goal.emoji2, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text("D-${goal.period - goal.currentDays} 남음", style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteGoal(goal.id),
                icon: const Icon(Icons.more_horiz, color: Colors.black26),
              )
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text("${(goal.progress * 100).toInt()}% 달성 중", style: const TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w500,),),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          const Text("🌹", style: TextStyle(fontSize: 25)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                const Text("성공!", style: TextStyle(fontSize: 11, color: Colors.brown)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _deleteGoal(goal.id),
            child: const Icon(Icons.close, size: 18, color: Colors.black26),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedCard(Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          const Text("🥀", style: TextStyle(fontSize: 25)),
          const SizedBox(width: 15),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)
                    ),
                    const Text("실패...", style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                  ]
              )
          ),
          GestureDetector(
            onTap: () => _deleteGoal(goal.id),
            child: const Icon(Icons.close, size: 18, color: Colors.black26),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🚜", style: TextStyle(fontSize: 50)),
          const SizedBox(height: 20),
          const Text("아직 가꾸고 있는 기록이 없어요", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text("목표를 달성하거나 기간이 만료되면\n이곳에서 통계를 모아볼 수 있습니다.",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black38, height: 1.5)),
        ],
      ),
    );
  }
}