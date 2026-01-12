import '../models/goal_model.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  List<Goal> activeGoals = [];
  List<Goal> completedFarm = [];

  List<Goal> get allGoals => [...activeGoals, ...completedFarm];

  void addGoal(Goal goal) => activeGoals.add(goal);

  void deleteGoal(String id) {
    activeGoals.removeWhere((g) => g.id == id);
    completedFarm.removeWhere((g) => g.id == id);
  }

  // 파라미터에 description 추가
  void recordProgress(int index, String path, String description) {
    if (index >= activeGoals.length) return;
    final goal = activeGoals[index];

    goal.currentDays++;
    goal.temperature = (goal.currentDays / goal.period) * 100;

    goal.memories = [
      ...goal.memories,
      {
        "date": "${DateTime
            .now()
            .month}월 ${DateTime
            .now()
            .day}일",
        "imagePath": path,
        "description": description // AI 설명 저장
      }
    ];

    if (goal.temperature >= 100) {
      completedFarm.add(goal); // 성공 목록에 추가
      activeGoals.removeAt(index); // 진행 목록에서 삭제
    }
  }



  void releaseToFarm(int index) {
    if (activeGoals[index].status == GoalStatus.chicken) {
      completedFarm.add(activeGoals[index]);
      activeGoals.removeAt(index);
    }
  }

  // 사진 저장 로직
/*  void recordProgress(int index, String path) {
    if (index >= activeGoals.length) return; // 에러 방지

    final goal = activeGoals[index];

    goal.currentDays++;
    goal.temperature = (goal.currentDays / goal.period) * 100;

    String dateStr = "${DateTime.now().month}월 ${DateTime.now().day}일";

    // 리스트를 새로 갱신하여 UI가 변경을 감지하기 쉽게 함
    goal.memories = [
      ...goal.memories,
      {"date": dateStr, "imagePath": path}
    ];
  }*/
}