import 'package:flutter/material.dart';
import '../../data/models/travel_plan_model.dart';

/// 개별 여행 계획 카드 위젯 (홈 화면 및 전체 일정 조회 페이지 공용)
class TravelPlanCard extends StatelessWidget {
  final TravelPlanModel plan;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onCompleteToggle;
  final VoidCallback onDelete;

  const TravelPlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onCompleteToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final startDateStr = plan.startDate.toString().substring(0, 10);
    final endDateStr = plan.endDate.toString().substring(0, 10);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: plan.isFavorite ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: plan.isFavorite
            ? BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 아이콘 / 즐겨찾기 아바타
              CircleAvatar(
                radius: 26,
                backgroundColor: plan.isCompleted
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.primaryContainer,
                child: Icon(
                  plan.isCompleted
                      ? Icons.done_all_rounded
                      : (plan.isFavorite ? Icons.star_rounded : Icons.flight_takeoff_rounded),
                  color: plan.isCompleted
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),

              // 여행 정보 요약
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: plan.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: plan.isCompleted
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (plan.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '완료됨',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$startDateStr ~ $endDateStr (${plan.durationInDays}일간)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (plan.destination != null &&
                        plan.destination!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            plan.destination!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 빠른 관리 액션 메뉴 (즐겨찾기, 팝업 메뉴)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      plan.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: plan.isFavorite ? Colors.amber : colorScheme.outline,
                    ),
                    tooltip: '즐겨찾기 토글',
                    onPressed: onFavoriteToggle,
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: colorScheme.onSurfaceVariant),
                    onSelected: (value) {
                      if (value == 'complete') {
                        onCompleteToggle();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(
                              plan.isCompleted
                                  ? Icons.refresh_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(plan.isCompleted ? '진행 중으로 변경' : '완료로 표시'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: colorScheme.error),
                            const SizedBox(width: 8),
                            Text('삭제하기',
                                style: TextStyle(color: colorScheme.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
