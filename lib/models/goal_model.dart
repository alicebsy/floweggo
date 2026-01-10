// 1. EggStatus enum을 클래스 외부(상단)에 정의해야 합니다.
enum EggStatus { egg, chick, chicken, fried }

class Goal {
  final String id;
  final String title;
  final int totalDays;
  int currentDays;
  EggStatus status;
  // 사진 경로, 날짜, 설명을 담는 리스트
  List<Map<String, dynamic>> authImages;

  Goal({
    required this.id,
    required this.title,
    required this.totalDays,
    this.currentDays = 0,
    this.status = EggStatus.egg,
    List<Map<String, dynamic>>? authImages,
  }) : authImages = authImages ?? [];

  double get progress => totalDays == 0 ? 0 : currentDays / totalDays;

  // 2. if 문에 중괄호 {}를 추가하여 권장 코딩 스타일 적용 및 에러 해결
  void updateStatus() {
    if (progress >= 1.0) {
      status = EggStatus.chicken;
    } else if (progress >= 0.5) {
      status = EggStatus.chick;
    } else {
      status = EggStatus.egg;
    }
  }
}
