import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/vendor.dart';

final _currency = NumberFormat.currency(symbol: '€', decimalDigits: 0);
final _dateFormat = DateFormat('d MMM y');

class VendorCard extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const VendorCard({
    super.key,
    required this.vendor,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final days = vendor.daysUntilNextDeadline;
    final isOverdue = vendor.isOverdue;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vendor.name, style: AppTextStyles.cardTitle),
                        const SizedBox(height: 4),
                        Text(vendor.category, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  if (isOverdue)
                    _DeadlineBadge(label: 'Overdue', color: AppColors.danger)
                  else if (days != null && days <= 14)
                    _DeadlineBadge(
                      label: days == 0 ? 'Due today' : 'Due in $days days',
                      color: AppColors.warning,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.warmGrey,
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.attach_money,
                    label: _currency.format(vendor.totalCost),
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: vendor.depositPaid ? Icons.check_circle : Icons.pending,
                    label: vendor.depositPaid ? 'Deposit paid' : 'Deposit pending',
                    color: vendor.depositPaid ? AppColors.success : AppColors.warning,
                  ),
                ],
              ),
              if (vendor.hasInstallments) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: vendor.installments.map((inst) {
                    return _InstallmentChip(installment: inst);
                  }).toList(),
                ),
              ] else if (vendor.depositDue != null || vendor.balanceDue != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (vendor.depositDue != null)
                      _DateChip(
                        label: 'Deposit',
                        date: vendor.depositDue!,
                        isPaid: vendor.depositPaid,
                      ),
                    if (vendor.depositDue != null && vendor.balanceDue != null)
                      const SizedBox(width: 8),
                    if (vendor.balanceDue != null)
                      _DateChip(
                        label: 'Balance',
                        date: vendor.balanceDue!,
                        isPaid: false,
                      ),
                  ],
                ),
              ],
              if (vendor.contactPerson.isNotEmpty || vendor.email.isNotEmpty) ...[
                const SizedBox(height: 10),
                if (vendor.contactPerson.isNotEmpty)
                  Text('Contact: ${vendor.contactPerson}',
                      style: AppTextStyles.bodySmall),
                if (vendor.email.isNotEmpty)
                  Text(vendor.email, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeadlineBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _DeadlineBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: color),
        ),
      ],
    );
  }
}

class _InstallmentChip extends StatelessWidget {
  final Installment installment;
  const _InstallmentChip({required this.installment});

  @override
  Widget build(BuildContext context) {
    final isPaid = installment.paid;
    final isOverdue = installment.isOverdue;
    final color = isPaid
        ? AppColors.success
        : isOverdue
            ? AppColors.danger
            : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            installment.dueDate != null
                ? '${installment.label}: ${_dateFormat.format(installment.dueDate!)}'
                : installment.label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool isPaid;
  const _DateChip({required this.label, required this.date, required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid
            ? AppColors.success.withAlpha(20)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${_dateFormat.format(date)}',
        style: AppTextStyles.labelSmall.copyWith(
          color: isPaid ? AppColors.success : null,
        ),
      ),
    );
  }
}
