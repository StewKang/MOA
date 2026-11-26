import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/schedule_item_model.dart';
import '../providers/travel_plan_provider.dart';
import '../widgets/floating_palette_bar.dart';
import '../widgets/schedule_detail_dialog.dart';
import '../widgets/timetable_grid_view.dart';

/// 메인 타임테이블 편집 화면
class TravelPlanEditScreen extends ConsumerStatefulWidget {
  final String? travelId;

  const TravelPlanEditScreen({
    super.key,
    this.travelId,
  });

  @override
  ConsumerState<TravelPlanEditScreen> createState() =>
      _TravelPlanEditScreenState();
}

class _TravelPlanEditScreenState extends ConsumerState<TravelPlanEditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.travelId != null && widget.travelId!.isNotEmpty) {
        ref.read(travelPlanProvider.notifier).loadPlan(widget.travelId!);
      }
    });
  }

  void _openAddCustomDialog() {
    final state = ref.read(travelPlanProvider);
    if (state.currentPlan == null) return;

    final defaultItem = ScheduleItemModel(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      travelId: state.currentPlan!.travelId,
      date: state.currentPlan!.startDate,
      startSlotIndex: 18, // 09:00
      durationSlots: 2, // 1시간
      category: 'custom',
      title: '새 일정',
    );

    showDialog(
      context: context,
      builder: (context) {
        return ScheduleDetailDialog(
          item: defaultItem,
          onSave: (newItem) {
            final success = ref
                .read(travelPlanProvider.notifier)
                .addOrUpdateItem(newItem);
            if (!success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('동시간대 일정은 최대 3개까지만 겹칠 수 있습니다.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final planState = ref.watch(travelPlanProvider);
    final currentPlan = planState.currentPlan;

    if (planState.isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (currentPlan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('타임테이블 편집')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                '여행 계획 정보를 찾을 수 없습니다.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentPlan.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${currentPlan.startDate.toString().substring(0, 10)} ~ ${currentPlan.endDate.toString().substring(0, 10)} (${currentPlan.durationInDays}일간)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              currentPlan.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: currentPlan.isFavorite ? Colors.amber : null,
            ),
            tooltip: '즐겨찾기',
            onPressed: () {
              final updated = currentPlan.copyWith(
                isFavorite: !currentPlan.isFavorite,
              );
              ref.read(travelPlanProvider.notifier).updatePlanMetadata(updated);
            },
          ),
          FilledButton.tonalIcon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('여행 일정 편집이 완료되었습니다!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.pop();
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('완료'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 메인 2D 타임테이블 표
          TimetableGridView(
            plan: currentPlan,
            items: planState.items,
          ),

          // 화면 하단 반투명 팔레트 오버레이
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: FloatingPaletteBar(
                onAddCustomTap: _openAddCustomDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
