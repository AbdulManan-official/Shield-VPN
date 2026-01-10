
import 'dart:math';

import 'package:flutter/material.dart';

class RadarLoadingAnimation extends StatelessWidget {
  final Animation<double> controller;
  final double size;
  final Color color;

  const RadarLoadingAnimation({
    super.key,
    required this.controller,
    this.size = 250,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RadarLoadingPainter(progress: controller.value, color: color),
    );
  }
}

class _RadarLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarLoadingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw enhanced radar circles
    final Paint circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 1; i <= 4; i++) {
      circlePaint.color = color.withValues(alpha: 0.08 + (i * 0.03));
      canvas.drawCircle(center, radius * i / 4, circlePaint);
    }

    // Draw enhanced radar sweep
    final Paint sweepPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.1),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        startAngle: 0,
        endAngle: 2 * pi,
        transform: GradientRotation(progress * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Draw scanning line
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * 2 * pi);

    final Paint linePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(0, 0), Offset(radius - 30, 0), linePaint);

    canvas.restore();

    // Draw center dot
    final Paint centerPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarLoadingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
