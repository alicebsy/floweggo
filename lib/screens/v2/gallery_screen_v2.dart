import 'dart:io';
import 'dart:math'; // max 함수 사용을 위해 추가
import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/goal_model.dart';
import '../photo_detail_screen.dart';

class GalleryScreenV2 extends StatefulWidget {
  const GalleryScreenV2({super.key});

  @override
  State<GalleryScreenV2> createState() => _GalleryScreenV2State();
}

class _GalleryScreenV2State extends State<GalleryScreenV2> {
  final db = DbHelper();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  // --- [추가] 1번 기능: 목표 삭제 로직 ---
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
              db.deleteGoal(id); // DB에서 삭제
              setState(() {});    // UI 갱신
              Navigator.pop(context);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 0: 목록 보기, 1: 잔디 보기
  int _selectedIndex = 0;

  // 선택된 날짜
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _searchText = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 검색 필터링
    final filteredGoals = db.allGoals.where((g) => g.name.contains(_searchText)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 2. 검색창
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "목표 기록 검색",
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),

          // 3. 탭 전환 버튼 (목록 vs 잔디)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  _buildTabButton("기록 목록", 0),
                  const SizedBox(width: 10),
                  _buildTabButton("이번 달 잔디", 1),
                ],
              ),
            ),
          ),

          // 4. 내용 (조건부 렌더링)
          if (_selectedIndex == 0)
          // [View 1] 리스트 뷰
            (filteredGoals.isEmpty
                ? SliverFillRemaining(hasScrollBody: false, child: _buildEmptyView())
                : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  filteredGoals.map((goal) => _buildLogCard(goal)).toList(),
                ),
              ),
            ))
          else
          // [View 2] 잔디 심기 (히트맵)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildHeatMapContent(),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // --- 🔘 탭 버튼 위젯 ---
  Widget _buildTabButton(String text, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _selectedDate = null; // 탭 변경 시 날짜 선택 초기화
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // --- 🌿 잔디 심기 (히트맵) 컨텐츠 ---
  Widget _buildHeatMapContent() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    // 데이터 집계 로직 (V1과 동일)
    Map<int, int> dailyCounts = {};
    int totalMemories = 0;

    for (var goal in db.allGoals) {
      for (var memory in goal.memories) {
        if (memory['date'] == null) continue;
        String dateStr = memory['date'].toString();
        String normalizedDate = dateStr.replaceAll('.', '-').replaceAll('/', '-').split(' ')[0];

        try {
          List<String> parts = normalizedDate.split('-');
          if (parts.length >= 3) {
            int year = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int day = int.parse(parts[2]);

            if (year == now.year && month == now.month) {
              dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
              totalMemories++;
            }
          }
        } catch (e) {
          // 파싱 에러 무시
        }
      }
    }

    int maxCount = dailyCounts.isEmpty ? 0 : dailyCounts.values.reduce(max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          "이번 달 총 $totalMemories개의 기록을 심었어요! 🌱",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 20),

        // 캘린더 박스 (V2 스타일: 밝은 회색 배경)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
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
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
                  bool isFuture = day > now.day;
                  bool isSelected = _selectedDate != null && _selectedDate!.day == day;

                  if (isFuture) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Text("$day", style: TextStyle(color: Colors.grey.shade300, fontSize: 10))),
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDate = null;
                        } else {
                          _selectedDate = DateTime(now.year, now.month, day);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getColorRelative(count, maxCount),
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                      ),
                      child: Center(
                        child: Text(
                          "$day",
                          style: TextStyle(
                            fontSize: 10,
                            color: count > 0 ? Colors.white : Colors.grey.shade400,
                            fontWeight: FontWeight.bold,
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
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Less ", style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
              _buildLegendBox(Colors.grey.shade200),
              const SizedBox(width: 4),
              _buildLegendBox(const Color(0xFFC6E48B)),
              _buildLegendBox(const Color(0xFF7BC96F)),
              _buildLegendBox(const Color(0xFF239A3B)),
              _buildLegendBox(const Color(0xFF196127)),
              const SizedBox(width: 4),
              Text(" More", style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
            ],
          ),
        ),

        // 선택된 날짜의 사진들
        if (_selectedDate != null) _buildSelectedDatePhotos(_selectedDate!),
      ],
    );
  }

  Widget _buildSelectedDatePhotos(DateTime date) {
    String targetDate = "${date.year}-${date.month}-${date.day}";
    List<Map<String, dynamic>> memoriesOnDate = [];

    for (var goal in db.allGoals) {
      for (var memory in goal.memories) {
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
            const Icon(Icons.calendar_today_rounded, color: Colors.black54, size: 18),
            const SizedBox(width: 8),
            Text(
              "${date.month}월 ${date.day}일의 기록",
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        memoriesOnDate.isEmpty
            ? Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Center(
            child: Text("이 날은 기록이 없어요 😴", style: TextStyle(color: Colors.grey)),
          ),
        )
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: memoriesOnDate.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final memory = memoriesOnDate[index];
            final String imagePath = memory['imagePath']?.toString() ?? "";

            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoDetailScreen(
                imagePath: imagePath,
                date: memory['date']?.toString() ?? "",
                description: memory['description']?.toString() ?? "",
              ))),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- 헬퍼 함수들 ---
  Color _getColorRelative(int count, int maxCount) {
    if (count == 0) return Colors.grey.shade200; // 빈 날짜는 연한 회색
    if (maxCount == 0) return Colors.grey.shade200;

    double ratio = count / maxCount;
    // GitHub 스타일의 초록색 테마
    if (ratio > 0.75) return const Color(0xFF196127);
    if (ratio > 0.50) return const Color(0xFF239A3B);
    if (ratio > 0.25) return const Color(0xFF7BC96F);
    return const Color(0xFFC6E48B);
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }


  Widget _buildLogCard(Goal goal) {
    final now = DateTime.now();
    DateTime startDate;
    try {
      startDate = DateTime.parse(goal.id); // 생성일 파싱
    } catch (e) {
      startDate = DateTime.now();
    }
    final endDate = startDate.add(Duration(days: goal.period)); // 종료일 계산
    final bool isFailed = now.isAfter(endDate) && goal.temperature < 100; // 실패 여부 판단

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isFailed ? "🥀" : goal.emoji2, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text("${goal.memories.length}개의 활동 인증", style: const TextStyle(fontSize: 13, color: Colors.black38)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.black26),
                onSelected: (value) {
                  if (value == 'delete') _deleteGoal(goal.id);
                },
                itemBuilder: (context) => [
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
          const SizedBox(height: 20),
            ],
          ),
          const SizedBox(height: 20),
          goal.memories.isEmpty
              ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text("기록된 활동이 없습니다.", style: TextStyle(color: Colors.black26, fontSize: 14))),
          )
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: goal.memories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, idx) {
              final memory = goal.memories[idx];
              final String imagePath = memory['imagePath']?.toString() ?? "";
              final String date = memory['date']?.toString() ?? "";
              final String description = memory['description']?.toString() ?? "";

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
                    child: Stack( // --- [수정] 날짜 표시를 위해 Stack 사용 ---
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                        // --- [추가] 썸네일 하단 날짜 표시 (Positioned) ---
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Text(
                              date,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildEmptyView() {
    String message = _searchText.isNotEmpty
        ? "검색된 씨앗이 없어요! "
        : "아직 심은 씨앗이 없어요!\n텃밭에서 씨앗을 심어주세요.";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🧐", style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, height: 1.5)),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}