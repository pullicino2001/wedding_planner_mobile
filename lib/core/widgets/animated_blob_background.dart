import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBlobBackground extends StatefulWidget {
  const AnimatedBlobBackground({super.key});

  @override
  State<AnimatedBlobBackground> createState() =>
      _AnimatedBlobBackgroundState();
}

class _AnimatedBlobBackgroundState extends State<AnimatedBlobBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _BlobPainter(_controller.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t;
  static const _tau = 2 * math.pi;

  const _BlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Solid background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF2F8FA),
    );

    // Blob 1 — teal, drifts around upper-centre
    _blob(
      canvas,
      Offset(
        w * 0.35 + w * 0.28 * math.sin(_tau * t * 1.0),
        h * 0.25 + h * 0.20 * math.cos(_tau * t * 0.7),
      ),
      180,
      const Color(0x330099AE),
      85,
    );

    // Blob 2 — deep teal, lower-right anchor
    _blob(
      canvas,
      Offset(
        w * 0.72 + w * 0.22 * math.sin(_tau * t * 0.8 + 1.2),
        h * 0.65 + h * 0.24 * math.cos(_tau * t * 1.1 + 0.5),
      ),
      155,
      const Color(0x26006064),
      75,
    );

    // Blob 3 — sky blue, mid-left wanderer
    _blob(
      canvas,
      Offset(
        w * 0.22 + w * 0.20 * math.sin(_tau * t * 1.3 + 2.4),
        h * 0.52 + h * 0.28 * math.cos(_tau * t * 0.9 + 1.8),
      ),
      140,
      const Color(0x1E00C2D6),
      70,
    );

    // Blob 4 — ice blue, lower-centre floater
    _blob(
      canvas,
      Offset(
        w * 0.55 + w * 0.24 * math.sin(_tau * t * 0.6 + 3.8),
        h * 0.80 + h * 0.14 * math.cos(_tau * t * 1.4 + 2.1),
      ),
      120,
      const Color(0x1AB2EBF2),
      60,
    );
  }

  void _blob(
      Canvas canvas, Offset center, double radius, Color color, double sigma) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
    );
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
