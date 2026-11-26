import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/schedule_item_model.dart';
import '../../data/models/travel_plan_model.dart';
import '../providers/travel_plan_provider.dart';
import 'schedule_detail_dialog.dart';
import 'schedule_item_card.dart';

/// 세로(30분 단위 시간축) × 가로(날짜축, 가로 스크롤) 2차원 타임테이블 표 위젯
class TimetableGridView extends ConsumerStatefulWidget {
  final TravelPlanModel plan;
  final List<ScheduleItemModel> items;

  const TimetableGridView({
    super.key,
    required this.plan,
    required this.items,
  });

  @override
  ConsumerState<TimetableGridView> createState() => _TimetableGridViewState();
}

class _TimetableGridViewState extends ConsumerState<TimetableGridView> {
  static const double slotHeight = 44.0; // 30분 슬롯 높이 (px)
  static const int totalSlots = 48; // 24시간 = 48개 슬롯
  static const double timeHeaderWidth = 55.0; // 좌측 고정 시간축 너비
  static const double dateHeaderHeight = 48.0; // 상단 날짜 헤더 높이

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  /// 겹침 3개 제한 초과 안내 알림 SnackBar
  void _showOverlapLimitSnackBar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '동시간대 일정은 최대 3개까지만 겹칠 수 있습니다.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 팔레트에서 신규 일정 드롭 시 다이얼로그 호출 또는 바로 생성
  void _handlePaletteDrop(String category, DateTime date, int slotIndex) {
    final defaultTitle = _getDefaultTitleForCategory(category);
    final newItem = ScheduleItemModel(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      travelId: widget.plan.travelId,
      date: DateTime(date.year, date.month, date.day),
      startSlotIndex: slotIndex,
      durationSlots: 2, // 기본 1시간 (2슬롯)
      category: category,
      title: defaultTitle,
    );

    // 겹침 검증 후 추가
    final success =
        ref.read(travelPlanProvider.notifier).addOrUpdateItem(newItem);
    if (!success) {
      _showOverlapLimitSnackBar();
    }
  }

  /// 카드 이동 드롭 처리
  void _handleItemMove(ScheduleItemModel movedItem, DateTime date, int slotIndex) {
    final success = ref
        .read(travelPlanProvider.notifier)
        .moveItem(movedItem.id, date, slotIndex);

    if (!success) {
      _showOverlapLimitSnackBar();
    }
  }

  /// 카드 클릭 시 편집 다이얼로그
  void _openEditDialog(ScheduleItemModel item) {
    showDialog(
      context: context,
      builder: (context) {
        return ScheduleDetailDialog(
          item: item,
          onSave: (updatedItem) {
            final success = ref
                .read(travelPlanProvider.notifier)
                .addOrUpdateItem(updatedItem);
            if (!success) {
              _showOverlapLimitSnackBar();
            }
          },
          onDelete: (itemId) {
            ref.read(travelPlanProvider.notifier).deleteItem(itemId);
          },
        );
      },
    );
  }

  String _getDefaultTitleForCategory(String category) {
    switch (category) {
      case 'activity':
        return '새 일정';
      case 'transport':
        return '이동';
      case 'meal':
        return '식사';
      case 'custom':
      default:
        return '자유 일정';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final durationDays = widget.plan.durationInDays;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        // 화면 너비에 따른 날짜 열 너비 반응형 계산
        final availableWidth = constraints.maxWidth - timeHeaderWidth;
        final visibleColumnsCount = isLandscape ? 4 : 2;
        final columnWidth = (availableWidth / visibleColumnsCount) < 140.0
            ? 140.0
            : (availableWidth / visibleColumnsCount);

        return Column(
          children: [
            // 1. Fixed Top Date Header Row
            Container(
              height: dateHeaderHeight,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 좌측 고정 시간축 헤더 교차 지점
                  Container(
                    width: timeHeaderWidth,
                    height: dateHeaderHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: Border(
                        right: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      '시간',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 가로 스크롤 날짜 헤더 목록
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Row(
                        children: List.generate(durationDays, (dayIdx) {
                          final date = widget.plan.getDateForDayIndex(dayIdx + 1);
                          final monthDayStr =
                              '${date.month}/${date.day}';

                          return Container(
                            width: columnWidth,
                            height: dateHeaderHeight,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              border: Border(
                                right: BorderSide(
                                  color: colorScheme.outlineVariant,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Day ${dayIdx + 1}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  monthDayStr,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Main Timetable Body (Vertical + Horizontal Scroll)
            Expanded(
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                child: SizedBox(
                  height: totalSlots * slotHeight,
                  child: Row(
                    children: [
                      // 좌측 고정 Y축 시간 슬롯 헤더
                      SizedBox(
                        width: timeHeaderWidth,
                        child: Column(
                          children: List.generate(totalSlots, (slotIdx) {
                            final hour = slotIdx ~/ 2;
                            final minute = (slotIdx % 2) * 30;
                            final timeStr =
                                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                            return Container(
                              height: slotHeight,
                              alignment: Alignment.topCenter,
                              padding: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                border: Border(
                                  right: BorderSide(
                                    color: colorScheme.outlineVariant,
                                    width: 1,
                                  ),
                                  bottom: BorderSide(
                                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                timeStr,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      // 날짜별 2차원 타임테이블 그리드
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: Row(
                            children: List.generate(durationDays, (dayIdx) {
                              final date =
                                  widget.plan.getDateForDayIndex(dayIdx + 1);
                              final layoutMap = ref
                                  .watch(travelPlanProvider.notifier)
                                  .getItemLayoutPositions(date);

                              return SizedBox(
                                width: columnWidth,
                                height: totalSlots * slotHeight,
                                child: Stack(
                                  children: [
                                    // 슬롯 배경 및 DragTarget
                                    Column(
                                      children: List.generate(totalSlots, (slotIdx) {
                                        return DragTarget<Object>(
                                          onWillAcceptWithDetails: (details) => true,
                                          onAcceptWithDetails: (details) {
                                            final data = details.data;
                                            if (data is String) {
                                              // 팔레트 카테고리 드롭
                                              _handlePaletteDrop(data, date, slotIdx);
                                            } else if (data is ScheduleItemModel) {
                                              // 기존 일정 이동 드롭
                                              _handleItemMove(data, date, slotIdx);
                                            }
                                          },
                                          builder: (context, candidateData, rejectedData) {
                                            final isHovered = candidateData.isNotEmpty;
                                            return Container(
                                              height: slotHeight,
                                              decoration: BoxDecoration(
                                                color: isHovered
                                                    ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                                                    : (slotIdx % 2 == 0
                                                        ? colorScheme.surface
                                                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.15)),
                                                border: Border(
                                                  right: BorderSide(
                                                    color: colorScheme.outlineVariant,
                                                    width: 1,
                                                  ),
                                                  bottom: BorderSide(
                                                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                                                    width: slotIdx % 2 == 1 ? 1.0 : 0.5,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }),
                                    ),

                                    // 날짜별 일정 카드들 배치
                                    ...widget.items
                                        .where((item) =>
                                            item.date.year == date.year &&
                                            item.date.month == date.month &&
                                            item.date.day == date.day)
                                        .map((item) {
                                      final layoutInfo = layoutMap[item.id] ??
                                          const ItemLayoutInfo(
                                            columnIndex: 0,
                                            totalColumns: 1,
                                          );

                                      return ScheduleItemCard(
                                        key: ValueKey(item.id),
                                        item: item,
                                        layoutInfo: layoutInfo,
                                        slotHeight: slotHeight,
                                        columnWidth: columnWidth,
                                        onTap: () => _openEditDialog(item),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
