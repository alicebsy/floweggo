enum GoalStatus { egg, chick, chicken, fried }

class Goal {
  String id;
  String name;
  int period;
  int currentDays;
  double temperature;
  String frequency;

  // Dynamic 으로 자료형 변경
  List<Map<String, dynamic>> memories;

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

  set status(GoalStatus value) {
    _manualStatus = value;
  }

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
      case GoalStatus.chicken:
        return "🐓";
      case GoalStatus.chick:
        return "🐣";
      case GoalStatus.egg:
        return "🥚";
      case GoalStatus.fried:
        return "🍳";
    }
  }

  String get emoji2 {
    switch (status) {
      case GoalStatus.chicken:
        return "🏵️";
      case GoalStatus.chick:
        return "🌱";
      case GoalStatus.egg:
        return "🥜";
      case GoalStatus.fried:
        return "🍂";
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