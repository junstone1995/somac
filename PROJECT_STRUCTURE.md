# Somac (소맥) 프로젝트 구조

> AR 기반 소맥(소주+맥주) 황금비율 가이드 iOS 앱

## 디렉토리 구조

```
somac/
├── somac/
│   ├── somacApp.swift              # 앱 진입점 (@main)
│   ├── ContentView.swift           # 홈 화면 및 네비게이션 라우팅
│   ├── Info.plist                  # 앱 설정 파일
│   ├── Assets.xcassets             # 이미지/색상 에셋
│   │
│   ├── Core/                       # 핵심 비즈니스 로직
│   │   ├── GlassMeasurement.swift  # 잔(원뿔대) 부피/높이 계산 모델
│   │   └── SomacRecipe.swift       # 소맥 레시피 (소주 25ml + 맥주 50ml)
│   │
│   ├── Views/                      # UI 화면
│   │   ├── MeasureView.swift       # AR 잔 측정 화면 (ARKit + RealityKit)
│   │   └── GuideView.swift         # 소맥 가이드 화면 (채움 높이 시각화)
│   │
│   └── Localizable.strings/        # 다국어 지원
│       ├── ko                      # 한국어
│       └── en                      # 영어
│
├── Frameworks/                     # 외부 프레임워크
│   ├── ARKit.framework/            # AR 세션 및 공간 인식
│   └── RealityKit.framework/       # 3D 렌더링 및 AR 뷰
│
└── Products/
    └── somac.app                   # 빌드 결과물
```

## 파일별 상세 설명

### 앱 진입점

| 파일 | 설명 |
|------|------|
| `somacApp.swift` | `@main` 앱 진입점. `WindowGroup`으로 `ContentView`를 루트 뷰로 설정 |

### 화면 (Views)

| 파일 | 설명 |
|------|------|
| `ContentView.swift` | 홈 화면. 소맥 황금비율(소주 25ml : 맥주 50ml) 안내 및 "맥주잔 측정하기" 버튼 제공. `NavigationStack` + `AppRoute` enum으로 화면 전환 관리 |
| `MeasureView.swift` | AR 측정 화면. LiDAR를 활용해 맥주잔의 바닥/상단 테두리 중심과 가장자리를 탭하여 반지름과 높이를 측정. `ARViewContainer`(UIViewRepresentable) + `MeasureCoordinator`(ARSessionDelegate) 사용 |
| `GuideView.swift` | 소맥 가이드 화면. 측정된 잔 크기에 맞춰 소주(파란색)와 맥주(노란색) 채움 높이를 전체 화면에 시각화. 폰을 잔 옆에 세우면 실제 채움 높이와 1:1 매핑 |

### 핵심 로직 (Core)

| 파일 | 설명 |
|------|------|
| `GlassMeasurement.swift` | 원뿔대(frustum) 모델로 잔의 부피를 계산. 바닥 반지름(`r1`), 상단 반지름(`r2`), 높이(`height`)를 기반으로 특정 부피에 해당하는 채움 높이를 이진 탐색으로 산출 |
| `SomacRecipe.swift` | 소맥 레시피 정의. 소주 25ml(소주잔 반잔) + 맥주 50ml의 고정 비율. `GlassMeasurement`를 활용해 맥주 채움 높이/비율 계산 |

### 다국어 (Localization)

| 파일 | 설명 |
|------|------|
| `Localizable.strings/ko` | 한국어 문자열 리소스 |
| `Localizable.strings/en` | 영어 문자열 리소스 |

## 앱 플로우

```
홈 화면 (ContentView)
    │
    ├─ 소맥 황금비율 안내 (소주 25ml : 맥주 50ml)
    │
    └─ [맥주잔 측정하기] 버튼
            │
            ▼
    AR 측정 화면 (MeasureView)
            │
            ├─ Step 1: 바닥 테두리 중심 탭 → 가장자리 탭 (반지름 측정)
            ├─ Step 2: 상단 테두리 중심 탭 → 가장자리 탭 (반지름 측정)
            │
            └─ [가이드 보기] 버튼
                    │
                    ▼
            가이드 화면 (GuideView)
                    │
                    ├─ 소주 채움 높이 (파란색 영역 + ① 점선)
                    ├─ 맥주 채움 높이 (노란색 영역 + ② 점선)
                    └─ 하단 정보 바 (용량, 잔 높이 표시)
```

## 기술 스택

- **UI**: SwiftUI
- **AR**: ARKit + RealityKit (LiDAR 기반 공간 인식)
- **최소 요구사항**: LiDAR 센서 탑재 기기 (iPhone 12 Pro 이상)
- **지원 언어**: 한국어, 영어
- **아키텍처**: SwiftUI NavigationStack 기반 단방향 네비게이션
