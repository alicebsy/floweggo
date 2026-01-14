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

  // 1일 1회 인증 제한 수정
  bool _isVerifiedToday(Goal goal) {
    if (goal.memories.isEmpty) return false;
    final lastMemory = goal.memories.last;

    // 1. timestamp가 있으면 시간 객체로 정확히 비교
    if (lastMemory.containsKey('timestamp')) {
      DateTime lastDate = DateTime.parse(lastMemory['timestamp']);
      DateTime now = DateTime.now();
      return lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day;
    }

    // 2. 없으면 V1 스타일의 날짜 문자열 비교 (db_helper 저장 방식 대응)
    DateTime now = DateTime.now();
    String todayStr = "${now.year}-${now.month}-${now.day}";
    return lastMemory['date'] == todayStr;
  }

  void _addEventToCalendar(Goal goal) {
    DateTime startDate = DateTime.tryParse(goal.id) ?? DateTime.now();
    DateTime endDate = startDate.add(Duration(days: goal.period));

    final Event event = Event(
      title: "🌱 ${goal.name}",
      description: "목표: ${goal.name}\n주기: ${goal.frequency}\n꾸준히 인증해서 꽃으로 키워봐요!",
      startDate: startDate,
      endDate: endDate,
      allDay: true,
    );

    Add2Calendar.addEvent2Cal(event).then((success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "캘린더에 등록되었어요! 📅" : "등록 실패했어요... 권한을 확인해주세요!")),
      );
    });
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final periodController = TextEditingController(text: "30");
    String selectedFreq = "매일";

    // ✨ [색상 변경] 새싹 테마 (Green & Brown)
    const Color primaryBrown = Color(0xFF6D4C41); // 흙 색깔 (조금 더 진한 갈색)
    const Color accentColor = Color(0xFF66BB6A);  // 포인트: 싱그러운 연두색 (Green 400)
    const Color softBase = Color(0xFFF1F8E9);     // 배경: 아주 연한 연두빛 화이트 (Light Green 50)

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setST) {

          // 🌿 칩 버튼 (선택 시 연두색)
          Widget buildFreqChip(String label, String value) {
            bool isSelected = selectedFreq == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => setST(() => selectedFreq = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : softBase, // 선택 안되면 연한 배경
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: isSelected
                        ? [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                        : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : primaryBrown.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }

          // 🌿 입력창 스타일 (연두색 포커스)
          InputDecoration inputDecoration(String hint, IconData icon, {String? suffix}) {
            return InputDecoration(
              filled: true,
              fillColor: softBase, // 배경색
              prefixIcon: Icon(icon, color: accentColor), // 아이콘 색상
              hintText: hint,
              hintStyle: TextStyle(color: primaryBrown.withOpacity(0.4)),
              suffixText: suffix,
              suffixStyle: const TextStyle(color: primaryBrown, fontWeight: FontWeight.bold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: accentColor, width: 1.5), // 포커스 시 연두색 테두리
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            );
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 25),
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 35, 25, 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 25, spreadRadius: 2, offset: const Offset(0, 10)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. 상단 아이콘 (연두빛 배경)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15), // 연한 연두색 원
                        shape: BoxShape.circle,
                      ),
                      child: const Text("🌱", style: TextStyle(fontSize: 55)),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "새로운 씨앗 심기",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: primaryBrown),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "무럭무럭 자라날 목표를 정해주세요!",
                      style: TextStyle(fontSize: 13, color: primaryBrown.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 30),

                    // 2. 목표 이름 입력
                    TextField(
                      controller: nameController,
                      cursorColor: accentColor,
                      style: const TextStyle(color: primaryBrown, fontWeight: FontWeight.w600),
                      decoration: inputDecoration("목표 이름 (예: 매일 독서하기)", Icons.edit_rounded),
                    ),
                    const SizedBox(height: 15),

                    // 3. 기간 입력
                    TextField(
                      controller: periodController,
                      keyboardType: TextInputType.number,
                      cursorColor: accentColor,
                      style: const TextStyle(color: primaryBrown, fontWeight: FontWeight.w600),
                      decoration: inputDecoration("목표 기간", Icons.calendar_month_rounded, suffix: "일 동안"),
                    ),
                    const SizedBox(height: 25),

                    // 4. 빈도 선택
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 12),
                        child: Text("물 주기 빈도 (인증 주기)", style: TextStyle(fontWeight: FontWeight.w700, color: primaryBrown.withOpacity(0.8))),
                      ),
                    ),
                    Row(
                      children: [
                        buildFreqChip("매일", "매일"),
                        buildFreqChip("격일", "격일"),
                        buildFreqChip("주 3회", "주 3회"),
                      ],
                    ),
                    const SizedBox(height: 35),

                    // 5. 하단 버튼
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              foregroundColor: primaryBrown.withOpacity(0.6),
                            ),
                            child: const Text("다음에 할래요", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
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
                                // 페이지 이동 애니메이션
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (_pageController.hasClients) {
                                    _pageController.animateToPage(0, duration: const Duration(milliseconds: 600), curve: Curves.easeOutQuart);
                                  }
                                });
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBrown, // 버튼은 갈색 (안정감)
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 3,
                              shadowColor: primaryBrown.withOpacity(0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text("심기 완료! 🌱", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditGoalDialog(int index, Goal goal) {
    final nameController = TextEditingController(text: goal.name);
    final periodController = TextEditingController(text: goal.period.toString());
    String selectedFreq = goal.frequency;

    const Color primaryBrown = Color(0xFF6D4C41); // 흙 색깔 (조금 더 진한 갈색)
    const Color accentColor = Color(0xFF66BB6A);  // 포인트: 싱그러운 연두색 (Green 400)
    const Color softBase = Color(0xFFF1F8E9);     // 배경: 아주 연한 연두빛 화이트 (Light Green 50)

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setST) {

          // 🌿 칩 버튼
          Widget buildFreqChip(String label, String value) {
            bool isSelected = selectedFreq == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => setST(() => selectedFreq = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : softBase,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: isSelected
                        ? [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                        : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : primaryBrown.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }

          // 🌿 입력창 스타일
          InputDecoration inputDecoration(String hint, IconData icon, {String? suffix}) {
            return InputDecoration(
              filled: true,
              fillColor: softBase,
              prefixIcon: Icon(icon, color: accentColor),
              hintText: hint,
              hintStyle: TextStyle(color: primaryBrown.withOpacity(0.4)),
              suffixText: suffix,
              suffixStyle: const TextStyle(color: primaryBrown, fontWeight: FontWeight.bold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            );
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 25),
            child: Container(
              padding: const EdgeInsets.fromLTRB(25, 35, 25, 25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 25, spreadRadius: 2, offset: const Offset(0, 10)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. 상단 아이콘 (수정 모드라 연필 아이콘 ✏️)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_note_rounded, size: 50, color: accentColor),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "목표 수정하기",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: primaryBrown),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "내용을 변경할까요?",
                      style: TextStyle(fontSize: 13, color: primaryBrown.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 30),

                    // 2. 목표 이름 입력
                    TextField(
                      controller: nameController,
                      cursorColor: accentColor,
                      style: const TextStyle(color: primaryBrown, fontWeight: FontWeight.w600),
                      decoration: inputDecoration("목표 이름", Icons.edit_rounded),
                    ),
                    const SizedBox(height: 15),

                    // 3. 기간 입력
                    TextField(
                      controller: periodController,
                      keyboardType: TextInputType.number,
                      cursorColor: accentColor,
                      style: const TextStyle(color: primaryBrown, fontWeight: FontWeight.w600),
                      decoration: inputDecoration("목표 기간", Icons.calendar_month_rounded, suffix: "일 동안"),
                    ),
                    const SizedBox(height: 25),

                    // 4. 빈도 선택
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 12),
                        child: Text("온도 높이기 빈도 (인증 주기)", style: TextStyle(fontWeight: FontWeight.w700, color: primaryBrown.withOpacity(0.8))),
                      ),
                    ),
                    Row(
                      children: [
                        buildFreqChip("매일", "매일"),
                        buildFreqChip("격일", "격일"),
                        buildFreqChip("주 3회", "주 3회"),
                      ],
                    ),
                    const SizedBox(height: 35),

                    // 5. 하단 버튼
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              foregroundColor: primaryBrown.withOpacity(0.6),
                            ),
                            child: const Text("취소", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                goal.name = nameController.text;
                                goal.period = int.parse(periodController.text);
                                goal.frequency = selectedFreq;
                                // 기간이 바뀌면 온도 재계산 (진행률 유지)
                                goal.temperature = (goal.currentDays / goal.period) * 100;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBrown,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 3,
                              shadowColor: primaryBrown.withOpacity(0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text("수정 완료 👌", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageSourceSheet(Goal goal) {
    if (_isGoalFailed(goal)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이미 실패한 목표입니다... 🥀")));
      return;
    }

    if (_isVerifiedToday(goal)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("오늘은 이미 인증을 완료했습니다!")));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("인증 방법을 선택해주세요!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAuthOption(Icons.camera_alt, "카메라", () { Navigator.pop(context); _handleAuth(goal, ImageSource.camera); }),
                  _buildAuthOption(Icons.photo_library, "갤러리", () { Navigator.pop(context); _handleAuth(goal, ImageSource.gallery); }),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.brown.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: Colors.brown),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
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
        builder: (context) => ImageCheckScreenV2(imagePath: image.path, goal: goal),
      ),
    );

    if (resultDesc != null) {
      setState(() {
        int index = db.activeGoals.indexOf(goal);
        if (index != -1) {
          // recordProgress 내부에서 memories 추가와 온도 계산이 모두 이루어집니다.
          db.recordProgress(index, image.path, resultDesc);
        }
      });

      if (goal.temperature >= 100) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _markAsCompleted(goal.id, today);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎉 축하해! 드디어 꽃이 되었어!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("목표 달성이 기록되었습니다!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final visibleGoals = db.activeGoals.where((goal) {
      if (_completionDates.containsKey(goal.id)) return _completionDates[goal.id] == todayStr;
      return true;
    }).toList().reversed.toList();

    return Scaffold(
      backgroundColor: Colors.grey[50], // 배경색을 흰색 계열로 변경
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(onPressed: _showAddGoalDialog, icon: const Icon(Icons.add_circle_outline_rounded, size: 28)),
          const SizedBox(width: 12),
        ],
      ),
      body: visibleGoals.isEmpty
          ? _buildEmptyUI()
          : PageView.builder(
            controller: _pageController,
            itemCount: visibleGoals.length,
            itemBuilder: (context, index) => _buildGoalCard(visibleGoals[index], index),
            ),
    );
  }

  // 🔥 카드 위젯 수정
  Widget _buildGoalCard(Goal goal, int index) {

    bool isFailed = _isGoalFailed(goal);
    bool hasVerifiedToday = _isVerifiedToday(goal);
    bool canVerify = !isFailed && !hasVerifiedToday && goal.temperature < 100;
    // -----------------------------------------------------------

    DateTime startDate;
    try {
      startDate = DateTime.parse(goal.id);
    } catch (e) {
      startDate = DateTime.now();
    }
    DateTime endDate = startDate.add(Duration(days: goal.period));
    String dateRange = "${DateFormat('yyyy.MM.dd').format(startDate)} ~ ${DateFormat('yyyy.MM.dd').format(endDate)}";

    String stageText = "시작 전";
    Color stageColor = Colors.blueGrey;
    if (goal.progress > 0) { stageText = "진행 중"; stageColor = Colors.green; }
    if (goal.progress >= 1.0) { stageText = "달성 완료"; stageColor = Colors.brown; }
    if (isFailed) { stageText = "기간 만료"; stageColor = Colors.redAccent; }

    // 메인 블록이 화면에 잘 맞도록 마진과 패딩을 수정합니다.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40), // 수직 마진 감소 (80 -> 30)
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      // SingleChildScrollView를 제거하고 Column으로 직접 내용을 배치합니다.
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween, // 위 아래로 컨텐츠를 분산시켜 꽉 채웁니다. -> SizedBox로 간격 조절
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
              const SizedBox(height: 10),
              Text(goal.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5), textAlign: TextAlign.center), // 폰트 크기 감소 (24 -> 22)
              const SizedBox(height: 4),
              Text(dateRange, style: const TextStyle(color: Colors.black38, fontSize: 12)),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(isFailed ? "🥀" : goal.emoji2, style: const TextStyle(fontSize: 70)), // 이모지 크기 감소 (90 -> 80)
              ),
              const SizedBox(height: 8), // 여백 감소 (10 -> 8)
              Text(isFailed ? "도전 기간이 끝났어요.." : "D-${goal.period - goal.currentDays}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 17)), // 폰트 크기 감소 (14 -> 13)
              const SizedBox(height: 4),
              Text("${goal.frequency}", style: const TextStyle(fontSize: 15, color: Colors.grey))
            ],
          ),

          // 상단과 하단 컨텐츠 사이의 간격을 조절합니다.
          const Spacer(),

          // 하단 컨텐츠 (달성률, 인증 버튼)
          Column(
            children: [
              const SizedBox(height: 15),
              _buildAchievementBar(goal),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (canVerify) {
                      _showImageSourceSheet(goal);
                    } else {
                      String msg = "";
                      if (isFailed) msg = "이미 실패한 목표입니다... 🥀";
                      else if (goal.temperature >= 100) msg = "이미 다 컸어요! 🎉";
                      else msg = "오늘은 이미 인증했어요! 내일 또 만나요!";

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canVerify ? Colors.lightGreen : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16), // 버튼 패딩 감소 (18 -> 16)
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: canVerify ? 2 : 0,
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
            const Text("물 주기 달성률", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
            Text("${(goal.progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.lightGreen, fontSize: 17)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: goal.progress,
            minHeight: 12,
            backgroundColor: Colors.lightGreenAccent.shade100,
            color: Colors.green,
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
    const Color primaryBrown = Color(0xFF6D4C41); // 흙/나무 색상
    const Color accentColor = Color(0xFF66BB6A);

    return Center(
      child: Container(
        // v1처럼 중앙에 집중된 큰 프레임 구성
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40), // v2의 둥근 디자인 강조
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ],
          // 은은한 연두색 테두리로 포인트
          border: Border.all(color: accentColor.withOpacity(0.1), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 메인 아이콘/이모지 영역
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text("🌻", style: TextStyle(fontSize: 70)), // v1의 🛖 대신 🪴 사용
            ),
            const SizedBox(height: 35),

            // 2. 타이틀 텍스트
            const Text(
              "텃밭이 비어있어요!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: primaryBrown,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 12),

            // 3. 서브 텍스트
            Text(
              "새로운 씨앗을 심어서\n정성껏 길러주세요",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: primaryBrown.withOpacity(0.5),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 45),

            // 4. 씨앗 심기 버튼 (v2의 버튼 스타일 유지)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showAddGoalDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                  shadowColor: primaryBrown.withOpacity(0.3),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 22),
                    SizedBox(width: 8),
                    Text(
                      "새로운 씨앗 심기",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
