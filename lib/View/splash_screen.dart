import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/logo_painter.dart';
import 'Widgets/navbar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  // late AnimationController _fadeController;
  // late Animation<double> _fadeIn;
  // late AnimationController _barController;
  // late Animation<double> _barAnimation;

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
          Get.offAll(() => const BottomNavigator());
        });
      }
    });

    // _fadeController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(seconds: 1),
    // );
    // _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    // _fadeController.repeat();

    // _barController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(milliseconds: 2000),
    // );
    // _barAnimation =
    //     CurvedAnimation(parent: _barController, curve: Curves.easeInOut);
    // _barController.repeat();
  }

  @override
  void dispose() {
    // _fadeController.dispose();
    // _barController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
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
      backgroundColor: const Color(0xFF1A1A2E),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF20E5C7),
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return SizedBox(
                width: Get.width * 0.8,
                height: Get.width * 0.32,
                child: CustomPaint(
                  painter: VpnMaxLogoPainter(progress: _controller.value),
                ),
              );
            },
          ),
        ),
        // child: Stack(
        //   children: [
        //     FadeTransition(
        //       opacity: _fadeIn,
        //       child: Center(
        //         child: Column(
        //           mainAxisAlignment: MainAxisAlignment.center,
        //           children: [
        //             Container(
        //               padding: EdgeInsets.all(boxPadding),
        //               decoration: BoxDecoration(
        //                 shape: BoxShape.circle,
        //                 color: Colors.white.withValues(alpha: 0.07),
        //                 boxShadow: [
        //                   BoxShadow(
        //                     color: theme.colorScheme.secondary
        //                         .withValues(alpha: 0.18),
        //                     blurRadius: boxShadowBlur,
        //                     spreadRadius: 2,
        //                     offset: Offset(0, boxShadowOffset),
        //                   ),
        //                 ],
        //               ),
        //               child: Icon(
        //                 Icons.security_rounded,
        //                 color: theme.colorScheme.secondary,
        //                 size: iconSize,
        //               ),
        //             ),
        //             SizedBox(height: verticalSpacing1 - 10),
        //             Stack(
        //               alignment: Alignment.center,
        //               children: [
        //                 RichText(
        //                   text: TextSpan(
        //                     children: [
        //                       TextSpan(
        //                         text: 'VPN',
        //                         style: TextStyle(
        //                           color: Colors.white,
        //                           fontSize: fontSize,
        //                           fontWeight: FontWeight.bold,
        //                           letterSpacing: 1.2,
        //                           shadows: [
        //                             Shadow(
        //                               color:
        //                                   Colors.black.withValues(alpha: 0.22),
        //                               blurRadius: titleUnderlineBlur,
        //                               offset: Offset(0, 2),
        //                             ),
        //                           ],
        //                         ),
        //                       ),
        //                       TextSpan(
        //                         text: ' Max',
        //                         style: TextStyle(
        //                           color: theme.colorScheme.secondary,
        //                           fontSize: fontSize,
        //                           fontWeight: FontWeight.bold,
        //                           letterSpacing: 1.2,
        //                           shadows: [
        //                             Shadow(
        //                               color: theme.colorScheme.secondary
        //                                   .withValues(alpha: 0.22),
        //                               blurRadius: titleUnderlineBlur,
        //                               offset: Offset(0, 2),
        //                             ),
        //                           ],
        //                         ),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //                 Positioned(
        //                   bottom: -titleUnderlineHeight,
        //                   child: Container(
        //                     width: titleUnderlineWidth,
        //                     height: titleUnderlineHeight,
        //                     decoration: BoxDecoration(
        //                       borderRadius: BorderRadius.circular(8),
        //                       gradient: LinearGradient(
        //                         colors: [
        //                           theme.colorScheme.secondary
        //                               .withValues(alpha: 0.0),
        //                           theme.colorScheme.secondary
        //                               .withValues(alpha: 0.7),
        //                           theme.colorScheme.secondary
        //                               .withValues(alpha: 0.0),
        //                         ],
        //                         stops: const [0.0, 0.5, 1.0],
        //                       ),
        //                       boxShadow: [
        //                         BoxShadow(
        //                           color: theme.colorScheme.secondary
        //                               .withValues(alpha: 0.18),
        //                           blurRadius: titleUnderlineBlur,
        //                           spreadRadius: 1,
        //                         ),
        //                       ],
        //                     ),
        //                   ),
        //                 ),
        //               ],
        //             ),
        //             SizedBox(height: verticalSpacing2),
        //             Padding(
        //               padding: EdgeInsets.symmetric(horizontal: textPaddingH),
        //               child: Text(
        //                 'Ultra Responsive VPN for Secure & Fast Browsing',
        //                 textAlign: TextAlign.center,
        //                 style: TextStyle(
        //                   color: Colors.white70,
        //                   fontSize: smallTextSize,
        //                   fontWeight: FontWeight.w500,
        //                   letterSpacing: 1.05,
        //                 ),
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //     Loading bar at the bottom
        //     Positioned(
        //       left: 0,
        //       right: 0,
        //       bottom: progressBarBottom,
        //       child: Padding(
        //         padding: EdgeInsets.symmetric(horizontal: progressBarPaddingH),
        //         child: AnimatedBuilder(
        //           animation: _barAnimation,
        //           builder: (context, child) {
        //             return ClipRRect(
        //               borderRadius: BorderRadius.circular(8),
        //               child: LinearProgressIndicator(
        //                 minHeight: progressBarHeight,
        //                 value: _barAnimation.value,
        //                 backgroundColor: Colors.white.withValues(alpha: 0.08),
        //                 valueColor: AlwaysStoppedAnimation<Color>(
        //                     theme.colorScheme.secondary),
        //               ),
        //             );
        //           },
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
      ),
    );
  }
}
