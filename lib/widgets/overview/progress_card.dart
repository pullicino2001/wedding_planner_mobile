import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// ModuleCard — Japandi × Material You style progress card
class ProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress; // 0.0 to 1.0
  final Color progressColor;
  final String? urgencyLabel;
  final VoidCallback onTap;
  final IconData? icon;

  const ProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressColor,
    required this.onTap,
    this.urgencyLabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D004D54),
              blurRadius: 22,
              spreadRadius: -14,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x1F004D54),
              blurRadius: 6,
              spreadRadius: -3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: progressColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, size: 22, color: progressColor),
                  ),
                if (icon != null) const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.cardTitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (urgencyLabel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withAlpha(22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                urgencyLabel!,
                                style: AppTextStyles.urgencyBadge,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.cardSubtitle),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right,
                    size: 18, color: AppColors.inkMute),
              ],
            ),
            const SizedBox(height: 14),
            // Progress bar
            SizedBox(
              height: 8,
              child: CustomPaint(
                size: const Size(double.infinity, 8),
                painter: _BarPainter(
                  progress: progress.clamp(0.0, 1.0),
                  color: progressColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PROGRESS',
                  style: AppTextStyles.sectionEyebrow.copyWith(fontSize: 9),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.percentLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _BarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = color.withAlpha(38)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(999)),
      trackPaint,
    );
    if (progress > 0) {
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width * progress, size.height),
          const Radius.circular(999),
        ),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.progress != progress || old.color != color;
}
