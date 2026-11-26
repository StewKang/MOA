# MOA 앱 - travel_plan 모듈 개발 진행 현황 리포트

> **문서 목적**: AI(Gemini) 모델 및 개발진이 `features/travel_plan` 모듈의 구조, 데이터 모델, DB 스키마, UI/UX 인터랙션, 현재 진행 상황 및 미구현 과제를 명확히 파악할 수 있도록 정리한 기술 사양서입니다.

---

## 1. Directory Tree (디렉토리 구조)

```
lib/
 ┣ core/
 ┃ ┣ routing/
 ┃ ┃ ┗ app_router.dart                     # GoRouter 라우트 (/travel-plan/create, /travel-plan/edit)
 ┃ ┗ theme/
 ┃   ┣ app_colors.dart                     # 파스텔 초록 메인 전역 테마 색상 정의
 ┃   ┗ app_theme.dart                      # Material 3 Light/Dark 테마 정의
 ┗ features/
   ┗ travel_plan/
     ┣ data/
     ┃ ┣ models/
     ┃ ┃ ┣ travel_plan_model.dart          # 전체 여행 계획 메타데이터 모델 (travelId, title, startDate, endDate 등)
     ┃ ┃ ┗ schedule_item_model.dart        # 개별 일정 타임 블록 모델 (id, travelId, date, slotIndex, category, origin, destination 등)
     ┃ ┗ repositories/
     ┃   ┗ travel_plan_repository.dart     # 추상 Repository 인터페이스 + LocalTravelPlanRepository (샘플 데이터 포함)
     ┗ presentation/
       ┣ providers/
       ┃ ┗ travel_plan_provider.dart       # Riverpod StateNotifier (CRUD, 3개 겹침 검증, Side-by-side 2D 열 분할, 과거 일정 복제)
       ┣ screens/
       ┃ ┣ travel_plan_create_screen.dart   # 새 여행계획 만들기 화면 (제목, 날짜 범위 선택, 과거 일정 불러오기 바텀시트)
       ┃ ┗ travel_plan_edit_screen.dart     # 메인 2D 타임테이블 편집 화면 (상단 앱바, 2D 그리드, 하단 플로팅 팔레트)
       ┗ widgets/
         ┣ timetable_grid_view.dart        # Y축(30분 단위 48슬롯 고정 시간축) × X축(날짜축) 2차원 그리드 표 위젯
         ┣ schedule_item_card.dart         # 타임테이블 위 일정 카드 (우측 3줄 그립 드래그 핸들, Side-by-side 분할 너비 반영)
         ┣ floating_palette_bar.dart       # 화면 하단 반투명 플로팅 팔레트 (BackdropFilter, 일정/이동/식사/직접추가 드래그 Clone)
         ┣ past_plan_import_sheet.dart     # 과거 완료/즐겨찾기 일정 복사용 모달 바텀시트
         ┗ schedule_detail_dialog.dart     # 일정 상세 정보 편집/추가 다이얼로그 (일반/이동 카테고리별 동적 폼 전환)
```

---

## 2. DB Schema & Entity Specifications (데이터베이스 스키마)

### Table 1: `travel_plans` (전체 여행 계획 메타데이터)

| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `travel_id` | VARCHAR(64) | PRIMARY KEY | 여행 계획 고유 식별자 (예: `plan_17123456789`) |
| `title` | VARCHAR(255) | NOT NULL | 여행 제목 (예: `2025 제주도 힐링 우정 여행`) |
| `start_date` | DATETIME / DATE | NOT NULL | 여행 시작일 (ISO8601 문자열) |
| `end_date` | DATETIME / DATE | NOT NULL | 여행 종료일 (ISO8601 문자열) |
| `destination` | VARCHAR(255) | NULLABLE | 여행 목적지 (예: `제주특별자치도`, `부산`) |
| `is_favorite` | BOOLEAN | DEFAULT FALSE | 즐겨찾기 등록 여부 |
| `is_completed` | BOOLEAN | DEFAULT FALSE | 과거 일정 완료 및 보관 여부 |

### Table 2: `schedule_items` (개별 일정 타임 블록)

| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `id` | VARCHAR(64) | PRIMARY KEY | 일정 블록 고유 식별자 (예: `item_17123456789_0`) |
| `travel_id` | VARCHAR(64) | FOREIGN KEY | 소속 `travel_plans.travel_id` 참조 |
| `date` | DATETIME / DATE | NOT NULL | 해당 일정이 속한 날짜 |
| `start_slot_index` | INT | NOT NULL | 시작 시간 슬롯 인덱스 (`0` = 00:00, `1` = 00:30, ..., `47` = 23:30) |
| `duration_slots` | INT | NOT NULL | 소요 시간 슬롯 개수 (`1`슬롯 = 30분, 예: `2` = 1시간) |
| `category` | VARCHAR(32) | NOT NULL | 카테고리 (`activity`, `transport`, `meal`, `custom`) |
| `title` | VARCHAR(255) | NOT NULL | 일정 제목 |
| `location` | TEXT | NULLABLE | 일반 카테고리용 장소/위치 또는 조합된 위치 요약 텍스트 |
| `memo` | TEXT | NULLABLE | 메모 및 참고사항 |
| `origin` | VARCHAR(255) | NULLABLE | **이동 카테고리 전용**: 출발지 (예: `서울역`, `인천공항`) |
| `destination` | VARCHAR(255) | NULLABLE | **이동 카테고리 전용**: 목적지 (예: `부산역`, `숙소`) |
| `transport_mode` | VARCHAR(64) | NULLABLE | **이동 카테고리 전용**: 이동 수단 (`지하철`, `버스`, `KTX/기차`, `자가용/렌터카`, `택시`, `비행기`, `도보`, `기타`) |

---

## 3. Core Technical Specifications (기술 사양 및 로직)

1. **상태 관리 (`travel_plan_provider.dart`)**
   - `StateNotifier<TravelPlanState>` 구조.
   - **동시간대 3개 겹침 제한 검증 (`_canPlaceItem`)**: 동일 날짜·동일 시간 슬롯 구간에 4번째 일정을 드래그 또는 배치하려고 할 경우 배치를 거부(`false` 반환)하고 하단 `SnackBar`로 경고 알림 표시.
   - **Side-by-side 2D 레이아웃 계산 (`getItemLayoutPositions`)**: 동시간대 겹치는 일정 카드들의 `columnIndex` (0, 1, 2) 및 `totalColumns`를 계산하여 카드 너비를 균등 분할하고 나란히 표시.
   - **과거 일정 복제 (`importPastPlan`)**: 과거 일정 아이템의 상대적 날짜 간격(Day offset)을 신규 시작일에 매핑하여 타임 블록 전체를 복사 생성.

2. **UI & Interaction Components**
   - **`TimetableGridView`**: 세로축(좌측 고정 30분 단위 48슬롯 시간축) × 가로축(날짜축 스크롤) 2차원 표. `LayoutBuilder` 기반 반응형으로 세로/가로 모드 지원. `DragTarget`으로 신규/이동 드롭 받음.
   - **`ScheduleItemCard`**: 카테고리별 테마 색상 적용. 카드 본문 탭(상세 다이얼로그)과 우측 3줄 그립 핸들(`Icons.drag_handle_rounded`) 전용 `Draggable` 분리.
   - **`FloatingPaletteBar`**: `BackdropFilter` 적용 하단 반투명 플로팅 바. 일정/이동/식사/직접추가 아이콘을 드래그하여 타임테이블 표 위 슬롯에 Clone 배치.
   - **`ScheduleDetailDialog`**: 카테고리가 '이동'일 경우 출발지, 목적지, 이동수단 드롭다운 선택 폼으로 동적 전환.

---

## 4. Current Status & Remaining Tasks (개발 현황 및 미구현 과제)

### ✅ 구현 완료된 항목 (Completed)
- `features/travel_plan` 내 11개 전체 모듈 구현 및 정적 분석 0 에러 검증.
- 2D 그리드 타임테이블, 3개 겹침 제약, Side-by-side 열 분할, 플로팅 팔레트 드래그 & 드롭.
- 이동 카테고리 전용 (출발지, 목적지, 이동수단) 폼 및 디스플레이 처리.
- 과거 완료/즐겨찾기 일정 불러오기 및 날짜 매핑 복사.

### 🟡 미구현 및 추가 작업 필요 항목 (To-Do)
1. **`HomeScreen` 목록 연동**: 생성된 여행 계획을 홈 화면 '내 여행 일정' 섹션에 동적으로 표시하도록 `HomeScreen`과 Riverpod Provider 연동.
2. **로컬 영구 저장소 (Persistence) 연동**: 현재 `LocalTravelPlanRepository`가 인메모리(`Map`)로 구성되어 있어 앱 재시작 시 초기화됨. SQLite (`sqflite`) 또는 `shared_preferences` / `hive` 연동 필요.
3. **중간 집결지 추천 및 백엔드 WebSocket 연동**: 기획서 상의 중간 집결지 추천 알고리즘 및 실시간 공동 편집 통신 연동.
