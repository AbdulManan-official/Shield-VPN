// import 'package:auto_size_text/auto_size_text.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:openvpn_flutter/openvpn_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vpnprowithjava/utils/my_icons_icons.dart';
//
// import '../../utils/custom_toast.dart';
// import '../home_screen.dart';
// import '../more_screen.dart';
//
// class BottomNavigator extends StatefulWidget {
//   const BottomNavigator({super.key});
//
//   @override
//   State<BottomNavigator> createState() => _BottomNavigatorState();
// }
//
// class _BottomNavigatorState extends State<BottomNavigator> {
//   int selectedTab = 0; // 0 = VPN, 1 = More
//   bool connected = false; // Add this to track VPN connection state
//
//   // Modern Color Palette from first screen
//   static const Color primaryPurple = Color(0xFF8A2BE2);
//
//   // static const Color lightPurple = Color(0xFFB19CD9);
//   static const Color accentTeal = Color(0xFF20E5C7);
//
//   static const Color cardBg = Color(0xFF16213E);
//
//   // Your existing screens
//   List<Widget> _buildScreens() {
//     return [
//       const HomeScreen(),
//       const MoreScreen(),
//     ];
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _request();
//   }
//
//   Future<void> _request() async {
//     bool has = await requestNotificationPermission();
//     if (has) {
//       _requestVpnPermission();
//       debugPrint("_requestVpnPermission called");
//     } else {
//       Future.delayed(const Duration(seconds: 6), () {
//         _requestVpnPermission();
//         debugPrint("_requestVpnPermission called");
//       });
//     }
//   }
//
//   void _requestVpnPermission() {
//     try {
//       OpenVPN().requestPermissionAndroid();
//     } catch (e) {
//       showLogoToast(
//         "Error requesting VPN permission: $e",
//         color: Colors.red,
//       );
//     }
//   }
//
//
//   Future<bool> requestNotificationPermission() async {
//
//
//     final status = await Permission.notification.status;
//
//     // ✅ Already granted
//     if (status.isGranted) {
//       debugPrint("✅ Notification permission already granted");
//       return true;
//     }
//
//     // ❓ Not determined → request
//     if (status.isDenied) {
//       final newStatus = await Permission.notification.request();
//
//       if (newStatus.isGranted) {
//         debugPrint("✅ User granted notification permission");
//         return true;
//       }
//     }
//
//     // 🚫 Permanently denied OR denied again
//     final prefs = await SharedPreferences.getInstance();
//     final deniedCount = prefs.getInt('notification_denied_count') ?? 0;
//
//     // Show UI only 1–2 times max
//     if (deniedCount < 2) {
//       await prefs.setInt('notification_denied_count', deniedCount + 1);
//
//       debugPrint("🚫 Notification permission denied ($deniedCount)");
//
//       showLogoToast(
//         "Notifications are disabled. VPN alerts may not appear.",
//         color: Colors.red,
//       );
//
//       Future.delayed(const Duration(milliseconds: 800), () {
//         Get.dialog(
//           AlertDialog(
//             title: const Text("Notifications Disabled"),
//             content: const Text(
//               "To receive VPN Notifications, please enable notifications in app settings.",
//               style: TextStyle(fontSize: 15),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Get.back(),
//                 child: const Text(
//                   "Cancel",
//                   style: TextStyle(
//                     color: Colors.tealAccent,
//                     fontSize: 14.5,
//                   ),
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {
//                   openAppSettings(); // permission_handler helper
//                   Get.back();
//                 },
//                 child: const Text(
//                   "Open Settings",
//                   style: TextStyle(
//                     color: Colors.tealAccent,
//                     fontSize: 14.5,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       });
//     } else {
//       debugPrint(
//           "⚠️ Notification permission prompt suppressed (limit reached)");
//     }
//
//     return false;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     // Proportional sizes for any device (from first screen)
//     double navHeight = screenHeight * 0.08;
//     double navIconSize = screenWidth * 0.07;
//     double navFontSize = screenWidth * 0.035;
//     double navPaddingH = screenWidth * 0.04;
//     double navPaddingV = screenHeight * 0.01;
//
//     // Clamp for extreme small/large screens
//     navHeight = navHeight.clamp(40.0, 80.0);
//     navIconSize = navIconSize.clamp(18.0, 32.0);
//     navFontSize = navFontSize.clamp(10.0, 16.0);
//     navPaddingH = navPaddingH.clamp(8.0, 32.0);
//     navPaddingV = navPaddingV.clamp(4.0, 18.0);
//
//     return PopScope(
//       canPop: selectedTab == 0,
//       onPopInvokedWithResult: (bool didPop, Object? result) {
//         if (didPop) {
//           return;
//         }
//         // Switch to the first tab if not on the first tab
//         setState(() => selectedTab = 0);
//       },
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         body: IndexedStack(
//           index: selectedTab,
//           children: _buildScreens(),
//         ),
//         // body: _buildScreens()[selectedTab],
//         bottomNavigationBar: Container(
//           decoration: BoxDecoration(
//             color: cardBg,
//             borderRadius:
//                 BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
//             border: Border.all(
//               color: (connected ? accentTeal : primaryPurple)
//                   .withValues(alpha: 0.3),
//               width: 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: (connected ? accentTeal : primaryPurple)
//                     .withValues(alpha: 0.2),
//                 blurRadius: screenWidth * 0.04,
//                 spreadRadius: screenWidth * 0.01,
//               ),
//             ],
//           ),
//           child: SafeArea(
//             child: Container(
//               height: navHeight,
//               padding: EdgeInsets.symmetric(
//                   horizontal: navPaddingH, vertical: navPaddingV),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                       onTap: () => setState(() => selectedTab = 0),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             MyIcons
//                                 .shieldCheckOutline, // Using your custom icon
//                             color: selectedTab == 0
//                                 ? (connected ? accentTeal : primaryPurple)
//                                 : Colors.white60,
//                             size: navIconSize,
//                           ),
//                           AutoSizeText(
//                             "VPN",
//                             maxFontSize: 13,
//                             style: TextStyle(
//                               color: selectedTab == 0
//                                   ? (connected ? accentTeal : primaryPurple)
//                                   : Colors.white60,
//                               fontWeight: selectedTab == 0
//                                   ? FontWeight.w700
//                                   : FontWeight.w500,
//                               fontSize: navFontSize,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(screenWidth * 0.027),
//                       onTap: () => setState(() => selectedTab = 1),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             MyIcons.more011, // Using your custom icon
//                             color: selectedTab == 1
//                                 ? (connected ? accentTeal : primaryPurple)
//                                 : Colors.white60,
//                             size: navIconSize,
//                           ),
//                           AutoSizeText(
//                             "More",
//                             maxFontSize: 13,
//                             style: TextStyle(
//                               color: selectedTab == 1
//                                   ? (connected ? accentTeal : primaryPurple)
//                                   : Colors.white60,
//                               fontWeight: selectedTab == 1
//                                   ? FontWeight.w700
//                                   : FontWeight.w500,
//                               fontSize: navFontSize,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Optional: Add this method to update connection state from your HomeScreen
//   void updateConnectionState(bool isConnected) {
//     setState(() {
//       connected = isConnected;
//     });
//   }
// }
