import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// A Material 3 ChoiceChip picker for selecting one value from a list.
class ChipPicker extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selected;
  final Map<String, IconData> icons;
  final ValueChanged<String> onChanged;
  final Color? selectedColor;

  const ChipPicker({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.icons = const {},
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.tealVibrant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected == opt;
            final icon = icons[opt];
            return ChoiceChip(
              label: Text(opt),
              avatar: icon != null
                  ? Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : color,
                    )
                  : null,
              selected: isSelected,
              onSelected: (_) => onChanged(opt),
              selectedColor: color,
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? color : AppColors.divider,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }
}
