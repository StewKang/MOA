import 'package:flutter/material.dart';

import '../../data/models/schedule_item_model.dart';
import '../providers/travel_plan_provider.dart';

/// 타임테이블 위 배치되는 일정 카드 위젯
/// (오른쪽 가로줄 3개 그립 드래그 핸들 포함, 겹침 분할 너비 반영)
class ScheduleItemCard extends StatelessWidget {
  final ScheduleItemModel item;
  final ItemLayoutInfo layoutInfo;
  final double slotHeight;
  final double columnWidth;
  final VoidCallback onTap;

  const ScheduleItemCard({
    super.key,
    required this.item,
    required this.layoutInfo,
    required this.slotHeight,
    required this.columnWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 카테고리별 테마 색상 정의 (Material 3 ColorScheme 기반)
    final categoryColors = _getCategoryColors(colorScheme, item.category);

    // 나란히 보기(Side-by-side) 분할 너비 및 위치 계산
    final totalCols = layoutInfo.totalColumns > 0 ? layoutInfo.totalColumns : 1;
    final itemWidth = (columnWidth / totalCols) - 4; // 간격 4px 차감
    final leftPos = (layoutInfo.columnIndex * (columnWidth / totalCols)) + 2;
    final topPos = item.startSlotIndex * slotHeight;
    final cardHeight = (item.durationSlots * slotHeight) - 2;

    return Positioned(
      left: leftPos,
      top: topPos,
      width: itemWidth,
      height: cardHeight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: categoryColors.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: categoryColors.borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 카드 본문 (탭 시 편집 다이얼로그 열기)
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    top: 6,
                    bottom: 6,
                    right: 24, // 우측 그립 핸들 공간 확보
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getCategoryIcon(item.category),
                            size: 14,
                            color: categoryColors.textColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: categoryColors.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (cardHeight >= 45) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${item.startTimeFormatted} - ${item.endTimeFormatted}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: categoryColors.textColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                      if (cardHeight >= 65 && item.location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 10,
                              color: categoryColors.textColor.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: categoryColors.textColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 우측 가로줄 3개 전용 드래그 핸들 (Draggable)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 24,
                child: Draggable<ScheduleItemModel>(
                  data: item,
                  feedback: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.transparent,
                    child: Container(
                      width: itemWidth,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        color: categoryColors.backgroundColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: categoryColors.textColor,
                            ),
                          ),
                          Text(
                            '${item.startTimeFormatted} (${item.durationFormatted})',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: categoryColors.textColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: categoryColors.backgroundColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 18,
                      color: categoryColors.textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'activity':
        return Icons.event_note_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'meal':
        return Icons.restaurant_rounded;
      case 'custom':
      default:
        return Icons.add_circle_outline_rounded;
    }
  }

  _CategoryTheme _getCategoryColors(ColorScheme colorScheme, String category) {
    switch (category) {
      case 'activity':
        return _CategoryTheme(
          backgroundColor: colorScheme.primaryContainer,
          borderColor: colorScheme.primary.withValues(alpha: 0.5),
          textColor: colorScheme.onPrimaryContainer,
        );
      case 'transport':
        return _CategoryTheme(
          backgroundColor: colorScheme.secondaryContainer,
          borderColor: colorScheme.secondary.withValues(alpha: 0.5),
          textColor: colorScheme.onSecondaryContainer,
        );
      case 'meal':
        return _CategoryTheme(
          backgroundColor: colorScheme.surfaceContainerHighest,
          borderColor: colorScheme.outlineVariant,
          textColor: colorScheme.onSurface,
        );
      case 'custom':
      default:
        return _CategoryTheme(
          backgroundColor: colorScheme.surface,
          borderColor: colorScheme.primary.withValues(alpha: 0.3),
          textColor: colorScheme.onSurface,
        );
    }
  }
}

class _CategoryTheme {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _CategoryTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
