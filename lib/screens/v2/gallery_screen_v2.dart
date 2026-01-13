import 'dart:io';
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
    final filteredGoals = db.allGoals.where((g) => g.name.contains(_searchText)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text("활동 기록 로그", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
            centerTitle: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
          filteredGoals.isEmpty
              ? SliverFillRemaining(hasScrollBody: false, child: _buildEmptyView())
              : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                filteredGoals.map((goal) => _buildLogCard(goal)).toList(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildLogCard(Goal goal) {
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
              Text(goal.emoji2, style: const TextStyle(fontSize: 24)),
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
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PhotoDetailScreen(
                  imagePath: memory['imagePath']!,
                  date: memory['date']!,
                  description: memory['description'] ?? "",
                ))),
                child: Hero(
                  tag: memory['imagePath']!,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(memory['imagePath']!), fit: BoxFit.cover),
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
    return const Center(
      child: Text("일치하는 기록이 없습니다.", style: TextStyle(color: Colors.black26, fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}