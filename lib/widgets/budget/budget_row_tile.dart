import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/budget_item.dart';

final _currency = NumberFormat.currency(symbol: '€', decimalDigits: 0);

class BudgetRowTile extends StatelessWidget {
  final BudgetItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BudgetRowTile({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final overBudget = item.actual > item.estimated && item.estimated > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      title: Row(
        children: [
          Expanded(
            child: Text(item.item, style: AppTextStyles.bodyMedium),
          ),
          if (item.paid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Paid',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(item.category, style: AppTextStyles.labelSmall),
            ),
            const SizedBox(width: 8),
            Text(
              'Est ${_currency.format(item.estimated)}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(width: 8),
            Text(
              '· Act ${_currency.format(item.actual)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: overBudget ? AppColors.danger : AppColors.textSecondary,
                fontWeight: overBudget ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.warmGrey,
              onPressed: onDelete,
            )
          : null,
    );
  }
}
