
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:http/http.dart' as http;

import '../../models/goal_model.dart'; // Goal 모델 import

class ImageCheckScreenV2 extends StatefulWidget {
  final String imagePath;
  final Goal goal; // 비교할 Goal 객체 전체를 전달받음

  const ImageCheckScreenV2({
    super.key,
    required this.imagePath,
    required this.goal, // 생성자에 goal 추가
  });

  @override
  ImageCheckScreenV2State createState() => ImageCheckScreenV2State();
}

class ImageCheckScreenV2State extends State<ImageCheckScreenV2> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isProcessing = true;
  bool _isRelated = false;
  String _checkingMessage = "이미지 분석 중..."; // 처리 중 표시할 메시지

  late ImageLabeler _imageLabeler;

  // 중요: 실제 앱에서는 API 키를 코드에 직접 노출하면 안 됩니다.
  // 이 키는 예시이며, 실제 키로 교체하고 안전한 방식으로 관리해야 합니다.
  final String _apiKey = 'AIzaSyA7nt85erpyLb_QGNPoNb9PFeOZ4fKzmoI';

  @override
  void initState() {
    super.initState();
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

  // Gemini API를 사용하여 연관성을 확인하는 함수
  Future<bool> _isRelatedToGoal(List<String> labels, String goalTitle) async {
    // Gemini API 키가 설정되지 않은 경우, 에러를 방지하고 사용자에게 입력을 요구하도록 기본값(false) 반환
    if (_apiKey != 'AIzaSyA7nt85erpyLb_QGNPoNb9PFeOZ4fKzmoI') {
      print("경고: Gemini API 키가 설정되지 않았습니다. 기본값인 '연관 없음'으로 처리합니다.");
      return false;
    }

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    // Gemini에게 보낼 프롬프트 (더 관대하게 판단하도록 수정)
    final prompt = '''
      당신은 사용자의 습관 형성을 돕는 친절한 AI 어시스턴트입니다.
      사용자가 자신의 목표 달성을 인증하기 위해 사진을 제출했습니다.
      
      - 사용자의 한국어 목표: "${goalTitle}"
      - 사진에서 추출된 영어 라벨: [${labels.join(', ')}]
      
      판단 기준:
      1. 목표 부합성: 추출된 라벨들이 사용자의 목표를 실제로 '실천'하고 있음을 증명하는지 관대하게 판단하세요.
        - 예: 목표가 "공부"인데 라벨에 'Book' 이나 'Writing' 이나 'Library'가 있다면 "yes".
        - 예: 목표가 "공부"인데 라벨에 'Video game' 이나 'Television'이 있다면 "no".
      2. 부정적 사례 차단: 목표와 반대되는 행위는 엄격히 거절하세요.
         - 목표가 '다이어트', '체중 감량', '식단 조절' 또는 '간강 관리' 인 경우:
            라벨에 'Food', 'Dish', 'Cuisine' 등이 포함되어 있더라도, 'Coke', 'Ice cream', 'Fast food', 'Dessert', 'Cake', 'Pizza' 등의 고칼로리 음식이나 패스트푸드와 관련된 라벨이 있다면 반드시 "no"를 반환하세요.
            단순 'Food' 나 'Dish' 만 존재한다면, "yes"라고 답하세요.
      4. 목표와 상충되는 라벨이 하나라도 포함되어 있다면 "no"라고 답하세요.
      5. 확신이 없거나 모호한 경우, 사용자가 직접 설명할 수 있도록 "no"를 선택하세요.
      6. 라벨이 'Musical instrument' 일 때는 'laptop'가 동일하게 판단하세요.
      
      답변은 반드시 "yes" 또는 "no"로만 해주세요.
    ''';

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)); // UTF-8로 디코딩
        final text = decodedResponse['candidates'][0]['content']['parts'][0]['text'] as String;
        print("Gemini API 응답: $text");
        return text.trim().toLowerCase() == 'yes';
      } else {
        print("Gemini API 오류: ${response.statusCode} ${response.body}");
        return false; // API 오류 시 기본값은 '연관 없음'
      }
    } catch (e) {
      print("Gemini API 호출 오류: $e");
      return false; // 네트워크 등 다른 오류 발생 시 기본값은 '연관 없음'
    }
  }

  // ML Kit과 Gemini를 순차적으로 호출하여 처리하는 함수
  Future<void> _processImageAndCheckRelevance() async {
    // 1. ML Kit으로 이미지에서 라벨 추출
    final inputImage = InputImage.fromFilePath(widget.imagePath);
    final List<ImageLabel> imageLabels = await _imageLabeler.processImage(inputImage);
    final List<String> labelTexts = imageLabels.map((label) => label.label).toList();

    print("ML Kit으로 추출된 라벨: $labelTexts");

    // 추출된 라벨이 없으면 사용자에게 설명 요구
    if (labelTexts.isEmpty) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isRelated = false;
        });
      }
      return;
    }

    // 2. Gemini API로 연관성 확인
    if (mounted) {
      setState(() {
        _checkingMessage = "목표와 연관성 확인 중...";
      });
    }

    final bool isGeminiRelated = await _isRelatedToGoal(labelTexts, widget.goal.name);

    if (mounted) {
      setState(() {
        _isRelated = isGeminiRelated;
        _isProcessing = false;
      });
    }

    // 3. 연관성이 있으면 자동으로 등록하고 화면 닫기
    if (isGeminiRelated) {
      if (!mounted) return;
      Navigator.pop(context, 'AI가 목표 달성을 확인했어요 ✨'); // 자동 등록을 위해 빈 설명 반환
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBrown = Color(0xFF6D4C41);
    const Color v2Background = Color(0xFFFDFCFB);

    return Scaffold(
      backgroundColor: v2Background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("인증 사진 확인", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // 1. 이미지 카드 (v2 특유의 둥근 모서리와 그림자)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.4,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 2. 상태 안내 및 입력 영역
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                ),
                child: Column(
                    children: [
                      if (_isProcessing) ...[
                        const CircularProgressIndicator(color: Colors.lightGreen, strokeWidth: 3),
                        const SizedBox(height: 20),
                        Text(_checkingMessage, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                      ] else if (!_isRelated) ...[
                          const Text("🤔", style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          const Text("AI가 확인이 필요하대요!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          const Text("사진이 목표와 어떻게 관련 있는지\n간단하게 설명해주실 수 있나요?", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black38, height: 1.5)),
                          const SizedBox(height: 20),
                          TextField(controller: _descriptionController, maxLines: 2,
                            decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50, hintText: "예: 오늘 공원에서 주운 쓰레기예요",
                              hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
                              contentPadding: const EdgeInsets.all(16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none,),
                            ),
                          ),
                      ],
                    ],
                ),
            ),
            const SizedBox(height: 32),

            // 3. 하단 버튼
            if (!_isProcessing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _descriptionController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    shadowColor: primaryBrown.withOpacity(0.4),
                  ),
                  child: const Text("인증 완료하기",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}