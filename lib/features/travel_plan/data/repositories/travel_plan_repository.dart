import '../models/schedule_item_model.dart';
import '../models/travel_plan_model.dart';

/// 여행 계획 및 일정 아이템 저장을 위한 추상 Repository 인터페이스
abstract class TravelPlanRepository {
  /// 저장된 전체 여행 계획 목록 조회
  Future<List<TravelPlanModel>> getAllTravelPlans();

  /// 과거 완료되거나 즐겨찾기된 과거 일정 리스트 조회
  Future<List<TravelPlanModel>> getPastTravelPlans();

  /// 특정 여행 계획 단건 조회
  Future<TravelPlanModel?> getTravelPlanById(String travelId);

  /// 여행 계획 메타데이터 저장/수정
  Future<void> saveTravelPlan(TravelPlanModel plan);

  /// 특정 여행 계획의 일정 목록 조회
  Future<List<ScheduleItemModel>> getScheduleItems(String travelId);

  /// 특정 여행 계획의 일정 목록 저장
  Future<void> saveScheduleItems(String travelId, List<ScheduleItemModel> items);

  /// 여행 계획 및 일정 삭제
  Future<void> deleteTravelPlan(String travelId);
}

/// 인메모리 폴백 구현체 (Flutter Web 등 SQLite 미지원 환경용)
class LocalTravelPlanRepository implements TravelPlanRepository {
  final Map<String, TravelPlanModel> _plansMap = {};
  final Map<String, List<ScheduleItemModel>> _itemsMap = {};

  LocalTravelPlanRepository() {
    _initSamplePastData();
  }

  /// 샘플 과거 여행 데이터 초기화
  void _initSamplePastData() {
    final now = DateTime.now();

    // 1. 샘플 과거 일정 1: 부산 식도락 여행
    const plan1Id = 'past_plan_busan_01';
    final plan1Start = now.subtract(const Duration(days: 30));
    final plan1End = plan1Start.add(const Duration(days: 2));

    _plansMap[plan1Id] = TravelPlanModel(
      travelId: plan1Id,
      title: '부산 맛집 탐방 식도락 여행',
      startDate: plan1Start,
      endDate: plan1End,
      isFavorite: true,
      isCompleted: true,
      destination: '부산광역시',
    );

    _itemsMap[plan1Id] = [
      ScheduleItemModel(
        id: 'item_b1',
        travelId: plan1Id,
        date: plan1Start,
        startSlotIndex: 18, // 09:00
        durationSlots: 2, // 1시간
        category: 'transport',
        title: 'KTX 부산역 이동',
        location: '서울역 ➔ 부산역 (KTX/기차)',
        memo: '짐 보관소에 가방 맡기기',
        origin: '서울역',
        destination: '부산역',
        transportMode: 'KTX/기차',
      ),
      ScheduleItemModel(
        id: 'item_b2',
        travelId: plan1Id,
        date: plan1Start,
        startSlotIndex: 24, // 12:00
        durationSlots: 3, // 1시간 30분
        category: 'meal',
        title: '초량밀면 점심 식사',
        location: '부산 동구 중앙대로 225',
        memo: '물밀면 + 만두 조합 강추',
      ),
      ScheduleItemModel(
        id: 'item_b3',
        travelId: plan1Id,
        date: plan1Start,
        startSlotIndex: 28, // 14:00
        durationSlots: 4, // 2시간
        category: 'activity',
        title: '해운대 해변 산책 및 미포철길',
        location: '해운대구',
        memo: '스카이캡슐 탑승 예약 확인',
      ),
    ];

    // 2. 샘플 과거 일정 2: 제주 힐링 여행
    const plan2Id = 'past_plan_jeju_02';
    final plan2Start = now.subtract(const Duration(days: 60));
    final plan2End = plan2Start.add(const Duration(days: 3));

    _plansMap[plan2Id] = TravelPlanModel(
      travelId: plan2Id,
      title: '제주 자연 속 힐링 3박 4일',
      startDate: plan2Start,
      endDate: plan2End,
      isFavorite: true,
      isCompleted: true,
      destination: '제주특별자치도',
    );

    _itemsMap[plan2Id] = [
      ScheduleItemModel(
        id: 'item_j1',
        travelId: plan2Id,
        date: plan2Start,
        startSlotIndex: 20, // 10:00
        durationSlots: 3,
        category: 'transport',
        title: '제주 공항 도착 & 렌터카 인수',
        location: '제주공항 (비행기)',
        memo: '차량 외관 사진 촬영 필수',
        origin: '김포공항',
        destination: '제주공항',
        transportMode: '비행기',
      ),
    ];
  }

  @override
  Future<List<TravelPlanModel>> getAllTravelPlans() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final list = _plansMap.values.toList();
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  @override
  Future<List<TravelPlanModel>> getPastTravelPlans() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _plansMap.values.where((p) => p.isCompleted || p.isFavorite).toList();
  }

  @override
  Future<TravelPlanModel?> getTravelPlanById(String travelId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _plansMap[travelId];
  }

  @override
  Future<void> saveTravelPlan(TravelPlanModel plan) async {
    _plansMap[plan.travelId] = plan;
  }

  @override
  Future<List<ScheduleItemModel>> getScheduleItems(String travelId) async {
    return _itemsMap[travelId] ?? [];
  }

  @override
  Future<void> saveScheduleItems(String travelId, List<ScheduleItemModel> items) async {
    _itemsMap[travelId] = List.from(items);
  }

  @override
  Future<void> deleteTravelPlan(String travelId) async {
    _plansMap.remove(travelId);
    _itemsMap.remove(travelId);
  }
}
