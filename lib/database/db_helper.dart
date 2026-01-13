import '../models/goal_model.dart'; // 경로 확인 필요

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;

  // 🔥 [수정 1] 생성자에서 "날짜 지난 닭" 확인 로직 실행
  DbHelper._internal() {
    _checkExpiredChickens();
  }

  List<Goal> activeGoals = [];
  List<Goal> completedFarm = [];

  List<Goal> get allGoals => [...activeGoals, ...completedFarm];

  void addGoal(Goal goal) => activeGoals.add(goal);

  void deleteGoal(String id) {
    activeGoals.removeWhere((g) => g.id == id);
    completedFarm.removeWhere((g) => g.id == id);
  }

  // 🔥 [수정 2] 하루 1회 제한 + 닭이 되어도 바로 삭제 안 함
  void recordProgress(int index, String path, String description) {
    if (index >= activeGoals.length) return;
    final goal = activeGoals[index];

    // 현재 날짜 구하기
    DateTime now = DateTime.now();
    String todayStr = "${now.year}-${now.month}-${now.day}";

    // ✅ 하루 1회 인증 제한 로직
    if (goal.memories.isNotEmpty) {
      String lastDate = goal.memories.last['date'];
      if (lastDate == todayStr) {
        // 이미 오늘 인증을 했다면 함수 종료 (아무것도 안 함)
        print("오늘은 이미 인증했습니다.");
        return;
      }
    }

    // -- 여기부터는 인증 진행 --
    goal.currentDays++;
    goal.temperature = (goal.currentDays / goal.period) * 100;

    goal.memories = [
      ...goal.memories,
      {
        "date": todayStr,
        "imagePath": path,
        "description": description
      }
    ];

    // ✅ 100도가 넘어도 바로 삭제하지 않습니다!
    // 상태만 닭으로 바뀌고(Goal 모델 내부 로직), 홈 화면에는 그대로 남아있게 됨.
    if (goal.temperature >= 100) {
      // 필요하다면 여기서 축하 메시지 트리거 등을 처리
      goal.status = GoalStatus.chicken;
    }
  }

  // 🔥 [신규 추가] 앱 켤 때 실행: 어제 완성된 닭을 졸업시키는 함수
  void _checkExpiredChickens() {
    DateTime now = DateTime.now();
    String todayStr = "${now.year}-${now.month}-${now.day}";
    List<Goal> toMove = [];

    for (var goal in activeGoals) {
      // 1. 이미 닭이 되었고 (100% 달성)
      if (goal.temperature >= 100) {
        // 2. 기록이 있다면 날짜 확인
        if (goal.memories.isNotEmpty) {
          String lastDate = goal.memories.last['date'];

          // 3. 마지막 인증 날짜가 오늘이 아니라면 (어제나 그 이전)
          if (lastDate != todayStr) {
            toMove.add(goal);
          }
        }
      }
    }

    // 대상들을 홈(active)에서 졸업앨범(completed)으로 이동
    for (var goal in toMove) {
      completedFarm.add(goal);
      activeGoals.remove(goal);
    }
  }

  void releaseToFarm(int index) {
    if (activeGoals[index].status == GoalStatus.chicken) {
      completedFarm.add(activeGoals[index]);
      activeGoals.removeAt(index);
    }
  }
}