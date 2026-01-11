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

  // 검색어 입력을 제어하는 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  // 현재 입력된 검색어를 저장하는 변수
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    // 검색창에 글자가 입력될 때마다 화면을 새로고침하여 결과를 갱신합니다.
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    // 화면이 꺼질 때 컨트롤러를 정리합니다 (메모리 누수 방지).
    _searchController.dispose();
    super.dispose();
  }

  // 화면을 강제로 다시 그리는 함수 (새로고침 버튼용)
  void _refresh() {
    setState(() {});
  }

  // 🔍 검색창 위젯 (디자인)
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // 약간 투명한 흰색 배경
        borderRadius: BorderRadius.circular(30), // 둥근 모서리
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))], // 그림자
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: "어떤 알을 찾고 있나요?", // 안내 문구
          border: InputBorder.none, // 테두리 없앰
          icon: Icon(Icons.search, color: Colors.brown), // 돋보기 아이콘
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. 데이터베이스에서 모든 목표(알) 리스트를 가져옵니다.
    final allGoals = db.allGoals;

    // 2. 검색어가 포함된 목표만 골라냅니다 (필터링).
    final filteredGoals = allGoals.where((goal) {
      // 검색어가 비어있으면 모든 알을 보여주고, 있으면 이름에 포함된 것만 보여줍니다.
      return goal.name.contains(_searchText);
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지 설정
          SizedBox.expand(child: Image.asset('assets/images/sum2.png', fit: BoxFit.cover)),

          // 배경을 약간 어둡게 처리 (글씨가 잘 보이도록)
          Container(color: Colors.black.withOpacity(0.3)),

          SafeArea(
            child: Column(
              children: [
                // 🔥🔥 [위치 재조정] 여백을 80 -> 130으로 더 늘려서 확실히 내렸습니다.
                const SizedBox(height: 100),

                // 검색창 표시
                _buildSearchBar(),

                const SizedBox(height: 10),

                // 우측 상단 새로고침 버튼
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _refresh,
                      tooltip: "새로고침",
                    ),
                  ),
                ),

                // 리스트 보여주는 부분
                Expanded(
                  child: filteredGoals.isEmpty
                      ? _buildEmptyView() // 검색 결과가 없으면 안내 문구 표시
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: filteredGoals.length,
                    itemBuilder: (context, index) {
                      final goal = filteredGoals[index];
                      return _buildGoalAlbumCard(goal); // 각 알의 카드 위젯
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

  // 데이터가 없을 때 보여줄 화면
  Widget _buildEmptyView() {
    // 검색 중일 때와, 아예 데이터가 없을 때 문구를 다르게 보여줍니다.
    String message = _searchText.isNotEmpty
        ? "검색된 알이 없닭! 🧐"
        : "아직 입양한 알이 없닭!\n인큐베이터에서 알을 입양해주세요.";

    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 각 알(목표) 정보를 보여주는 카드 위젯
  Widget _buildGoalAlbumCard(Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25), // 카드 간 간격
      padding: const EdgeInsets.all(15), // 내부 여백
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1).withOpacity(0.95), // 연한 노란색 배경
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 이모지, 이름, 사진 개수
          Row(
            children: [
              Text(goal.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
                  Text("${goal.memories.length}개의 인증샷", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.brown, thickness: 1, height: 20), // 구분선

          // 하단: 사진 그리드 (사진이 없으면 안내 문구)
          goal.memories.isEmpty
              ? Container(
            height: 100,
            alignment: Alignment.center,
            child: const Text("아직 기록된 사진이 없어요.\n온도를 높여 인증샷을 남겨보세요!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          )
              : GridView.builder(
            shrinkWrap: true, // 리스트 안에 리스트가 들어갈 때 필수
            physics: const NeverScrollableScrollPhysics(), // 스크롤 방지 (전체 스크롤 사용)
            itemCount: goal.memories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 한 줄에 3개씩
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8, // 정사각형
            ),
            itemBuilder: (context, imgIndex) {
              final memory = goal.memories[imgIndex];
              final String description = memory['description'] ?? "";
              return Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(memory['imagePath']!), fit: BoxFit.cover),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              color: Colors.black54,
                              child: Text(memory['date']!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 🔥 [추가됨] 사진 아래에 AI 설명(description) 표시
                  if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9, color: Colors.brown),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}