enum GoalStatus { egg, chick, chicken, fried }

class Goal {
  String id;
  String name;
  int period;
  int currentDays;
  double temperature;
  String frequency;

  // 다양한 데이터(날짜, 이미지 경로 등)를 담기 위해 dynamic으로 설정
  List<Map<String, dynamic>> memories;

  // 상태를 수동으로 설정할 때 사용할 변수
  GoalStatus? _manualStatus;

  Goal({
    required this.id,
    required this.name,
    required this.period,
    this.currentDays = 0,
    this.temperature = 0.0,
    required this.frequency,
    this.memories = const [],
    GoalStatus? initialStatus,
  }) : _manualStatus = initialStatus;

  double get progress => currentDays / period;

  // 🔥 [Setter 추가] 외부에서 goal.status = ... 로 값을 넣을 수 있게 함
  set status(GoalStatus value) {
    _manualStatus = value;
  }

  // 🔥 [Getter 수정] 수동 설정값이 있으면 그걸 쓰고, 없으면 자동 계산
  GoalStatus get status {
    if (_manualStatus != null) {
      return _manualStatus!;
    }
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

  bool get isTodayDone {
    if (memories.isEmpty) return false; // 기록 없으면 안 한 것

    DateTime now = DateTime.now();
    String todayStr = "${now.year}-${now.month}-${now.day}";

    // 마지막 기록 날짜가 오늘과 같으면 true
    return memories.last['date'] == todayStr;
  }

}