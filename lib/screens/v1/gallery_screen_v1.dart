import 'dart:ui';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/goal_model.dart';
import '../photo_detail_screen.dart';

class GalleryScreenV1 extends StatefulWidget {
  const GalleryScreenV1({super.key});

  @override
  State<GalleryScreenV1> createState() => _GalleryScreenV1State();
}

class _GalleryScreenV1State extends State<GalleryScreenV1> {
  final db = DbHelper();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  // (0: 앨범 목록, 1: 잔디심기 화면)
  int _selectedIndex = 0;

  // 🔥 [추가] 사용자가 선택한 날짜 (없으면 null)
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  // 🔥 데이터 새로고침 함수
  void _loadData() async {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _deleteGoal(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("기록 삭제"),
        content: const Text("이 성장 기록을 영구적으로 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              db.deleteGoal(id);
              _loadData(); // 삭제 후 데이터 갱신
              Navigator.pop(context);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 위젯 빌더들 ---
  Widget _buildTabButton(String text, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _selectedDate = null; // 탭 바꿀 때 선택 날짜 초기화
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "어떤 알을 찾고 있나요?",
              border: InputBorder.none,
              icon: Icon(Icons.search, color: Colors.white70),
              hintStyle: TextStyle(color: Colors.white60),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 📸 1번 화면: 앨범 리스트
  // ---------------------------------------------------------
  Widget _buildAlbumListScreen(List<Goal> filteredGoals) {
    if (filteredGoals.isEmpty) {
      return _buildEmptyView();
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: filteredGoals.length,
      itemBuilder: (context, index) {
        final goal = filteredGoals[index];
        return _buildGoalAlbumCard(goal);
      },
    );
  }

  // ---------------------------------------------------------
  // 🌿 2번 화면: 잔디심기 (Heatmap)
  // ---------------------------------------------------------
  Widget _buildHeatMapScreen() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    // [데이터 분석]
    Map<int, int> dailyCounts = {};
    int totalMemories = 0;

    for (var goal in db.allGoals) {
      for (var memory in goal.memories) {
        // 🔥 [수정] dynamic 타입일 수 있으므로 안전하게 변환
        if (memory['date'] == null) continue;
        String dateStr = memory['date'].toString();

        // 날짜 정규화 (시간 제거, .을 -로 변경)
        String normalizedDate = dateStr.replaceAll('.', '-').replaceAll('/', '-').split(' ')[0];

        try {
          List<String> parts = normalizedDate.split('-');
          if (parts.length >= 3) {
            int year = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int day = int.parse(parts[2]);

            // 이번 달 데이터만 카운트
            if (year == now.year && month == now.month) {
              dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
              totalMemories++;
            }
          }
        } catch (e) {
          // 파싱 에러 무시 (형식이 안 맞는 데이터 skip)
        }
      }
    }

    // 최댓값 계산 (상대평가용)
    int maxCount = 0;
    if (dailyCounts.isNotEmpty) {
      maxCount = dailyCounts.values.reduce(max);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "이번 달 성장 기록 🌿",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "총 $totalMemories장의 인증샷을 올렸어요!",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
            const SizedBox(height: 20),

            // 1️⃣ 캘린더 그리드 컨테이너
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  // 요일 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ["일", "월", "화", "수", "목", "금", "토"]
                        .map((d) => SizedBox(
                      width: 30,
                      child: Text(d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),

                  // 날짜 그리드
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: lastDayOfMonth + (firstDayOfMonth.weekday % 7),
                    itemBuilder: (context, index) {
                      int offset = firstDayOfMonth.weekday % 7;
                      if (index < offset) return const SizedBox();

                      int day = index - offset + 1;
                      int count = dailyCounts[day] ?? 0;

                      // 미래 날짜 처리
                      if (day > now.day) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(child: Text("$day", style: TextStyle(color: Colors.white12, fontSize: 10))),
                        );
                      }

                      // 🔥 선택된 날짜인지 확인
                      bool isSelected = _selectedDate != null && _selectedDate!.day == day;

                      return GestureDetector(
                        // 🔥 [터치 이벤트] 날짜 선택
                        onTap: () {
                          setState(() {
                            // 같은 날짜 누르면 선택 해제, 아니면 선택
                            if (isSelected) {
                              _selectedDate = null;
                            } else {
                              _selectedDate = DateTime(now.year, now.month, day);
                            }
                          });
                        },
                        child: Tooltip(
                          message: "$day일: $count장",
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getColorRelative(count, maxCount),
                              borderRadius: BorderRadius.circular(6),
                              // 🔥 선택 시 흰색 테두리 추가
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2.5)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                "$day",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: count > 0 ? Colors.white : Colors.white30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 범례
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Less ", style: TextStyle(color: Colors.white54, fontSize: 10)),
                _buildLegendBox(Colors.white.withOpacity(0.1)),
                const SizedBox(width: 4),
                _buildLegendBox(const Color(0xFF9BE9A8)),
                _buildLegendBox(const Color(0xFF40C463)),
                _buildLegendBox(const Color(0xFF30A14E)),
                _buildLegendBox(const Color(0xFF216E39)),
                const SizedBox(width: 4),
                const Text(" More", style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),

            // 2️⃣ 🔥 [신규 추가] 선택된 날짜의 인증샷 리스트
            if (_selectedDate != null)
              _buildSelectedDatePhotos(_selectedDate!),
          ],
        ),
      ),
    );
  }

  // 🔥 [수정됨] 타입 에러 해결 버전
  Widget _buildSelectedDatePhotos(DateTime date) {
    String targetDate = "${date.year}-${date.month}-${date.day}";

    // 1. [수정 포인트] String -> dynamic 으로 변경
    List<Map<String, dynamic>> memoriesOnDate = [];

    for (var goal in db.allGoals) {
      for (var memory in goal.memories) {
        // 날짜 비교 (memory['date']가 dynamic일 수 있으므로 toString()으로 안전하게 비교)
        if (memory['date'].toString() == targetDate) {
          memoriesOnDate.add(memory);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              "${date.month}월 ${date.day}일의 기록",
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: memoriesOnDate.isEmpty
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "이 날은 쉬어갔네요! 😴",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          )
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: memoriesOnDate.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final memory = memoriesOnDate[index];

              // 2. [안전한 사용] dynamic 타입이므로 꺼낼 때 String으로 명시적 변환
              final String imagePath = memory['imagePath']?.toString() ?? "";
              final String dateStr = memory['date']?.toString() ?? "";
              final String description = memory['description']?.toString() ?? "";

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoDetailScreen(
                  imagePath: imagePath,
                  date: dateStr,
                  description: description,
                ))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: Colors.white10,
                      child: const Icon(Icons.broken_image, color: Colors.white30),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 색상 계산 로직
  Color _getColorRelative(int count, int maxCount) {
    if (count == 0) return Colors.white.withOpacity(0.1);
    if (maxCount == 0) return Colors.white.withOpacity(0.1);

    double ratio = count / maxCount;

    if (ratio > 0.75) return const Color(0xFF216E39);
    if (ratio > 0.50) return const Color(0xFF30A14E);
    if (ratio > 0.25) return const Color(0xFF40C463);
    return const Color(0xFF9BE9A8);
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGoals = db.allGoals;

    List<Goal> filteredGoals = allGoals.where((goal) {
      return goal.name.contains(_searchText);
    }).toList().reversed.toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SizedBox.expand(child: Image.asset('assets/images/bg_farm.png', fit: BoxFit.cover)),
          Container(color: Colors.black.withOpacity(0.3)),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                _buildSearchBar(),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildTabButton("내 앨범", 0),
                      const SizedBox(width: 10),
                      _buildTabButton("이번 달 기록", 1),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _selectedIndex == 0
                      ? _buildAlbumListScreen(filteredGoals)
                      : _buildHeatMapScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    String message = _searchText.isNotEmpty
        ? "검색된 알이 없닭! "
        : "아직 입양한 알이 없닭!\n둥지에서 알을 입양해주세요.";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🧐", style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.5)),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildGoalAlbumCard(Goal goal) {
    final now = DateTime.now();
    DateTime startDate;
    try {
      startDate = DateTime.parse(goal.id); // goal.id에 저장된 생성일 파싱
    } catch (e) {
      startDate = DateTime.now();
    }
    final endDate = startDate.add(Duration(days: goal.period)); // 종료일 계산
    final bool isFailed = now.isAfter(endDate) && goal.temperature < 100; // 기간 만료 및 미달성 체크

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                          isFailed ? "🍳" : goal.emoji, // 🔥 [수정] 실패 시 후라이, 아니면 단계별 이모지 표시
                          style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "기록 ${goal.memories.length}장",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        popupMenuTheme: PopupMenuThemeData(
                          color: const Color(0xFF2C2C2C),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          textStyle: const TextStyle(color: Colors.white),
                        ),
                        dividerTheme: DividerThemeData(
                          color: Colors.white.withOpacity(0.1),
                          thickness: 0.5,
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: Colors.white70),
                        onSelected: (value) {
                          if (value == 'delete') _deleteGoal(goal.id);
                        },
                        itemBuilder: (BuildContext context) =>
                        [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                SizedBox(width: 10),
                                Text('앨범 삭제', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                goal.memories.isEmpty
                    ? SizedBox(
                  width: double.infinity,
                  height: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.photo_library_outlined, size: 30, color: Colors.white24),
                      SizedBox(height: 10),
                      Text(
                        "아직 인증샷이 없어요",
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                )
                    : GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: goal.memories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, imgIndex) {
                    final memory = goal.memories[imgIndex];

                    // 🔥 [수정] 여기서도 안전하게 타입 변환
                    final String description = memory['description']?.toString() ?? "";
                    final String imagePath = memory['imagePath']?.toString() ?? "";
                    final String date = memory['date']?.toString() ?? "";

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoDetailScreen(
                        imagePath: imagePath,
                        date: date,
                        description: description,
                      ))),
                      child: Hero(
                        tag: imagePath,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.white10,
                                    child: const Icon(Icons.broken_image, color: Colors.white54),
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 0, left: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [Colors.black54, Colors.transparent],
                                    ),
                                  ),
                                  child: Text(
                                    date,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}