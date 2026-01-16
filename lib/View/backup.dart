// import 'dart:async';
// import 'dart:io';
// import 'dart:math';
//
// import 'package:auto_size_text/auto_size_text.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:openvpn_flutter/openvpn_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vpnprowithjava/View/Widgets/floating_lines_animation.dart';
// import 'package:vpnprowithjava/View/Widgets/radar_loading_animation.dart';
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
// import '../utils/rating_service.dart';
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
//
//
//     _blinkController.addStatusListener((status) {
//       if (status == AnimationStatus.completed) {
//         _blinkController.reverse();
//       } else if (status == AnimationStatus.dismissed) {
//
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
//
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
//
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
//
//                                                 await adsController
//                                                     .showInterstitial();
//
//                                                 await _disconnect();
//                                                 await vpnValue.disconnect();
//                                                 vpnValue.resetRadius();
//                                                 AnalyticsService.logFirebaseEvent(
//                                                   'vpn_disconnect',
//                                                 );
//
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
// }
//
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












































// lastimport 'dart:async';
// import 'dart:math';
// import 'dart:ui';
//
// import 'package:auto_size_text/auto_size_text.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:openvpn_flutter/openvpn_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vpnprowithjava/View/server_tabs.dart';
// import 'package:vpnprowithjava/utils/custom_toast.dart';
// import 'package:vpnprowithjava/utils/app_theme.dart';
// import '../providers/ads_controller.dart';
// import '../providers/apps_provider.dart';
// import '../providers/servers_provider.dart';
// import '../providers/vpn_connection_provider.dart';
// import '../utils/analytics_service.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'more_screen.dart';
//
// class Particle {
//   double x;
//   double y;
//   double vx;
//   double vy;
//   double size;
//   double opacity;
//
//   Particle({
//     required this.x,
//     required this.y,
//     required this.vx,
//     required this.vy,
//     required this.size,
//     required this.opacity,
//   });
// }
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen>
//     with TickerProviderStateMixin, WidgetsBindingObserver {
//   // === FIELDS ===
//   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
//   bool _isLoading = false;
//   bool _isConnected = false;
//   bool _isButtonPressed = false;
//
//   late AnimationController _pulseController;
//   late AnimationController _meshController;
//   late AnimationController _particleController;
//   late AnimationController _progressController;
//   late AnimationController _drawerIconController;
//   late AnimationController _buttonPressController;
//   late AnimationController _buttonMoveController;
//
//   final AdsController adsController = Get.find();
//   List<Particle> particles = [];
//
//   @override
//   void initState() {
//     super.initState();
//
//     adsController.loadBanner();
//     WidgetsBinding.instance.addObserver(this);
//
//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//
//     _meshController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 10),
//     )..repeat();
//
//     _particleController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 20),
//     )..repeat();
//
//     _progressController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     );
//
//     _drawerIconController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//
//     _buttonPressController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 100),
//     );
//     _buttonMoveController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );
//     _initializeParticles();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
//       await Provider.of<ServersProvider>(context, listen: false).initialize();
//       _loadAppState();
//     });
//   }
//
//   void _initializeParticles() {
//     final random = Random();
//     for (int i = 0; i < 50; i++) {
//       particles.add(Particle(
//         x: random.nextDouble(),
//         y: random.nextDouble(),
//         vx: (random.nextDouble() - 0.5) * 0.0005,
//         vy: (random.nextDouble() - 0.5) * 0.0005,
//         size: random.nextDouble() * 3 + 1,
//         opacity: random.nextDouble() * 0.5 + 0.2,
//       ));
//     }
//   }
//   Widget _buildConnectionStatus(bool connected, bool isConnecting, VpnConnectionProvider vpnValue) {
//     if (!connected && !isConnecting) return const SizedBox.shrink();
//
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Connection Status Badge
//         Container(
//           margin: const EdgeInsets.only(top: 18),
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           decoration: BoxDecoration(
//             color: (connected ? AppTheme.connected : AppTheme.connecting)
//                 .withOpacity(0.15),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: (connected ? AppTheme.connected : AppTheme.connecting)
//                   .withOpacity(0.3),
//             ),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 8,
//                 height: 8,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: connected ? AppTheme.connected : AppTheme.connecting,
//                   boxShadow: [
//                     BoxShadow(
//                       color: (connected ? AppTheme.connected : AppTheme.connecting)
//                           .withOpacity(0.5),
//                       blurRadius: 8,
//                       spreadRadius: 2,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 connected ? "CONNECTED" : "CONNECTING...",
//                 style: GoogleFonts.poppins(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: connected ? AppTheme.connected : AppTheme.connecting,
//                   letterSpacing: 1,
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         // Speed Section (only show when connected) with smooth animation
//         AnimatedSize(
//           duration: const Duration(milliseconds: 3000),
//           curve: Curves.easeInOut,
//           child: connected
//               ? Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const SizedBox(height: 16),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(20),
//                   child: BackdropFilter(
//                     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//                       decoration: BoxDecoration(
//                         color: AppTheme.getCardColor(context).withOpacity(0.4),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: AppTheme.connected.withOpacity(0.3),
//                           width: 1.5,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: AppTheme.connected.withOpacity(0.1),
//                             blurRadius: 20,
//                             spreadRadius: 2,
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           // UPLOAD
//                           Expanded(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.all(8),
//                                   decoration: BoxDecoration(
//                                     color: AppTheme.success.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   child: Icon(Icons.arrow_upward_rounded, color: AppTheme.success, size: 20),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Text(
//                                       "UPLOAD",
//                                       style: GoogleFonts.poppins(
//                                         fontSize: 10,
//                                         color: AppTheme.getTextSecondaryColor(context),
//                                         fontWeight: FontWeight.w600,
//                                         letterSpacing: 0.5,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 2),
//                                     Text(
//                                       formatSpeed(vpnValue.status?.byteOut),
//                                       style: GoogleFonts.poppins(
//                                         fontSize: 14,
//                                         color: AppTheme.getTextPrimaryColor(context),
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//
//                           // DIVIDER
//                           Container(
//                             height: 40,
//                             width: 1.5,
//                             color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
//                           ),
//
//                           // DOWNLOAD
//                           Expanded(
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.all(8),
//                                   decoration: BoxDecoration(
//                                     color: AppTheme.accentLight.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   child: Icon(Icons.arrow_downward_rounded, color: AppTheme.accentLight, size: 20),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Text(
//                                       "DOWNLOAD",
//                                       style: GoogleFonts.poppins(
//                                         fontSize: 10,
//                                         color: AppTheme.getTextSecondaryColor(context),
//                                         fontWeight: FontWeight.w600,
//                                         letterSpacing: 0.5,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 2),
//                                     Text(
//                                       formatSpeed(vpnValue.status?.byteIn),
//                                       style: GoogleFonts.poppins(
//                                         fontSize: 14,
//                                         color: AppTheme.getTextPrimaryColor(context),
//                                         fontWeight: FontWeight.bold,
//                                       ),
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
//                 ),
//               ),
//             ],
//           )
//               : const SizedBox.shrink(),
//         ),
//       ],
//     );
//   }
//
//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _meshController.dispose();
//     _particleController.dispose();
//     _progressController.dispose();
//     _drawerIconController.dispose();
//     _buttonPressController.dispose();
//     _connectivitySubscription?.cancel();
//     _buttonMoveController.dispose();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   void _loadAppState() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() => _isConnected = prefs.getBool('isConnected') ?? false);
//   }
//
//   void _updateConnectionStatus(List<ConnectivityResult> result) {
//     if (result.contains(ConnectivityResult.none)) {
//       showLogoToast("No Connection", color: AppTheme.error);
//     }
//   }
//
//   String formatSpeed(String? bytes) {
//     double b = double.tryParse(bytes ?? "0") ?? 0;
//     if (b <= 0) return "0.0 Mbps";
//     return "${((b * 8) / 1000000).toStringAsFixed(1)} Mbps";
//   }
//
//   // --- UI COMPONENTS ---
//
//   Widget _buildParticleBackground(bool isConnected) {
//     return AnimatedBuilder(
//       animation: _particleController,
//       builder: (context, child) {
//         // Update particle positions
//         for (var particle in particles) {
//           particle.x += particle.vx;
//           particle.y += particle.vy;
//
//           // Wrap around edges
//           if (particle.x < 0) particle.x = 1;
//           if (particle.x > 1) particle.x = 0;
//           if (particle.y < 0) particle.y = 1;
//           if (particle.y > 1) particle.y = 0;
//         }
//
//         return CustomPaint(
//           painter: ParticlePainter(
//             particles: particles,
//             isConnected: isConnected,
//             isDark: AppTheme.isDarkMode(context),
//             animationValue: _particleController.value,
//           ),
//           size: Size.infinite,
//         );
//       },
//     );
//   }
//   Widget _buildMeshBackground() {
//     final isDark = AppTheme.isDarkMode(context);
//
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 800),
//       decoration: BoxDecoration(
//         color: _isConnected
//             ? const Color(0xFF10B981).withOpacity(isDark ? 0.15 : 0.08)  // GREEN when connected
//             : const Color(0xFF1D4ED8).withOpacity(isDark ? 0.15 : 0.08), // BLUE when disconnected
//       ),
//     );
//
//   }
//
//
//   Widget _buildSpeedCard(String label, String value, IconData icon, Color color) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           width: MediaQuery.of(context).size.width * 0.42,
//           padding: const EdgeInsets.symmetric( vertical: 20),
//           decoration: BoxDecoration(
//             color: AppTheme.getCardColor(context).withOpacity(0.4),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: color.withOpacity(0.3), width: 1.5),
//             boxShadow: [
//               BoxShadow(
//                 color: color.withOpacity(0.1),
//                 blurRadius: 20,
//                 spreadRadius: 2,
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: color.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(icon, color: color, size: 22),
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     label,
//                     style: GoogleFonts.poppins(
//                       fontSize: 13,
//                       color: AppTheme.getTextSecondaryColor(context),
//                       fontWeight: FontWeight.w700,
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               AutoSizeText(
//                 value,
//                 maxLines: 1,
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   color: AppTheme.getTextPrimaryColor(context),
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Color _getDarkerPrimaryColor(bool connected) {
//     if (connected) return const Color(0xFF10B981); // Keep original green
//     final isDark = AppTheme.isDarkMode(context);
//     return isDark ? AppTheme.primaryDark : AppTheme.primaryLight; // Keep original
//   }
//
//   Color _getButtonColor(bool connected, bool isConnecting) {
//     if (connected) return const Color(0xFF047857); // DARK GREEN for button
//     if (isConnecting) return const Color(0xFFD97706); // DARK ORANGE for button
//     return const Color(0xFF1D4ED8); // DARK BLUE for button
//   }
//
//   Widget _buildPowerOrb(bool connected, bool isConnecting, VpnConnectionProvider vpnValue, ServersProvider serversProvider) {
//     final isDark = AppTheme.isDarkMode(context);
//
//     // Button color based on state and theme
//     final statusColor = connected
//         ? AppTheme.connected
//         : (isConnecting
//         ? AppTheme.connecting
//         : (isDark ? AppTheme.primaryDark : AppTheme.primaryLight));
//
//     return GestureDetector(
//       onTapDown: (_) {
//         setState(() => _isButtonPressed = true);
//         _buttonPressController.forward();
//       },
//       onTapUp: (_) {
//         setState(() => _isButtonPressed = false);
//         _buttonPressController.reverse();
//       },
//       onTapCancel: () {
//         setState(() => _isButtonPressed = false);
//         _buttonPressController.reverse();
//       },
//       onTap: () async {
//         HapticFeedback.mediumImpact();
//
//         if (connected) {
//           showEnhancedDisconnectDialog(context, () async {
//             adsController.showInterstitial(); // Add this
//             await vpnValue.disconnect();
//             setState(() => _isConnected = false);
//             _progressController.reset();
//             showLogoToast("Disconnected", color: AppTheme.error);
//           });
//         } else if (!isConnecting) {
//           if (serversProvider.selectedServer == null) {
//             return showLogoToast("Please select a server", color: AppTheme.error);
//           }
//
//           setState(() => _isLoading = true);
//           _progressController.repeat();
//
//           adsController.showInterstitial();
//           final AppsController apps = Get.find();
//           vpnValue.initPlatformState(
//             serversProvider.selectedServer!.ovpn,
//             serversProvider.selectedServer!.country,
//             apps.disallowList,
//             serversProvider.selectedServer!.username ?? "",
//             serversProvider.selectedServer!.password ?? "",
//           );
//         }
//       },
//       child: AnimatedBuilder(
//         animation: Listenable.merge([_pulseController, _progressController, _buttonPressController]),
//         builder: (context, child) {
//           final pressScale = 1.0 - (_buttonPressController.value * 0.05);
//
//           return Transform.scale(
//             scale: pressScale,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 // Outer pulse rings
//                 if (connected) ...[
//                   Container(
//                     width: 240 + (_pulseController.value * 20),
//                     height: 240 + (_pulseController.value * 20),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border: Border.all(
//                         color: statusColor.withOpacity(0.2 - (_pulseController.value * 0.15)),
//                         width: 2,
//                       ),
//                     ),
//                   ),
//                   Container(
//                     width: 210 + (_pulseController.value * 15),
//                     height: 210 + (_pulseController.value * 15),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border: Border.all(
//                         color: statusColor.withOpacity(0.3 - (_pulseController.value * 0.2)),
//                         width: 2,
//                       ),
//                     ),
//                   ),
//                 ],
//
//                 // Progress ring for connecting state
//                 if (isConnecting)
//                   SizedBox(
//                     width: 200,
//                     height: 200,
//                     child: CircularProgressIndicator(
//                       value: null,
//                       strokeWidth: 3,
//                       valueColor: AlwaysStoppedAnimation<Color>(statusColor),
//                       backgroundColor: statusColor.withOpacity(0.1),
//                     ),
//                   ),
//
//                 // Main orb - FILLED WITH THEME COLORS
//                 Container(
//                   width: 180,
//                   height: 180,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: statusColor, // SOLID THEME COLOR
//                     boxShadow: [
//                       BoxShadow(
//                         color: statusColor.withOpacity(0.6),
//                         blurRadius: 50,
//                         spreadRadius: connected ? 15 : 8,
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 Container(
//                   width: 150,
//                   height: 150,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: statusColor.withOpacity(0.9), // Slightly transparent for depth
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.2),
//                       width: 2,
//                     ),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         connected
//                             ? Icons.shield_outlined
//                             : isConnecting
//                             ? Icons.vpn_lock_rounded
//                             : Icons.power_settings_new_rounded,
//                         color: Colors.white,
//                         size: 50,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         connected
//                             ? "DISCONNECT"
//                             : isConnecting
//                             ? "CONNECTING"
//                             : "CONNECT",
//                         style: GoogleFonts.poppins(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: connected ? 12 : 14,
//                           letterSpacing: 2,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildAnimatedDrawerIcon() {
//     return AnimatedBuilder(
//       animation: _drawerIconController,
//       builder: (context, child) {
//         return IconButton(
//           onPressed: () {
//             _drawerIconController.forward().then((_) {
//               _drawerIconController.reverse();
//             });
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const MoreScreen()),
//             );
//           },
//           icon: Icon(
//             Icons.menu_rounded,
//             color: AppTheme.getPrimaryColor(context),
//             size: 26,
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<VpnConnectionProvider, ServersProvider>(
//       builder: (context, vpnValue, serversProvider, child) {
//         final connected = vpnValue.stage?.toString() == "VPNStage.connected";
//         final isConnecting = _isLoading ||
//             vpnValue.stage?.toString() == "VPNStage.connecting" ||
//             vpnValue.stage?.toString() == "VPNStage.authenticating" ||
//             vpnValue.stage?.toString() == "VPNStage.reconnecting";
//
//         // Animate button movement
//         // Animate button movement - only when CONNECTED (not connecting)
//         if (connected && !_buttonMoveController.isCompleted) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _buttonMoveController.forward();
//           });
//         } else if (!connected && !isConnecting && _buttonMoveController.isCompleted) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             _buttonMoveController.reverse();
//           });
//         }
//         // Reset loading when connected
//         if (connected) {
//           if (_progressController.isAnimating) {
//             _progressController.stop();
//             _progressController.reset();
//           }
//           if (_isLoading) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (mounted) setState(() => _isLoading = false);
//             });
//           }
//         }
//
//         return Scaffold(
//           backgroundColor: AppTheme.getBackgroundColor(context),
//           body: Stack(
//             children: [
//               _buildMeshBackground(),
//               _buildParticleBackground(connected),
//               SafeArea(
//                 child: Column(
//                   children: [
//                     // --- HEADER ---
//                     Padding(
//                       padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           RichText(
//                             text: TextSpan(
//                               children: [
//                                 TextSpan(
//                                   text: "SHIELD ",
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.w900,
//                                     color: AppTheme.getTextPrimaryColor(context),
//                                   ),
//                                 ),
//                                 TextSpan(
//                                   text: "VPN",
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.w900,
//                                     color: AppTheme.getPrimaryColor(context),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             decoration: BoxDecoration(
//                               color: AppTheme.getCardColor(context).withOpacity(0.5),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: _buildAnimatedDrawerIcon(),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const Spacer(flex: 4),
//                     //
//
//                     AnimatedBuilder(
//                       animation: _buttonMoveController,
//                       builder: (context, child) {
//                         final moveOffset = _buttonMoveController.value * -50;
//
//                         return Transform.translate(
//                           offset: Offset(0, moveOffset),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               _buildPowerOrb(connected, isConnecting, vpnValue, serversProvider),
//                               _buildConnectionStatus(connected, isConnecting, vpnValue),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                     const Spacer(flex: 2),
//
//                     // --- SERVER SELECTOR ---
//                     // --- BANNER AD + SERVER SELECTOR ---
//                     Column(
//                       children: [
//                         // Banner Ad
//                         Obx(() {
//                           if (adsController.banner != null) {
//                             return Container(
//                               margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
//                               alignment: Alignment.center,
//                               width: adsController.banner!.size.width.toDouble(),
//                               height: adsController.banner!.size.height.toDouble(),
//                               child: AdWidget(ad: adsController.banner!),
//                             );
//                           }
//                           return const SizedBox.shrink();
//                         }),
//
//                         // Server Selector
//                         Padding(
//                           padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
//                           child: GestureDetector(
//                             onTap: () => Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => ServerTabs(isConnected: connected),
//                               ),
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(24),
//                               child: BackdropFilter(
//                                 filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(20),
//                                   decoration: BoxDecoration(
//                                     color: AppTheme.getCardColor(context).withOpacity(0.4),
//                                     borderRadius: BorderRadius.circular(24),
//                                     border: Border.all(
//                                       color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
//                                       width: 1.5,
//                                     ),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
//                                         blurRadius: 20,
//                                         spreadRadius: 2,
//                                       ),
//                                     ],
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Container(
//                                         width: 50,
//                                         height: 50,
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           border: Border.all(
//                                             color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
//                                             width: 2,
//                                           ),
//                                           boxShadow: [
//                                             BoxShadow(
//                                               color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
//                                               blurRadius: 10,
//                                             ),
//                                           ],
//                                         ),
//                                         child: ClipOval(
//                                           child: serversProvider.selectedServer != null
//                                               ? Image.asset(
//                                             'assets/flags/${serversProvider.selectedServer!.countryCode.toLowerCase()}.png',
//                                             fit: BoxFit.cover,
//                                           )
//                                               : Container(
//                                             color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
//                                             child: Icon(
//                                               Icons.public,
//                                               color: AppTheme.getPrimaryColor(context),
//                                               size: 24,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 16),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               "SECURE LOCATION",
//                                               style: GoogleFonts.poppins(
//                                                 color: AppTheme.getTextSecondaryColor(context),
//                                                 fontSize: 10,
//                                                 fontWeight: FontWeight.w600,
//                                                 letterSpacing: 1,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               serversProvider.selectedServer?.country ?? "Select Smart Server",
//                                               style: GoogleFonts.poppins(
//                                                 color: AppTheme.getTextPrimaryColor(context),
//                                                 fontWeight: FontWeight.bold,
//                                                 fontSize: 16,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       Container(
//                                         padding: const EdgeInsets.all(8),
//                                         decoration: BoxDecoration(
//                                           color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
//                                           borderRadius: BorderRadius.circular(10),
//                                         ),
//                                         child: Icon(
//                                           Icons.arrow_forward_ios_rounded,
//                                           color: AppTheme.getPrimaryColor(context),
//                                           size: 18,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//
// class ParticlePainter extends CustomPainter {
//   final List<Particle> particles;
//   final bool isConnected;
//   final bool isDark;
//   final double animationValue;
//
//   ParticlePainter({
//     required this.particles,
//     required this.isConnected,
//     required this.isDark,
//     required this.animationValue,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..style = PaintingStyle.fill;
//
//     // Draw particles
//     for (var particle in particles) {
//       final x = particle.x * size.width;
//       final y = particle.y * size.height;
//
//       // Particle color based on connection state - ORIGINAL COLORS
//       Color particleColor;
//       if (isConnected) {
//         particleColor = AppTheme.connected;
//       } else {
//         particleColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
//       }
//
//       paint.color = particleColor.withOpacity(particle.opacity * (isConnected ? 0.8 : 0.4));
//       canvas.drawCircle(Offset(x, y), particle.size, paint);
//
//       // Add glow effect for connected state
//       if (isConnected) {
//         paint.color = particleColor.withOpacity(particle.opacity * 0.2);
//         canvas.drawCircle(Offset(x, y), particle.size * 3, paint);
//       }
//     }
//
//     // Draw connecting lines between nearby particles - ORIGINAL
//     if (isConnected) {
//       final linePaint = Paint()
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 0.5;
//
//       for (int i = 0; i < particles.length; i++) {
//         for (int j = i + 1; j < particles.length; j++) {
//           final p1 = particles[i];
//           final p2 = particles[j];
//
//           final dx = (p1.x - p2.x) * size.width;
//           final dy = (p1.y - p2.y) * size.height;
//           final distance = sqrt(dx * dx + dy * dy);
//
//           if (distance < 100) {
//             final opacity = (1 - distance / 100) * 0.3;
//             linePaint.color = AppTheme.connected.withOpacity(opacity);
//             canvas.drawLine(
//               Offset(p1.x * size.width, p1.y * size.height),
//               Offset(p2.x * size.width, p2.y * size.height),
//               linePaint,
//             );
//           }
//         }
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(ParticlePainter oldDelegate) => true;
// }
//
// class _GlowOrb extends StatelessWidget {
//   final Color color;
//   const _GlowOrb({required this.color});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 350,
//       height: 350,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: color,
//       ),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
//         child: Container(color: Colors.transparent),
//       ),
//     );
//   }
// }
//
// void showEnhancedDisconnectDialog(BuildContext context, VoidCallback onConfirm) {
//   showDialog(
//     context: context,
//     builder: (c) => BackdropFilter(
//       filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//       child: AlertDialog(
//         backgroundColor: AppTheme.getCardColor(context).withOpacity(0.95),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(28),
//           side: BorderSide(
//             color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
//           ),
//         ),
//         title: Row(
//           children: [
//             Icon(
//               Icons.warning_amber_rounded,
//               color: AppTheme.warning,
//               size: 28,
//             ),
//             const SizedBox(width: 12),
//             Text(
//               "Stop Connection?",
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//         content: Text(
//           "Are you sure you want to disconnect from this secure server?",
//           style: GoogleFonts.poppins(
//             fontSize: 14,
//             color: AppTheme.getTextSecondaryColor(context),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(c),
//             child: Text(
//               "CANCEL",
//               style: GoogleFonts.poppins(
//                 color: AppTheme.getTextSecondaryColor(context),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppTheme.error,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             ),
//             onPressed: () {
//               Navigator.pop(c);
//               onConfirm();
//             },
//             child: Text(
//               "DISCONNECT",
//               style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }// }