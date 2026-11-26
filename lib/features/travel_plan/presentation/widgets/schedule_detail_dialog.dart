import 'package:flutter/material.dart';

import '../../data/models/schedule_item_model.dart';

/// 일정 상세 정보 입력 및 수정 다이얼로그
class ScheduleDetailDialog extends StatefulWidget {
  final ScheduleItemModel item;
  final ValueChanged<ScheduleItemModel> onSave;
  final ValueChanged<String>? onDelete;

  const ScheduleDetailDialog({
    super.key,
    required this.item,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<ScheduleDetailDialog> createState() => _ScheduleDetailDialogState();
}

class _ScheduleDetailDialogState extends State<ScheduleDetailDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _memoController;

  late String _selectedCategory;
  late int _startSlotIndex;
  late int _durationSlots;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _locationController = TextEditingController(text: widget.item.location);
    _memoController = TextEditingController(text: widget.item.memo);

    _selectedCategory = widget.item.category;
    _startSlotIndex = widget.item.startSlotIndex;
    _durationSlots = widget.item.durationSlots;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updated = widget.item.copyWith(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        memo: _memoController.text.trim(),
        startSlotIndex: _startSlotIndex,
        durationSlots: _durationSlots,
      );
      widget.onSave(updated);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getCategoryIcon(_selectedCategory),
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(widget.item.title.isEmpty ? '새 일정 추가' : '일정 상세 편집'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 선택
                Text(
                  '카테고리',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'activity', label: Text('일정')),
                    ButtonSegment(value: 'transport', label: Text('이동')),
                    ButtonSegment(value: 'meal', label: Text('식사')),
                    ButtonSegment(value: 'custom', label: Text('기타')),
                  ],
                  selected: {_selectedCategory},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedCategory = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 제목
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '일정 제목 *',
                    hintText: '예: 해운대 해수욕장, 점심 식사',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? '제목을 입력해 주세요' : null,
                ),
                const SizedBox(height: 14),

                // 장소
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: '장소 / 위치',
                    hintText: '예: 부산 해운대구',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // 시작 시간 및 소요 시간 드롭다운
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _startSlotIndex,
                        decoration: const InputDecoration(
                          labelText: '시작 시간',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(48, (index) {
                          final hour = index ~/ 2;
                          final minute = (index % 2) * 30;
                          final timeStr =
                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                          return DropdownMenuItem(
                            value: index,
                            child: Text(timeStr),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _startSlotIndex = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _durationSlots,
                        decoration: const InputDecoration(
                          labelText: '소요 시간',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('30분')),
                          DropdownMenuItem(value: 2, child: Text('1시간')),
                          DropdownMenuItem(value: 3, child: Text('1시간 30분')),
                          DropdownMenuItem(value: 4, child: Text('2시간')),
                          DropdownMenuItem(value: 5, child: Text('2시간 30분')),
                          DropdownMenuItem(value: 6, child: Text('3시간')),
                          DropdownMenuItem(value: 8, child: Text('4시간')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _durationSlots = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 메모
                TextFormField(
                  controller: _memoController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '메모 / 참고사항',
                    hintText: '예: 예약번호 #1234, 준비물 챙기기',
                    prefixIcon: Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
            tooltip: '일정 삭제',
            onPressed: () {
              widget.onDelete!(widget.item.id);
              Navigator.pop(context);
            },
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('저장'),
        ),
      ],
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
}
