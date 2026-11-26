import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../travel_plan/presentation/providers/travel_plan_provider.dart';
import '../../../travel_plan/presentation/widgets/travel_plan_card.dart';

/// 홈 화면 내 여행 일정 목록 섹션 위젯
class MyTravelPlanSection extends ConsumerWidget {
  const MyTravelPlanSection({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String travelId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('여행 계획 삭제'),
        content: Text('"$title" 여행 계획과 포함된 모든 일정이 영구적으로 삭제됩니다. 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(travelPlanProvider.notifier).deletePlan(travelId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('여행 계획이 삭제되었습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final planState = ref.watch(travelPlanProvider);
    final plans = planState.allPlans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '내 여행 일정',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (plans.isNotEmpty)
                  Text(
                    '총 ${plans.length}개',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => context.push('/travel-plan/all'),
                  child: const Text('전체보기'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (plans.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  '아직 등록된 여행 일정이 없습니다.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push('/travel-plan/create'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('첫 여행 시작하기'),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plans.length > 3 ? 3 : plans.length, // 홈 화면에서는 최대 3개까지만 표시하고 '전체보기' 유도
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final plan = plans[index];

              return TravelPlanCard(
                plan: plan,
                onTap: () {
                  context.push('/travel-plan/edit?travelId=${plan.travelId}');
                },
                onFavoriteToggle: () {
                  final updated = plan.copyWith(isFavorite: !plan.isFavorite);
                  ref.read(travelPlanProvider.notifier).updatePlanMetadata(updated);
                },
                onCompleteToggle: () {
                  final updated = plan.copyWith(isCompleted: !plan.isCompleted);
                  ref.read(travelPlanProvider.notifier).updatePlanMetadata(updated);
                },
                onDelete: () {
                  _confirmDelete(context, ref, plan.travelId, plan.title);
                },
              );
            },
          ),
      ],
    );
  }
}
