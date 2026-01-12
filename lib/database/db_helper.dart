import '../models/goal_model.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  List<Goal> activeGoals = [];
  List<Goal> completedFarm = [];

  List<Goal> get allGoals => [...activeGoals, ...completedFarm];

  void addGoal(Goal goal) => activeGoals.add(goal);

  // 파라미터에 description 추가
  void recordProgress(int index, String path, String description) {
    if (index >= activeGoals.length) return;
    final goal = activeGoals[index];

    goal.currentDays++;
    goal.temperature = (goal.currentDays / goal.period) * 100;

    goal.memories = [
      ...goal.memories,
      {
        "date": "${DateTime.now().month}월 ${DateTime.now().day}일",
        // 🔥 [로직 추가] 날짜 계산을 위해 timestamp도 같이 저장해두면 정확도가 올라갑니다.
        "timestamp": DateTime.now().toIso8601String(),
        "imagePath": path,
        "description": description // AI 설명 저장
      }
    ];
  }

  void releaseToFarm(int index) {
    if (activeGoals[index].status == GoalStatus.chicken) {
      completedFarm.add(activeGoals[index]);
      activeGoals.removeAt(index);
    }
  }

  // 목표 삭제 기능
  void deleteGoal(String id) {
    // 1. 성장 중인 목록에서 ID가 같은 것 찾아서 삭제
    activeGoals.removeWhere((goal) => goal.id == id);

    // 2. 완료된 농장 목록에서 ID가 같은 것 찾아서 삭제
    completedFarm.removeWhere((goal) => goal.id == id);
  }

  // ----------------------------------------------------------------------
  // 🔥 [추가된 로직] 인증 가능 여부 계산 (블록 나누기)
  // ----------------------------------------------------------------------

  // 1. 빈도 문자열을 숫자로 변환 (블록 크기)
  // 매일 = 1일 간격, 격일 = 2일 간격, 주 3회(예시) = 3일 간격으로 가정
  int getInterval(String freq) {
    if (freq == "매일") return 1;
    if (freq == "격일") return 2;
    if (freq == "주 3회") return 3; // 사용자의 예시(1~3일, 4~6일)에 맞춰 3일로 설정
    return 1;
  }

  // 2. 날짜에서 시간 제거 (00:00:00으로 통일)
  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // 3. 오늘 인증 가능한지 확인하는 함수
  bool checkCanVerify(Goal goal) {
    // 목표 시작일 (ID가 날짜 문자열이라고 가정, 만약 아니라면 goal.startDate 필드 필요)
    DateTime startDate;
    try {
      startDate = DateTime.parse(goal.id);
    } catch (e) {
      startDate = DateTime.now(); // 에러 시 오늘로 처리
    }

    final interval = getInterval(goal.frequency);
    final now = _stripTime(DateTime.now());
    final start = _stripTime(startDate);

    // 1) 시작일로부터 며칠 지났는지 (0일차, 1일차...)
    int daysSinceStart = now.difference(start).inDays;
    if (daysSinceStart < 0) return false; // 미래의 목표?

    // 2) 현재 내가 속한 '블록 번호' 계산 (나눗셈 몫)
    // 예: 3일 주기일 때 -> 0,1,2일차(0번 블록) / 3,4,5일차(1번 블록)
    int currentBlock = daysSinceStart ~/ interval;

    // 3) 과거 기록(memories)을 뒤져서, '현재 블록'에 해당하는 기록이 있는지 확인
    for (var memory in goal.memories) {
      // 저장된 timestamp가 있다면 사용, 없으면 오늘 날짜로 가정(기존 데이터 호환)
      DateTime memDate;
      if (memory.containsKey("timestamp")) {
        memDate = DateTime.parse(memory["timestamp"]);
      } else {
        // 기존 데이터 호환용: 날짜 파싱이 어려우면 패스하거나 로직 보강 필요
        continue;
      }

      final memDay = _stripTime(memDate);
      int memDaysSinceStart = memDay.difference(start).inDays;
      int memBlock = memDaysSinceStart ~/ interval; // 기록된 날짜의 블록 번호

      // 💥 이미 이번 블록(구간)에 인증한 기록이 있다면 false 리턴
      if (memBlock == currentBlock) {
        return false;
      }
    }

    // 여기까지 통과하면 이번 구간엔 아직 인증 안 함 -> 가능!
    return true;
  }

}