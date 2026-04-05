import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_radius.dart';
import '../data/inspection_model.dart';

/// Returns the color associated with an item condition.
Color conditionColor(ItemCondition condition) {
  switch (condition) {
    case ItemCondition.unchecked:
      return AppColors.textTertiary;
    case ItemCondition.ok:
      return AppColors.success;
    case ItemCondition.minorDamage:
      return AppColors.warning;
    case ItemCondition.majorDamage:
      return AppColors.error;
    case ItemCondition.missing:
      return const Color(0xFF7C3AED);
  }
}

/// Returns the icon for a given condition.
IconData conditionIcon(ItemCondition condition) {
  switch (condition) {
    case ItemCondition.unchecked:
      return Icons.radio_button_unchecked;
    case ItemCondition.ok:
      return Icons.check_circle_rounded;
    case ItemCondition.minorDamage:
      return Icons.warning_amber_rounded;
    case ItemCondition.majorDamage:
      return Icons.error_rounded;
    case ItemCondition.missing:
      return Icons.remove_circle_rounded;
  }
}

/// A row of tappable chips for selecting item condition.
class ConditionSelector extends StatelessWidget {
  final ItemCondition selected;
  final ValueChanged<ItemCondition> onChanged;

  const ConditionSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _selectableConditions = [
    ItemCondition.ok,
    ItemCondition.minorDamage,
    ItemCondition.majorDamage,
    ItemCondition.missing,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _selectableConditions.map((condition) {
        final isActive = condition == selected;
        final color = conditionColor(condition);

        return GestureDetector(
          onTap: () => onChanged(
            isActive ? ItemCondition.unchecked : condition,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? color.withValues(alpha: 0.12) : AppColors.surfaceVariant,
              borderRadius: AppRadius.borderRadiusSm,
              border: Border.all(
                color: isActive ? color : AppColors.borderLight,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  conditionIcon(condition),
                  size: 14,
                  color: isActive ? color : AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  condition.shortLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: isActive ? color : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// A small inline badge showing the condition.
class ConditionBadge extends StatelessWidget {
  final ItemCondition condition;

  const ConditionBadge({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    if (condition == ItemCondition.unchecked) {
      return const SizedBox.shrink();
    }
    final color = conditionColor(condition);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(conditionIcon(condition), size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            condition.shortLabel,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
