import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/travel_plan_model.dart';
import '../providers/travel_plan_provider.dart';
import '../widgets/past_plan_import_sheet.dart';

/// 새 여행계획 만들기 화면
class TravelPlanCreateScreen extends ConsumerStatefulWidget {
  const TravelPlanCreateScreen({super.key});

  @override
  ConsumerState<TravelPlanCreateScreen> createState() =>
      _TravelPlanCreateScreenState();
}

class _TravelPlanCreateScreenState
    extends ConsumerState<TravelPlanCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  TravelPlanModel? _importedPastPlan;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now,
      end: now.add(const Duration(days: 2)),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _openPastPlanImportSheet() {
    final allPlans = ref.read(travelPlanProvider).allPlans;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return PastPlanImportSheet(
          pastPlans: allPlans,
          onSelectPlan: (pastPlan) {
            setState(() {
              _importedPastPlan = pastPlan;
              _titleController.text = '${pastPlan.title} (복사본)';
              _destinationController.text = pastPlan.destination ?? '';
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('\'${pastPlan.title}\' 일정을 불러왔습니다.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitNewPlan() async {
    if (_formKey.currentState!.validate() && _selectedDateRange != null) {
      if (_importedPastPlan != null) {
        // 불러온 과거 일정을 바탕으로 복사 생성
        await ref.read(travelPlanProvider.notifier).importPastPlan(
              pastPlan: _importedPastPlan!,
              newTitle: _titleController.text.trim(),
              newStartDate: _selectedDateRange!.start,
              newEndDate: _selectedDateRange!.end,
            );
      } else {
        // 일반 신규 작성 생성
        await ref.read(travelPlanProvider.notifier).initNewPlan(
              title: _titleController.text.trim(),
              startDate: _selectedDateRange!.start,
              endDate: _selectedDateRange!.end,
              destination: _destinationController.text.trim().isNotEmpty
                  ? _destinationController.text.trim()
                  : null,
            );
      }

      if (mounted) {
        final currentPlan = ref.read(travelPlanProvider).currentPlan;
        if (currentPlan != null) {
          context.pushReplacement('/travel-plan/edit?travelId=${currentPlan.travelId}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('새 여행계획 만들기'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // '과거 일정 가져오기' 안내 배너
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      radius: 20,
                      child: Icon(
                        Icons.history_rounded,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '기존 일정을 재활용해보세요',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '진행 중, 예정, 완료된 모든 여행 코스를 가져와 빠른 수립이 가능합니다.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _openPastPlanImportSheet,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('불러오기'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text(
                '여행 기본 정보',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // 여행 제목 입력
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '여행 제목 *',
                  hintText: '예: 2025 제주도 힐링 우정 여행',
                  prefixIcon: const Icon(Icons.flight_land_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '여행 제목을 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 여행 목적지 입력 (선택)
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: '목적지 (선택)',
                  hintText: '예: 제주특별자치도, 부산, 도쿄',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 여행 기간 선택 버튼
              InkWell(
                onTap: _selectDateRange,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '여행 일정 선택 *',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDateRange == null
                                  ? '날짜를 선택하세요'
                                  : '${_selectedDateRange!.start.toString().substring(0, 10)} ~ ${_selectedDateRange!.end.toString().substring(0, 10)} (${_selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1}일간)',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 생성 및 시작 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitNewPlan,
                  child: const Text('타임테이블 편집 시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
