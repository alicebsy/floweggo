import 'dart:ui'; // 🔥 [UI 추가] 유리 효과(Blur)를 위해 필수 import
import 'dart:io';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/goal_model.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final db = DbHelper();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _deleteGoal(String id) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("기록 삭제"),
            content: const Text("이 성장 기록을 영구적으로 삭제하시겠습니까?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text("취소")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
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

  // 🔥 [NEW] 사진 크게 보기 팝업 함수
  void _showImagePopup(BuildContext context, String imagePath, String date,
      String description) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent, // 배경 투명하게
          insetPadding: EdgeInsets.zero, // 화면 꽉 차게
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. 검은색 반투명 배경 (클릭 시 닫힘)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.black.withOpacity(0.8)),
              ),

              // 2. 사진 (확대/축소 가능)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: InteractiveViewer( // 🔍 줌 기능 추가
                      child: Hero( // ✨ 애니메이션 효과
                        tag: imagePath, // 리스트와 동일한 태그 사용
                        child: Image.file(File(imagePath), fit: BoxFit.contain),
                      ),
                    ),
                  ),

                  // 3. 하단 설명창 (날짜 & 내용)
                  if (date.isNotEmpty || description.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      color: Colors.black.withOpacity(0.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            date,
                            style: const TextStyle(color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            description.isEmpty ? "내용 없음" : description,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // 4. 우측 상단 닫기 버튼
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
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
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
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

  @override
  Widget build(BuildContext context) {
    final allGoals = db.allGoals;
    final filteredGoals = allGoals.where((goal) {
      return goal.name.contains(_searchText);
    })
        .toList()
        .reversed
        .toList();

    return Scaffold(
      // 키보드가 올라올 때 배경이 찌그러지지 않게 설정
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 배경 이미지
          SizedBox.expand(child: Image.asset(
              'assets/images/bg_farm.png', fit: BoxFit.cover)),
          // 배경 어둡게 처리
          Container(color: Colors.black.withOpacity(0.3)),

          SafeArea(
            child: Column(
              children: [
                // 🔥 [수정 1] 상단 여백을 100 -> 10으로 줄여서 검색창을 위로 올림
                const SizedBox(height: 30),

                _buildSearchBar(),

                const SizedBox(height: 10), // 검색창과 리스트 사이 간격도 살짝 조절

                // 리스트 영역 (비어있으면 안내 문구)
                Expanded(
                  child: filteredGoals.isEmpty
                      ? _buildEmptyView() // 🔥 [수정 2] 이제 화면 중앙에 배치됨
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    itemCount: filteredGoals.length,
                    itemBuilder: (context, index) {
                      final goal = filteredGoals[index];
                      return _buildGoalAlbumCard(goal);
                    },
                  ),
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
        ? "검색된 알이 없닭! 🧐"
        : "아직 입양한 알이 없닭!\n인큐베이터에서 알을 입양해주세요.";

    // 🔥 [수정 3] Container로 감싸서 너비를 꽉 채우고 확실하게 중앙 정렬
    return Container(
      width: double.infinity, // 가로 꽉 채움
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
        children: [
          // 텅 빈 느낌을 주는 아이콘 추가 (선택사항)
          const Text("🥚", style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center, // 텍스트 가운데 정렬
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.5 // 줄 간격 조절
            ),
          ),
          // 시각적으로 너무 정중앙이면 살짝 답답할 수 있어 위쪽으로 살짝 올림 (선택사항)
          const SizedBox(height: 50),
        ],
      ),
    );
  }

// 각 알(목표) 정보를 보여주는 카드 위젯
  Widget _buildGoalAlbumCard(Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        // 전체 카드 배경 (유리 효과)
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
                // 1. 상단 헤더
                Row(
                  children: [
                    // 이모지
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                          goal.emoji, style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 15),

                    // 제목 및 개수
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
                            "추억 ${goal.memories.length}장",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    // 더보기 메뉴
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
                        icon: const Icon(
                            Icons.more_horiz, color: Colors.white70),
                        onSelected: (value) {
                          if (value == 'delete') _deleteGoal(goal.id);
                        },
                        itemBuilder: (BuildContext context) =>
                        [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 20),
                                SizedBox(width: 10),
                                Text('앨범 삭제', style: TextStyle(
                                    color: Colors.redAccent, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. 내용 영역 (박스 제거됨)
                goal.memories.isEmpty
                    ? SizedBox( // 🔥 [수정] 박스(Container/Decoration) 제거하고 투명하게 처리
                  width: double.infinity,
                  height: 100, // 적당한 높이 확보
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.photo_library_outlined, size: 30,
                          color: Colors.white24),
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
                    final String description = memory['description'] ?? "";
                    final String imagePath = memory['imagePath']!;
                    final String date = memory['date']!;

                    return GestureDetector(
                      onTap: () =>
                          _showImagePopup(
                              context, imagePath, date, description),
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
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.white54),
                                );
                              },
                            ),
                            // 날짜 표시
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black54,
                                      Colors.transparent
                                    ],
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