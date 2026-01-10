import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/goal_model.dart';

class HomeScreen extends StatefulWidget {
  // main.dart에서 데이터를 넘겨받습니다.
  final List<Goal> goals;
  final VoidCallback onUpdate; // 데이터가 바뀔 때 main을 새로고침하기 위한 콜백

  const HomeScreen({
    super.key,
    required this.goals,
    required this.onUpdate
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // 1. 목표 추가 팝업
  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("새로운 목표 추가", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  const Text("목표 이름", style: TextStyle(fontWeight: FontWeight.w600)),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: "예: 매일 운동하기"),
                  ),
                  const SizedBox(height: 20),
                  const Text("목표 일수", style: TextStyle(fontWeight: FontWeight.w600)),
                  TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: "30"),
                  ),
                  const SizedBox(height: 24),
                  _buildGuideBox(), // 가이드 박스 분리
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 가이드 박스 UI
  Widget _buildGuideBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFF176).withOpacity(0.5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("💡 성장 과정:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF57F17))),
          Text("• 50% 달성 → 병아리 🐣", style: TextStyle(fontSize: 12, color: Color(0xFF795548))),
          Text("• 100% 달성 → 닭 🐔", style: TextStyle(fontSize: 12, color: Color(0xFF795548))),
          Text("• 50% 미만 실패 → 후라이 🍳", style: TextStyle(fontSize: 12, color: Color(0xFF795548))),
        ],
      ),
    );
  }

  // 팝업 하단 버튼
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("취소"))),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF8A00), Color(0xFFFFB800)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty && _daysController.text.isNotEmpty) {
                  setState(() {
                    // widget.goals에 추가해야 데이터가 유지됩니다.
                    widget.goals.add(Goal(
                      id: DateTime.now().toString(),
                      title: _titleController.text,
                      totalDays: int.parse(_daysController.text),
                    ));
                  });
                  _titleController.clear();
                  _daysController.clear();
                  widget.onUpdate(); // 메인 화면 갱신
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              child: const Text("추가하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  // 2. 인증 로직 (사진을 찍으면 갤러리용 데이터로 저장)
  Future<void> _pickImage(Goal goal, ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source, imageQuality: 50);
    if (photo != null) {
      setState(() {
        // 날짜 생성
        String formattedDate = "${DateTime.now().month}월 ${DateTime.now().day}일";

        // Goal 모델 내부에 사진 정보 저장 (갤러리 탭에서 사용)
        goal.authImages.add({
          'path': photo.path,
          'date': formattedDate,
        });

        if (goal.currentDays < goal.totalDays) {
          goal.currentDays++;
          goal.updateStatus();
        }
      });
      widget.onUpdate(); // 메인 갱신
    }
  }

  void _showPicker(Goal goal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.camera_alt, color: Colors.orange), title: const Text('카메라로 촬영'), onTap: () { Navigator.pop(context); _pickImage(goal, ImageSource.camera); }),
            ListTile(leading: const Icon(Icons.photo_library, color: Colors.orange), title: const Text('갤러리에서 선택'), onTap: () { Navigator.pop(context); _pickImage(goal, ImageSource.gallery); }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      body: Column(
        children: [
          _buildHeader(),
          _buildAddButtonOverlay(),
          Expanded(
            child: widget.goals.isEmpty ? _buildEmptyState() : _buildGoalList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 200, // 나의 농장과 동일한 높이
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF8A00), Color(0xFFFFB800)]
          )
      ),
      // SafeArea 기능을 패딩으로 직접 구현하여 위치 고정
      padding: const EdgeInsets.only(top: 60, left: 25),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("🐣 나의 농장", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("목표를 달성하며 알을 키워보세요!", style: TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAddButtonOverlay() {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: InkWell(
        onTap: _showAddGoalDialog,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 56,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
          child: const Center(child: Text("+ 새로운 목표 추가하기", style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("🥚", style: TextStyle(fontSize: 80)),
        const SizedBox(height: 20),
        const Text("첫 번째 알을 만들어보세요!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text("매일 인증하면 알이 부화해요", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildGoalList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: widget.goals.length,
      itemBuilder: (context, index) => _buildGoalCard(widget.goals[index]),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    String emoji = "🥚";
    if (goal.status == EggStatus.chicken) emoji = "🐔";
    else if (goal.status == EggStatus.chick) emoji = "🐣";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text("열심히 성장 중이에요!", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                  onPressed: () => setState(() {
                    widget.goals.remove(goal);
                    widget.onUpdate();
                  }),
                  icon: const Icon(Icons.delete_outline, color: Colors.grey)
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${goal.currentDays}/${goal.totalDays}일", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("${(goal.progress * 100).toInt()}%", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF81C784)),
            ),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => _showPicker(goal),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF8A00), Color(0xFFFFB800)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(child: Text("인증하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ),
        ],
      ),
    );
  }
}