# MOA 앱 - travel_plan 모듈 아키텍처 및 기술 사양서

> **문서 목적**: AI(Gemini) 모델이 `features/travel_plan` 모듈의 모듈화 상태, DB 스키마, 데이터 조회/저장 방식(Repository Pattern), 그리고 UI/UX 컴포넌트 구조를 완벽히 파악할 수 있도록 구조화한 기술 명세서입니다.

---

## 1. 아키텍처 및 모듈화 상태 (Modularization & Repository Pattern)

현재 `travel_plan` 모듈은 **관심사 분리(Separation of Concerns)**와 **오프라인 우선(Offline-first)** 원칙에 따라 철저하게 모듈화되어 있습니다.

```
[ UI Layer ]
  ├── HomeScreen / TravelPlanCreateScreen / TravelPlanEditScreen / ProfileScreen
       │ (watches)
       ▼
[ State Management Layer ]
  ├── TravelPlanNotifier (Riverpod StateNotifier)
       │ (calls interface)
       ▼
[ Data Access / Repository Layer ]
  ├── TravelPlanRepository (Abstract Interface)
       ├── SqliteTravelPlanRepository (Concrete SQLite Implementation)
       └── LocalTravelPlanRepository (In-memory Fallback for Web)
            │ (executes queries on)
            ▼
[ Persistence Layer ]
  ├── AppDatabase (SQLite Singleton, DDL, Seed Data, Foreign Key Constraints)
  └── sqflite / path
```

* **추상화 계층**: UI와 비즈니스 로직(Notifier)은 구체적인 DB 기술을 알지 못하며, 오직 `TravelPlanRepository` 인터페이스에만 의존합니다.
* **멀티플랫폼 안전성**: 플랫폼이 SQLite를 지원하는 Android/iOS에서는 `SqliteTravelPlanRepository`가 작동하고, Web 환경에서는 런타임 에러 없이 `LocalTravelPlanRepository`(인메모리 폴백)로 자동 전환됩니다.

---

## 2. 데이터베이스 스키마 (Database Schema)

`AppDatabase` (`lib/core/database/app_database.dart`)에 의해 관리되며, 외래키 제약조건(`PRAGMA foreign_keys = ON;`) 및 `CASCADE` 삭제가 적용되어 있습니다.

### ① `travel_plans` (여행 계획 메타데이터)
| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `travel_id` | TEXT | PRIMARY KEY | 여행 고유 식별자 (`plan_17123456789`) |
| `title` | VARCHAR(255) | NOT NULL | 여행 제목 |
| `start_date` | TEXT (ISO8601) | NOT NULL | 여행 시작일 |
| `end_date` | TEXT (ISO8601) | NOT NULL | 여행 종료일 |
| `destination` | TEXT | NULLABLE | 목적지 (예: 제주특별자치도) |
| `is_favorite` | INTEGER (0/1) | DEFAULT 0 | 즐겨찾기 여부 |
| `is_completed` | INTEGER (0/1) | DEFAULT 0 | 완료 및 보관 여부 |

### ② `schedule_items` (타임테이블 개별 일정 블록)
| Column Name | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | 일정 블록 고유 식별자 (`item_...`) |
| `travel_id` | TEXT | FOREIGN KEY | `travel_plans.travel_id` 참조 (`ON DELETE CASCADE`) |
| `date` | TEXT (ISO8601) | NOT NULL | 일정이 속한 날짜 |
| `start_slot_index` | INTEGER | NOT NULL | 시작 시간 슬롯 (`0` = 00:00 ~ `47` = 23:30, 30분 단위) |
| `duration_slots` | INTEGER | NOT NULL | 소요 시간 슬롯 개수 (1슬롯 = 30분) |
| `category` | TEXT | NOT NULL | 카테고리 (`activity`, `transport`, `meal`, `custom`) |
| `title` | TEXT | NOT NULL | 일정 제목 |
| `location` | TEXT | NULLABLE | 장소/위치 또는 요약 텍스트 |
| `memo` | TEXT | NULLABLE | 메모 및 참고사항 |
| `origin` | TEXT | NULLABLE | **이동 전용**: 출발지 |
| `destination` | TEXT | NULLABLE | **이동 전용**: 목적지 |
| `transport_mode` | TEXT | NULLABLE | **이동 수단**: 지하철, 버스, KTX, 자가용, 도보 등 |

---

## 3. 데이터 조회 및 저장 방식 (Query & Transaction Approach)

`SqliteTravelPlanRepository`는 `sqflite`를 사용하여 오프라인 우선으로 동작하며, 원자성(Atomicity)을 보장하기 위해 **DB 트랜잭션(Transaction)**을 활용합니다.

1. **전체 일정 조회 (`getAllTravelPlans`)**:
   - `SELECT * FROM travel_plans ORDER BY start_date DESC;` 쿼리로 모든 여행 계획을 최신순 조회.
2. **과거/즐겨찾기 일정 조회 (`getPastTravelPlans`)**:
   - `SELECT * FROM travel_plans WHERE is_completed = 1 OR is_favorite = 1 ORDER BY start_date DESC;` 쿼리로 아카이브용 일정 조회.
3. **일정 목록 일괄 저장 (Transaction)**:
   - `db.transaction((txn) async { ... })` 내부에서 기존 `schedule_items`를 `DELETE`한 뒤, 새로운 일정 아이템들을 `INSERT`하여 불일치를 방지.
4. **여행 계획 완전 삭제 (Cascade / Transaction)**:
   - 상위 여행 계획(`travel_plans`) 삭제 시 외래키 `ON DELETE CASCADE` 제약에 따라 하위 `schedule_items`가 원자적으로 함께 삭제됨.
5. **동시성 락킹 (`AppDatabase`)**:
   - `_initFuture ??= _initDatabase();` 패턴을 적용하여 앱 구동 시 다수의 비동기 쿼리가 동시에 DB를 열려고 할 때 발생하는 락 충돌을 원천 차단.

---

## 4. UI/UX 구성 및 컴포넌트 구조

* **`HomeScreen` (`lib/features/home/presentation/screens/home_screen.dart`)**:
  - 홈 화면에서 `travelPlanProvider`를 실시간 구독하여 저장된 전체 여행 계획 목록(`allPlans`)을 렌더링.
* **`MyTravelPlanSection` & `TravelPlanCard`**:
  - 여행 목록을 카드 형태로 표시하며, 즐겨찾기 토글, 완료 상태 전환, 삭제(확인 다이얼로그) 기능 제공.
* **`TravelPlanCreateScreen` (`/travel-plan/create`)**:
  - 새 여행 계획 제목, 목적지, 날짜 범위 선택.
  - **기존 일정 불러오기 (Import Sheet)**: 저장된 전체 여행 계획(`allPlans`)을 모달 바텀시트로 띄워 진행 중, 예정, 완료된 일정을 새 여행의 템플릿으로 즉시 복사 가능.
* **`TravelPlanEditScreen` (`/travel-plan/edit?travelId=...`)**:
  - **`TimetableGridView`**: 세로축(좌측 고정 30분 단위 48슬롯 시간축) × 가로축(날짜별 열, 가로 스크롤) 2차원 표. 반응형 `LayoutBuilder` 적용.
  - **동시간대 3개 겹침 제한 및 Side-by-side 분할**: 겹치는 일정들의 열 인덱스를 동적으로 계산하여 나란히 배치하고, 4개 이상 겹치면 드래그 배치를 거부하고 `SnackBar` 알림.
  - **`FloatingPaletteBar`**: 하단 반투명(`BackdropFilter`) 팔레트바. 카테고리 아이콘을 드래그하여 타임테이블 슬롯에 클론 투하.
  - **`ScheduleDetailDialog`**: 카테고리가 '이동'일 경우 장소 입력 폼 대신 **[출발지]**, **[목적지]**, **[이동수단 선택]** 폼으로 동적 전환.
* **`ProfileScreen` (`lib/features/profile/presentation/profile_screen.dart`)**:
  - SQLite 통계를 연동하여 완료된 여행 수, 전체 일정 수, 즐겨찾기 수를 표시하고 하단에 완료된 여행 아카이브 리스트 제공.
