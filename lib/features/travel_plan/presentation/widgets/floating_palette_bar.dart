import 'dart:ui';
import 'package:flutter/material.dart';

/// 하단 반투명 팔레트 가로바 (드래그 가능한 일정 카테고리 아이콘들)
class FloatingPaletteBar extends StatelessWidget {
  final VoidCallback onAddCustomTap;

  const FloatingPaletteBar({
    super.key,
    required this.onAddCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final items = [
      {
        'category': 'activity',
        'label': '일정',
        'icon': Icons.event_note_rounded,
        'color': colorScheme.primary,
        'bgColor': colorScheme.primaryContainer,
      },
      {
        'category': 'transport',
        'label': '이동',
        'icon': Icons.directions_car_rounded,
        'color': colorScheme.secondary,
        'bgColor': colorScheme.secondaryContainer,
      },
      {
        'category': 'meal',
        'label': '식사',
        'icon': Icons.restaurant_rounded,
        'color': colorScheme.onSurfaceVariant,
        'bgColor': colorScheme.surfaceContainerHighest,
      },
      {
        'category': 'custom',
        'label': '직접 추가',
        'icon': Icons.add_circle_outline_rounded,
        'color': colorScheme.primary,
        'bgColor': colorScheme.surface,
      },
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) {
              final category = item['category'] as String;
              final label = item['label'] as String;
              final icon = item['icon'] as IconData;
              final color = item['color'] as Color;
              final bgColor = item['bgColor'] as Color;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Draggable<String>(
                  data: category,
                  feedback: Material(
                    elevation: 6,
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: color, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.4,
                    child: _buildPaletteButton(
                      theme: theme,
                      label: label,
                      icon: icon,
                      color: color,
                      bgColor: bgColor,
                      onTap: category == 'custom' ? onAddCustomTap : null,
                    ),
                  ),
                  child: _buildPaletteButton(
                    theme: theme,
                    label: label,
                    icon: icon,
                    color: color,
                    bgColor: bgColor,
                    onTap: category == 'custom' ? onAddCustomTap : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaletteButton({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
