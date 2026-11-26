import 'package:flutter/material.dart';
import '../../data/models/travel_plan_model.dart';

/// 기존 여행 일정 불러오기 바텀시트 (진행 중, 예정, 완료 일정 모두 포함)
class PastPlanImportSheet extends StatelessWidget {
  final List<TravelPlanModel> pastPlans;
  final ValueChanged<TravelPlanModel> onSelectPlan;

  const PastPlanImportSheet({
    super.key,
    required this.pastPlans,
    required this.onSelectPlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 핸들 드래그 바
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.copy_all_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '기존 일정 불러오기',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '진행 중, 예정된 일정 및 완료된 일정을 복사하여 새로운 여행을 빠르게 시작하세요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (pastPlans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '등록된 여행 일정이 없습니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: pastPlans.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final plan = pastPlans[index];
                  final startDateStr = plan.startDate.toString().substring(0, 10);
                  final endDateStr = plan.endDate.toString().substring(0, 10);

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          plan.isCompleted
                              ? Icons.done_all_rounded
                              : (plan.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.flight_takeoff_rounded),
                          color: colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        plan.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '$startDateStr ~ $endDateStr (${plan.durationInDays}일)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (plan.destination != null && plan.destination!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '목적지: ${plan.destination}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: () {
                          Navigator.pop(context);
                          onSelectPlan(plan);
                        },
                        child: const Text('가져오기'),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
