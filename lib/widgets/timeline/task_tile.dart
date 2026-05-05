import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/task_item.dart';

final _dateFormat = DateFormat('d MMM y');

class TaskTile extends StatelessWidget {
  final TaskItem task;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TaskTile({
    super.key,
    required this.task,
    this.onToggle,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    final tod = task.timeOfDay;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: GestureDetector(
        onTap: onToggle,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: task.isDone
                  ? AppColors.success
                  : overdue
                      ? AppColors.danger
                      : AppColors.divider,
              width: 2,
            ),
            color: task.isDone ? AppColors.success : Colors.transparent,
          ),
          child: task.isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
      title: Text(
        task.title,
        style: AppTextStyles.bodyMedium.copyWith(
          decoration: task.isDone ? TextDecoration.lineThrough : null,
          color: task.isDone ? AppColors.textSecondary : null,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _PriorityDot(priority: task.priority),
            _Badge(label: task.category, color: AppColors.surfaceVariant,
                textColor: AppColors.textSecondary),
            if (task.dueDate != null)
              _Badge(
                label: tod != null
                    ? '${_dateFormat.format(task.dueDate!)} · ${tod.format(context)}'
                    : _dateFormat.format(task.dueDate!),
                color: overdue
                    ? AppColors.danger.withAlpha(20)
                    : AppColors.surfaceVariant,
                textColor: overdue ? AppColors.danger : AppColors.textSecondary,
                icon: Icons.event_outlined,
              ),
            if (task.assignedTo.isNotEmpty)
              _Badge(
                label: task.assignedTo,
                color: AppColors.tealVibrant.withAlpha(20),
                textColor: AppColors.tealVibrant,
                icon: task.assignedTo == 'Bride'
                    ? Icons.woman_outlined
                    : task.assignedTo == 'Groom'
                        ? Icons.man_outlined
                        : Icons.people_outline,
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(color: textColor)),
        ],
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final String priority;
  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case AppConstants.priorityHigh:
        color = AppColors.danger;
        break;
      case AppConstants.priorityMedium:
        color = AppColors.warning;
        break;
      default:
        color = AppColors.sage;
    }
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
