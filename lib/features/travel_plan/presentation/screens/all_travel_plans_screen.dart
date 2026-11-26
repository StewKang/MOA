import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/travel_plan_provider.dart';
import '../widgets/travel_plan_card.dart';

/// 전체 여행 일정 조회 페이지 (검색 및 카테고리 필터 지원)
class AllTravelPlansScreen extends ConsumerStatefulWidget {
  const AllTravelPlansScreen({super.key});

  @override
  ConsumerState<AllTravelPlansScreen> createState() =>
      _AllTravelPlansScreenState();
}

class _AllTravelPlansScreenState extends ConsumerState<AllTravelPlansScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'favorite', 'ongoing', 'completed'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String travelId, String title) async {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final planState = ref.watch(travelPlanProvider);
    final allPlans = planState.allPlans;
    final query = _searchController.text.trim().toLowerCase();

    // 필터링 및 검색어 적용
    final filteredPlans = allPlans.where((plan) {
      // 1. 검색어 필터 (제목 또는 목적지)
      final titleMatch = plan.title.toLowerCase().contains(query);
      final destMatch = plan.destination != null &&
          plan.destination!.toLowerCase().contains(query);
      if (query.isNotEmpty && !titleMatch && !destMatch) {
        return false;
      }

      // 2. 카테고리 탭 필터
      if (_selectedFilter == 'favorite') {
        return plan.isFavorite;
      } else if (_selectedFilter == 'ongoing') {
        return !plan.isCompleted;
      } else if (_selectedFilter == 'completed') {
        return plan.isCompleted;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 여행 일정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 상단 검색바 및 필터 칩 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Column(
              children: [
                // 검색어 입력창
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '여행 제목 또는 목적지 검색',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),

                // 필터 칩 가로 스크롤 바
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(context, '전체', 'all', allPlans.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        '즐겨찾기',
                        'favorite',
                        allPlans.where((p) => p.isFavorite).length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        '예정/진행중',
                        'ongoing',
                        allPlans.where((p) => !p.isCompleted).length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        '완료됨',
                        'completed',
                        allPlans.where((p) => p.isCompleted).length,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 여행 계획 리스트 본문
          Expanded(
            child: filteredPlans.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          query.isNotEmpty
                              ? '검색 결과가 없습니다.'
                              : '해당 조건의 여행 일정이 없습니다.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredPlans.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final plan = filteredPlans[index];
                      return TravelPlanCard(
                        plan: plan,
                        onTap: () {
                          context.push(
                              '/travel-plan/edit?travelId=${plan.travelId}');
                        },
                        onFavoriteToggle: () {
                          final updated =
                              plan.copyWith(isFavorite: !plan.isFavorite);
                          ref
                              .read(travelPlanProvider.notifier)
                              .updatePlanMetadata(updated);
                        },
                        onCompleteToggle: () {
                          final updated =
                              plan.copyWith(isCompleted: !plan.isCompleted);
                          ref
                              .read(travelPlanProvider.notifier)
                              .updatePlanMetadata(updated);
                        },
                        onDelete: () {
                          _confirmDelete(
                              context, ref, plan.travelId, plan.title);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, String value, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedFilter == value;

    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
