enum GoalStatus { egg, chick, chicken, fried }

class Goal {
  String id;
  String name;
  int period;
  int currentDays;
  double temperature;
  String frequency;

  // 🔥 추가된 부분: 이 목표에 속한 사진 기록들 (경로와 날짜 저장)
  List<Map<String, String>> memories;

  Goal({
    required this.id,
    required this.name,
    required this.period,
    this.currentDays = 0,
    this.temperature = 0.0,
    required this.frequency,
    this.memories = const [], // 기본값은 빈 리스트
  });

  double get progress => currentDays / period;

  GoalStatus get status {
    if (progress >= 1.0) return GoalStatus.chicken;
    if (progress >= 0.5) return GoalStatus.chick;
    if (progress < 0.5 && currentDays >= 0) return GoalStatus.egg;
    return GoalStatus.fried;
  }

  String get emoji {
    switch (status) {
      case GoalStatus.chicken: return "🐓";
      case GoalStatus.chick: return "🐣";
      case GoalStatus.egg: return "🥚";
      case GoalStatus.fried: return "🍳";
    }
  }
}