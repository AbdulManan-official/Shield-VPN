import 'dart:math';

import 'package:flutter/material.dart';

// --- Enhanced Animation Widgets ---
class FloatingHorizontalLines extends StatelessWidget {
  final Animation<double> controller;
  final double size;
  final Color color;

  const FloatingHorizontalLines({
    super.key,
    required this.controller,
    this.size = 280,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(
        MediaQuery.of(context).size.width,
        size,
      ),
      painter: _FloatingHorizontalLinesPainter(
        progress: controller.value,
        color: color,
        screenWidth: MediaQuery.of(context).size.width,
      ),
    );
  }
}

class _FloatingHorizontalLinesPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double screenWidth;

  _FloatingHorizontalLinesPainter({
    required this.progress,
    required this.color,
    required this.screenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.square;

    final Paint outerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    final Paint innerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final double centerY = size.height / 2;
    final double minY = centerY - 90;
    final double maxY = centerY + 90;
    final double screenLeft = -20.0;
    final double screenRight = screenWidth + 20.0;

    final List<double> yOffsets = [
      minY + 10,
      minY + 35,
      minY + 60,
      centerY - 40,
      centerY - 15,
      centerY + 15,
      centerY + 40,
      maxY - 60,
      maxY - 35,
      maxY - 10,
    ];

    for (int i = 0; i < yOffsets.length; i++) {
      double t = (progress * 3.5 + i * 0.2) % 1.0;
      double dx = (screenRight - screenLeft) * t;

      double fade = 1.0;
      if (t < 0.12) fade = (t / 0.12) * (t / 0.12) * (t / 0.12);
      if (t > 0.88) {
        fade = ((1.0 - t) / 0.12) * ((1.0 - t) / 0.12) * ((1.0 - t) / 0.12);
      }

      final mainOpacity = 0.85 + 0.15 * fade;
      paint.color = color.withValues(alpha: mainOpacity);

      final outerGlowOpacity = 0.15 + 0.25 * fade;
      outerGlowPaint.color = color.withValues(alpha: outerGlowOpacity);

      final innerGlowOpacity = 0.35 + 0.45 * fade;
      innerGlowPaint.color = color.withValues(alpha: innerGlowOpacity);

      double lineLength = 55 + 30 * sin(i + progress * 3.5 * pi);

      final startPoint = Offset(screenLeft + dx, yOffsets[i]);
      final endPoint = Offset(screenLeft + dx + lineLength, yOffsets[i]);

      canvas.drawLine(startPoint, endPoint, outerGlowPaint);
      canvas.drawLine(startPoint, endPoint, innerGlowPaint);
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingHorizontalLinesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class FloatingLeftWindLines extends StatelessWidget {
  final Animation<double> controller;
  final double size;
  final Color color;

  const FloatingLeftWindLines({
    super.key,
    required this.controller,
    this.size = 280,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FloatingLeftWindLinesPainter(
        progress: controller.value,
        color: color,
      ),
    );
  }
}

class _FloatingLeftWindLinesPainter extends CustomPainter {
  final double progress;
  final Color color;

  _FloatingLeftWindLinesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double minX = centerX - 90;
    final double maxX = centerX + 90;

    final List<Offset> positions = [
      Offset(minX + 20, centerY - 60),
      Offset(minX + 40, centerY - 20),
      Offset(minX + 15, centerY + 20),
      Offset(minX + 35, centerY + 60),
    ];

    for (int i = 0; i < positions.length; i++) {
      double t = (progress + i * 0.2) % 1.0;
      double dx = (maxX - minX) * t * 0.6;

      double fade = 1.0;
      if (t < 0.2) fade = t / 0.2;
      if (t > 0.8) fade = (1.0 - t) / 0.2;

      paint.color = color.withValues(alpha: 0.2 + 0.4 * fade);

      double lineLength = 25 + 10 * sin(i + progress * 3 * pi);

      canvas.drawLine(
        Offset(positions[i].dx + dx, positions[i].dy),
        Offset(positions[i].dx + dx + lineLength, positions[i].dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingLeftWindLinesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}