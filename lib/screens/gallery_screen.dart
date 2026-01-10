import 'package:flutter/material.dart';
import 'dart:io';
import '../models/goal_model.dart';

class GalleryScreen extends StatelessWidget {
  final List<Goal> goals;

  const GalleryScreen({super.key, required this.goals});

  @override
  Widget build(BuildContext context) {
    // 인증샷이 있는 목표들만 필터링
    final goalsWithImages = goals.where((g) => g.authImages.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // 아이폰 배경색
      body: Column(
        children: [
          // 1. 고정형 헤더: '나의 농장'과 높이/패딩 완벽 통일
          _buildHeader(),

          // 2. 하단 리스트 영역
          Expanded(
            child: goalsWithImages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 30),
              itemCount: goalsWithImages.length,
              itemBuilder: (context, index) => _buildGoalGalleryCard(goalsWithImages[index]),
            ),
          ),
        ],
      ),
    );
  }

  // 상단 헤더 규격 통일 (높이 200, 상단 패딩 60)
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 200, // 규격 통일
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFCC00FF), // 보라
            Color(0xFFFF00CC), // 핑크
          ],
        ),
      ),
      padding: const EdgeInsets.only(top: 60, left: 25), // 여백 통일
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📸 갤러리",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -1.0,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "나의 노력을 한눈에 확인하세요",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("📸", style: TextStyle(fontSize: 50)),
          SizedBox(height: 16),
          Text(
            "아직 인증샷이 없어요\n홈에서 첫 인증을 완료해보세요!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalGalleryCard(Goal goal) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10), // 0.04 opacity
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getEggEmoji(goal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${goal.authImages.length}개",
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: goal.authImages.reversed.map((img) => _buildPolaroidImage(img)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolaroidImage(Map<String, dynamic> imageData) {
    final description = imageData['description'] as String?;
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.5),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: Image.file(
              File(imageData['path']!),
              width: 140,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(17)),
            ),
            child: Column(
              children: [
                Text(
                  imageData['date']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getEggEmoji(Goal goal) {
    String emoji = "🥚";
    if (goal.status == EggStatus.chicken) {
      emoji = "🐔";
    } else if (goal.status == EggStatus.chick) {
      emoji = "🐣";
    }
    return Text(emoji, style: const TextStyle(fontSize: 28));
  }
}
