# 🐓 EGGO - 농꾸하고 작심삼일 타파하자!

> **"습관이 나(Ego)를 만든다!"**   
> 매일 습관을 인증하고 닭과 꽃을 얻어 나만의 농장을 가꾸는 습관 형성 앱, eggo입니다.

## 📖 프로젝트 소개
### **[EGGO]** 는 단순한 투두 리스트가 아닙니다.  
사용자가 설정한 습관을 '알'이나 '씨앗'으로 형상화하고, 정성껏 돌보며 키워내는  
**게이미피케이션(Gamification)** 요소가 가미된 '습관 형성 도우미 앱' 입니다. 

### 목표를 키우며 '농장 꾸미기(농꾸)'의 즐거움을 느껴보세요.

## 💡 기획 의도
- **Habit makes Ego** (습관이 나를 만든다): '작은 습관들이 모여 단단한 자아 **(Ego)** 를 형성한다'는 철학을 바탕으로, 사용자가 매일 '나'를 성장시키는 기쁨을 느끼도록 설계했습니다.
- **게이미피케이션(Gamification)을 통한 동기부여**: 작심삼일의 원인인 '지루함'을 해결하기 위해 수집형 게임 요소를 도입했습니다. 캐릭터의 진화 과정을 통해 단순한 기록 이상의 재미를 제공합니다.
- **AI를 이용한 가짜 인증 방지**: 가짜 인증을 방지하기 위해 AI 검열 시스템을 도입했습니다. Gemini API가 실천 여부를 객관적으로 검증하여 사용자가 정직하게 자신을 가꾸어 나갈 수 있도록 돕습니다.

---

## ✨ 핵심 기능 (Key Features)

### 1. 🤖 AI 기반 스마트 사진 검열 (Habit Guard)
|           AI 분석중           |           인증 성공            |       인증 보류 (사용자 설명)       | 
|:--------------------------:|:--------------------------:|:--------------------------:|
| <img src="" width="200" /> | <img src="" width="200" /> | <img src="" width="200" />

* **객관적 실천 검증:** Google ML Kit으로 이미지 라벨을 추출하고 Gemini API가 이를 분석하여 목표와의 연관성을 판단합니다.
* **엄격한 가이드라인:** 다이어트 중 고칼로리 음식 사진을 올리는 등 목표와 상충하는 행위는 AI가 감지하여 거절함으로써 진정한 습관 형성을 유도합니다.

### 2. 📈 단계별 시각적 성장 시스템
|     1단계: 시작 (Egg/Seed)     |   2단계: 성장 (Chick/Sprout)   |  3단계: 완성 (Chicken/Flower)  |  4단계: 실패 (Fried/Fallen)  |
|:--------------------------:|:--------------------------:|:--------------------------:|:--------------------------:|
| <img src="" width="200" /> | <img src="" width="200" /> | <img src="" width="200" /> | <img src="" width="200" /> |

* **진화 로직:** 달성률(온도)에 따라 캐릭터가 진화하며 '나'의 성장을 시각화합니다.
  * **0% ~ 49%:** 알(🥚) 또는 씨앗(🥜) 상태
  * **50% ~ 99%:** 병아리(🐣) 또는 새싹(🌱) 상태
  * **100%:** 닭(🐓) 또는 꽃(🌹) 수확
  * **실패:** 기한 만료 시 계란후라이(🍳) 또는 시든 꽃(🥀)으로 변화

### 3. 📅 스마트 캘린더 연동 및 유연한 관리
|         일정 자동 등록         |        빈도 설정        |      1일 1회 제한       |        
|:--------------------------:|:--------------------------:|:----------------------------:|
| <img src="" width="200" /> | <img src="" width="200" /> |  <img src="" width="200" />  |

* **일정 자동 등록:** 목표 도전 기간을 시스템 캘린더(Google, Galaxy 등)에 즉시 등록하여 잊지 않고 관리할 수 있습니다.
* **빈도 설정 및 1일 1회 제한:** 매일, 격일 등 주기를 설정할 수 있으며, 목표 당 하루 한 번만 인증 및 온도 상승이 가능하도록 제한하여 편법 없는 성장을 지향합니다.

### 4. 🌿 이번 달 잔디 심기 (Ego Timeline)
|         월간 히트맵(잔디)         |        날짜별 기록 상세 보기        |        
|:--------------------------:|:--------------------------:|
| <img src="" width="200" /> | <img src="" width="200" /> |

* **성실함의 시각화:** 한 달간의 여정을 히트맵 잔디로 확인합니다. 인증 횟수가 많을수록 잔디의 색이 짙어집니다.
* **과거 회상:** 특정 날짜를 터치하면 당시의 인증 사진과 메모를 확인할 수 있습니다.

### 5. 🎭 듀얼 테마 & 프로필 관리
|      농장 테마 (Classic)       |       모던 테마 (Modern)       |        
|:--------------------------:|:--------------------------:|
| <img src="" width="200" /> | <img src="" width="200" /> |

* **분위기 전환:** 정겨운 '농장 테마'와 세련된 '모던 테마'를 실시간으로 전환하며 즐길 수 있습니다.
* **농부 프로필:** 이름, 사진, 한줄 소개를 변경하여 나만의 농부 아이덴티티를 표현합니다.
---

## 🛠 기술 스택 (Tech Stack)

### Environment
![Android Studio](https://img.shields.io/badge/Android%20Studio-3DDC84?style=for-the-badge&logo=androidstudio&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=Git&logoColor=white)
![Github](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=GitHub&logoColor=white)

### Development
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=Dart&logoColor=white)


### API
![ML Kit](https://img.shields.io/badge/ML_Kit-4285F4?style=for-the-badge&logo=google&logoColor=white)
![Gemini](https://img.shields.io/badge/Gemini_Flash_2.5-8E75B2?style=for-the-badge&logo=googlegemini&logoColor=white)

---

## 🧑‍💻 팀원 소개 (Team)

|   이름    | 역할 | 담당 기능                                                     |              GitHub              |
|:-------:| :---: |:----------------------------------------------------------|:--------------------------------:|
| **배서연** | 기획, 디자인, FE | UI 기본 틀 구현, version1 UI 구현, 메인 로직들 구현            | [@alicebsy](https://github.com/) |
| **박찬우** | 기획, 디자인, FE | version2 UI 구현, ml kit + gemini 2.5 flash api 활용 |  [@onff02](https://github.com/)  |—

## 📂 폴더 구조 (Directory Structure)

```text
floweggo/
├── assets/
│   └── images/              # 앱에 사용되는 이미지 리소스 (이모지, 배경 등)
├── lib/
│   ├── database/
│   │   └── db_helper.dart   # 로컬 데이터 저장소 (DB) 및 데이터 처리 로직
│   ├── models/
│   │   └── goal_model.dart  # 습관(Goal) 데이터 모델 및 상태(Status) 로직
│   ├── screens/
│   │   ├── v1/              # 농장 컨셉의 화면 구성
│   │       ├── farm_screen_v1.dart        # 완료된 목표들이 모이는 농장 화면
│   │       ├── gallery_screen_v1.dart     # 인증 사진들을 모아보는 갤러리
│   │       ├── home_screen_v1.dart        # 목표 리스트 및 메인 대시보드
│   │       └── image_check_screen_v1.dart # 사진 인증 확인 화면
│   │   ├── v2/              # 모던 컨셉의 화면 구성
│   │       ├── farm_screen_v2.dart        # 완료된 목표들이 모이는 농장 화면
│   │       ├── gallery_screen_v2.dart     # 인증 사진들을 모아보는 갤러리
│   │       ├── home_screen_v2.dart        # 목표 리스트 및 메인 대시보드
│   │       └── image_check_screen_v2.dart # 사진 인증 확인 화면
│   │   └── photo_detail_screen.dart # 공통 사진 상세 보기 화면
│   ├── widgets/
│   │   └── goal_card.dart   # 공통 위젯 관리
│   └── main.dart            # 앱 진입점 (Entry Point), 테마 전환 내비게이션
├── pubspec.yaml             # 패키지 의존성 및 에셋 설정
└── README.md                # 프로젝트 설명서