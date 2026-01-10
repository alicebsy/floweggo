class Goal {
  String id;
  String name;
  int period; // 며칠 동안? (예: 30일)
  String frequency; // 얼마나 자주? (매일, 격일 등)
  int currentDays;
  double temperature;
  List<String> authImages; // 인증 사진 경로 저장

  Goal({
    required this.id,
    required this.name,
    required this.period,
    required this.frequency,
    this.currentDays = 0,
    this.temperature = 0.0,
    this.authImages = const [],
  });

  String getStatusEmoji() {
    double progress = currentDays / period;
    if (progress >= 1.0) return "🐔";
    if (progress >= 0.5) return "🐣";
    return "🥚";
  }
}