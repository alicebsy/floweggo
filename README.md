# 🐓 EGGO - 나만의 목표 농장

> "당신의 꾸준함이 알을 깨웁니다! 목표를 달성하고 나만의 닭을 키워보세요."

## 📖 프로젝트 소개
[EGGO]는 단순한 투두 리스트가 아닙니다.  
사용자가 설정한 목표를 매일 달성할 때마다 온도가 올라가고, 알에서 병아리, 그리고 닭으로 성장하는 **게이미피케이션 목표 관리 앱**입니다.


### 💡 기획 의도
- 딱딱한 목표 관리에 '성장'의 즐거움을 더했습니다.
- 목표한 빈도수와 날짜에 소홀하면 계란후라이가 되어버리는 긴장감을 줍니다!
- 완성된 닭은 '나의 농장'으로 이동하여 성취감을 기록합니다.
- '성장 기록'에서 그동안 인증한 사진을 볼 수 있으며, 이번달에 얼만큼 자주 인증을 했는지 캘린더 형식으로 한 눈에 볼 수 있습니다. 

---

## 📸 주요 기능 & 스크린샷

| 메인 화면 (알) | 성장 과정 (병아리) | 목표 달성 (닭) | 실패 (후라이) |
| :---: | :---: | :---: | :---: |
| <img src="" width="200" /> | <img src="" width="200" /> | <img src="" width="200" /> | <img src="" width="200" /> |
| 목표 등록 및 <br> 알 상태 확인 | 온도가 오르며 <br> 병아리로 부화 | 100도 달성! <br> 닭으로 성장 | 기간 내 미달성 시 <br> 후라이로 변함 |

* **목표 설정:** 기간, 빈도, 이름을 설정하여 알을 생성합니다.
* **인증하기:** 매일 사진과 함께 목표를 인증하면 온도가 올라갑니다.
* **성장 시스템:** 알(0~49%) → 병아리(50~99%) → 닭(100%) 단계별 진화.
* **빈도수 설정:** 매일, 격일, 3일에 한 번 인증하도록 설정 가능합니다.
* **하루 제한:** 하루에 한 번만 인증 가능하며, 인증 후엔 버튼이 비활성화됩니다.

---

## 🛠 기술 스택 (Tech Stack)

### Environment
![Visual Studio Code](https://img.shields.io/badge/Visual%20Studio%20Code-007ACC?style=for-the-badge&logo=Visual%20Studio%20Code&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=Git&logoColor=white)
![Github](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=GitHub&logoColor=white)

### Development
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=Dart&logoColor=white)

---

## 🧑‍💻 팀원 소개 (Team)

|   이름    | 역할 | 담당 기능                                     |              GitHub              |
|:-------:| :---: |:------------------------------------------|:--------------------------------:|
| **배서연** | FE | 기획, 디자인, version1 UI 구현, 메인 로직(성장 시스템) 구현 | [@alicebsy](https://github.com/) |
| **박찬우** | FE | 기획, 디자인, version2 UI 구현, 화면 전환 구현         |  [@onff02](https://github.com/)  |---

## 📂 폴더 구조 (Directory Structure)

```text
floweggo/
├── assets/
│   └── images/              # 앱에 사용되는 이미지 리소스 (이모지, 배경 등)
├── lib/
│   ├── database/
│   │   └── db_helper.dart   # 로컬 데이터 저장소 (DB) 및 데이터 처리 로직
│   ├── models/
│   │   └── goal_model.dart  # 목표(Goal) 데이터 모델 및 상태(Status) 로직
│   ├── screens/
│   │   ├── v1/              # 메인 컨셉의 화면 구성
│   │       ├── farm_screen_v1.dart        # 완료된 목표들이 모이는 농장 화면
│   │       ├── gallery_screen_v1.dart     # 인증 사진들을 모아보는 갤러리
│   │       ├── home_screen_v1.dart        # 목표 리스트 및 메인 대시보드
│   │       ├── image_check_screen_v1.dart # 사진 인증 확인 화면
│   │       └── photo_detail_screen.dart   # 사진 상세 보기
│   │   └── v2/              # 다른 컨셉의 화면 구성
│   │       ├── farm_screen_v2.dart        # 완료된 목표들이 모이는 농장 화면
│   │       ├── gallery_screen_v2.dart     # 인증 사진들을 모아보는 갤러리
│   │       ├── home_screen_v2.dart        # 목표 리스트 및 메인 대시보드
│   │       ├── image_check_screen_v2.dart # 사진 인증 확인 화면
│   │       └── photo_detail_screen.dart   # 사진 상세 보기
│   ├── widgets/
│   │   └── goal_card.dart   # 재사용 가능한 목표 카드 위젯
│   └── main.dart            # 앱 진입점 (Entry Point)
├── pubspec.yaml             # 패키지 의존성 및 자산 설정
└── README.md                # 프로젝트 설명서