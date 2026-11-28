import 'package:moa/features/travel_plan/data/models/schedule_item_model.dart';
import 'package:moa/features/travel_plan/data/models/travel_plan_model.dart';
import 'package:moa/features/travel_plan/data/repositories/firebase_travel_plan_repository.dart';
import 'package:moa/features/travel_plan/data/repositories/sqlite_travel_plan_repository.dart';
import 'package:moa/features/travel_plan/data/repositories/travel_plan_repository.dart';

/// SQLite (로컬 캐시)와 Firebase Firestore (원격) 간의 하이브리드 동기화 Repository
class SyncTravelPlanRepository implements TravelPlanRepository {
  final SqliteTravelPlanRepository localRepository;
  final FirebaseTravelPlanRepository remoteRepository;

  SyncTravelPlanRepository({
    required this.localRepository,
    required this.remoteRepository,
  });

  /// 모든 여행 계획 조회 (로컬 캐시 먼저 즉시 반환, 비동기 원격 Sync 진행)
  @override
  Future<List<TravelPlanModel>> getAllTravelPlans() async {
    // 1. SQLite 로컬 데이터 즉시 로드
    final localPlans = await localRepository.getAllTravelPlans();

    // 2. 비동기로 Firebase 원격 데이터 수집 및 로컬 동기화 (백그라운드)
    _syncWithRemoteInBackground();

    return localPlans;
  }

  @override
  Future<List<TravelPlanModel>> getPastTravelPlans() async {
    return await localRepository.getPastTravelPlans();
  }

  @override
  Future<TravelPlanModel?> getTravelPlanById(String travelId) async {
    final localPlan = await localRepository.getTravelPlanById(travelId);
    if (localPlan != null) return localPlan;

    // 로컬에 없을 경우 Firebase에서 가져와 로컬 캐싱
    final remotePlan = await remoteRepository.getTravelPlanById(travelId);
    if (remotePlan != null) {
      await localRepository.saveTravelPlan(remotePlan);
    }
    return remotePlan;
  }

  /// 여행 계획 저장 (SQLite 로컬 선저장 + Firebase 원격 업로드)
  @override
  Future<void> saveTravelPlan(TravelPlanModel plan) async {
    final updatedPlan = plan.copyWith(updatedAt: DateTime.now());

    // 1. 로컬 SQLite 즉시 저장
    await localRepository.saveTravelPlan(updatedPlan);

    // 2. Firebase 원격 업로드 (네트워크 예외 시 로컬 데이터만 보존)
    try {
      await remoteRepository.saveTravelPlan(updatedPlan);
    } catch (_) {
      // 오프라인 상태 시 원격 저장 실패를 묵인하고 로컬 캐시 사용 유지
    }
  }

  @override
  Future<List<ScheduleItemModel>> getScheduleItems(String travelId) async {
    final localItems = await localRepository.getScheduleItems(travelId);
    if (localItems.isNotEmpty) return localItems;

    // 로컬 일정 없으면 Firebase 조회 후 로컬 저장
    final remoteItems = await remoteRepository.getScheduleItems(travelId);
    if (remoteItems.isNotEmpty) {
      await localRepository.saveScheduleItems(travelId, remoteItems);
    }
    return remoteItems;
  }

  @override
  Future<void> saveScheduleItems(
      String travelId, List<ScheduleItemModel> items) async {
    // 1. 로컬 저장
    await localRepository.saveScheduleItems(travelId, items);

    // 2. 원격 업로드
    try {
      await remoteRepository.saveScheduleItems(travelId, items);
    } catch (_) {}
  }

  @override
  Future<void> deleteTravelPlan(String travelId) async {
    await localRepository.deleteTravelPlan(travelId);
    try {
      await remoteRepository.deleteTravelPlan(travelId);
    } catch (_) {}
  }

  /// 백그라운드 원격 <-> 로컬 데이터 동기화
  Future<void> _syncWithRemoteInBackground() async {
    try {
      final remotePlans = await remoteRepository.getAllTravelPlans();
      for (final plan in remotePlans) {
        await localRepository.saveTravelPlan(plan);
      }
    } catch (_) {}
  }
}
