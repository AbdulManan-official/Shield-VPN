// import 'dart:async';
// import 'dart:io';
// import 'dart:math';
//
// import 'package:auto_size_text/auto_size_text.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:http/http.dart' as http;
// import 'package:openvpn_flutter/openvpn_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vpnprowithjava/View/Widgets/floating_lines_animation.dart';
// import 'package:vpnprowithjava/View/Widgets/radar_loading_animation.dart';
// import 'package:vpnprowithjava/View/allowed_app_screen.dart';
// import 'package:vpnprowithjava/View/premium_access_screen.dart';
// import 'package:vpnprowithjava/View/server_tabs.dart';
// import 'package:vpnprowithjava/View/splash_screen.dart';
// import 'package:vpnprowithjava/View/subscription_manager.dart';
// // import 'package:vpnprowithjava/utils/colors.dart';
// import 'package:vpnprowithjava/utils/custom_toast.dart';
// import 'package:workmanager/workmanager.dart';
// import 'package:vpnprowithjava/utils/app_theme.dart';
// import '../providers/ads_controller.dart';
// import '../providers/apps_provider.dart';
// import '../providers/servers_provider.dart';
// import '../providers/vpn_connection_provider.dart';
// import '../utils/analytics_service.dart';
// import '../utils/vpn_app_review.dart';
// import 'more_screen.dart';
//
// // Extension for responsive design
// extension ResponsiveContext on BuildContext {
//   bool get hasLimitedHeight => MediaQuery.of(this).size.height < 700;
// }
//
// Color _getTextColor(BuildContext context, bool connected) {
//   if (connected) return Colors.white;
//   return AppTheme.getTextPrimaryColor(context);
// }
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
//
// class _HomeScreenState extends State<HomeScreen>
//     with TickerProviderStateMixin, WidgetsBindingObserver {
//   // === FIELDS ===
//   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
//   Timer? _debounceTimer;
//   bool _isCheckingConnection = false;
//   bool _hasRealInternet = true;
//   int _failureCount = 0;
//   final int _maxFailuresBeforeDialog = 2; // set to 1 for testing
//   bool _isDialogShowing = false;
//
//   // var v5;
//   // var data;
//   bool _isLoading = false;
//   bool _isConnected = false;
//
//   // int _progressPercentage = 0;
//   // Animation controllers for new UI
//   late AnimationController _animationController;
//   late AnimationController _radarController;
//
//   // blink
//   late AnimationController _blinkController;
//   late Animation<double> _blinkAnimation;
//
//   bool _isWaitingForServer = false;
//
//   // Timer? _waitingTimer;
//   bool _connectionCompleted = false;
//
//   Timer? _progressTimer;
//
//   double _progress = 0;
//   double _targetProgress = 90;
//
//   static const int _maxWaitSeconds = 15;
//   int _waitedSeconds = 0;
//
//   late ServersProvider _myProvider;
//
//   // late SubscriptionManager subscriptionManager;
//
//   final SubscriptionController subscriptionManager = Get.find();
//   final ratingService = RatingService();
//
//
//
//   @override
//   Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
//     if (state == AppLifecycleState.detached) {
//       final openVpn = OpenVPN();
//       if (await openVpn.isConnected()) {
//         openVpn.disconnect();
//       }
//
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool('isConnected', false);
//
//       _scheduleDisconnectTask();
//     }
//     if (state == AppLifecycleState.resumed) {
//       _checkSubscriptionStatus();
//     }
//   }
//
//   void _scheduleDisconnectTask() {
//     // disconnectVpnCallback();
//     // _disconnect();
//     Workmanager().registerOneOffTask(
//       "vpnDisconnectTask",
//       "disconnectVpnTask",
//       initialDelay: const Duration(seconds: 1),
//     );
//   }
//
//   final AdsController adsController = Get.find();
//
//   // REPLACE THESE:
//   Color _getPrimaryColor(bool connected) {
//     final isDark = AppTheme.isDarkMode(context);
//     return connected
//         ? AppTheme.connected
//         : (isDark ? AppTheme.primaryDark : AppTheme.primaryLight);
//   }
//
//   Color _getAccentColor(bool connected) {
//     final isDark = AppTheme.isDarkMode(context);
//     return connected
//         ? AppTheme.connected
//         : (isDark ? AppTheme.accentDark : AppTheme.accentLight);
//   }
//
//
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _myProvider = context.read<ServersProvider>(); // safe at init
//
//     _animationController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat();
//
//     _radarController = AnimationController(
//       duration: const Duration(seconds: 3),
//       vsync: this,
//     )..repeat();
//
//     //blink
//     _blinkController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 750),
//     );
//
//     _blinkAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
//       CurvedAnimation(
//         parent: _blinkController,
//         curve: Curves.easeInOut,
//       ),
//     );
//     // _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
//     //   CurvedAnimation(
//     //     parent: _blinkController,
//     //     curve: Curves.easeOutBack,
//     //   ),
//     // );
//
//     _blinkController.addStatusListener((status) {
//       if (status == AnimationStatus.completed) {
//         _blinkController.reverse();
//       } else if (status == AnimationStatus.dismissed) {
//         // _blinkCount++;
//         // if (_blinkCount < _maxBlinks) {
//         _blinkController.forward();
//         // }
//       }
//     });
//
//     _blinkController.forward();
//     //--
//
//     // Update your initState method's ads loading part:
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       _connectivitySubscription =
//           Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
//
//       // adsController.preloadInterstitial();
//       // adsController.loadBanner();
//
//       _checkSubscriptionStatus();
//       // _requestPermission();
//
//       final vpnConnectionProvider =
//       Provider.of<VpnConnectionProvider>(context, listen: false);
//       await Provider.of<ServersProvider>(context, listen: false).initialize();
//       _loadAppState();
//       await vpnConnectionProvider.restoreVpnState();
//       // await _getAllApps();
//     });
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _radarController.dispose();
//     _blinkController.dispose();
//     _progressTimer?.cancel();
//
//     adsController.disposeBanner();
//     _progressTimer?.cancel();
//
//     WidgetsBinding.instance.removeObserver(this);
//     _connectivitySubscription?.cancel();
//     _saveAppState();
//
//     super.dispose();
//   }
//
//
//   Future<void> _checkSubscriptionStatus() async {
//     debugPrint("_checkSubscriptionStatus CALLED--");
//     subscriptionManager.loadSubscriptionStatus();
//   }
//
//   Future<void> _saveAppState() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     prefs.setBool('isConnected', _isConnected);
//   }
//
//   Future<void> _loadAppState() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _isConnected = prefs.getBool('isConnected') ?? false;
//     });
//   }
//
//   void _startLoading() {
//     _progressTimer?.cancel();
//
//     setState(() {
//       _progress = 0;
//       _targetProgress = 90;
//       _isLoading = true;
//       _isWaitingForServer = false;
//       _isConnected = false;
//       _connectionCompleted = false;
//       _waitedSeconds = 0;
//     });
//
//     _progressTimer = Timer.periodic(
//       const Duration(milliseconds: 50),
//           (_) => _tickProgress(),
//     );
//   }
//
//   void _tickProgress() {
//     if (!mounted) return;
//
//     final provider = context.read<VpnConnectionProvider>();
//     final stage = provider.stage;
//
//     // 🔥 VPN CONNECTED AT ANY POINT
//     if (stage == VPNStage.connected && !_isConnected) {
//       _isConnected = true;
//       _progress = 100;
//       _isWaitingForServer = false;
//     }
//
//     // ⏳ Reached 90% but not connected → waiting mode
//     if (_progress >= 90 && !_isConnected && !_isWaitingForServer) {
//       _enterWaitingState();
//       return;
//     }
//
//     // 📈 Move progress forward
//     if (_progress < _targetProgress) {
//       setState(() {
//         _progress += _progressSpeed();
//         // if (_progress > _targetProgress) {
//         //   _progress = _targetProgress;
//         // }
//       });
//     }
//
//     // ✅ Completed
//     if (_progress >= 100 && !_connectionCompleted) {
//       _completeConnection();
//     }
//   }
//
//   void _completeConnection() {
//     _progressTimer?.cancel();
//
//     setState(() {
//       _isLoading = false;
//       _connectionCompleted = true;
//       _isConnected = true;
//     });
//
//     _saveAppState();
//
//     showLogoToast(
//       "Connected",
//       color: Colors.green,
//     );
//   }
//
//   double _progressSpeed() {
//     if (_progress < 60) return 1.2; // Fast
//     if (_progress < 90) return 0.8; // Medium
//     return 0.3; // Smooth finish
//   }
//
//   void _enterWaitingState() {
//     _progressTimer?.cancel();
//
//     setState(() {
//       _isLoading = false;
//       _isWaitingForServer = true;
//     });
//
//     _progressTimer = Timer.periodic(
//       const Duration(seconds: 1),
//           (_) => _checkServerWhileWaiting(),
//     );
//   }
//
//   void _checkServerWhileWaiting() {
//     if (!mounted) return;
//
//     final provider = context.read<VpnConnectionProvider>();
//     final stage = provider.stage;
//
//     _waitedSeconds++;
//
//     if (stage == VPNStage.connected) {
//       _progressTimer?.cancel();
//       setState(() {
//         _isConnected = true;
//         _progress = 100;
//         _isWaitingForServer = false;
//         _isLoading = true;
//       });
//
//       _progressTimer = Timer.periodic(
//         const Duration(milliseconds: 50),
//             (_) => _tickProgress(),
//       );
//       return;
//     }
//
//     // ❌ Timeout
//     if (_waitedSeconds >= _maxWaitSeconds) {
//       _handleConnectionTimeout();
//     }
//   }
//
//   void _handleConnectionTimeout() {
//     setState(() {
//       _isLoading = false;
//     });
//     OpenVPN().disconnect();
//     _disconnect();
//
//     showLogoToast(
//       "Server is taking too long. Please try again.",
//       color: Colors.red,
//     );
//   }
//
//   Future<void> _disconnect() async {
//     _progressTimer?.cancel();
//     setState(() {
//       _isConnected = false;
//       _progress = 0;
//       _isWaitingForServer = false;
//       _connectionCompleted = false;
//     });
//     await _saveAppState();
//   }
//
//   // NEW METHOD: Check actual internet connectivity
//   Future<bool> _checkRealInternetConnection() async {
//     if (_isCheckingConnection) return _hasRealInternet;
//
//     setState(() => _isCheckingConnection = true);
//
//     const urls = [
//       'https://www.google.com/generate_204',
//       'https://www.gstatic.com/generate_204',
//     ];
//
//     try {
//       for (final url in urls) {
//         final response =
//         await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
//         debugPrint('http status for $url -> ${response.statusCode}');
//         if (response.statusCode == 204 || response.statusCode == 200) {
//           _hasRealInternet = true;
//           return true;
//         }
//       }
//
//       final result = await InternetAddress.lookup('google.com')
//           .timeout(const Duration(seconds: 6));
//       _hasRealInternet = result.isNotEmpty;
//       debugPrint('dns lookup result: ${result.isNotEmpty}');
//       return _hasRealInternet;
//     } catch (err) {
//       debugPrint('checkRealInternetConnection error: $err');
//       _hasRealInternet = false;
//       return false;
//     } finally {
//       if (mounted) setState(() => _isCheckingConnection = false);
//     }
//   }
//
//   void _closeAnyDialog() {
//     if (!_isDialogShowing) return;
//
//     if (mounted) {
//       try {
//         debugPrint('🔒 Closing dialog');
//         Navigator.of(context, rootNavigator: true).pop();
//         _isDialogShowing = false; // Set AFTER successful pop
//         debugPrint('✅ Dialog closed successfully');
//       } catch (e) {
//         debugPrint('⚠️ Error closing dialog: $e');
//         _isDialogShowing = false; // Reset flag even on error
//       }
//     } else {
//       _isDialogShowing = false; // Reset if not mounted
//     }
//   }
//
//   void _showNetworkErrorDialog() {
//     if (!mounted) {
//       debugPrint('⚠️ Cannot show dialog: widget not mounted');
//       return;
//     }
//
//     if (_isDialogShowing) {
//       debugPrint('⚠️ Dialog already showing, skipping');
//       return;
//     }
//
//     debugPrint('🚨 SHOWING NETWORK ERROR DIALOG');
//     _isDialogShowing = true;
//
//     // Use addPostFrameCallback to ensure context is ready
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) {
//         debugPrint('⚠️ Widget unmounted before dialog could show');
//         _isDialogShowing = false;
//         return;
//       }
//
//       showDialog<void>(
//         context: context,
//         barrierDismissible: false,
//         useRootNavigator: true, // ✅ CRITICAL: Show above all other content
//         builder: (dialogContext) {
//           return Center(
//             child: AnimatedScale(
//               scale: 1.0,
//               duration: const Duration(milliseconds: 250),
//               curve: Curves.easeOutBack,
//               child: AlertDialog(
//                 backgroundColor: AppTheme.getCardColor(context),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(24),
//                   side: BorderSide(
//                     color: AppTheme.premiumGold,
//                   ),
//                 ),
//                 title: const Text(
//                   "No Network Connection",
//                   style: TextStyle(
//                     color: Colors.white,  // ✅ Simple and works
//                     fontWeight: FontWeight.bold,
//                     fontSize: 20,
//                   ),
//                 ),
//                 content: const Text(
//                   "Please check your WiFi or mobile network connection.",
//                   style: TextStyle(color: Colors.white70, fontSize: 16),
//                 ),
//                 actionsPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 actions: [
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor:AppTheme.premiumGold,
//                       foregroundColor:AppTheme.bgDark,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 24,
//                         vertical: 12,
//                       ),
//                     ),
//                     onPressed: () async {
//                       debugPrint('👆 User pressed Refresh');
//
//                       // Close dialog first
//                       _isDialogShowing = false;
//                       Navigator.of(dialogContext, rootNavigator: true).pop();
//
//                       // Then handle refresh
//                       try {
//                         await adsController.disposeBanner();
//
//                         if (mounted) {
//                           Navigator.pushAndRemoveUntil(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const SplashScreen(),
//                             ),
//                                 (route) => false,
//                           );
//                         }
//
//                         _myProvider.getServers();
//                       } catch (e) {
//                         debugPrint('⚠️ Error during refresh: $e');
//                       }
//                     },
//                     child: const Text(
//                       "Refresh",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ).then((_) {
//         // Ensure flag is reset when dialog closes by any means
//         debugPrint('✅ Dialog dismissed');
//         _isDialogShowing = false;
//       }).catchError((error) {
//         debugPrint('❌ Dialog error: $error');
//         _isDialogShowing = false;
//       });
//     });
//   }
//
//   void _updateConnectionStatus(List<ConnectivityResult> result) {
//     debugPrint('🔔 connectivity changed: $result');
//
//     // Cancel previous debounce
//     _debounceTimer?.cancel();
//
//     // Debounce rapid changes (adjust duration as needed)
//     _debounceTimer = Timer(const Duration(milliseconds: 800), () {
//       _evaluateConnection(result);
//     });
//   }
//
//   Future<void> _evaluateConnection(List<ConnectivityResult> results) async {
//     debugPrint('🔎 evaluateConnection: $results');
//     try {
//       // Check if ANY connection exists (not just "none")
//       final hasBasicConnection =
//           !results.contains(ConnectivityResult.none) && results.isNotEmpty;
//
//       if (!hasBasicConnection) {
//         // _failureCount++;
//         debugPrint('❌ no basic connection (failureCount=$_failureCount)');
//         _handleFailure(reason: "No network");
//         return;
//       }
//
//       // If connected to wifi/mobile, verify real internet (HTTP lookup)
//       final hasRealInternet = await _checkRealInternetConnection();
//
//       debugPrint('🌐 real internet: $hasRealInternet');
//
//       if (!hasRealInternet) {
//         _failureCount++;
//         debugPrint('❌ internet unreachable (failureCount=$_failureCount)');
//         _handleFailure(reason: "Internet unreachable");
//         return;
//       }
//
//       // success -> reset and fetch
//       _failureCount = 0;
//       _hasRealInternet = true;
//       _myProvider.getServers();
//       _handleInternetRestored();
//     } catch (e, st) {
//       debugPrint('⚠️ Connection eval error: $e\n$st');
//       _failureCount++;
//       _handleFailure(reason: "Exception");
//     }
//   }
//
//   // === FAILURE HANDLING ===
//   void _handleFailure({required String reason}) {
//     debugPrint(
//         "⚠️ Connection failure ($_failureCount/$_maxFailuresBeforeDialog): $reason");
//
//     if (reason != "No network") {
//       // Grace period - adjust _maxFailuresBeforeDialog for production
//       if (_failureCount < _maxFailuresBeforeDialog) {
//         debugPrint("⏳ grace period - not showing dialog yet");
//         return;
//       }
//     }
//
//     // mark hasRealInternet false
//     if (_hasRealInternet) setState(() => _hasRealInternet = false);
//
//     // close existing and show dialog
//     _closeAnyDialog();
//     _showNetworkErrorDialog();
//   }
//
// // === INTERNET RESTORED ===
//   void _handleInternetRestored() {
//     if (!_hasRealInternet) {
//       debugPrint("✅ Internet restored");
//       setState(() => _hasRealInternet = true);
//     }
//     _closeAnyDialog();
//   }
//
//   String formatSpeed(double bytesPerSecond) {
//     if (bytesPerSecond <= 0) {
//       return "0 KB";
//     }
//
//     const kb = 1024;
//     const mb = kb * 1024;
//
//     if (bytesPerSecond < kb) {
//       return "${bytesPerSecond.toStringAsFixed(0)} B";
//     } else if (bytesPerSecond < mb) {
//       return "${(bytesPerSecond / kb).toStringAsFixed(2)} KB";
//     } else {
//       return "${(bytesPerSecond / mb).toStringAsFixed(2)} MB";
//     }
//   }
//
//   double bytesPerSecondToMbps(double bytesPerSecond) {
//     const bitsInByte = 8;
//     const bitsInMegabit = 1000000;
//     return (bytesPerSecond * bitsInByte) / bitsInMegabit;
//   }
//
//   Widget _buildResponsiveAnimationArea(BuildContext context) {
//     return Consumer<VpnConnectionProvider>(
//       builder: (context, vpnValue, child) {
//         final connected = vpnValue.stage?.toString() == "VPNStage.connected";
//         final connecting = _isLoading;
//
//         final screenWidth = MediaQuery.of(context).size.width;
//         final screenHeight = MediaQuery.of(context).size.height;
//
//         // Animation sizes
//         double animationSize = (screenWidth * 0.55 + screenHeight * 0.22) / 2;
//         double gifSize = (screenWidth * 0.60 + screenHeight * 0.24) / 2;
//         double connectedImageSize =
//             (screenWidth * 0.45 + screenHeight * 0.18) / 2;
//
//         // Clamp for extreme small/large screens
//         animationSize = animationSize.clamp(90.0, screenHeight * 0.45);
//         gifSize = gifSize.clamp(100.0, screenHeight * 0.5);
//         connectedImageSize = connectedImageSize.clamp(70.0, screenHeight * 0.4);
//
//         return Center(
//           child: SizedBox(
//             width: animationSize + 40,
//             height: animationSize + 40,
//             child: Center(
//               child: connecting
//                   ? AnimatedBuilder(
//                 animation: _radarController,
//                 builder: (context, child) {
//                   final double scale =
//                       1 + 0.05 * sin(_animationController.value * 2 * pi);
//                   return Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       RadarLoadingAnimation(
//                         controller: _radarController,
//                         size: animationSize,
//                         color:_getPrimaryColor(connected),
//                       ),
//                       Transform.scale(
//                         scale: scale,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             boxShadow: [
//                               BoxShadow(
//                                 color:_getPrimaryColor(connected).withValues(alpha: 0.6),
//                                 blurRadius: animationSize * 0.13,
//                                 spreadRadius: animationSize * 0.04,
//                               ),
//                               BoxShadow(
//                                 color: _getPrimaryColor(connected).withValues(alpha: 0.6),
//                                 blurRadius: animationSize * 0.22,
//                                 spreadRadius: animationSize * 0.09,
//                               ),
//                             ],
//                           ),
//                           child: ClipOval(
//                             child: Image.asset(
//                               "assets/images/say_no_vpn.gif",
//                               width: gifSize,
//                               height: gifSize * 0.93,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               )
//                   : connected
//                   ? AnimatedBuilder(
//                 animation: _animationController,
//                 builder: (context, child) {
//                   return Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       RotatingGradientRing(
//                         t: _animationController.value,
//                         size: animationSize,
//                         color: _getAccentColor(connected),
//                       ),
//                       FloatingHorizontalLines(
//                         controller: _animationController,
//                         size: animationSize,
//                         color: _getPrimaryColor(connected),
//                       ),
//                       FloatingLeftWindLines(
//                         controller: _animationController,
//                         size: animationSize,
//                         color:
//                         _getAccentColor(connected).withValues(alpha: 0.8),
//                       ),
//                       AnimatedScale(
//                         scale: 1 +
//                             0.03 *
//                                 (sin(_animationController.value *
//                                     2 *
//                                     pi)),
//                         duration: Duration.zero,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             boxShadow: [
//                               BoxShadow(
//                                 color:  _getAccentColor(connected)
//                                     .withValues(alpha: 0.4),
//                                 blurRadius: animationSize * 0.13,
//                                 spreadRadius: animationSize * 0.04,
//                               ),
//                             ],
//                           ),
//                           child: Image.asset(
//                             "assets/images/connect_wifi.png",
//                             width: connectedImageSize,
//                             height: connectedImageSize,
//                             fit: BoxFit.contain,
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               )
//                   : AnimatedBuilder(
//                 animation: _animationController,
//                 builder: (context, child) {
//                   final double scale = 1 +
//                       0.05 * sin(_animationController.value * 2 * pi);
//                   return Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       RadarLoadingAnimation(
//                         controller: _animationController,
//                         size: animationSize,
//                         color: _getPrimaryColor(connected),
//                       ),
//                       Transform.scale(
//                         scale: scale,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: _getPrimaryColor(connected)
//                                     .withValues(alpha: 0.3),
//                                 blurRadius: animationSize * 0.13,
//                                 spreadRadius: animationSize * 0.04,
//                               ),
//                               BoxShadow(
//                                 color: _getPrimaryColor(connected).withValues(alpha: 0.6),
//                                 blurRadius: animationSize * 0.22,
//                                 spreadRadius: animationSize * 0.09,
//                               ),
//                             ],
//                           ),
//                           child: ClipOval(
//                             child: Image.asset(
//                               "assets/images/say_no_vpn.gif",
//                               width: gifSize,
//                               height: gifSize * 0.93,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     subscriptionManager.loadSubscriptionStatus();
//     return Consumer<VpnConnectionProvider>(
//       builder: (context, vpnValue, child) {
//         final connected = vpnValue.stage == VPNStage.connected;
//         // final connecting = _isLoading;
//
//         // Calculate responsive dimensions
//         final screenWidth = MediaQuery.of(context).size.width;
//         final screenHeight = MediaQuery.of(context).size.height;
//
//         // Proportional sizes for any device
//         double titleFontSize = screenWidth * 0.09;
//         double appFilterFontSize = screenWidth * 0.032;
//         double speedValueFontSize = screenWidth * 0.052;
//         double speedLabelFontSize = screenWidth * 0.03;
//         double serverNameFontSize = screenWidth * 0.045;
//         double bannerTitleFontSize = screenWidth * 0.04;
//         double bannerSubtitleFontSize = screenWidth * 0.032;
//         double upgradeFontSize = screenWidth * 0.032;
//         double topPadding = screenHeight * 0.04;
//         double sidePadding = screenWidth * 0.04;
//         double spacingSmall = screenHeight * 0.018;
//         double spacingMedium = screenHeight * 0.014;
//         double bannerHeight = screenHeight * 0.08;
//         double serverBoxHeight = screenHeight * 0.065;
//         double iconSize = screenWidth * 0.09;
//         double smallIconSize = screenWidth * 0.05;
//         double borderRadius = screenWidth * 0.04;
//         double largeBorderRadius = screenWidth * 0.05;
//         double connectBtnHeight = screenHeight * 0.065;
//
//         // Clamp for extreme small/large screens
//         titleFontSize = titleFontSize.clamp(18.0, 40.0);
//         appFilterFontSize = appFilterFontSize.clamp(9.0, 15.0);
//         speedValueFontSize = speedValueFontSize.clamp(12.0, 32.0);
//         speedLabelFontSize = speedLabelFontSize.clamp(8.0, 18.0);
//         serverNameFontSize = serverNameFontSize.clamp(10.0, 22.0);
//         bannerTitleFontSize = bannerTitleFontSize.clamp(10.0, 20.0);
//         bannerSubtitleFontSize = bannerSubtitleFontSize.clamp(8.0, 16.0);
//         upgradeFontSize = upgradeFontSize.clamp(8.0, 16.0);
//         topPadding = topPadding.clamp(8.0, 40.0);
//         sidePadding = sidePadding.clamp(8.0, 40.0);
//         spacingSmall = spacingSmall.clamp(4.0, 24.0);
//         spacingMedium = spacingMedium.clamp(4.0, 18.0);
//         bannerHeight = bannerHeight.clamp(32.0, 80.0);
//         serverBoxHeight = serverBoxHeight.clamp(28.0, 60.0);
//         iconSize = iconSize.clamp(16.0, 48.0);
//         smallIconSize = smallIconSize.clamp(10.0, 28.0);
//         borderRadius = borderRadius.clamp(6.0, 24.0);
//         largeBorderRadius = largeBorderRadius.clamp(8.0, 32.0);
//         connectBtnHeight = connectBtnHeight.clamp(28.0, 60.0);
//
//         // Dynamic colors based on connection state
//         final speedBlockColor =
//         connected ? _getAccentColor(connected) : _getPrimaryColor(connected);
//         final blockBackgroundColor = connected
//             ? AppTheme.connected.withValues(alpha: 0.15)
//             : AppTheme.getCardColor(context);
//         final appFilterBackgroundColor = connected
//             ? _getAccentColor(connected).withValues(alpha: 0.8)
//             : AppTheme.getCardColor(context);
//         final serverBlockColor = connected
//             ?  AppTheme.connected .withValues(alpha: 0.9)
//             : AppTheme.getCardColor(context);
//         final adBannerColor = connected
//             ?  AppTheme.connected
//             : AppTheme.getCardColor(context) ;
//         // final textColor = connected ? Colors.white : Colors.white70;
//
//         return Scaffold(
//           body: Stack(
//             children: [
//               // Gradient Background
//               Container(
//                 decoration: BoxDecoration(
//                   gradient: connected
//                       ? LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       AppTheme.connected,
//                       AppTheme.connected.withValues(alpha: 0.8),
//                       AppTheme.getBackgroundColor(context),
//                     ],
//                   )
//                       : AppTheme.getBackgroundGradient(context),
//                 ),
//               ),
//               // Main content with proper flex layout
//               Column(
//                 children: [
//                   // Top Section (VPNMax, App Filter, Upload/Download)
//                   SafeArea(
//                     child: Padding(
//                       padding: EdgeInsets.fromLTRB(
//                           sidePadding, 0, sidePadding, spacingMedium),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               RichText(
//                                 text: TextSpan(
//                                   children: [
//                                     TextSpan(
//                                       text: "SHIELD",
//                                       style: GoogleFonts.montserrat(
//                                         color: AppTheme.getTextPrimaryColor(context),  // ✅ Theme-aware
//                                         fontSize: titleFontSize - 1,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     TextSpan(
//                                       text: "VPN",
//                                       style: GoogleFonts.montserrat(
//                                         color: connected
//                                             ? _getAccentColor(connected)
//                                             : _getPrimaryColor(connected),
//                                         fontSize: titleFontSize - 1,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const Spacer(),
//                               // Settings Button
//                               // Settings Button - CORRECTED VERSION
//                               InkWell(
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(builder: (context) => const MoreScreen()),
//                                   );
//                                 },
//                                 child: Container(
//                                   padding: EdgeInsets.all(spacingSmall * 0.6),
//                                   decoration: BoxDecoration(
//                                     color: AppTheme.getCardColor(context),
//                                     borderRadius: BorderRadius.circular(12),
//                                     border: Border.all(
//                                       color: _getPrimaryColor(connected).withValues(alpha: 0.3),
//                                     ),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: _getPrimaryColor(connected).withValues(alpha: 0.2),
//                                         blurRadius: 8,
//                                         spreadRadius: 1,
//                                       ),
//                                     ],
//                                   ),
//                                   child: Icon(
//                                     Icons.settings,
//                                     color: _getPrimaryColor(connected),
//                                     size: iconSize * 0.6,
//                                   ),
//                                 ),
//                               ),
//
//                             ],
//                           ),
//                           SizedBox(height: spacingSmall),
//                           Container(
//                             width: double.infinity,
//                             padding: EdgeInsets.symmetric(
//                                 vertical: spacingSmall * 0.7),
//                             decoration: BoxDecoration(
//                               color: blockBackgroundColor,
//                               borderRadius: BorderRadius.circular(borderRadius),
//                               border: Border.all(
//                                 color: connected
//                                     ? AppTheme.connected.withValues(alpha: 0.3)
//                                     : AppTheme.borderLight.withValues(alpha: 0.3),
//                                 width: 1.2,
//                               ),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: connected
//                                       ? AppTheme.connected.withValues(alpha: 0.3)
//                                       : AppTheme.shadowLight,
//                                   blurRadius: borderRadius,
//                                   spreadRadius: 2,
//                                 ),
//                               ],
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                               children: [
//                                 // Download section
//                                 Row(
//                                   children: [
//                                     Icon(
//                                       Icons.arrow_downward,
//                                       color: connected
//                                           ?_getAccentColor(connected)
//                                           : _getPrimaryColor(connected),
//                                       size: speedLabelFontSize + 10,
//                                     ),
//                                     SizedBox(width: sidePadding * 0.3),
//                                     Column(
//                                       children: [
//                                         Text(
//                                           "DOWNLOAD",
//                                           style: GoogleFonts.montserrat(
//                                             color: connected ? Colors.white : AppTheme.getTextPrimaryColor(context),  // ✅
//                                             fontWeight: FontWeight.w800,
//                                             fontSize: speedLabelFontSize - 1,
//                                           ),
//                                         ),
//                                         SizedBox(height: spacingSmall * 0.25),
//                                         Text(
//                                           vpnValue.stage == VPNStage.connected
//                                               ? formatSpeed(
//                                             double.tryParse(vpnValue
//                                                 .status?.byteIn ??
//                                                 "0") ??
//                                                 0,
//                                           )
//                                               : "0 KB",
//                                           style: GoogleFonts.montserrat(
//                                             color: connected ? Colors.white : AppTheme.getTextPrimaryColor(context),  // ✅
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: speedValueFontSize + 1.5,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                                 // Vertical divider
//                                 Container(
//                                   height: speedValueFontSize * 2,
//                                   width: 1.5,
//                                   color: speedBlockColor.withValues(alpha: 0.3),
//                                   margin: EdgeInsets.symmetric(
//                                       horizontal: sidePadding * 0.7),
//                                 ),
//                                 // Upload section
//                                 Row(
//                                   children: [
//                                     Icon(
//                                       Icons.arrow_upward,
//                                       color: connected
//                                           ? _getAccentColor(connected)
//                                           : _getPrimaryColor(connected),
//                                       size: speedLabelFontSize + 10,
//                                     ),
//                                     SizedBox(width: sidePadding * 0.3),
//                                     Column(
//                                       children: [
//                                         Text(
//                                           "UPLOAD",
//                                           style: GoogleFonts.montserrat(
//                                             color: connected ? Colors.white : AppTheme.getTextPrimaryColor(context),  // ✅
//                                             fontWeight: FontWeight.w800,
//                                             fontSize: speedLabelFontSize,
//                                           ),
//                                         ),
//                                         SizedBox(height: spacingSmall * 0.25),
//                                         Text(
//                                           vpnValue.stage == VPNStage.connected
//                                               ? formatSpeed(
//                                             double.tryParse(vpnValue.status?.byteOut ?? "0") ?? 0,
//                                           )
//                                               : "0 KB",
//                                           style: GoogleFonts.montserrat(
//                                             color: connected ? Colors.white : AppTheme.getTextPrimaryColor(context),  // ✅
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: speedValueFontSize + 1.5,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   // Ad Banner Section - Only show if not subscribed
//                   Obx(() {
//                     debugPrint(
//                         '👀 Obx rebuild: ${subscriptionManager.isSubscribed.value}');
//
//                     if (subscriptionManager.isSubscribed.value) {
//                       return buildSubscribedBox(
//                         sidePadding,
//                         bannerHeight,
//                         adBannerColor,
//                         largeBorderRadius,
//                         connected,
//                         borderRadius,
//                         iconSize,
//                         smallIconSize,
//                         bannerTitleFontSize,
//                         bannerSubtitleFontSize,
//                       );
//                     }
//
//                     return buildNonSubscribedBox(
//                       sidePadding,
//                       spacingMedium,
//                       bannerHeight,
//                       adBannerColor,
//                       largeBorderRadius,
//                       connected,
//                       borderRadius,
//                       iconSize,
//                       smallIconSize,
//                       bannerTitleFontSize,
//                       bannerSubtitleFontSize,
//                       spacingSmall,
//                       context,
//                       upgradeFontSize,
//                     );
//                   }),
//
//                   // Flexible spacer to balance the layout
//                   Expanded(
//                     child: Column(
//                       children: [
//                         // Animation Section - takes up remaining space appropriately
//                         Expanded(
//                           flex: 3,
//                           child: Center(
//                             child: _buildResponsiveAnimationArea(context),
//                           ),
//                         ),
//
//                         // Server Box and Connect Button - fixed at bottom
//                         Padding(
//                           padding:
//                           EdgeInsets.symmetric(horizontal: sidePadding),
//                           child: Column(
//                             children: [
//                               // Server Box
//                               Consumer<ServersProvider>(
//                                 builder: (context, serversProvider, child) {
//                                   return GestureDetector(
//                                     onTap: () {
//
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) => ServerTabs(
//                                             isConnected: vpnValue.isConnected,
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                     child: Container(
//                                       height: serverBoxHeight,
//                                       decoration: BoxDecoration(
//                                         color: serverBlockColor,
//                                         borderRadius: BorderRadius.circular(
//                                             largeBorderRadius),
//                                         border: Border.all(
//                                           color: connected
//                                               ? _getAccentColor(connected)
//                                               .withValues(alpha: 0.4)
//                                               : _getPrimaryColor(connected)
//                                               .withValues(alpha: 0.3),
//                                           width: 1.5,
//                                         ),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color: (connected
//                                                 ? _getAccentColor(connected)
//                                                 : _getPrimaryColor(connected))
//                                                 .withValues(alpha: 0.2),
//                                             blurRadius: borderRadius,
//                                             spreadRadius: 2,
//                                           ),
//                                         ],
//                                       ),
//                                       child: Row(
//                                         children: [
//                                           SizedBox(width: sidePadding * 0.75),
//                                           Container(
//                                             width: iconSize,
//                                             height: iconSize,
//                                             decoration: BoxDecoration(
//                                               color: Colors.white,
//                                               borderRadius:
//                                               BorderRadius.circular(
//                                                   iconSize / 2),
//                                               boxShadow: [
//                                                 BoxShadow(
//                                                   color: Colors.black
//                                                       .withValues(alpha: 0.1),
//                                                   blurRadius:
//                                                   borderRadius * 0.33,
//                                                   spreadRadius: 1,
//                                                 ),
//                                               ],
//                                             ),
//                                             child: Center(
//                                               child: serversProvider
//                                                   .selectedServer !=
//                                                   null
//                                                   ? Container(
//                                                 width: iconSize * 0.8,
//                                                 height: iconSize * 0.8,
//                                                 decoration: BoxDecoration(
//                                                   borderRadius:
//                                                   BorderRadius
//                                                       .circular(
//                                                       iconSize /
//                                                           2),
//                                                   image: DecorationImage(
//                                                     fit: BoxFit.cover,
//                                                     image: AssetImage(
//                                                       'assets/flags/${serversProvider.selectedServer!.countryCode.toLowerCase()}.png',
//                                                     ),
//                                                   ),
//                                                 ),
//                                               )
//                                                   : Icon(
//                                                 Icons.flag,
//                                                 size: smallIconSize,
//                                                 color: _getPrimaryColor(connected),
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(width: sidePadding * 0.75),
//                                           Expanded(
//                                             child: Text(
//                                               serversProvider.selectedServer?.country ?? "Select your country",
//                                               style: TextStyle(
//                                                 color: connected ? Colors.white : AppTheme.getTextPrimaryColor(context),  // ✅
//                                                 fontSize: serverNameFontSize,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                           ),
//                                           Container(
//                                             padding: EdgeInsets.all(
//                                                 spacingSmall * 0.5),
//                                             decoration: BoxDecoration(
//                                               color: (connected
//                                                   ? _getAccentColor(connected)
//
//                                                   : _getPrimaryColor(connected))
//                                                   .withValues(alpha: 0.2),
//                                               borderRadius:
//                                               BorderRadius.circular(
//                                                   borderRadius),
//                                             ),
//                                             child: Icon(
//                                               Icons.arrow_forward_ios,
//                                               color: connected
//                                                   ? _getAccentColor(connected)
//                                                   : _getPrimaryColor(connected),
//                                               size: smallIconSize * 0.75,
//                                             ),
//                                           ),
//                                           SizedBox(width: sidePadding * 0.75),
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//
//                               SizedBox(height: spacingSmall),
//                               SizedBox(
//                                 width: double.infinity,
//                                 height: connectBtnHeight,
//                                 child: Consumer2<VpnConnectionProvider,
//                                     ServersProvider>(
//                                   builder: (context, vpnValue, serversProvider,
//                                       child) {
//                                     String vpnStage = vpnValue.stage
//                                         ?.toString()
//                                         .split('.')
//                                         .last ??
//                                         "disconnected";
//                                     bool isConnected = vpnStage == "connected";
//
//                                     // Show connecting button during progress (0-100%)
//                                     if (_isLoading) {
//                                       return ConnectingButton(
//                                         progress: _progress / 100.0,
//                                         height: connectBtnHeight,
//                                         borderRadius: largeBorderRadius,
//                                       );
//                                     }
//
//                                     // Show waiting button when waiting for server
//                                     if (_isWaitingForServer) {
//                                       return WaitingButton(
//                                         height: connectBtnHeight,
//                                         borderRadius: largeBorderRadius,
//                                         onCancel: () async {
//                                           _progressTimer?.cancel();
//                                           await vpnValue.disconnect();
//                                           setState(() {
//                                             _isWaitingForServer = false;
//                                             _isLoading = false;
//                                             _isConnected = false;
//                                             _connectionCompleted = false;
//                                           });
//                                         },
//                                       );
//                                     }
//
//                                     // Show disconnect button when connected
//                                     if (isConnected && _isConnected) {
//                                       return DisconnectButton(
//                                         onPressed: () async {
//                                           showEnhancedDisconnectDialog(context,
//                                                   () async {
//                                                 // final ads =
//                                                 // Provider.of<AdsProvider>(
//                                                 //     context,
//                                                 //     listen: false);
//                                                 await adsController
//                                                     .showInterstitial();
//
//                                                 await _disconnect();
//                                                 await vpnValue.disconnect();
//                                                 vpnValue.resetRadius();
//                                                 AnalyticsService.logFirebaseEvent(
//                                                   'vpn_disconnect',
//                                                 );
//                                                 // Fluttertoast.showToast(
//                                                 //   msg:
//                                                 //       "VPN Disconnected Successfully",
//                                                 //   backgroundColor: Colors.red,
//                                                 // );
//                                                 showLogoToast(
//                                                   "Disconnected",
//                                                   color: Colors.red,
//                                                 );
//                                                 ratingService.showRating();
//                                               });
//                                         },
//                                         height: connectBtnHeight,
//                                         borderRadius: largeBorderRadius,
//                                       );
//                                     }
//
//                                     // Default connect button
//                                     return ConnectButton(
//                                       onPressed: () async {
//
//                                         final AppsController apps = Get.find();
//
//                                         final selectedServer =
//                                             serversProvider.selectedServer;
//                                         if (selectedServer == null) {
//                                           showLogoToast(
//                                             "Please select a server first",
//                                             color: Colors.red,
//                                           );
//
//                                           return;
//                                         }
//
//                                         // Start connection
//                                         vpnValue.setRadius();
//
//                                         _startLoading();
//
//                                         adsController.showInterstitial();
//                                         AnalyticsService.logFirebaseEvent(
//                                           'vpn_connect',
//                                         );
//
//                                         try {
//                                           await vpnValue.initPlatformState(
//                                             selectedServer.ovpn,
//                                             selectedServer.country,
//                                             apps.disallowList,
//                                             selectedServer.username ?? "",
//                                             selectedServer.password ?? "",
//                                           );
//                                         } catch (e) {
//                                           setState(() {
//                                             _isLoading = false;
//                                             _connectionCompleted = false;
//                                           });
//                                           showLogoToast(
//                                             "Connection failed: $e",
//                                             color: Colors.red,
//                                           );
//                                         }
//                                       },
//                                       color: _getPrimaryColor(connected),
//                                       height: connectBtnHeight,
//                                       borderRadius: largeBorderRadius,
//                                     );
//                                   },
//                                 ),
//                               ),
//
//                               SizedBox(
//                                   height:
//                                   MediaQuery.of(context).padding.bottom +
//                                       spacingSmall),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Column buildNonSubscribedBox(
//       double sidePadding,
//       double spacingMedium,
//       double bannerHeight,
//       Color adBannerColor,
//       double largeBorderRadius,
//       bool connected,
//       double borderRadius,
//       double iconSize,
//       double smallIconSize,
//       double bannerTitleFontSize,
//       double bannerSubtitleFontSize,
//       double spacingSmall,
//       BuildContext context,
//       double upgradeFontSize) {
//     return Column(
//       children: [
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: sidePadding),
//           child: Column(
//             children: [
//               SizedBox(height: spacingMedium + 5),
//               // First banner - Always show upgrade promotion at top
//               Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   Container(
//                     // height: bannerHeight,
//                     padding: EdgeInsets.symmetric(vertical: 8),
//                     decoration: BoxDecoration(
//                       color: adBannerColor,
//                       borderRadius: BorderRadius.circular(largeBorderRadius),
//                       border: Border.all(
//                         color: (connected
//                             ? _getAccentColor(connected)
//                             : _getPrimaryColor(connected))
//                             .withValues(alpha: 0.3),
//                         width: 1.5,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: (connected
//                               ? _getAccentColor(connected)
//                               : _getPrimaryColor(connected))
//                               .withValues(alpha: 0.2),
//                           blurRadius: borderRadius,
//                           spreadRadius: 2,
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         SizedBox(width: sidePadding * 0.75),
//                         Container(
//                           width: iconSize,
//                           height: iconSize,
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               colors: [AppTheme.premiumGold, AppTheme.premiumGoldDark  ],
//                             ),
//                             borderRadius: BorderRadius.circular(iconSize / 2),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: AppTheme.premiumGold.withValues(alpha: 0.3),
//                                 blurRadius: borderRadius,
//                                 spreadRadius: 1,
//                               ),
//                             ],
//                           ),
//                           child: Center(
//                             child: Icon(
//                               Icons.local_offer,
//                               color: const Color(0xFF1A1A2E),
//                               size: smallIconSize,
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: sidePadding * 0.75),
//                         Expanded(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               AutoSizeText(
//                                 "Premium VPN - 50% OFF",
//                                 maxLines: 1,
//                                 style: TextStyle(
//                                   color: connected ? Colors.white : AppTheme.getTextPrimaryColor(context),  // ✅
//                                   fontSize: bannerTitleFontSize,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               AutoSizeText(
//                                 "Upgrade now for no limits",
//                                 maxLines: 2,
//                                 style: TextStyle(
//                                   color: connected
//                                       ? Colors.white70
//                                       : AppTheme.getTextSecondaryColor(context),  // ✅
//                                   fontSize: bannerSubtitleFontSize,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Container(
//                           width: MediaQuery.of(context).size.width * 0.235,
//                           padding: EdgeInsets.symmetric(
//                             horizontal: sidePadding - 5,
//                             vertical: spacingSmall * 0.55,
//                           ),
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               colors: [AppTheme.premiumGold,AppTheme.premiumGoldDark ],
//                             ),
//                             borderRadius: BorderRadius.circular(borderRadius),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: AppTheme.premiumGold.withValues(alpha: 0.3),
//                                 blurRadius: borderRadius,
//                                 spreadRadius: 1,
//                               ),
//                             ],
//                           ),
//                           child: InkWell(
//                             onTap: () async {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => PremiumAccessScreen(),
//                                 ),
//                               );
//                             },
//                             child: Center(
//                               child: AutoSizeText(
//                                 "UPGRADE",
//                                 maxLines: 1,
//                                 maxFontSize: 15,
//                                 style: TextStyle(
//                                   color: const Color(0xFF1A1A2E),
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: upgradeFontSize,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: sidePadding * 0.75),
//                       ],
//                     ),
//                   ),
//                   Positioned(
//                     top: -12.4,
//                     left: 10,
//                     child: AnimatedBuilder(
//                       animation: _blinkAnimation,
//                       builder: (context, child) {
//                         return Opacity(
//                           opacity: _blinkAnimation.value,
//                           child: child,
//                         );
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           vertical: 3.5,
//                           horizontal: 7,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppTheme.premiumGold  ,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Text(
//                           "Limited Time Offer",
//                           style: TextStyle(
//                             fontSize: 10,
//                             color: Colors.black,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: spacingMedium),
//         Obx(() {
//           if (!adsController.isBannerAdLoaded.value &&
//               adsController.banner == null) {
//             return const SizedBox();
//           }
//
//           return SizedBox(
//             width: adsController.banner!.size.width.toDouble(),
//             height: adsController.banner!.size.height.toDouble(),
//             child: AdWidget(ad: adsController.banner!),
//           );
//         }),
//
//       ],
//     );
//   }
//
//   Container buildSubscribedBox(
//       double sidePadding,
//       double bannerHeight,
//       Color adBannerColor,
//       double largeBorderRadius,
//       bool connected,
//       double borderRadius,
//       double iconSize,
//       double smallIconSize,
//       double bannerTitleFontSize,
//       double bannerSubtitleFontSize) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: sidePadding),
//       height: bannerHeight,
//       decoration: BoxDecoration(
//         color: adBannerColor,
//         borderRadius: BorderRadius.circular(largeBorderRadius),
//         border: Border.all(
//           color: (connected ?  _getAccentColor(connected) : _getPrimaryColor(connected))
//               .withValues(alpha: 0.3),
//           width: 1.5,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: (connected ?  _getAccentColor(connected): _getPrimaryColor(connected))
//                 .withValues(alpha: 0.2),
//             blurRadius: borderRadius,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           SizedBox(width: sidePadding * 0.75),
//           Container(
//             width: iconSize,
//             height: iconSize,
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [AppTheme.premiumGold , AppTheme.premiumGoldDark],
//               ),
//               borderRadius: BorderRadius.circular(iconSize / 2),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppTheme.premiumGold .withValues(alpha: 0.3),
//                   blurRadius: borderRadius,
//                   spreadRadius: 1,
//                 ),
//               ],
//             ),
//             child: Center(
//               child: Icon(
//                 Icons.shield,
//                 color: const Color(0xFF1A1A2E),
//                 size: smallIconSize,
//               ),
//             ),
//           ),
//           SizedBox(width: sidePadding * 0.75),
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "You're Now a Premium Member",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: bannerTitleFontSize,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   "Enjoy Ad-Free, Most Secure and Ultra Fast.",
//                   style: TextStyle(
//                     color: Colors.white60,
//                     fontSize: bannerSubtitleFontSize,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// Future<bool> hasInternetConnection() async {
//   final connectivityResults = await Connectivity().checkConnectivity();
//
//   if (connectivityResults.contains(ConnectivityResult.none)) {
//     return false;
//   }
//
//   const testUrls = [
//     'https://www.google.com/generate_204',
//     'https://www.gstatic.com/generate_204',
//   ];
//
//   try {
//     for (final url in testUrls) {
//       final response =
//       await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
//
//       if (response.statusCode == 204 || response.statusCode == 200) {
//         return true;
//       }
//     }
//
//     // DNS fallback
//     final result = await InternetAddress.lookup('google.com')
//         .timeout(const Duration(seconds: 6));
//
//     return result.isNotEmpty;
//   } catch (_) {
//     return false;
//   }
// }
//
// // Enhanced disconnect dialog function
// void showEnhancedDisconnectDialog(
//     BuildContext context,
//     VoidCallback onConfirm,
//     ) {
//   showDialog(
//     context: context,
//     barrierDismissible: true,
//     builder: (BuildContext context) {
//       return Center(
//         child: AnimatedScale(
//           scale: 1.0,
//           duration: const Duration(milliseconds: 250),
//           curve: Curves.easeOutBack,
//           child: AlertDialog(
//             backgroundColor: AppTheme.getCardColor(context),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(24),
//               // side: BorderSide(
//               //   color: _getPrimaryColor(false).withValues(alpha: 0.6),
//               // ),
//             ),
//             title: const Text(
//               "Disconnect?",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 22,
//               ),
//             ),
//             content: const Text(
//               "Are you sure you want to disconnect from the VPN?",
//               style: TextStyle(
//                 color: Colors.white70,
//                 fontSize: 16,
//               ),
//             ),
//             actionsPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 12,
//             ),
//             actions: [
//               TextButton(
//                 style: TextButton.styleFrom(
//                   // foregroundColor: _getPrimaryColor(false).withValues(alpha: 0.9),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 12,
//                   ),
//                 ),
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text(
//                   "Cancel",
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppTheme.connected,
//                   foregroundColor: Colors.black,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 12,
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   onConfirm();
//                 },
//                 child: const Text(
//                   "Disconnect",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }
//
//
// class ConnectButton extends StatelessWidget {
//   final VoidCallback onPressed;
//   final Color color;
//   final double height;
//   final double borderRadius;
//
//   const ConnectButton({
//     super.key,
//     required this.onPressed,
//     required this.color,
//     required this.height,
//     required this.borderRadius,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final fontSize = (screenWidth * 0.045).clamp(14.0, 18.0);
//
//     return SizedBox(
//       height: height,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(borderRadius),
//           ),
//           elevation: 8,
//           shadowColor: color.withValues(alpha: 0.4),
//         ),
//         onPressed: onPressed,
//         child: AutoSizeText(
//           "CONNECT",
//           maxLines: 1,
//           maxFontSize: 18,
//           style: TextStyle(
//             fontSize: fontSize,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 1.2,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // --- Enhanced Rotating Gradient Ring ---
// class RotatingGradientRing extends StatelessWidget {
//   final double t;
//   final double size;
//   final Color color;
//
//   const RotatingGradientRing({
//     super.key,
//     required this.t,
//     this.size = 280,
//     required this.color,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Transform.rotate(
//       angle: t * 2 * pi,
//       child: Container(
//         width: size,
//         height: size,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           gradient: SweepGradient(
//             colors: [
//               color,
//               color.withValues(alpha: 0.6),
//               color.withValues(alpha: 0.3),
//               color.withValues(alpha: 0.1),
//               color,
//             ],
//             stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
//             startAngle: 0.0,
//             endAngle: 2 * pi,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: color.withValues(alpha: 0.3),
//               blurRadius: 25,
//               spreadRadius: 15,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class ConnectingButton extends StatelessWidget {
//   final double progress;
//   final double height;
//   final double borderRadius;
//
//   const ConnectingButton({
//     super.key,
//     required this.progress,
//     required this.height,
//     required this.borderRadius,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final percent = (progress * 100).toInt();
//     final screenWidth = MediaQuery.of(context).size.width;
//     final fontSize = (screenWidth * 0.04).clamp(12.0, 16.0);
//
//     return SizedBox(
//       height: height,
//       child: Stack(
//         children: [
//           LayoutBuilder(
//             builder: (context, constraints) {
//               return Row(
//                 children: [
//                   Container(
//                     width: constraints.maxWidth * progress,
//                     height: height,
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [
//                           AppTheme.connected,
//                           AppTheme.success,
//                         ],
//                       ),
//                       borderRadius: BorderRadius.horizontal(
//                         left: Radius.circular(borderRadius),
//                         right: Radius.circular(
//                           progress == 1.0 ? borderRadius : 0,
//                         ),
//                       ),
//                     ),
//                   ),
//                   Container(
//                     width: constraints.maxWidth * (1 - progress),
//                     height: height,
//                     decoration: BoxDecoration(
//                       color: AppTheme.getCardColor(context).withValues(alpha: 0.8),
//                       borderRadius: BorderRadius.horizontal(
//                         right: Radius.circular(borderRadius),
//                         left: Radius.circular(
//                           progress == 0.0 ? borderRadius : 0,
//                         ),
//                       ),
//                       border: Border.all(
//                         color: AppTheme.connected.withValues(alpha: 0.3),
//                         width: 1,
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//           Container(
//             height: height,
//             alignment: Alignment.center,
//             child: Text(
//               "CONNECTING... $percent%",
//               style: TextStyle(
//                 fontSize: fontSize,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//                 letterSpacing: 1.0,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class DisconnectButton extends StatelessWidget {
//   final VoidCallback onPressed;
//   final double height;
//   final double borderRadius;
//
//   const DisconnectButton({
//     super.key,
//     required this.onPressed,
//     required this.height,
//     required this.borderRadius,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final fontSize = (screenWidth * 0.045).clamp(14.0, 18.0);
//
//     return SizedBox(
//       height: height,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppTheme.connected,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(borderRadius),
//           ),
//           elevation: 8,
//           shadowColor: AppTheme.connected.withValues(alpha: 0.4),
//         ),
//         onPressed: onPressed,
//         child: Text(
//           "DISCONNECT",
//           style: TextStyle(
//             fontSize: fontSize,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 1.2,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // Enhanced WaitingButton widget - add this at the end of your file
// class WaitingButton extends StatefulWidget {
//   final double height;
//   final double borderRadius;
//   final VoidCallback? onCancel;
//
//   const WaitingButton({
//     super.key,
//     required this.height,
//     required this.borderRadius,
//     this.onCancel,
//   });
//
//   @override
//   State<WaitingButton> createState() => _WaitingButtonState();
// }
//
// class _WaitingButtonState extends State<WaitingButton>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _pulseController;
//
//   @override
//   void initState() {
//     super.initState();
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 1),
//       vsync: this,
//     )..repeat(reverse: true);
//   }
//
//   @override
//   void dispose() {
//     _pulseController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final fontSize = (screenWidth * 0.04).clamp(12.0, 16.0);
//
//     return Container(
//       height: widget.height,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppTheme.premiumGold.withValues(alpha: 0.8),
//             AppTheme.premiumGoldDark.withValues(alpha: 0.8),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(widget.borderRadius),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.orange.withValues(alpha: 0.4),
//             blurRadius: 12,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(widget.borderRadius),
//           onTap: widget.onCancel,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2.5,
//                     valueColor: AlwaysStoppedAnimation(Colors.white),
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     "WAITING..",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: fontSize,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 1.0,
//                     ),
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: widget.onCancel,
//                   child: Container(
//                     padding: const EdgeInsets.all(4),
//                     child: const Icon(
//                       Icons.close,
//                       color: Colors.white70,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// now i have a screen that u will redeisgn based on dark and light mode . the ui is just for u for the idea . we will use gifs . as well just redeign the ui . before connecting we will show like this and then after it we will deisgn it in this way . like we will show the speeds in this way at the top of the center animation . i need a clean header and button of setting. then the center where we will show gifs . we will create a button at center for connecting it . and the servers will be as it is in the buttom . just take center button in center and place the gifs in it . also show the speeds section slike download and upload when the vpn is connected and hide them when vpn is disconnected . use the colors that i gave u in theme . the pics are just for ui . the download and upload buttons will be at top of connect .thats the cod eo fthe screen .cn u do this
