import 'dart:ui'; // 유리 효과(Blur)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // 날짜 포맷
import 'package:add_2_calendar/add_2_calendar.dart'; // 캘린더 기능
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 [NEW] 데이터 저장
import 'dart:async';
import '../../database/db_helper.dart';
import '../../models/goal_model.dart';
import 'image_check_screen_v1.dart';

class HomeScreenV1 extends StatefulWidget {
  const HomeScreenV1({super.key});
  @override
  State<HomeScreenV1> createState() => _HomeScreenV1State();
}

class _HomeScreenV1State extends State<HomeScreenV1> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  final db = DbHelper();
  final ImagePicker _picker = ImagePicker();

  int _currentPage = 0;

  // 🔥 [NEW] 완료된(성공/실패) 날짜를 저장할 Map
  // Key: goalId, Value: "yyyy-MM-dd"
  Map<String, String> _completionDates = {};

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 저장된 완료 날짜 불러오기 & 상태 체크
    _loadAndCheckStatus();
  }

  // ----------------------------------------------------------------------
  // 🔥 [NEW] 로직: 완료 날짜 관리 및 자동 상태 체크
  // ----------------------------------------------------------------------
  Future<void> _loadAndCheckStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    setState(() {
      // 1. 저장된 데이터 불러오기
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('completed_')) {
          String goalId = key.replaceAll('completed_', '');
          _completionDates[goalId] = prefs.getString(key) ?? "";
        }
      }

      // 2. "시간이 지나서" 실패한 목표가 있는지 체크하여 처리
      for (var goal in db.activeGoals) {
        if (_completionDates.containsKey(goal.id)) continue; // 이미 처리된건 패스

        bool isFailed = _isGoalFailed(goal);
        if (isFailed) {
          // 실패 확정 -> 오늘 날짜로 기록
          _markAsCompleted(goal.id, today, prefs);
        }
      }
    });
  }

  // 목표를 완료(성공/실패) 상태로 확정하고 저장
  Future<void> _markAsCompleted(String goalId, String date, [SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    await prefs.setString('completed_$goalId', date);
    setState(() {
      _completionDates[goalId] = date;
    });
  }

  // ----------------------------------------------------------------------
  // 📅 캘린더 등록 기능
  // ----------------------------------------------------------------------
  void _addEventToCalendar(Goal goal) {
    DateTime startDate;
    try {
      startDate = DateTime.parse(goal.id);
    } catch (e) {
      startDate = DateTime.now();
    }

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

  // ----------------------------------------------------------------------
  // 1. 목표 수정 팝업
  // ----------------------------------------------------------------------
  void _showEditGoalDialog(int index, Goal goal) {
    // 기존 데이터로 초기화
    final nameController = TextEditingController(text: goal.name);
    final periodController = TextEditingController(text: goal.period.toString());
    String selectedFreq = goal.frequency;

    // ✨ [디자인 통일] 새싹 테마 (Green & Brown)
    const Color primaryBrown = Color(0xFF6D4C41);
    const Color accentColor = Color(0xFF66BB6A);
    const Color softBase = Color(0xFFF1F8E9);

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

  // ----------------------------------------------------------------------
  // 2. 새 알 입양 팝업
  // ----------------------------------------------------------------------
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
                      child: const Text("🥚", style: TextStyle(fontSize: 55)),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "새로운 알 입양하기",
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
                            child: const Text("입양 확정! 🌱", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
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

  // ----------------------------------------------------------------------
  // 3. 인증 기능 & 로직
  // ----------------------------------------------------------------------

  bool _isGoalFailed(Goal goal) {
    if (goal.temperature >= 100) return false;
    DateTime startDate;
    try { startDate = DateTime.parse(goal.id); } catch (e) { startDate = DateTime.now(); }
    DateTime endDate = startDate.add(Duration(days: goal.period));
    return DateTime.now().isAfter(endDate);
  }

// ----------------------------------------------------------------------
  // 🔥 [수정] 오늘 인증 여부 확인 (Timestamp 우선 비교)
  // ----------------------------------------------------------------------
  bool _isVerifiedToday(Goal goal) {
    if (goal.memories.isEmpty) return false;

    // 1. 가장 최근 기록 가져오기
    final lastMemory = goal.memories.last;

    // 2. timestamp(정확한 시간)가 저장되어 있다면 이걸로 비교 (가장 정확함)
    if (lastMemory.containsKey('timestamp')) {
      DateTime lastDate = DateTime.parse(lastMemory['timestamp']);
      DateTime now = DateTime.now();

      // 연, 월, 일이 모두 같으면 같은 날로 취급
      return lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day;
    }

    // 3. timestamp가 없는 옛날 데이터라면 "M월 d일" 문자열로 비교
    String lastDateStr = lastMemory['date'] ?? "";
    String todayStr = "${DateTime.now().month}월 ${DateTime.now().day}일";

    return lastDateStr == todayStr;
  }

  void _showImageSourceSheet(Goal goal) { // 🔥 [수정] index 대신 goal 객체 직접 전달
    // 1. 실패 여부 체크
    if (_isGoalFailed(goal)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이미 실패한 목표닭... 🍳 다음 기회에!")));
      return;
    }

    // 2. 오늘 인증 여부 체크
    if (_isVerifiedToday(goal)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("오늘은 이미 인증을 완료했닭! 내일 또 봐 🐔")));
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
              const Text("인증 방법을 선택해주세닭!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

  // 🔥 [NEW] 인증 처리 로직 수정 (성공 시 완료 처리 추가)
  Future<void> _handleAuth(Goal goal, ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    if (!mounted) return;

    // AI 검열 화면 이동
    final String? resultDesc = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCheckScreenV1(
          imagePath: image.path,
          goal: goal,
        ),
      ),
    );

    if (resultDesc != null) {
      setState(() {
        // DB 업데이트: 원래 db_helper에서 index를 썼지만, 여기선 goal을 직접 찾음
        int index = db.activeGoals.indexOf(goal);
        if (index != -1) {
          db.recordProgress(index, image.path, resultDesc);
        }
      });

      // 🔥 인증 후 100도 달성했는지 체크!
      if (goal.temperature >= 100) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _markAsCompleted(goal.id, today);

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🎉 축하한닭! 드디어 닭이 되었어! (내일이면 둥지를 떠납니다)"))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("인증 성공! 온도가 올라갔닭 🔥"))
        );
      }
    }
  }

  // ----------------------------------------------------------------------
  // 4. UI 구성
  // ----------------------------------------------------------------------

  Widget _buildGlassCard({required Widget child, double padding = 20}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEmptyUI() {
    return Center(
      child: _buildGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🛖", style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            const Text("둥지가 텅 비었닭!", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("새로운 알을 입양해서\n따뜻하게 품어주세요.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, foregroundColor: Colors.brown,
                shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: _showAddGoalDialog,
              child: const Text("+ 새로운 알 입양하기", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(Goal goal) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("현재 온도", style: TextStyle(color: Colors.white70, fontSize: 13)),
            Text("${goal.temperature.toInt()}°C", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 20,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                // progress가 1.0을 넘지 않도록 제한
                double p = goal.progress > 1.0 ? 1.0 : goal.progress;
                return Container(
                  width: constraints.maxWidth * p,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.orange, Colors.redAccent]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 [NEW] 필터링 로직: 화면에 보여줄 목표들만 추려냄
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final visibleGoals = db.activeGoals.where((goal) {
      // 1. 완료된 기록이 있는지 확인
      if (_completionDates.containsKey(goal.id)) {
        // 기록이 있다면, "오늘 완료된 것"만 보여줌
        return _completionDates[goal.id] == todayStr;
      }
      // 2. 기록이 없다면 기본적으로 보여줌 (아직 진행중)
      return true;
    }).toList().reversed.toList();

    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          SizedBox.expand(child: Image.asset('assets/images/bg_farm.png', fit: BoxFit.cover)),

          // 오버레이
          Container(color: Colors.black.withOpacity(0.3)),

          SafeArea(
            child: Column(
              children: [
                // 상단 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _showAddGoalDialog,
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                        tooltip: "알 추가",
                      )
                    ],
                  ),
                ),

                Expanded(
                  child: visibleGoals.isEmpty
                      ? _buildEmptyUI()
                      : Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: visibleGoals.length,
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        itemBuilder: (context, index) {
                          // 🔥 [NEW] 필터링된 리스트 사용
                          final goal = visibleGoals[index];

                          // 상태 확인
                          bool isFailed = _isGoalFailed(goal);
                          bool hasVerifiedToday = _isVerifiedToday(goal);
                          bool isCompletedToday = (_completionDates[goal.id] == todayStr);

                          // 버튼 활성화 로직
                          // 성공했거나 실패했으면 인증 불가
                          bool canVerify = !isFailed && !hasVerifiedToday && goal.temperature < 100;

                          // 날짜 계산
                          DateTime startDate;
                          try { startDate = DateTime.parse(goal.id); } catch (e) { startDate = DateTime.now(); }
                          DateTime endDate = startDate.add(Duration(days: goal.period));
                          String dateRange = "${DateFormat('yyyy.MM.dd').format(startDate)} ~ ${DateFormat('yyyy.MM.dd').format(endDate)}";

                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                              child: _buildGlassCard(
                                padding: 20,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // 상단: 이름 및 메뉴
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // 1. 캘린더 버튼 (기존 스타일 유지)
                                        InkWell(
                                          onTap: () => _addEventToCalendar(goal),
                                          borderRadius: BorderRadius.circular(30), // 터치 효과 둥글게
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                shape: BoxShape.circle
                                            ),
                                            child: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                                          ),
                                        ),

                                        // 2. 제목 (중앙 정렬)
                                        Expanded(
                                          child: Text(
                                            goal.name,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)] // 그림자 추가로 가독성 UP
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // 3. 수정/삭제 메뉴 (캘린더 버튼과 디자인 통일 + 세련된 팝업)
                                        Theme(
                                          data: Theme.of(context).copyWith(
                                            popupMenuTheme: PopupMenuThemeData(
                                              color: const Color(0xFF2C2C2C), // 팝업 배경색 (진한 회색)
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 둥근 모서리
                                              textStyle: const TextStyle(color: Colors.white), // 텍스트 흰색
                                            ),
                                            dividerTheme: DividerThemeData(
                                              color: Colors.white.withOpacity(0.1), // 아주 연한 흰색
                                              thickness: 0.5, // 얇은 두께
                                            ),
                                          ),
                                          child: PopupMenuButton<String>(
                                            offset: const Offset(0, 45), // 버튼 바로 아래에 뜨도록 위치 조정
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            elevation: 8,
                                            // 버튼 모양을 캘린더와 똑같이 만듦
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  shape: BoxShape.circle
                                              ),
                                              child: const Icon(Icons.more_horiz, color: Colors.white, size: 18),
                                            ),
                                            onSelected: (value) {
                                              int realIndex = db.activeGoals.indexOf(goal);
                                              if (value == 'edit') _showEditGoalDialog(realIndex, goal);
                                              if (value == 'delete') setState(() => db.activeGoals.remove(goal));
                                            },
                                            itemBuilder: (BuildContext context) => [
                                              // 수정하기 메뉴
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                                                    SizedBox(width: 12),
                                                    Text('수정하기', style: TextStyle(color: Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              // 구분선 (선택 사항, 필요 없으면 제거)
                                              const PopupMenuDivider(height: 1),
                                              // 삭제하기 메뉴
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                    SizedBox(width: 12),
                                                    Text('삭제하기', style: TextStyle(color: Colors.redAccent)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 5),
                                    Text(dateRange, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                    const SizedBox(height: 15),

                                    // 메인 캐릭터 (이모지)
                                    Container(
                                      height: 155,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(colors: [Colors.white.withOpacity(0.3), Colors.transparent]),
                                      ),
                                      child: Text(
                                          isFailed ? "🍳" : goal.emoji,
                                          style: const TextStyle(fontSize: 90)
                                      ),
                                    ),

                                    const SizedBox(height: 15),

                                    // 하단 텍스트
                                    Text(
                                      isFailed ? "이 목표는 실패닭.."
                                          : (goal.temperature >= 100 ? "축하해! 닭이 되었어!" : "D-${goal.period - goal.currentDays}"),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 24, // 폰트 사이즈 조정
                                          fontWeight: FontWeight.w900,
                                          color: isFailed ? Colors.grey[400] : Colors.white
                                      ),
                                    ),
                                    Text(
                                      isFailed ? "기간이 끝났어요 😭"
                                          : (goal.temperature >= 100 ? "내일 둥지를 떠나요 👋" : "(${goal.frequency})"),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                                    ),

                                    const SizedBox(height: 16),
                                    _buildProgressBar(goal),
                                    const SizedBox(height: 16),

                                    // 인증 버튼
                                    SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: canVerify
                                            ? () => _showImageSourceSheet(goal) // goal 객체 전달
                                            : () {
                                          String msg = "";
                                          if (isFailed) msg = "이 목표는 실패했닭... 🍳";
                                          else if (goal.temperature >= 100) msg = "이미 다 컸닭! 🎉";
                                          else msg = "💤 오늘은 이미 인증했닭! 내일 또 만나!";

                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: !canVerify
                                              ? Colors.grey.withOpacity(0.3)
                                              : Colors.white,
                                          foregroundColor: !canVerify
                                              ? Colors.white60
                                              : Colors.brown,
                                          elevation: canVerify ? 5 : 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                                isFailed ? Icons.error_outline : (canVerify ? Icons.local_fire_department : Icons.check_circle),
                                                color: !canVerify ? Colors.white60 : Colors.orange
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isFailed ? "목표 실패"
                                                  : (goal.temperature >= 100 ? "성장 완료"
                                                  : (canVerify ? "온도 높이기" : "오늘 인증 완료")),
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // 화살표 네비게이션
                      if (_currentPage > 0)
                        Positioned(
                          left: 10, top: 0, bottom: 0,
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 30),
                              onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                            ),
                          ),
                        ),

                      if (_currentPage < visibleGoals.length - 1)
                        Positioned(
                          right: 10, top: 0, bottom: 0,
                          child: Center(
                            child: IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 30),
                              onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}