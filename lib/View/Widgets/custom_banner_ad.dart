// import 'dart:math';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:vpnprowithjava/utils/app_theme.dart';
//
// class VpnLogoPainter extends CustomPainter {
//   final double progress; // 0.0 → 1.0
//   final bool isDarkMode;
//
//   VpnLogoPainter({
//     required this.progress,
//     this.isDarkMode = true,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;
//
//     // ✅ Shield dimensions
//     final shieldWidth = size.width * 0.45;
//     final shieldHeight = size.height * 0.55;
//     final shieldTop = centerY - shieldHeight / 2;
//     final shieldBottom = centerY + shieldHeight / 2;
//
//     // ✅ Use theme colors
//     final glowColor = isDarkMode ? AppTheme.primaryDark : AppTheme.primaryLight;
//     final lineColor = isDarkMode ? Colors.white : AppTheme.textPrimaryLight;
//     final fillColor = isDarkMode
//         ? AppTheme.primaryDark.withValues(alpha: 0.1)
//         : AppTheme.primaryLight.withValues(alpha: 0.1);
//
//     // Paint styles
//     final glowPaint = Paint()
//       ..color = glowColor
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4.5
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
//
//     final linePaint = Paint()
//       ..color = lineColor
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round;
//
//     final fillPaint = Paint()
//       ..color = fillColor
//       ..style = PaintingStyle.fill;
//
//     // ============ DRAW SHIELD ============
//     final shieldPath = Path();
//
//     // Top center point
//     final topPoint = Offset(centerX, shieldTop);
//
//     // Top left and right points
//     final topLeftX = centerX - shieldWidth / 2;
//     final topRightX = centerX + shieldWidth / 2;
//     final topY = shieldTop + shieldHeight * 0.15;
//
//     // Middle left and right points (widest part)
//     final midLeftX = centerX - shieldWidth / 2;
//     final midRightX = centerX + shieldWidth / 2;
//     final midY = shieldTop + shieldHeight * 0.5;
//
//     // Bottom point (sharp tip)
//     final bottomPoint = Offset(centerX, shieldBottom);
//
//     // Animate the shield drawing from top to bottom
//     final animatedProgress = Curves.easeInOut.transform(progress);
//
//     if (animatedProgress > 0) {
//       shieldPath.moveTo(topPoint.dx, topPoint.dy);
//
//       // Top left curve
//       if (animatedProgress >= 0.15) {
//         shieldPath.quadraticBezierTo(
//           topLeftX,
//           shieldTop,
//           topLeftX,
//           topY,
//         );
//       } else {
//         final t = animatedProgress / 0.15;
//         final controlX = lerpDouble(topPoint.dx, topLeftX, t)!;
//         final controlY = lerpDouble(topPoint.dy, shieldTop, t)!;
//         final endX = lerpDouble(topPoint.dx, topLeftX, t)!;
//         final endY = lerpDouble(topPoint.dy, topY, t)!;
//         shieldPath.quadraticBezierTo(controlX, controlY, endX, endY);
//       }
//
//       // Left side to middle
//       if (animatedProgress >= 0.4) {
//         shieldPath.lineTo(midLeftX, midY);
//       } else if (animatedProgress > 0.15) {
//         final t = (animatedProgress - 0.15) / 0.25;
//         shieldPath.lineTo(
//           lerpDouble(topLeftX, midLeftX, t)!,
//           lerpDouble(topY, midY, t)!,
//         );
//       }
//
//       // Left bottom curve to tip
//       if (animatedProgress >= 0.65) {
//         shieldPath.quadraticBezierTo(
//           midLeftX,
//           shieldBottom - shieldHeight * 0.15,
//           bottomPoint.dx,
//           bottomPoint.dy,
//         );
//       } else if (animatedProgress > 0.4) {
//         final t = (animatedProgress - 0.4) / 0.25;
//         final controlX = midLeftX;
//         final controlY = lerpDouble(midY, shieldBottom - shieldHeight * 0.15, t)!;
//         final endX = lerpDouble(midLeftX, bottomPoint.dx, t)!;
//         final endY = lerpDouble(midY, bottomPoint.dy, t)!;
//         shieldPath.quadraticBezierTo(controlX, controlY, endX, endY);
//       }
//
//       // Right bottom curve from tip
//       if (animatedProgress >= 0.85) {
//         shieldPath.quadraticBezierTo(
//           midRightX,
//           shieldBottom - shieldHeight * 0.15,
//           midRightX,
//           midY,
//         );
//       } else if (animatedProgress > 0.65) {
//         final t = (animatedProgress - 0.65) / 0.2;
//         final controlX = midRightX;
//         final controlY = lerpDouble(shieldBottom - shieldHeight * 0.15, midY, t)!;
//         final endX = lerpDouble(bottomPoint.dx, midRightX, t)!;
//         final endY = lerpDouble(bottomPoint.dy, midY, t)!;
//         shieldPath.quadraticBezierTo(controlX, controlY, endX, endY);
//       }
//
//       // Right side to top
//       if (animatedProgress >= 0.95) {
//         shieldPath.lineTo(topRightX, topY);
//       } else if (animatedProgress > 0.85) {
//         final t = (animatedProgress - 0.85) / 0.1;
//         shieldPath.lineTo(
//           lerpDouble(midRightX, topRightX, t)!,
//           lerpDouble(midY, topY, t)!,
//         );
//       }
//
//       // Top right curve back to center
//       if (animatedProgress >= 1.0) {
//         shieldPath.quadraticBezierTo(
//           topRightX,
//           shieldTop,
//           topPoint.dx,
//           topPoint.dy,
//         );
//         shieldPath.close();
//       } else if (animatedProgress > 0.95) {
//         final t = (animatedProgress - 0.95) / 0.05;
//         final controlX = topRightX;
//         final controlY = shieldTop;
//         final endX = lerpDouble(topRightX, topPoint.dx, t)!;
//         final endY = lerpDouble(topY, topPoint.dy, t)!;
//         shieldPath.quadraticBezierTo(controlX, controlY, endX, endY);
//       }
//
//       // Draw shield with fill and stroke
//       if (progress >= 1.0) {
//         canvas.drawPath(shieldPath, fillPaint);
//       }
//       canvas.drawPath(shieldPath, glowPaint);
//       canvas.drawPath(shieldPath, linePaint);
//     }
//
//     // ============ DRAW "V" CHECKMARK INSIDE SHIELD ============
//     if (progress >= 0.5) {
//       final checkProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
//       final checkPaint = Paint()
//         ..color = lineColor
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 4
//         ..strokeCap = StrokeCap.round;
//
//       final checkGlowPaint = Paint()
//         ..color = glowColor
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 6
//         ..strokeCap = StrokeCap.round
//         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
//
//       // Check mark points
//       final checkStartX = centerX - shieldWidth * 0.25;
//       final checkStartY = centerY;
//       final checkMidX = centerX - shieldWidth * 0.05;
//       final checkMidY = centerY + shieldHeight * 0.15;
//       final checkEndX = centerX + shieldWidth * 0.25;
//       final checkEndY = centerY - shieldHeight * 0.15;
//
//       final checkPath = Path();
//       checkPath.moveTo(checkStartX, checkStartY);
//
//       if (checkProgress < 0.5) {
//         // First half of check
//         final t = checkProgress / 0.5;
//         checkPath.lineTo(
//           lerpDouble(checkStartX, checkMidX, t)!,
//           lerpDouble(checkStartY, checkMidY, t)!,
//         );
//       } else {
//         // Complete first half
//         checkPath.lineTo(checkMidX, checkMidY);
//         // Second half of check
//         final t = (checkProgress - 0.5) / 0.5;
//         checkPath.lineTo(
//           lerpDouble(checkMidX, checkEndX, t)!,
//           lerpDouble(checkMidY, checkEndY, t)!,
//         );
//       }
//
//       canvas.drawPath(checkPath, checkGlowPaint);
//       canvas.drawPath(checkPath, checkPaint);
//     }
//
//     // ============ DRAW TEXT ============
//     if (progress >= 0.8) {
//       final textProgress = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
//       final textPainter = TextPainter(
//         text: TextSpan(
//           text: 'SHIELD VPN',
//           style: TextStyle(
//             color: lineColor.withValues(alpha: textProgress),
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 2,
//             shadows: [
//               Shadow(
//                 color: glowColor.withValues(alpha: textProgress * 0.6),
//                 blurRadius: 8,
//               ),
//             ],
//           ),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//
//       textPainter.layout();
//       textPainter.paint(
//         canvas,
//         Offset(
//           centerX - textPainter.width / 2,
//           shieldBottom + 25,
//         ),
//       );
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant VpnLogoPainter oldDelegate) {
//     return oldDelegate.progress != progress || oldDelegate.isDarkMode != isDarkMode;
//   }
// }