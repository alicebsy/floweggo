
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:http/http.dart' as http;

import '../models/goal_model.dart'; // Goal 모델 import

class ImageCheckScreen extends StatefulWidget {
  final String imagePath;
  final Goal goal; // 비교할 Goal 객체 전체를 전달받음

  const ImageCheckScreen({
    super.key,
    required this.imagePath,
    required this.goal, // 생성자에 goal 추가
  });

  @override
  ImageCheckScreenState createState() => ImageCheckScreenState();
}

class ImageCheckScreenState extends State<ImageCheckScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isProcessing = true;
  bool _isRelated = false;
  String _checkingMessage = "이미지 분석 중..."; // 처리 중 표시할 메시지

  late ImageLabeler _imageLabeler;

  // 중요: 실제 앱에서는 API 키를 코드에 직접 노출하면 안 됩니다.
  // 이 키는 예시이며, 실제 키로 교체하고 안전한 방식으로 관리해야 합니다.
  final String _apiKey = 'AIzaSyDHTcv2uw-a1FzQ8qwexY2a8925PJfMQwM';

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
    if (_apiKey != 'AIzaSyDHTcv2uw-a1FzQ8qwexY2a8925PJfMQwM') {
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
      
      이 라벨들을 바탕으로, 제출된 사진이 사용자의 목표와 간접적으로라도 연관될 가능성이 있는지 판단해주세요.
      예를 들어, 목표가 "쓰레기 줍기"이고 라벨에 'Floor'나 'Street'가 있다면 연관될 수 있습니다.
      목표가 "운동하기"이고 라벨에 'Person'이나 'Room', 'Shoe'가 있어도 연관될 수 있습니다.
      완벽하게 일치하지 않아도 괜찮으니, 사용자의 상황을 고려하여 관대하게 판단해주세요.
      
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
      Navigator.pop(context, 'AI가 목표 달성을 확인했닭! ✨'); // 자동 등록을 위해 빈 설명 반환
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("인증 사진 확인"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.file(File(widget.imagePath)),
            const SizedBox(height: 24),
            if (_isProcessing)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_checkingMessage),
                  ],
                ),
              )
            else if (!_isRelated)
              Column(
                children: [
                  const Text(
                    'AI가 목표와 관련이 적다고 판단했어요.\n사진에 대한 설명을 간단히 남겨주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '예: 오늘은 공원에서 주운 쓰레기들',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            const SizedBox(height: 24),
            // 처리 과정이 끝난 후에만 등록하기 버튼 표시
            if (!_isProcessing)
              ElevatedButton(
                onPressed: () {
                  // 설명이 있으면 설명을, 없으면 빈 문자열을 반환
                  Navigator.pop(context, _descriptionController.text);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('등록하기'),
              ),
          ],
        ),
      ),
    );
  }
}