import 'dart:io';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/goal_model.dart';
import 'photo_detail_screen.dart'; // 🔥 [추가] 상세 화면 import

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

  void _refresh() {
    setState(() {});
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: "어떤 알의 기록을 찾고 있냐닭?",
          border: InputBorder.none,
          icon: Icon(Icons.search_rounded, color: Color(0xFFD35400)),
          hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGoals = db.allGoals;
    final filteredGoals = allGoals.where((goal) {
      return goal.name.contains(_searchText);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: const Color(0xFFFDFCFB),
            title: const Text("성장기록이닭! 📸", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28)),
            actions: [
              IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
              const SizedBox(width: 10),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildSearchBar(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          filteredGoals.isEmpty
              ? SliverFillRemaining(hasScrollBody: false, child: _buildEmptyView())
              : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                filteredGoals.map((goal) => _buildGoalAlbumCard(goal)).toList(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    String message = _searchText.isNotEmpty
        ? "검색된 알이 없닭! 🧐"
        : "아직 입양한 알이 없닭!\n부화장에서 알을 입양해달닭.";
    return Center(
      child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black26, fontSize: 16, fontWeight: FontWeight.bold, height: 1.5)),
    );
  }

  Widget _buildGoalAlbumCard(Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFDF2E9), borderRadius: BorderRadius.circular(15)),
                child: Text(goal.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    Text("${goal.memories.length}개의 인증샷이 있닭", style: const TextStyle(fontSize: 13, color: Colors.black38, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          goal.memories.isEmpty
              ? Container(
            height: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(20)),
            child: const Text("아직 기록된 사진이 없닭!\n온도를 높여 인증샷을 남겨달닭!", textAlign: TextAlign.center, style: TextStyle(color: Colors.black26, fontSize: 13)),
          )
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: goal.memories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, imgIndex) {
              final memory = goal.memories[imgIndex];
              final imagePath = memory['imagePath']!;
              final date = memory['date']!;
              final description = memory['description'] ?? "";

              // 🔥 [수정] GestureDetector로 감싸서 클릭 이벤트 추가
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoDetailScreen(
                        imagePath: imagePath,
                        date: date,
                        description: description,
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 🔥 [수정] Hero 위젯 적용 (tag는 유니크한 이미지 경로 사용)
                            Hero(
                              tag: imagePath,
                              child: Image.file(File(imagePath), fit: BoxFit.cover),
                            ),
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                color: Colors.black45,
                                child: Text(date, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}