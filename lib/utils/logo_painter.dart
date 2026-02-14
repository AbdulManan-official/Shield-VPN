import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class VpnLogoPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final bool isDarkMode;

  VpnLogoPainter({
    required this.progress,
    this.isDarkMode = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Colors based on theme
    final glowColor = isDarkMode ? const Color(0xFF00D9FF) : const Color(0xFF0095FF);
    final lineColor = isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
    final accentColor = isDarkMode ? const Color(0xFF00FFA3) : const Color(0xFFFF6B35);

    // Animation phases
    final particlePhase = (progress * 1.2).clamp(0.0, 1.0);
    final circlePhase = ((progress - 0.2) * 1.5).clamp(0.0, 1.0);
    final textPhase = ((progress - 0.4) * 1.8).clamp(0.0, 1.0);
    final glowPhase = ((progress - 0.6) * 2.5).clamp(0.0, 1.0);
    final subtitlePhase = ((progress - 0.5) * 2.0).clamp(0.0, 1.0);

    // ---------------- PARTICLE BURST EFFECT ----------------
    if (particlePhase > 0) {
      _drawParticles(canvas, centerX, centerY, particlePhase, glowColor, accentColor);
    }

    // ---------------- EXPANDING CIRCLES ----------------
    if (circlePhase > 0) {
      _drawExpandingCircles(canvas, centerX, centerY, circlePhase, glowColor, lineColor);
    }

    // ---------------- ANIMATED TEXT WITH EFFECTS ----------------
    if (textPhase > 0) {
      _drawTextWithEffects(canvas, centerX, centerY, textPhase, glowPhase, lineColor, glowColor);
    }

    // ---------------- SUBTITLE TEXT ----------------
    if (subtitlePhase > 0) {
      _drawSubtitle(canvas, centerX, centerY, subtitlePhase, lineColor);
    }

    // ---------------- CONNECTING LINES ----------------
    if (textPhase > 0.5) {
      _drawConnectingLines(canvas, centerX, centerY, textPhase, glowColor, lineColor);
    }
  }

  void _drawParticles(Canvas canvas, double centerX, double centerY,
      double phase, Color glowColor, Color accentColor) {
    final particleCount = 16;
    final maxRadius = 120.0 * phase;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi;
      final distance = maxRadius * (0.6 + (i % 3) * 0.2);

      final x = centerX + cos(angle) * distance;
      final y = centerY + sin(angle) * distance;

      final size = 3.0 - (phase * 2);
      final opacity = (1 - phase) * 0.8;

      final particlePaint = Paint()
        ..color = (i % 2 == 0 ? glowColor : accentColor).withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(x, y), size, particlePaint);
    }
  }

  void _drawExpandingCircles(Canvas canvas, double centerX, double centerY,
      double phase, Color glowColor, Color lineColor) {

    // Multiple circle waves
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.15;
      final circlePhase = ((phase - delay) / (1 - delay)).clamp(0.0, 1.0);

      if (circlePhase > 0) {
        final radius = 40.0 + (circlePhase * 60.0);
        final opacity = (1 - circlePhase) * 0.6;

        // Outer glow
        final glowPaint = Paint()
          ..color = glowColor.withOpacity(opacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12);

        canvas.drawCircle(Offset(centerX, centerY), radius, glowPaint);

        // Main circle
        final circlePaint = Paint()
          ..color = lineColor.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(Offset(centerX, centerY), radius, circlePaint);
      }
    }

    // Central pulse
    if (phase > 0.5) {
      final pulsePhase = ((phase - 0.5) / 0.5);
      final pulseRadius = 15.0 + (sin(pulsePhase * pi) * 5);

      final pulsePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            glowColor.withOpacity(0.6),
            glowColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: pulseRadius,
        ));

      canvas.drawCircle(Offset(centerX, centerY), pulseRadius, pulsePaint);
    }
  }

  void _drawTextWithEffects(Canvas canvas, double centerX, double centerY,
      double textPhase, double glowPhase, Color lineColor, Color glowColor) {

    // Calculate text metrics first
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Shield VPN',
        style: TextStyle(
          color: lineColor.withOpacity(textPhase),
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Animated glow effect
    final glowIntensity = 8 + (sin(glowPhase * pi * 4) * 4);

    final glowTextPainter = TextPainter(
      text: TextSpan(
        text: 'Shield VPN',
        style: TextStyle(
          color: lineColor.withOpacity(textPhase),
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
          shadows: [
            Shadow(
              color: glowColor.withOpacity(0.8 * textPhase),
              blurRadius: glowIntensity,
            ),
            Shadow(
              color: glowColor.withOpacity(0.4 * textPhase),
              blurRadius: glowIntensity * 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    glowTextPainter.layout();

    // Scale and fade animation
    final scale = 0.7 + (textPhase * 0.3);
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.scale(scale);
    canvas.translate(-glowTextPainter.width / 2, -glowTextPainter.height / 2);

    glowTextPainter.paint(canvas, Offset.zero);
    canvas.restore();

    // Sliding underline
    if (textPhase > 0.6) {
      final underlinePhase = ((textPhase - 0.6) / 0.4);
      final underlineWidth = textPainter.width * underlinePhase;

      final gradient = LinearGradient(
        colors: [
          glowColor.withOpacity(0),
          glowColor.withOpacity(0.8),
          glowColor.withOpacity(0),
        ],
      );

      final underlinePaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(centerX - underlineWidth / 2, centerY + 18, underlineWidth, 3),
        )
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawLine(
        Offset(centerX - underlineWidth / 2, centerY + 20),
        Offset(centerX + underlineWidth / 2, centerY + 20),
        underlinePaint,
      );
    }
  }

  void _drawSubtitle(Canvas canvas, double centerX, double centerY,
      double subtitlePhase, Color lineColor) {

    final subtitlePainter = TextPainter(
      text: TextSpan(
        text: 'Secure Proxy Connection',
        style: TextStyle(
          color: lineColor.withOpacity(subtitlePhase * 0.7), // Slightly transparent
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subtitlePainter.layout();

    // Position below Shield VPN text (about 35 pixels down)
    final subtitleY = centerY + 35;

    // Slide up effect
    final slideOffset = (1 - subtitlePhase) * 10;

    canvas.save();
    canvas.translate(
      centerX - subtitlePainter.width / 2,
      subtitleY + slideOffset,
    );

    subtitlePainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawConnectingLines(Canvas canvas, double centerX, double centerY,
      double textPhase, Color glowColor, Color lineColor) {

    final linePhase = ((textPhase - 0.5) / 0.5).clamp(0.0, 1.0);
    final lineLength = 60.0 * linePhase;

    // Left and right decorative lines
    final positions = [
      {'x': -90.0, 'y': 0.0, 'angle': pi},
      {'x': 90.0, 'y': 0.0, 'angle': 0.0},
    ];

    for (var pos in positions) {
      final startX = centerX + (pos['x'] as double);
      final endX = startX + (cos(pos['angle'] as double) * lineLength);

      // Glow
      final glowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            glowColor.withOpacity(0),
            glowColor.withOpacity(0.6 * linePhase),
          ],
        ).createShader(Rect.fromLTWH(
          min(startX, endX), centerY, lineLength, 1,
        ))
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawLine(
        Offset(startX, centerY + (pos['y'] as double)),
        Offset(endX, centerY + (pos['y'] as double)),
        glowPaint,
      );

      // Main line
      final linePaint = Paint()
        ..color = lineColor.withOpacity(0.8 * linePhase)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(startX, centerY + (pos['y'] as double)),
        Offset(endX, centerY + (pos['y'] as double)),
        linePaint,
      );

      // End dots
      final dotPaint = Paint()
        ..color = glowColor.withOpacity(linePhase)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(
        Offset(endX, centerY + (pos['y'] as double)),
        3,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VpnLogoPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDarkMode != isDarkMode;
  }
}