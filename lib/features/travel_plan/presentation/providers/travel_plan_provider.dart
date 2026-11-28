import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moa/core/database/app_database.dart';
import 'package:moa/features/travel_plan/data/models/schedule_item_model.dart';
import 'package:moa/features/travel_plan/data/models/travel_plan_model.dart';
import 'package:moa/features/travel_plan/data/repositories/sqlite_travel_plan_repository.dart';
import 'package:moa/features/travel_plan/data/repositories/travel_plan_repository.dart';

/// 일정 카드의 2D 타임테이블 레이아웃 계산 정보
class ItemLayoutInfo {
  final int columnIndex; // 0, 1, 2 중 하나
  final int totalColumns; // 해당 위치에서 겹치는 최대 열 개수 (1, 2, 3)

  const ItemLayoutInfo({
    required this.columnIndex,
    required this.totalColumns,
  });
}

/// 여행 계획 상태 클래스
@immutable
class TravelPlanState {
  final TravelPlanModel? currentPlan;
  final List<ScheduleItemModel> items;
  final bool isLoading;
  final String? errorMessage;
  final List<TravelPlanModel> pastPlans;
  final List<TravelPlanModel> allPlans; // 전체 저장된 여행 계획 목록

  const TravelPlanState({
    this.currentPlan,
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.pastPlans = const [],
    this.allPlans = const [],
  });

  TravelPlanState copyWith({
    TravelPlanModel? currentPlan,
    List<ScheduleItemModel>? items,
    bool? isLoading,
    String? errorMessage,
    List<TravelPlanModel>? pastPlans,
    List<TravelPlanModel>? allPlans,
  }) {
    return TravelPlanState(
      currentPlan: currentPlan ?? this.currentPlan,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      pastPlans: pastPlans ?? this.pastPlans,
      allPlans: allPlans ?? this.allPlans,
    );
  }
}

/// 여행 계획 Notifier
class TravelPlanNotifier extends StateNotifier<TravelPlanState> {
  final TravelPlanRepository _repository;

  TravelPlanNotifier(this._repository) : super(const TravelPlanState()) {
    init();
  }

  /// 초기 데이터 로드 (전체 일정 및 과거 일정 조회)
  Future<void> init() async {
    await loadAllPlans();
    await loadPastPlans();
  }

  /// 전체 저장된 여행 일정 목록 불러오기
  Future<void> loadAllPlans() async {
    try {
      final plans = await _repository.getAllTravelPlans();
      state = state.copyWith(allPlans: plans);
    } catch (e) {
      state = state.copyWith(errorMessage: '전체 일정을 불러오는데 실패했습니다: $e');
    }
  }

  /// 과거 여행 일정 목록 불러오기
  Future<void> loadPastPlans() async {
    try {
      final plans = await _repository.getPastTravelPlans();
      state = state.copyWith(pastPlans: plans);
    } catch (e) {
      state = state.copyWith(errorMessage: '과거 일정을 불러오는데 실패했습니다: $e');
    }
  }

  /// 새 여행 계획 초기화 및 생성
  Future<void> initNewPlan({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? destination,
  }) async {
    final travelId = 'plan_${DateTime.now().millisecondsSinceEpoch}';
    final newPlan = TravelPlanModel(
      travelId: travelId,
      title: title,
      startDate: startDate,
      endDate: endDate,
      destination: destination,
    );

    await _repository.saveTravelPlan(newPlan);
    await _repository.saveScheduleItems(travelId, []);

    state = state.copyWith(
      currentPlan: newPlan,
      items: [],
    );

    await loadAllPlans();
  }

  /// 기존 여행 계획 불러오기
  Future<void> loadPlan(String travelId) async {
    state = state.copyWith(isLoading: true);
    try {
      final plan = await _repository.getTravelPlanById(travelId);
      final items = await _repository.getScheduleItems(travelId);
      state = state.copyWith(
        currentPlan: plan,
        items: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '여행 계획을 불러오지 못했습니다.',
      );
    }
  }

  /// 과거 여행 일정을 복사하여 새로운 여행 계획 생성
  Future<void> importPastPlan({
    required TravelPlanModel pastPlan,
    required String newTitle,
    required DateTime newStartDate,
    required DateTime newEndDate,
  }) async {
    final travelId = 'plan_${DateTime.now().millisecondsSinceEpoch}';
    final newPlan = TravelPlanModel(
      travelId: travelId,
      title: newTitle,
      startDate: newStartDate,
      endDate: newEndDate,
      destination: pastPlan.destination,
    );

    // 과거 일정 아이템 가져오기
    final pastItems = await _repository.getScheduleItems(pastPlan.travelId);

    // 과거 일정의 상대 날짜를 신규 날짜 범위로 매핑
    final List<ScheduleItemModel> copiedItems = [];
    final newDurationDays = newPlan.durationInDays;

    for (final item in pastItems) {
      final dayOffset = item.date.difference(pastPlan.startDate).inDays;
      if (dayOffset >= 0 && dayOffset < newDurationDays) {
        final targetDate = newStartDate.add(Duration(days: dayOffset));
        copiedItems.add(
          item.copyWith(
            id: 'item_${DateTime.now().microsecondsSinceEpoch}_${copiedItems.length}',
            travelId: travelId,
            date: DateTime(targetDate.year, targetDate.month, targetDate.day),
          ),
        );
      }
    }

    await _repository.saveTravelPlan(newPlan);
    await _repository.saveScheduleItems(travelId, copiedItems);

    state = state.copyWith(
      currentPlan: newPlan,
      items: copiedItems,
    );

    await loadAllPlans();
  }

  /// 여행 계획 메타데이터 업데이트 (즐겨찾기, 완료 등)
  Future<void> updatePlanMetadata(TravelPlanModel updatedPlan) async {
    await _repository.saveTravelPlan(updatedPlan);
    if (state.currentPlan?.travelId == updatedPlan.travelId) {
      state = state.copyWith(currentPlan: updatedPlan);
    }
    await loadAllPlans();
    await loadPastPlans();
  }

  /// 특정 여행 계획 완전 삭제
  Future<void> deletePlan(String travelId) async {
    await _repository.deleteTravelPlan(travelId);
    if (state.currentPlan?.travelId == travelId) {
      state = state.copyWith(currentPlan: null, items: []);
    }
    await loadAllPlans();
    await loadPastPlans();
  }

  /// 특정 슬롯 구간에 동시간대 3개 초과 겹침이 발생하는지 검증
  bool _canPlaceItem(ScheduleItemModel candidateItem) {
    final sameDateItems = state.items.where((item) {
      return item.id != candidateItem.id &&
          _isSameDate(item.date, candidateItem.date);
    }).toList();

    for (int slot = candidateItem.startSlotIndex;
        slot < candidateItem.endSlotIndex;
        slot++) {
      int count = 0;
      for (final existing in sameDateItems) {
        if (slot >= existing.startSlotIndex && slot < existing.endSlotIndex) {
          count++;
        }
      }

      if (count >= 3) {
        return false;
      }
    }
    return true;
  }

  /// 일정 추가 또는 수정 (3개 겹침 제한 검증)
  bool addOrUpdateItem(ScheduleItemModel item) {
    if (state.currentPlan == null) return false;

    if (!_canPlaceItem(item)) {
      return false;
    }

    final currentItems = List<ScheduleItemModel>.from(state.items);
    final existingIndex = currentItems.indexWhere((i) => i.id == item.id);

    if (existingIndex >= 0) {
      currentItems[existingIndex] = item;
    } else {
      currentItems.add(item);
    }

    state = state.copyWith(items: currentItems);
    _repository.saveScheduleItems(state.currentPlan!.travelId, currentItems);
    return true;
  }

  /// 일정 위치 이동 (날짜 및 시간 슬롯 변경)
  bool moveItem(String itemId, DateTime newDate, int newStartSlotIndex) {
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index == -1) return false;

    final targetItem = state.items[index];
    final updatedItem = targetItem.copyWith(
      date: DateTime(newDate.year, newDate.month, newDate.day),
      startSlotIndex: newStartSlotIndex,
    );

    return addOrUpdateItem(updatedItem);
  }

  /// 일정 삭제
  void deleteItem(String itemId) {
    if (state.currentPlan == null) return;

    final currentItems = state.items.where((i) => i.id != itemId).toList();
    state = state.copyWith(items: currentItems);
    _repository.saveScheduleItems(state.currentPlan!.travelId, currentItems);
  }

  /// 특정 날짜의 일정 카드들에 대한 2D 나란히 보기(Side-by-side) 열 및 너비 분할 계산
  Map<String, ItemLayoutInfo> getItemLayoutPositions(DateTime date) {
    final dayItems = state.items
        .where((item) => _isSameDate(item.date, date))
        .toList();

    dayItems.sort((a, b) {
      final slotComp = a.startSlotIndex.compareTo(b.startSlotIndex);
      if (slotComp != 0) return slotComp;
      return b.durationSlots.compareTo(a.durationSlots);
    });

    final Map<String, int> columnMap = {};
    final Map<String, int> maxConcurrentMap = {};

    final List<List<ScheduleItemModel>> slotOccupancy = List.generate(48, (_) => []);
    for (final item in dayItems) {
      for (int s = item.startSlotIndex; s < item.endSlotIndex && s < 48; s++) {
        slotOccupancy[s].add(item);
      }
    }

    for (final item in dayItems) {
      final usedColumns = <int>{};
      for (int s = item.startSlotIndex; s < item.endSlotIndex && s < 48; s++) {
        for (final other in slotOccupancy[s]) {
          if (other.id != item.id && columnMap.containsKey(other.id)) {
            usedColumns.add(columnMap[other.id]!);
          }
        }
      }

      int col = 0;
      while (usedColumns.contains(col)) {
        col++;
      }
      columnMap[item.id] = col;
    }

    for (final item in dayItems) {
      int maxOverlap = 1;
      for (int s = item.startSlotIndex; s < item.endSlotIndex && s < 48; s++) {
        if (slotOccupancy[s].length > maxOverlap) {
          maxOverlap = slotOccupancy[s].length;
        }
      }
      maxConcurrentMap[item.id] = maxOverlap;
    }

    for (final item in dayItems) {
      for (int s = item.startSlotIndex; s < item.endSlotIndex && s < 48; s++) {
        for (final other in slotOccupancy[s]) {
          final groupMax = maxConcurrentMap[item.id]! > maxConcurrentMap[other.id]!
              ? maxConcurrentMap[item.id]!
              : maxConcurrentMap[other.id]!;
          maxConcurrentMap[item.id] = groupMax;
          maxConcurrentMap[other.id] = groupMax;
        }
      }
    }

    final Map<String, ItemLayoutInfo> result = {};
    for (final item in dayItems) {
      final col = columnMap[item.id] ?? 0;
      final total = maxConcurrentMap[item.id] ?? 1;
      result[item.id] = ItemLayoutInfo(
        columnIndex: col,
        totalColumns: total < col + 1 ? col + 1 : total,
      );
    }

    return result;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

import 'package:moa/features/travel_plan/data/repositories/firebase_travel_plan_repository.dart';
import 'package:moa/features/travel_plan/data/repositories/sync_travel_plan_repository.dart';

/// Provider 생성 - SQLite(로컬 캐시) + Firebase(원격) 하이브리드 동기화 저장소 주입
final travelPlanRepositoryProvider = Provider<TravelPlanRepository>((ref) {
  final localRepo = SqliteTravelPlanRepository(AppDatabase.instance);
  final remoteRepo = FirebaseTravelPlanRepository();
  return SyncTravelPlanRepository(
    localRepository: localRepo,
    remoteRepository: remoteRepo,
  );
});

final travelPlanProvider =
    StateNotifierProvider<TravelPlanNotifier, TravelPlanState>((ref) {
  final repository = ref.watch(travelPlanRepositoryProvider);
  return TravelPlanNotifier(repository);
});
