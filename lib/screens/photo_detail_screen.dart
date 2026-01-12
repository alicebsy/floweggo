import 'dart:io';
import 'package:flutter/material.dart';

class PhotoDetailScreen extends StatelessWidget {
  final String imagePath;
  final String date;
  final String description;

  const PhotoDetailScreen({
    super.key,
    required this.imagePath,
    required this.date,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 사진에 집중하도록 검은 배경
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // v2의 세련된 닫기 버튼
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true, // 앱바 뒤로 이미지가 보이게
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. 중앙의 큰 이미지 (Hero 애니메이션 적용)
          Center(
            child: Hero(
              tag: imagePath, // 썸네일과 같은 태그를 사용해야 연결됨
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain, // 비율 유지하며 화면에 맞춤
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // 2. 하단 설명 영역
          Container(
            width: double.infinity,
            // v2의 구체적인 패딩 값
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  // v1의 부드러운 그라데이션
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "📅 $date",
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                // 설명이 있으면 v1처럼 bold, 없으면 v2처럼 italic
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  )
                else
                  const Text(
                    "기록된 설명이 없닭! 🐥",
                    style: TextStyle(color: Colors.white60, fontSize: 16, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
