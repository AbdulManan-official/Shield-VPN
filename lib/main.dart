import 'dart:async';
import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpnprowithjava/View/splash_screen.dart';
import 'package:vpnprowithjava/providers/ads_controller.dart';
import 'package:vpnprowithjava/providers/apps_provider.dart';
import 'package:vpnprowithjava/providers/device_detail_provider.dart';
import 'package:vpnprowithjava/providers/servers_provider.dart';
import 'package:vpnprowithjava/providers/vpn_connection_provider.dart';
import 'package:vpnprowithjava/providers/vpn_provider.dart';
import 'package:vpnprowithjava/utils/preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'View/subscription_manager.dart';
import 'utils/initialization_helper.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.grey[900],
  ));
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Workmanager().initialize(callbackDispatcher);

  await Prefs.init();

  Get.put(SubscriptionController(), permanent: true);
  Get.put(AppsController(), permanent: true);
  Get.put(AdsController(), permanent: true);

  initializeAdsAndConsent();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((_) {
    runApp(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ServersProvider()),
      ChangeNotifierProvider(create: (_) => DeviceDetailProvider()),
      // ChangeNotifierProvider(create: (_) => AppsProvider()),
      ChangeNotifierProvider(create: (_) => VpnProvider()),
      ChangeNotifierProvider(create: (_) => VpnConnectionProvider()),
      // ChangeNotifierProvider(create: (_) => AdsProvider()..loadBanner()),
      // ChangeNotifierProvider(create: (_) => SubscriptionManager()..loadSubscriptionStatus()),
    ], child: const MyApp()));
  });
}

Future<void> initializeAdsAndConsent() async {
  final AdsController adsController = Get.find();
  final initHelper = InitializationHelper();
  await initHelper.initialize();
  adsController.preloadInterstitial();
  adsController.loadBanner2();
  adsController.loadBanner();
}

// Add this callback function (outside your class)
// @pragma('vm:entry-point')
// void disconnectVpnCallback() async {
//   Workmanager().executeTask((task, inputData) async {
//     switch (task) {
//       case "disconnectVpnTask":
//         try {
//           final openVpn = OpenVPN();
//           openVpn.disconnect();
//           final prefs = await SharedPreferences.getInstance();
//           await prefs.setBool('isConnected', false);
//           debugPrint("VPN disconnected by background task");
//           return Future.value(true);
//         } catch (e) {
//           debugPrint("Error disconnecting VPN in background: $e");
//           return Future.value(false);
//         }

//       default:
//         return Future.value(false);
//     }
//   });
// }

/// ✅ Dispatcher that Workmanager calls
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "disconnectVpnTask":
        return await disconnectVpnCallback(); // returns Future<bool>
      default:
        return Future.value(false);
    }
  });
}

/// ✅ Actual VPN disconnect logic
@pragma('vm:entry-point')
Future<bool> disconnectVpnCallback() async {
  try {
    final openVpn = OpenVPN();
    if (await openVpn.isConnected()) {
      openVpn.disconnect();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isConnected', false);

    debugPrint("VPN disconnected by background task ✅");
    return true;
  } catch (e) {
    debugPrint("Error disconnecting VPN in background: $e");
    return false;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Centralized purchase handling
  // Future<void> initializePurchases(BuildContext context) async {
  //   try {
  //     final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  //     final bool available = await _inAppPurchase.isAvailable();
  //     if (!available) {
  //       log('InAppPurchase not available');
  //       return;
  //     }

  //     // Query product details
  //     final Set<String> ids = {
  //       'vpnmax_999_1m',
  //       'vpnmax_99_1year',
  //       'one_time_purchase',
  //     };
  //     ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(ids);
  //     if (response.error != null) {
  //       log('Error querying product details: ${response.error}');
  //       return;
  //     }

  //     // Set up a single purchaseStream listener
  //     _inAppPurchase.purchaseStream.listen((List<PurchaseDetails> purchaseDetailsList) {
  //       for (var purchaseDetails in purchaseDetailsList) {
  //         if (purchaseDetails.status == PurchaseStatus.purchased ||
  //             purchaseDetails.status == PurchaseStatus.restored) {
  //           Prefs.setBool('isSubscribed', true);
  //           Provider.of<AdsProvider>(context, listen: false).setSubscriptionStatus();
  //           log('Subscription active: ${purchaseDetails.productID}');
  //         } else if (purchaseDetails.status == PurchaseStatus.error) {
  //           Prefs.setBool('isSubscribed', false);
  //           Provider.of<AdsProvider>(context, listen: false).setSubscriptionStatus();
  //           log('Purchase error: ${purchaseDetails.error}');
  //         } else if (purchaseDetails.status == PurchaseStatus.canceled) {
  //           Prefs.setBool('isSubscribed', false);
  //           Provider.of<AdsProvider>(context, listen: false).setSubscriptionStatus();
  //           log('Purchase canceled');
  //         }

  //         // Complete purchase to avoid pending state
  //         if (purchaseDetails.pendingCompletePurchase) {
  //           _inAppPurchase.completePurchase(purchaseDetails);
  //         }
  //       }
  //     });
  //   } catch (e) {
  //     debugPrint('Error initializing purchases: $e');
  //   }
  // }

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  void initState() {
    super.initState();
    _initPurchaseListener();
  }

  void _initPurchaseListener() async {
    final InAppPurchase inAppPurchase = InAppPurchase.instance;
    final bool available = await inAppPurchase.isAvailable();
    if (!available) {
      log('InAppPurchase not available');
      return;
    }

    // Initialize the purchase stream listener
    _purchaseSubscription = inAppPurchase.purchaseStream.listen(
      (purchaseDetailsList) {
        _processPurchases(purchaseDetailsList);
      },
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (error) => log('Purchase stream error: $error'),
    );

    // Restore existing purchases
    await inAppPurchase.restorePurchases();
  }

  void _processPurchases(List<PurchaseDetails> purchaseDetailsList) {
    bool hasActiveSubscription = false;

    for (final purchaseDetails in purchaseDetailsList) {
      // Handle purchase status
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        hasActiveSubscription = true;
        log('Valid purchase: ${purchaseDetails.productID}');
      }

      // Complete pending purchases
      if (purchaseDetails.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }

    // Update subscription status based on all purchases
    final newStatus =
        hasActiveSubscription || _checkOtherSubscriptionConditions();
    Prefs.setBool('isSubscribed', newStatus);
    if (mounted) {
      final AdsController adsController = Get.find();
      adsController.setSubscriptionStatus();
      // Provider.of<AdsProvider>(context, listen: false).setSubscriptionStatus();
    }
  }

  bool _checkOtherSubscriptionConditions() {
    // Add custom logic here if needed
    return false;
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: rootNavigatorKey,
      navigatorObservers: <NavigatorObserver>[observer],
      title: 'VPN Max - Ultra Responsive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: ThemeData.dark().textTheme.apply(
              fontSizeFactor: 1.0,
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8A2BE2),
          secondary: Color(0xFF20E5C7),
          surface: Color(0xFF16213E),
        ),
      ),
      home: const SplashScreen(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;

        double textScaleFactor = 1.0;
        if (screenWidth < 320) {
          textScaleFactor = 0.75;
        } else if (screenWidth < 360) {
          textScaleFactor = 0.80;
        } else if (screenWidth < 480) {
          textScaleFactor = 0.90;
        } else if (screenWidth > 1024) {
          textScaleFactor = 1.1;
        }

        final currentTextScale = mediaQuery.textScaler.scale(1.0);
        final clampedTextScale = (currentTextScale * textScaleFactor).clamp(
          0.7,
          1.4,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(clampedTextScale),
            padding: EdgeInsets.only(
              top: mediaQuery.padding.top,
              bottom: mediaQuery.padding.bottom.clamp(0, screenHeight * 0.1),
              left: mediaQuery.padding.left,
              right: mediaQuery.padding.right,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                ],
              ),
            ),
            child: child!,
          ),
        );
      },
    );
  }
}

//
// import 'package:flutter/material.dart';
// import 'dart:math' as math;
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child: AnimatedVFNMaxLogo(),
//         ),
//       ),
//     );
//   }
// }
//
// class AnimatedVFNMaxLogo extends StatefulWidget {
//   @override
//   _AnimatedVFNMaxLogoState createState() => _AnimatedVFNMaxLogoState();
// }
//
// class _AnimatedVFNMaxLogoState extends State<AnimatedVFNMaxLogo>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 3),
//       vsync: this,
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return CustomPaint(
//           size: Size(300, 300),
//           painter: VFNMaxPainter(_controller.value),
//         );
//       },
//     );
//   }
// }
//
// class VFNMaxPainter extends CustomPainter {
//   final double animationValue;
//   static const Color accentTeal = Color(0xFF20E5C7);
//   static const Color paintColor = Colors.blueAccent;
//
//   VFNMaxPainter(this.animationValue);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = size.width * 0.35;
//
//     // Paint for the main circles with glow effect
//     final circlePaint = Paint()
//       ..color = Colors.blue
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0
//       ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
//
//     // Draw the arcs instead of full circles
//     final rect = Rect.fromCircle(center: center, radius: radius);
//     final innerRect = Rect.fromCircle(center: center, radius: radius * 0.93);
//
//     // Define arc segments (gaps where connection lines are)
//     // Each arc segment defined by start angle and sweep angle
//     final rotationOffset = animationValue * 2 * math.pi;
//
//     // Arc 1: From right side, going clockwise, stopping before top-left connection
//     canvas.drawArc(rect, -0.4 + rotationOffset, 1.55, false, circlePaint);
//     canvas.drawArc(innerRect, -0.4 + rotationOffset, 1.55, false, circlePaint);
//
//     // Arc 2: Small arc between top connections
//     canvas.drawArc(rect, 1.9 + rotationOffset, 0.5, false, circlePaint);
//     canvas.drawArc(innerRect, 1.9 + rotationOffset, 0.5, false, circlePaint);
//
//     // Arc 3: Bottom arc
//     canvas.drawArc(rect, 3.8 + rotationOffset, 2.0, false, circlePaint);
//     canvas.drawArc(innerRect, 3.8 + rotationOffset, 2.0, false, circlePaint);
//
//     // Paint for the connection lines (without glow)
//     final linePaint = Paint()
//       ..color = Colors.blue
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0
//       ..strokeCap = StrokeCap.round;
//
//     // Paint for connection lines with glow
//     final lineGlowPaint = Paint()
//       ..color = Colors.blue
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0
//       ..strokeCap = StrokeCap.round
//       ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
//
//     // Paint for dots
//     final dotPaint = Paint()
//       ..color = Colors.blue
//       ..style = PaintingStyle.fill
//       ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);
//
//     final dotOutlinePaint = Paint()
//       ..color = Colors.blue
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     // Define the 3 connection points and their angles (matching the image)
//     final connections = [
//       {'angle': math.pi * 1, 'length': 45.0}, // Top-left
//       {'angle': math.pi * 0.3, 'length': 45.0}, // Top-right
//       {'angle': math.pi * 1.6, 'length': 45.0}, // Bottom-right
//     ];
//
//     // Draw the connection lines
//     for (var connection in connections) {
//       final angle = (connection['angle'] as double) + rotationOffset;
//       final length = connection['length'] as double;
//
//       // Point on the outer circle
//       final circlePoint = Offset(
//         center.dx + radius * math.cos(angle),
//         center.dy + radius * math.sin(angle),
//       );
//
//       // End point of the line
//       final endPoint = Offset(
//         center.dx + (radius + length) * math.cos(angle),
//         center.dy + (radius + length) * math.sin(angle),
//       );
//
//       // Draw line with glow
//       canvas.drawLine(circlePoint, endPoint, lineGlowPaint);
//
//       // Draw dot at the end
//       canvas.drawCircle(endPoint, 6, dotPaint);
//       canvas.drawCircle(endPoint, 6, dotOutlinePaint);
//     }
//
//     // Draw horizontal lines extending left and right with glow
//     final horizontalLinePaint = Paint()
//       ..color = Colors.blue
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0
//       ..strokeCap = StrokeCap.round
//       ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
//
//     // Left line with dot
//     final leftLineStart = Offset(center.dx - radius - 20, center.dy);
//     final leftLineEnd = Offset(20, center.dy);
//     canvas.drawLine(leftLineStart, leftLineEnd, horizontalLinePaint);
//     canvas.drawCircle(leftLineEnd, 6, dotPaint);
//     canvas.drawCircle(leftLineEnd, 6, dotOutlinePaint);
//
//     // Right line with dot
//     final rightLineStart = Offset(center.dx + radius + 20, center.dy);
//     final rightLineEnd = Offset(size.width - 20, center.dy);
//     canvas.drawLine(rightLineStart, rightLineEnd, horizontalLinePaint);
//     canvas.drawCircle(rightLineEnd, 6, dotPaint);
//     canvas.drawCircle(rightLineEnd, 6, dotOutlinePaint);
//
//     // Draw text
//     final textPainterVPN = TextPainter(
//       text: TextSpan(
//         text: 'VPN ',
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: 36,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 1,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     textPainterVPN.layout();
//
//     final textPainterMax = TextPainter(
//       text: TextSpan(
//         text: 'Max',
//         style: TextStyle(
//           color: Colors.green,
//           fontSize: 36,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 1,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     textPainterMax.layout();
//
//     final totalWidth = textPainterVPN.width + textPainterMax.width;
//     final textStart = center.dx - totalWidth / 2;
//
//     textPainterVPN.paint(
//       canvas,
//       Offset(textStart, center.dy - textPainterVPN.height / 2),
//     );
//
//     textPainterMax.paint(
//       canvas,
//       Offset(textStart + textPainterVPN.width, center.dy - textPainterMax.height / 2),
//     );
//   }
//
//   @override
//   bool shouldRepaint(VFNMaxPainter oldDelegate) => true;
// }