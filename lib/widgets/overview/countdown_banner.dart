import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CountdownBanner extends StatelessWidget {
  final int daysUntilWedding;
  final String coupleNames;
  final String weddingDate;
  final double plannedProgress; // 0.0–1.0

  const CountdownBanner({
    super.key,
    required this.daysUntilWedding,
    required this.coupleNames,
    this.weddingDate = '',
    this.plannedProgress = 0.62,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = daysUntilWedding < 0;
    final isToday = daysUntilWedding == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGrad,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: const [AppColors.cardGlow],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Top-right white radial blob
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xD9FFFFFF), Color(0x00FFFFFF)],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          // Bottom-left deep teal blob
          Positioned(
            left: -40,
            bottom: -55,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF004D54).withAlpha(90),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COUNTING DOWN TO',
                  style: AppTextStyles.sectionEyebrow.copyWith(
                    color: AppColors.primaryTC,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  coupleNames.isNotEmpty ? coupleNames : 'Your Wedding',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.primaryTC,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 10),
                if (isToday)
                  Text(
                    'Today is the day!',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.primaryTC,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (isPast)
                  Text(
                    'Congratulations!',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.primaryTC,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF003E45),
                            Color(0xFF006064),
                            Color(0xFF0099AE),
                          ],
                          stops: [0.0, 0.6, 1.0],
                        ).createShader(bounds),
                        child: Text(
                          '${daysUntilWedding.abs()}',
                          style: AppTextStyles.countdownNumber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'days to go',
                              style: AppTextStyles.countdownLabel,
                            ),
                            if (weddingDate.isNotEmpty)
                              Text(
                                weddingDate,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryTC.withAlpha(180),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                _ProgressRuler(progress: plannedProgress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRuler extends StatelessWidget {
  final double progress;
  const _ProgressRuler({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 6,
            child: CustomPaint(
              painter: _RulerPainter(progress: progress.clamp(0.0, 1.0)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(progress * 100).toStringAsFixed(0)}% planned',
          style: const TextStyle(
            fontFamily: 'GoogleSans',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTC,
          ),
        ),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double progress;
  const _RulerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = const Color(0x2E003E45)
      ..style = PaintingStyle.fill;
    final trackRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(999),
    );
    canvas.drawRRect(trackRect, trackPaint);

    if (progress > 0) {
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * progress, size.height),
        const Radius.circular(999),
      );
      final fillPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF006064), Color(0xFF00C2D6)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(fillRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) => old.progress != progress;
}

// Circular progress dial used in venue cards
class ProgressDial extends StatelessWidget {
  final double progress;
  const ProgressDial({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(56, 56),
            painter: _DialPainter(progress: progress.clamp(0.0, 1.0)),
          ),
          Text(
            (progress * 100).toStringAsFixed(0),
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double progress;
  const _DialPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 4.0;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.line;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = AppColors.dialGrad.createShader(rect);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.progress != progress;
}
