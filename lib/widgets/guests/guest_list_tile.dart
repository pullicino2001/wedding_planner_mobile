import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/guest.dart';

class GuestListTile extends StatelessWidget {
  final Guest guest;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GuestListTile({
    super.key,
    required this.guest,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _rsvpColor(guest.rsvpStatus).withAlpha(40),
        child: Text(
          guest.firstName.isNotEmpty ? guest.firstName[0].toUpperCase() : '?',
          style: TextStyle(
            color: _rsvpColor(guest.rsvpStatus),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(guest.fullName, style: AppTextStyles.bodyMedium),
      subtitle: Text(
        guest.email.isNotEmpty ? guest.email : 'No email',
        style: AppTextStyles.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RsvpBadge(status: guest.rsvpStatus),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.warmGrey,
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }

  Color _rsvpColor(String status) {
    switch (status) {
      case AppConstants.rsvpConfirmed:
        return AppColors.success;
      case AppConstants.rsvpDeclined:
        return AppColors.danger;
      default:
        return AppColors.pending;
    }
  }
}

class _RsvpBadge extends StatelessWidget {
  final String status;
  const _RsvpBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case AppConstants.rsvpConfirmed:
        color = AppColors.success;
        label = 'Coming';
        break;
      case AppConstants.rsvpDeclined:
        color = AppColors.danger;
        label = 'Declined';
        break;
      default:
        color = AppColors.pending;
        label = 'Pending';
    }
    return Container(
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
