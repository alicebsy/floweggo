import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/goal_model.dart';
import '../photo_detail_screen.dart'; // 🔥 1. 통합된 상세 페이지 import

class GalleryScreenV1 extends StatefulWidget {
  const GalleryScreenV1({super.key});

  @override
  State<GalleryScreenV1> createState() => _GalleryScreenV1State();
}

class _GalleryScreenV1State extends State<GalleryScreenV1> {
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

  // 🔥 2. _showImagePopup 함수는 이제 사용하지 않으므로 삭제되었습니다.

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
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SizedBox.expand(child: Image.asset(
              'assets/images/bg_farm.png', fit: BoxFit.cover)),
          Container(color: Colors.black.withOpacity(0.3)),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),

                _buildSearchBar(),

                const SizedBox(height: 10),

                Expanded(
                  child: filteredGoals.isEmpty
                      ? _buildEmptyView()
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🥚", style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.5
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildGoalAlbumCard(Goal goal) {
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
                // ... (상단 헤더 부분은 동일)
                Row(
                  children: [
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
                goal.memories.isEmpty
                    ? SizedBox(
                  width: double.infinity,
                  height: 100, 
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

                    // 🔥 3. 상세 페이지로 이동하도록 수정
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoDetailScreen(
                        imagePath: imagePath,
                        date: date,
                        description: description,
                      ))),
                      // 🔥 4. Hero 애니메이션 추가
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
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.white54),
                                  );
                                },
                              ),
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
