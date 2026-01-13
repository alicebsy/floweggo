import 'dart:convert';
import 'dart:io';
import 'dart:ui'; // 🔥 유리 효과(Blur)를 위해 필수

import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:http/http.dart' as http;

import '../../models/goal_model.dart';

class ImageCheckScreenV1 extends StatefulWidget {
  final String imagePath;
  final Goal goal;

  const ImageCheckScreenV1({
    super.key,
    required this.imagePath,
    required this.goal,
  });

  @override
  ImageCheckScreenV1State createState() => ImageCheckScreenV1State();
}

class ImageCheckScreenV1State extends State<ImageCheckScreenV1> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isProcessing = true;
  bool _isRelated = false;
  String _checkingMessage = "이미지 분석 중이닭...";

  late ImageLabeler _imageLabeler;

  // 🔥 [주의] 실제 배포 시에는 API 키를 안전하게 관리해야 합니다.
  final String _apiKey = 'AIzaSyDiLJyKKzD7nQOxJw24yE-6gK5FMZZEZ_A';

  @override
  void initState() {
    super.initState();
    // 신뢰도 0.7 이상인 라벨만 가져오기
    final ImageLabelerOptions options = ImageLabelerOptions(confidenceThreshold: 0.7);
    _imageLabeler = ImageLabeler(options: options);
    _processImageAndCheckRelevance();
  }

  @override
  void dispose() {
    _imageLabeler.close();
    _descriptionController.dispose();
    super.dispose();
  }

  // 🤖 Gemini API 호출 함수 (디버깅 로그 추가됨)
  Future<bool> _isRelatedToGoal(List<String> labels, String goalTitle) async {
    // 1. API 키 확인
    if (_apiKey != '') {
      print("🚨 [ERROR] 예시 API 키가 사용되었습니다. 본인의 키로 교체해주세요!");
      return false;
    }

    print("🤖 [Gemini] 요청 시작...");
    print("👉 목표: $goalTitle");
    print("👉 감지된 라벨: $labels");

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    final prompt = '''
      당신은 사용자의 습관 형성을 돕는 친절한 AI 어시스턴트입니다.
      사용자가 자신의 목표 달성을 인증하기 위해 사진을 제출했습니다.
      
      - 사용자의 한국어 목표: "${goalTitle}"
      - 사진에서 추출된 영어 라벨: [${labels.join(', ')}]
      
      이 라벨들을 바탕으로, 제출된 사진이 사용자의 목표와 간접적으로라도 연관될 가능성이 있는지 판단해주세요.
      관대하게 판단해주세요.
      답변은 반드시 "yes" 또는 "no"로만 해주세요.
    ''';

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      print("🤖 [Gemini] 응답 상태 코드: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        print("🤖 [Gemini] 전체 응답: $decodedResponse"); // 🔥 전체 응답 확인

        // 응답 파싱 안전하게 처리
        try {
          final text = decodedResponse['candidates'][0]['content']['parts'][0]['text'] as String;
          print("🤖 [Gemini] 최종 판단 결과: ${text.trim()}");
          return text.trim().toLowerCase() == 'yes';
        } catch (e) {
          print("🚨 [ERROR] 응답 파싱 실패: $e");
          return false;
        }
      } else {
        // 200이 아닐 경우 에러 내용 출력
        print("🚨 [ERROR] Gemini API 호출 실패!");
        print("🚨 본문: ${response.body}");
        return false;
      }
    } catch (e) {
      print("🚨 [ERROR] 네트워크 연결 오류 또는 기타 예외: $e");
      return false;
    }
  }

  // 🖼️ 이미지 분석 함수 (ML Kit 디버깅 로그 추가됨)
  Future<void> _processImageAndCheckRelevance() async {
    print("📸 [ML Kit] 이미지 분석 시작: ${widget.imagePath}");

    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      final List<ImageLabel> imageLabels = await _imageLabeler.processImage(inputImage);
      final List<String> labelTexts = imageLabels.map((label) => label.label).toList();

      print("📸 [ML Kit] 감지된 라벨 목록: $labelTexts");

      if (labelTexts.isEmpty) {
        print("⚠️ [ML Kit] 라벨을 하나도 찾지 못했습니다.");
        if (mounted) setState(() { _isProcessing = false; _isRelated = false; });
        return;
      }

      if (mounted) setState(() { _checkingMessage = "목표와 맞는지 고민 중이닭..."; });

      // Gemini에게 물어보기
      final bool isGeminiRelated = await _isRelatedToGoal(labelTexts, widget.goal.name);

      if (mounted) {
        setState(() {
          _isRelated = isGeminiRelated;
          _isProcessing = false;
        });
      }

      if (isGeminiRelated) {
        if (!mounted) return;
        print("✨ [Success] 목표 달성 확인됨!");
        Navigator.pop(context, 'AI가 목표 달성을 확인했닭! ✨');
      } else {
        print("🤔 [Info] AI가 관련성을 찾지 못함. 사용자 입력 대기.");
      }

    } catch (e) {
      print("🚨 [ERROR] ML Kit 처리 중 치명적 오류 발생: $e");
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isRelated = false; // 에러 나면 수동 입력으로 유도
        });
      }
    }
  }

  // 🔥 [디자인] 유리 효과 카드 위젯
  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 배경
          SizedBox.expand(
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/images/farm_inside.png', // 배경 이미지
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 상단 바
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _buildGlassCard(
                        padding: const EdgeInsets.all(8),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "인증 사진 확인",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 선택된 이미지
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 400),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 상태창
                        _buildGlassCard(
                          child: Column(
                            children: [
                              if (_isProcessing) ...[
                                const CircularProgressIndicator(color: Colors.white),
                                const SizedBox(height: 16),
                                Text(
                                  _checkingMessage,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ] else if (!_isRelated) ...[
                                const Icon(Icons.help_outline, color: Colors.amberAccent, size: 40),
                                const SizedBox(height: 10),
                                const Text(
                                  'AI가 고개를 갸웃거린닭... 🤔',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '사진이 목표와 관련이 적어 보여요.\n어떤 상황인지 설명을 남겨주세요!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _descriptionController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.black.withOpacity(0.3),
                                    hintText: '예: 공원에서 쓰레기를 주웠어요',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 버튼
                        if (!_isProcessing)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, _descriptionController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              '기록 남기기',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
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