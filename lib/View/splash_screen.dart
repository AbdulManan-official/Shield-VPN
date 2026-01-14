import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/logo_painter.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        _controller.forward();
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.offAll(() => const HomeScreen());
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Proportional sizes for any device
    double fontSize = screenWidth * 0.10;
    double iconSize = screenWidth * 0.18;
    double boxPadding = screenWidth * 0.05;
    double boxShadowBlur = screenWidth * 0.09;
    double boxShadowOffset = screenHeight * 0.012;
    double titleUnderlineWidth = fontSize * 2.5;
    double titleUnderlineHeight = screenHeight * 0.012;
    double titleUnderlineBlur = screenWidth * 0.03;
    double verticalSpacing1 = screenHeight * 0.04;
    double verticalSpacing2 = screenHeight * 0.02;
    double textPaddingH = screenWidth * 0.05;
    double smallTextSize = screenWidth * 0.035;
    double progressBarHeight = screenHeight * 0.012;
    double progressBarPaddingH = screenWidth * 0.08;
    double progressBarBottom =
        MediaQuery.of(context).padding.bottom + screenHeight * 0.04;

    // Clamp for extreme small/large screens
    fontSize = fontSize.clamp(18.0, 56.0);
    iconSize = iconSize.clamp(28.0, 100.0);
    boxPadding = boxPadding.clamp(8.0, 32.0);
    boxShadowBlur = boxShadowBlur.clamp(6.0, 32.0);
    boxShadowOffset = boxShadowOffset.clamp(2.0, 16.0);
    titleUnderlineWidth = titleUnderlineWidth.clamp(32.0, 180.0);
    titleUnderlineHeight = titleUnderlineHeight.clamp(2.0, 12.0);
    titleUnderlineBlur = titleUnderlineBlur.clamp(2.0, 12.0);
    verticalSpacing1 = verticalSpacing1.clamp(6.0, 32.0);
    verticalSpacing2 = verticalSpacing2.clamp(4.0, 18.0);
    textPaddingH = textPaddingH.clamp(8.0, 32.0);
    smallTextSize = smallTextSize.clamp(10.0, 18.0);
    progressBarHeight = progressBarHeight.clamp(3.0, 12.0);
    progressBarPaddingH = progressBarPaddingH.clamp(10.0, 64.0);
    progressBarBottom = progressBarBottom.clamp(
        MediaQuery.of(context).padding.bottom + 8.0,
        MediaQuery.of(context).padding.bottom + 64.0);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.bgGradientDark : AppTheme.bgGradientLight,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return SizedBox(
                width: Get.width * 0.8,
                height: Get.width * 0.32,
                child: CustomPaint(
                  painter: VpnLogoPainter(
                    progress: _controller.value,
                    isDarkMode: isDark,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}