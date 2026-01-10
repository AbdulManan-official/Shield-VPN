// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:openvpn_flutter/openvpn_flutter.dart';
// import 'package:vpnprowithjava/providers/vpn_connection_provider.dart';
//
// import '../Model/vpn_server.dart';
// import '../View/Widgets/internet_connection_manager.dart';
//
// class ConnectionStateManager {
//   static const int maxRetryAttempts = 3;
//   static const Duration retryDelay = Duration(seconds: 2);
//   static const Duration connectTimeout = Duration(seconds: 25);
//   static const Duration disconnectTimeout = Duration(seconds: 10);
//
//   /// ------------------------------------------------------
//   /// CONNECT WITH RETRY (EVENT-DRIVEN)
//   /// ------------------------------------------------------
//   static Future<bool> connectWithRetry({
//     required VpnConnectionProvider vpnProvider,
//     required VpnServer server,
//     required void Function(String) onStatusUpdate,
//   }) async {
//     for (int attempt = 1; attempt <= maxRetryAttempts; attempt++) {
//       try {
//         // 1️⃣ Pre-flight internet check
//         if (!await InternetConnectionManager.checkConnection()) {
//           throw Exception('No internet connection');
//         }
//
//         onStatusUpdate(
//           'Connecting to ${server.country} ($attempt/$maxRetryAttempts)',
//         );
//
//         // 2️⃣ Start VPN connection (non-blocking)
//         await vpnProvider.initPlatformState(
//           server.ovpn,
//           server.country,
//           const ["com.technosofts.vpnmax"],
//           server.username ?? "",
//           server.password ?? "",
//         );
//
//         // 3️⃣ Wait for CONNECTED event
//         await _waitForStage(
//           vpnProvider,
//           VPNStage.connected,
//           timeout: connectTimeout,
//         );
//
//         onStatusUpdate('Connected to ${server.country}');
//         return true;
//
//       } catch (e) {
//         debugPrint('VPN connect attempt $attempt failed: $e');
//
//         if (attempt == maxRetryAttempts) {
//           throw Exception(
//             'Failed to connect after $maxRetryAttempts attempts',
//           );
//         }
//
//         onStatusUpdate(
//           'Retrying connection (${attempt + 1}/$maxRetryAttempts)...',
//         );
//
//         await Future.delayed(retryDelay);
//       }
//     }
//     return false;
//   }
//
//   /// ------------------------------------------------------
//   /// WAIT FOR SPECIFIC VPN STAGE (CORE LOGIC)
//   /// ------------------------------------------------------
//   static Future<void> _waitForStage(
//       VpnConnectionProvider provider,
//       VPNStage expectedStage, {
//         required Duration timeout,
//       }) async {
//     // Already in desired state → return immediately
//     if (provider.stage == expectedStage) return;
//
//     final completer = Completer<void>();
//     late StreamSubscription<VPNStage> subscription;
//
//     final timer = Timer(timeout, () {
//       if (!completer.isCompleted) {
//         subscription.cancel();
//         completer.completeError(
//           TimeoutException('Timed out waiting for $expectedStage'),
//         );
//       }
//     });
//
//     subscription = provider.stageStream.listen((stage) {
//       if (stage == expectedStage && !completer.isCompleted) {
//         timer.cancel();
//         subscription.cancel();
//         completer.complete();
//       }
//     });
//
//     return completer.future;
//   }
//
//   /// ------------------------------------------------------
//   /// SAFE DISCONNECT
//   /// ------------------------------------------------------
//   static Future<bool> disconnectSafely(
//       VpnConnectionProvider vpnProvider,
//       ) async {
//     try {
//       vpnProvider.engine.disconnect();
//
//       // Wait for DISCONNECTED event (silent timeout)
//       await _waitForStage(
//         vpnProvider,
//         VPNStage.disconnected,
//         timeout: disconnectTimeout,
//       ).catchError((_) {});
//
//       return true;
//     } catch (e) {
//       debugPrint('VPN disconnect error: $e');
//       return false;
//     }
//   }
// }
