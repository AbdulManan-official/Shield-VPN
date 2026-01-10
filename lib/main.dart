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
import 'package:vpnprowithjava/utils/app_theme.dart'; // ✅ Import new theme
import 'package:workmanager/workmanager.dart';

import 'View/subscription_manager.dart';
import 'utils/initialization_helper.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Set system UI overlay with transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Will auto-adjust with theme
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

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
      ChangeNotifierProvider(create: (_) => VpnProvider()),
      ChangeNotifierProvider(create: (_) => VpnConnectionProvider()),
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
      title: 'VPN Max',
      debugShowCheckedModeBanner: false,

      // ✅ NEW THEME SYSTEM - Auto switches based on system dark/light mode
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Automatically follows device theme

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
          child: child!,
        );
      },
    );
  }
}