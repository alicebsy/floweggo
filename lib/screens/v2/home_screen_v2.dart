import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../database/db_helper.dart';
import '../../models/goal_model.dart';
import 'image_check_screen_v2.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  final db = DbHelper();
  final ImagePicker _picker = ImagePicker();
  int _currentPage = 0;

  Map<String, String> _completionDates = {};

  @override
  void initState() {
    super.initState();
    _loadAndCheckStatus();
  }

  Future<void> _loadAndCheckStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    setState(() {
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('completed_')) {
          String goalId = key.replaceAll('completed_', '');
          _completionDates[goalId] = prefs.getString(key) ?? "";
        }
      }

      for (var goal in db.activeGoals) {
        if (_completionDates.containsKey(goal.id)) continue;

        if (_isGoalFailed(goal)) {
          _markAsCompleted(goal.id, today, prefs);
        }
      }
    });
  }

  Future<void> _markAsCompleted(String goalId, String date, [SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    await prefs.setString('completed_$goalId', date);
    setState(() {
      _completionDates[goalId] = date;
    });
  }

  bool _isGoalFailed(Goal goal) {
    if (goal.temperature >= 100) return false;
    DateTime startDate = DateTime.tryParse(goal.id) ?? DateTime.now();
    DateTime endDate = startDate.add(Duration(days: goal.period));
    return DateTime.now().isAfter(endDate);
  }

  bool _isVerifiedToday(Goal goal) {
    if (goal.memories.isEmpty) return false;
    final lastMemory = goal.memories.last;
    String lastDateStr = lastMemory['date'] ?? "";
    String todayStr = "${DateTime.now().month}월 ${DateTime.now().day}일";
    return lastDateStr == todayStr;
  }

  void _addEventToCalendar(Goal goal) {
    DateTime startDate = DateTime.tryParse(goal.id) ?? DateTime.now();
    DateTime endDate = startDate.add(Duration(days: goal.period));

    final Event event = Event(
      title: "🐣 ${goal.name}",
      description: "목표: ${goal.name}\n주기: ${goal.frequency}\n꾸준히 인증해서 닭으로 키워보자!",
      startDate: startDate,
      endDate: endDate,
      allDay: true,
    );

    Add2Calendar.addEvent2Cal(event).then((success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "캘린더에 등록되었닭! 📅" : "등록 실패했닭... 권한을 확인해줘!")),
      );
    });
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final periodController = TextEditingController(text: "30");
    String selectedFreq = "매일";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setST) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("새 목표 추가", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "실천할 목표 입력",
                    filled: true,
                    fillColor: Colors.blue.shade50.withOpacity(0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: periodController,
                  decoration: InputDecoration(
                    labelText: "목표 기간 (일)",
                    filled: true,
                    fillColor: Colors.blue.shade50.withOpacity(0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text("실천 빈도", style: TextStyle(fontSize: 12, color: Colors.blueGrey))),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    db.addGoal(Goal(
                      id: DateTime.now().toIso8601String(),
                      name: nameController.text,
                      period: int.parse(periodController.text),
                      frequency: selectedFreq,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("추가하기"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(int index, Goal goal) {
    final nameController = TextEditingController(text: goal.name);
    final periodController = TextEditingController(text: goal.period.toString());
    String selectedFreq = goal.frequency;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setST) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("목표 수정", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: periodController,
                  decoration: InputDecoration(
                    labelText: "목표 기간 (일)",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: const Text("수정 완료"),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceSheet(Goal goal) {
    if (_isGoalFailed(goal)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이미 실패한 목표닭... 🍳")));
      return;
    }

    if (_isVerifiedToday(goal)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("오늘은 이미 인증을 완료했닭!")));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            const Text("인증 방식 선택", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.camera_alt_outlined, color: Colors.blueAccent)),
              title: const Text("카메라 촬영"),
              onTap: () { Navigator.pop(context); _handleAuth(goal, ImageSource.camera); },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.photo_library_outlined, color: Colors.blueAccent)),
              title: const Text("갤러리에서 선택"),
              onTap: () { Navigator.pop(context); _handleAuth(goal, ImageSource.gallery); },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAuth(Goal goal, ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;
    if (!mounted) return;

    final String? resultDesc = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCheckScreenV2(
          imagePath: image.path,
          goal: goal,
        ),
      ),
    );

    if (resultDesc != null) {
      setState(() {
        int index = db.activeGoals.indexOf(goal);
        if (index != -1) {
          db.recordProgress(index, image.path, resultDesc);
        }
      });

      if (goal.temperature >= 100) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _markAsCompleted(goal.id, today);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎉 축하한닭! 드디어 닭이 되었어!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("목표 달성이 기록되었습니다!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final visibleGoals = db.activeGoals.where((goal) {
      if (_completionDates.containsKey(goal.id)) {
        return _completionDates[goal.id] == todayStr;
      }
      return true; 
    }).toList().reversed.toList();

    return Scaffold(
      backgroundColor: Colors.grey[50], // 배경색을 흰색 계열로 변경
      appBar: AppBar(
        title: const Text("진행 중인 목표", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _showAddGoalDialog, icon: const Icon(Icons.add_circle_outline_rounded, size: 28)),
          const SizedBox(width: 12),
        ],
      ),
      body: visibleGoals.isEmpty
          ? _buildEmptyUI()
          : Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: visibleGoals.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final goal = visibleGoals[index];
              return _buildGoalCard(goal, index);
            },
          ),
          if (_currentPage > 0)
            _buildNavArrow(Icons.arrow_back_ios_new_rounded, Alignment.centerLeft,
                    () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
          if (_currentPage < visibleGoals.length - 1)
            _buildNavArrow(Icons.arrow_forward_ios_rounded, Alignment.centerRight,
                    () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)),
        ],
      ),
    );
  }

  // 🔥 카드 위젯 수정
  Widget _buildGoalCard(Goal goal, int index) {
    bool isFailed = _isGoalFailed(goal);
    bool hasVerifiedToday = _isVerifiedToday(goal);
    bool canVerify = !isFailed && !hasVerifiedToday && goal.temperature < 100;

    String stageText = "시작 단계";
    Color stageColor = Colors.blueGrey;
    if (goal.progress >= 0.5) { stageText = "진행 중"; stageColor = Colors.blueAccent; }
    if (goal.progress >= 1.0) { stageText = "달성 완료"; stageColor = Colors.green; }
    if (isFailed) { stageText = "기간 만료"; stageColor = Colors.redAccent; }

    // 메인 블록이 화면에 잘 맞도록 마진과 패딩을 수정합니다.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25), // 수직 마진 감소
      padding: const EdgeInsets.all(24), // 패딩 감소
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      // SingleChildScrollView를 제거하고 Column으로 직접 내용을 배치합니다.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 위 아래로 컨텐츠를 분산시켜 꽉 채웁니다.
        children: [
          // 상단 컨텐츠 (상태, 아이콘, 이모지, 제목)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: stageColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(stageText, style: TextStyle(color: stageColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Row(
                    children: [
                      IconButton(onPressed: () => _addEventToCalendar(goal), icon: const Icon(Icons.calendar_today, size: 20, color: Colors.grey)),
                      IconButton(onPressed: () => _showEditGoalDialog(index, goal), icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20)),
                      IconButton(onPressed: () { setState(() => db.deleteGoal(goal.id)); }, icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15), // 여백 감소
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(isFailed ? "🍳" : goal.emoji, style: const TextStyle(fontSize: 90)), // 이모지 크기 약간 감소
              ),
              const SizedBox(height: 10), // 여백 감소
              Text(goal.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5), textAlign: TextAlign.center), // 폰트 크기 약간 감소
              const SizedBox(height: 6),
              Text(isFailed ? "도전 기간이 끝났닭.." : "남은 기간: D-${goal.period - goal.currentDays} (${goal.frequency})", style: const TextStyle(color: Colors.grey, fontSize: 14)), // 폰트 크기 약간 감소
            ],
          ),
          
          // 하단 컨텐츠 (달성률, 인증 버튼)
          Column(
            children: [
              const SizedBox(height: 20), // 여백 감소
              _buildAchievementBar(goal),
              const SizedBox(height: 25), // 여백 감소
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canVerify ? () => _showImageSourceSheet(goal) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canVerify ? Colors.blueAccent : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18), // 버튼 패딩 약간 감소
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                      isFailed ? "실패한 목표" : (hasVerifiedToday ? "오늘 인증 완료" : "오늘의 인증 기록하기"),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBar(Goal goal) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("전체 달성률", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
            Text("${(goal.progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 17)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: goal.progress,
            minHeight: 12,
            backgroundColor: Colors.blue.shade50,
            color: Colors.blueAccent,
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
          const Icon(Icons.assignment_outlined, size: 80, color: Colors.black12),
          const SizedBox(height: 20),
          const Text("현재 진행 중인 목표가 없습니다.\n새로운 목표를 설정해보세요.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _showAddGoalDialog,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("목표 추가하기"),
          ),
        ],
      ),
    );
  }
}
