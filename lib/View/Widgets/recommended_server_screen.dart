import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vpnprowithjava/View/Widgets/internet_connection_manager.dart';
import 'package:vpnprowithjava/utils/colors.dart';

import '../../Model/vpn_config.dart';
import '../../Model/vpn_server.dart';
import '../../providers/servers_provider.dart';
import '../../providers/vpn_connection_provider.dart';
import '../../providers/vpn_provider.dart';

// Enhanced Toast Helper Class
class ToastHelper {
  static Timer? _toastTimer;
  static String? _lastMessage;
  static bool _isShowing = false;

  static void showToast({
    required String message,
    Color backgroundColor = Colors.green,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Toast length = Toast.LENGTH_SHORT,
    bool preventDuplicates = true,
    bool forceClear = false,
  }) {
    if (_isShowing && !forceClear) return;

    if (preventDuplicates && _lastMessage == message && !forceClear) {
      return;
    }

    _toastTimer?.cancel();

    if (forceClear) {
      Fluttertoast.cancel();
      Future.delayed(const Duration(milliseconds: 100), () {
        _showToastInternal(message, backgroundColor, gravity, length);
      });
    } else {
      _showToastInternal(message, backgroundColor, gravity, length);
    }
  }

  static void _showToastInternal(String message, Color backgroundColor,
      ToastGravity gravity, Toast length) {
    _lastMessage = message;
    _isShowing = true;

    Fluttertoast.showToast(
      msg: message,
      toastLength: length,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 14.0,
    );

    _toastTimer = Timer(
        length == Toast.LENGTH_LONG
            ? const Duration(seconds: 4)
            : const Duration(seconds: 2), () {
      _lastMessage = null;
      _isShowing = false;
    });
  }

  static void showError(String message) {
    showToast(
      message: message,
      backgroundColor: Colors.red.shade600,
      length: Toast.LENGTH_LONG,
      forceClear: true,
    );
  }

  static void showSuccess(String message) {
    showToast(
      message: message,
      backgroundColor: Colors.green.shade600,
      forceClear: true,
    );
  }

  static void showInfo(String message) {
    showToast(
      message: message,
      backgroundColor: Colors.blue.shade600,
    );
  }

  static void showWarning(String message) {
    showToast(
      message: message,
      backgroundColor: Colors.orange.shade600,
      length: Toast.LENGTH_LONG,
    );
  }

  static void clear() {
    _toastTimer?.cancel();
    Fluttertoast.cancel();
    _lastMessage = null;
    _isShowing = false;
  }
}

// Enhanced ServersScreen (First Screen)
// ignore: must_be_immutable
class RecommendedServer extends StatefulWidget {
  String tab;
  List<VpnServer> servers;
  final bool isConnected;

  RecommendedServer({
    super.key,
    required this.servers,
    required this.tab,
    required this.isConnected,
  });

  @override
  State<RecommendedServer> createState() => _RecommendedServerState();
}

class _RecommendedServerState extends State<RecommendedServer> {
  bool _isProcessing = false;
  String _currentStatus = '';
  bool _hasInternetConnection = true;
  // BuildContext? _dialogContext;
  bool dialogClosed = false;

  @override
  void initState() {
    super.initState();
    InternetConnectionManager.initialize(_onInternetConnectionChanged);
  }

  @override
  void dispose() {
    InternetConnectionManager.dispose();
    ToastHelper.clear();
    super.dispose();
  }

  void _onInternetConnectionChanged(bool isConnected) {
    if (mounted) {
      setState(() {
        _hasInternetConnection = isConnected;
      });
    }
  }

  // void _updateStatus(String status) {
  //   if (mounted) {
  //     setState(() {
  //       _currentStatus = status;
  //     });
  //   }
  // }

  // Future<bool> _showServerChangeDialog(
  //     BuildContext context, VpnServer server) async {
  //   if (!_hasInternetConnection) {
  //     ToastHelper.showError(
  //         'No internet connection. Please check your connection and try again.');
  //     return false;
  //   }
  //
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (context) {
  //       return Center(
  //         child: AnimatedScale(
  //           scale: 1.0,
  //           duration: const Duration(milliseconds: 250),
  //           curve: Curves.easeOutBack,
  //           child: AlertDialog(
  //             backgroundColor: UIColors.cardBg,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(24),
  //               side: BorderSide(
  //                   color: UIColors.accentTeal.withValues(alpha: 0.3)),
  //             ),
  //             title: const Row(
  //               children: [
  //                 Icon(Icons.swap_horiz, color: UIColors.accentTeal, size: 28),
  //                 SizedBox(width: 12),
  //                 Text("Change Server?",
  //                     style: TextStyle(
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.bold,
  //                         fontSize: 22)),
  //               ],
  //             ),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Text(
  //                     "You are currently connected to VPN. Changing the server will:",
  //                     style: TextStyle(color: Colors.white70, fontSize: 16)),
  //                 const SizedBox(height: 16),
  //                 Container(
  //                   padding: const EdgeInsets.all(16),
  //                   decoration: BoxDecoration(
  //                     color: UIColors.warmGold.withValues(alpha: 0.1),
  //                     borderRadius: BorderRadius.circular(12),
  //                     border: Border.all(
  //                         color: UIColors.warmGold.withValues(alpha: 0.3),
  //                         width: 1),
  //                   ),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       const Row(
  //                         children: [
  //                           Icon(Icons.power_off,
  //                               color: Color(0xFFFF6B6B), size: 16),
  //                           SizedBox(width: 8),
  //                           Text("Disconnect current VPN",
  //                               style: TextStyle(
  //                                   color: Colors.white,
  //                                   fontSize: 14,
  //                                   fontWeight: FontWeight.w500)),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 8),
  //                       Row(
  //                         children: [
  //                           const Icon(Icons.public,
  //                               color: UIColors.accentTeal, size: 16),
  //                           const SizedBox(width: 8),
  //                           Expanded(
  //                             child: Text("Switch to ${server.country}",
  //                                 style: const TextStyle(
  //                                     color: Colors.white,
  //                                     fontSize: 14,
  //                                     fontWeight: FontWeight.w500)),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 const Text(
  //                     "The connection will be established automatically after switching.",
  //                     style: TextStyle(
  //                         color: Colors.white60,
  //                         fontSize: 14,
  //                         fontStyle: FontStyle.italic)),
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.of(context).pop(false),
  //                 child: const Text("Cancel",
  //                     style: TextStyle(
  //                         color: UIColors.lightPurple,
  //                         fontWeight: FontWeight.w600)),
  //               ),
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: const Color(0xFFFF6B6B),
  //                   foregroundColor: Colors.white,
  //                   shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(12)),
  //                 ),
  //                 onPressed: () => Navigator.of(context).pop(true),
  //                 child: const Text("Change Server",
  //                     style: TextStyle(fontWeight: FontWeight.bold)),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  //
  //   return confirmed == true;
  // }

  // Future<void> _showProcessingDialog(
  //     BuildContext context, VpnServer server) async {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (dialogContext) {
  //       _dialogContext = dialogContext;
  //       return PopScope(
  //         onPopInvokedWithResult: (didPop, _) {
  //           if (didPop) {
  //             dialogClosed = true;
  //             debugPrint("dialogClosed = true");
  //           }
  //         },
  //         child: StatefulBuilder(
  //           builder: (context, setState) {
  //             return AlertDialog(
  //               shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(20)),
  //               backgroundColor: UIColors.cardBg,
  //               content: Container(
  //                 padding: const EdgeInsets.all(20),
  //                 child: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     // Connection indicator
  //                     Container(
  //                       width: 80,
  //                       height: 80,
  //                       decoration: BoxDecoration(
  //                         borderRadius: BorderRadius.circular(40),
  //                         gradient: const LinearGradient(
  //                           colors: [
  //                             UIColors.primaryPurple,
  //                             UIColors.accentTeal
  //                           ],
  //                           begin: Alignment.topLeft,
  //                           end: Alignment.bottomRight,
  //                         ),
  //                       ),
  //                       child: const Center(
  //                         child: CircularProgressIndicator(
  //                           color: Colors.white,
  //                           strokeWidth: 3,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 24),
  //
  //                     // Server info
  //                     Text(
  //                       'Switching to ${server.country}',
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 12),
  //
  //                     // Status text
  //                     Text(
  //                       _currentStatus.isEmpty
  //                           ? 'Preparing connection...'
  //                           : _currentStatus,
  //                       textAlign: TextAlign.center,
  //                       style: const TextStyle(
  //                         color: Colors.white70,
  //                         fontSize: 14,
  //                       ),
  //                     ),
  //
  //                     const SizedBox(height: 20),
  //
  //                     // Internet connection indicator
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         Icon(
  //                           _hasInternetConnection
  //                               ? Icons.wifi
  //                               : Icons.wifi_off,
  //                           color: _hasInternetConnection
  //                               ? UIColors.connectGreen
  //                               : Colors.red,
  //                           size: 16,
  //                         ),
  //                         const SizedBox(width: 8),
  //                         Text(
  //                           _hasInternetConnection
  //                               ? 'Internet Connected'
  //                               : 'No Internet',
  //                           style: TextStyle(
  //                             color: _hasInternetConnection
  //                                 ? UIColors.connectGreen
  //                                 : Colors.red,
  //                             fontSize: 12,
  //                             fontWeight: FontWeight.w500,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  // Future<void> _connectWithNetworkMonitoring({
  //   required VpnConnectionProvider vpnProvider,
  //   required VpnServer server,
  //   required Function(String) onStatusUpdate,
  // }) async {
  //   // Single pre-flight network check
  //   if (!await _checkNetworkConnection()) {
  //     throw NetworkException('No network connection available');
  //   }
  //
  //   await ConnectionStateManager.connectWithRetry(
  //     vpnProvider: vpnProvider,
  //     server: server,
  //     onStatusUpdate: onStatusUpdate,
  //   ).timeout(const Duration(seconds: 60));
  // }

  // Future<bool> _disconnectWithTimeout(VpnConnectionProvider vpnProvider) async {
  //   try {
  //     return await ConnectionStateManager.disconnectSafely(vpnProvider)
  //         .timeout(const Duration(seconds: 30));
  //   } on TimeoutException {
  //     throw Exception('Disconnect operation timed out');
  //   }
  // }

  // Future<bool> _checkNetworkConnection() async {
  //   try {
  //     final result = await InternetAddress.lookup('google.com')
  //         .timeout(const Duration(seconds: 5));
  //     return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  //   } catch (e) {
  //     return false;
  //   }
  // }

  // StreamSubscription<List<ConnectivityResult>> _startNetworkMonitoring(
  //     Function(bool) onNetworkChange) {
  //   return Connectivity().onConnectivityChanged.listen((result) async {
  //     final hasConnection = await _checkNetworkConnection();
  //     onNetworkChange(hasConnection);
  //   });
  // }

  // Future<void> _changeServerLocation(
  //     BuildContext context,
  //     VpnServer server,
  //     ) async {
  //   final navigator = Navigator.of(context);
  //   if (_isProcessing) {
  //     ToastHelper.showWarning('Please wait for current operation to complete');
  //     return;
  //   }
  //
  //   if (!_hasInternetConnection) {
  //     ToastHelper.showError(
  //         'No internet connection. Please check your connection and try again.');
  //     return;
  //   }
  //
  //   final controller = Provider.of<ServersProvider>(context, listen: false);
  //   final vpnProvider =
  //   Provider.of<VpnConnectionProvider>(context, listen: false);
  //   final vpnConfigProvider = Provider.of<VpnProvider>(context, listen: false);
  //
  //   final isConnected = vpnProvider.stage == VPNStage.connected;
  //   // final isConnected = vpnProvider.stage?.toString() == "VPNStage.connected";
  //   final serverIndex = widget.servers.indexOf(server);
  //   bool isConnecting =
  //       vpnProvider.isConnecting; // Use the new isConnecting property
  //
  //   // Check if server is already selected
  //   if (controller.isServerSelected(server, serverIndex, widget.tab)) {
  //     if (isConnected) {
  //       ToastHelper.showInfo('Already connected to ${server.country}');
  //     } else {
  //       ToastHelper.showInfo('${server.country} is already selected');
  //     }
  //     return;
  //   }
  //
  //   if (isConnected || isConnecting) {
  //     final confirmed = await _showServerChangeDialog(context, server);
  //     if (!confirmed) return;
  //
  //     setState(() {
  //       _isProcessing = true;
  //     });
  //
  //     _showProcessingDialog(context, server);
  //
  //     // Network monitoring stream
  //     StreamSubscription<List<ConnectivityResult>>? networkSubscription;
  //     bool networkLostDuringProcess = false;
  //
  //     try {
  //       // Start monitoring network during the process
  //       networkSubscription = _startNetworkMonitoring((hasConnection) {
  //         if (!hasConnection && !networkLostDuringProcess) {
  //           networkLostDuringProcess = true;
  //           _handleNetworkLoss(context);
  //         }
  //       });
  //
  //       vpnProvider.startServerChange();
  //
  //       _updateStatus('Disconnecting from current server...');
  //
  //       // Check network before disconnecting
  //       if (!await _checkNetworkConnection()) {
  //         throw NetworkException(
  //             'Network connection lost before disconnecting');
  //       }
  //
  //       // Disconnect safely with timeout
  //       final disconnected = await _disconnectWithTimeout(vpnProvider);
  //
  //       if (!disconnected) {
  //         throw Exception('Failed to disconnect from current server');
  //       }
  //
  //       // AFTER successful disconnect
  //       controller.setSelectedIndex(serverIndex);
  //       controller.setSelectedTab(widget.tab);
  //       controller.setSelectedServer(server);
  //       vpnConfigProvider.vpnConfig = VpnConfig.fromJson(server.toJson());
  //
  //       _updateStatus('Disconnected. Connecting to ${server.country}...');
  //       await Future.delayed(const Duration(seconds: 1));
  //
  //       // Check network before connecting
  //       if (!await _checkNetworkConnection()) {
  //         throw NetworkException(
  //             'Network connection lost before connecting to new server');
  //       }
  //
  //       // Connect to new server with retry logic and network monitoring
  //       await _connectWithNetworkMonitoring(
  //         vpnProvider: vpnProvider,
  //         server: server,
  //         onStatusUpdate: _updateStatus,
  //       );
  //
  //       // Final network check
  //       if (!await _checkNetworkConnection()) {
  //         throw NetworkException('Network connection lost after connecting');
  //       }
  //
  //       _updateStatus('Connected successfully!');
  //       ToastHelper.showSuccess('Successfully connected to ${server.country}!');
  //
  //       await Future.delayed(const Duration(seconds: 1));
  //
  //       // Close dialog first
  //       if (mounted && !dialogClosed && !networkLostDuringProcess) {
  //         try {
  //           // Close processing dialog
  //           // await _closeProcessingDialogSafely();
  //           if (_dialogContext != null) {
  //             Navigator.of(_dialogContext!).pop();
  //             dialogClosed = true;
  //           } else {
  //             navigator.pop();
  //             dialogClosed = true;
  //           }
  //           debugPrint("Dialog Closed--");
  //         } catch (e) {
  //           debugPrint('Error closing processing dialog: $e');
  //         }
  //       }
  //
  //       if (mounted && !networkLostDuringProcess) {
  //         await Future.delayed(
  //             const Duration(milliseconds: 200)); // give time for dialog close
  //
  //         try {
  //           navigator.pop();
  //           debugPrint("Page pop done");
  //           // final navigator = rootNavigatorKey.currentState;
  //           // if (navigator != null && navigator.mounted) {
  //           //   await navigator.pushAndRemoveUntil(
  //           //     MaterialPageRoute(builder: (_) => const BottomNavigator()),
  //           //     (route) => false,
  //           //   );
  //           //   debugPrint('Navigation successful to BottomNavigator');
  //           // } else {
  //           //   debugPrint('Navigator not ready or disposed.');
  //           // }
  //         } catch (e) {
  //           debugPrint('Navigation error: $e');
  //         }
  //       }
  //
  //       // // Navigate to bottom navigator with proper context
  //       // if (mounted && !networkLostDuringProcess) {
  //       //   await Future.delayed(
  //       //     const Duration(milliseconds: 200),
  //       //   ); // Small delay for dialog to close
  //       //
  //       //   try {
  //       //     // Use Navigator.of(rootContext) to ensure proper navigation
  //       //     await Navigator.of(rootContext).pushAndRemoveUntil(
  //       //       MaterialPageRoute(builder: (context) => const BottomNavigator()),
  //       //       (route) => false,
  //       //     );
  //       //     debugPrint('Navigation successful to bottom_navigator');
  //       //   } catch (e) {
  //       //     debugPrint('Navigation error: $e');
  //       //     // Fallback navigation
  //       //     try {
  //       //       Navigator.of(rootContext).pushReplacement(
  //       //         MaterialPageRoute(
  //       //             builder: (context) => const BottomNavigator()),
  //       //       );
  //       //     } catch (fallbackError) {
  //       //       debugPrint('Fallback navigation error: $fallbackError');
  //       //     }
  //       //   }
  //       // }
  //     } on NetworkException catch (e) {
  //       debugPrint('Network error during server change: $e');
  //       _handleNetworkError(context, e.message);
  //     } catch (e) {
  //       debugPrint('Server change error: $e');
  //       _handleGeneralError(context, server, e);
  //     } finally {
  //       // Clean up network monitoring
  //       networkSubscription?.cancel();
  //
  //       // Ensure dialog is closed regardless of error (only if not already closed)
  //       if (mounted && !dialogClosed) {
  //         try {
  //           navigator.pop(); // Close processing dialog
  //           dialogClosed = true;
  //         } catch (e) {
  //           debugPrint('Error closing dialog in finally: $e');
  //         }
  //       }
  //
  //       vpnProvider.completeServerChange();
  //       if (mounted) {
  //         setState(() {
  //           _isProcessing = false;
  //         });
  //       }
  //     }
  //   } else {
  //     // If not connected, just update the server selection
  //     controller.setSelectedIndex(serverIndex);
  //     controller.setSelectedTab(widget.tab);
  //     controller.setSelectedServer(server);
  //     vpnConfigProvider.vpnConfig = VpnConfig.fromJson(server.toJson());
  //
  //     ToastHelper.showSuccess('${server.country} selected');
  //     if (mounted) {
  //       // For non-connected case, also navigate to bottom navigator
  //       try {
  //         navigator.pop(); // Close current screen
  //         // Navigator.pushAndRemoveUntil(
  //         //   context,
  //         //   MaterialPageRoute(builder: (context) => const BottomNavigator()),
  //         //   (route) => false,
  //         // );
  //       } catch (e) {
  //         debugPrint('Navigation error in non-connected case: $e');
  //         Navigator.of(context).pop(); // Just close current screen as fallback
  //       }
  //     }
  //   }
  // }

  // void _handleNetworkError(BuildContext context, String message) {
  //   if (mounted) {
  //     try {
  //       Navigator.of(context).pop(); // Close processing dialog
  //     } catch (e) {
  //       debugPrint('Error closing dialog: $e');
  //     }
  //   }
  //
  //   ToastHelper.showError('Network Error: $message');
  //   // _showNetworkErrorDialog(context, message);
  // }

  // void _handleNetworkLoss(BuildContext context) {
  //   debugPrint('Network lost during server change process');
  //
  //   // Close any open dialogs
  //   if (mounted) {
  //     try {
  //       Navigator.of(context).pop(); // Close processing dialog
  //     } catch (e) {
  //       debugPrint('Error closing dialog on network loss: $e');
  //     }
  //   }
  //
  //   ToastHelper.showError('Network connection lost during server change');
  // }

  // Handle general errors
  // void _handleGeneralError(
  //     BuildContext context, VpnServer server, dynamic error) {
  //   if (mounted) {
  //     try {
  //       Navigator.of(context).pop(); // Close processing dialog
  //     } catch (e) {
  //       debugPrint('Error closing dialog: $e');
  //     }
  //   }
  //
  //   ToastHelper.showError('Failed to connect to ${server.country}');
  //   _showErrorSnackBar(context, 'Connection failed: ${error.toString()}');
  // }

  // void _showErrorSnackBar(BuildContext context, String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       backgroundColor: Colors.red.shade700,
  //       content: Row(
  //         children: [
  //           const Icon(Icons.error_outline, color: Colors.white),
  //           const SizedBox(width: 12),
  //           Expanded(
  //               child:
  //                   Text(message, style: const TextStyle(color: Colors.white))),
  //         ],
  //       ),
  //       duration: const Duration(seconds: 4),
  //       action: SnackBarAction(
  //         label: 'Retry',
  //         textColor: Colors.white,
  //         onPressed: () {
  //           // Retry logic can be implemented here
  //         },
  //       ),
  //     ),
  //   );
  // }
  void showCancelConfirmationDialog(
      BuildContext context, {
        required VoidCallback onConfirm,
      }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: AlertDialog(
              backgroundColor: UIColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                    color: UIColors.accentTeal.withValues(alpha: 0.3)),
              ),
              title: Text(
                "Cancel Confirmation",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                ),
              ),
              content: const Text("Disconnect the connected VPN?",
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 2),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UIColors.accentTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onConfirm,
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void onServerClicked(VpnServer server) {
    final vpnProvider =
    Provider.of<VpnConnectionProvider>(context, listen: false);
    final controller = Provider.of<ServersProvider>(context, listen: false);
    final vpnConfigProvider = Provider.of<VpnProvider>(context, listen: false);
    final serverIndex = widget.servers.indexOf(server);
    final isConnected = vpnProvider.stage == VPNStage.connected;
    bool isConnecting = vpnProvider.isConnecting;

    if (isConnected || isConnecting) {
      showCancelConfirmationDialog(
        context,
        onConfirm: () {
          controller.setSelectedIndex(serverIndex);
          controller.setSelectedTab(widget.tab);
          controller.setSelectedServer(server);
          vpnConfigProvider.vpnConfig = VpnConfig.fromJson(server.toJson());
          vpnProvider.engine.disconnect();

          Navigator.of(context).pop(); // Close dialog
          ToastHelper.showSuccess('${server.country} selected');
          Navigator.of(context).pop(); // Close current screen
        },
      );
    } else {
      controller.setSelectedIndex(serverIndex);
      controller.setSelectedTab(widget.tab);
      controller.setSelectedServer(server);
      vpnConfigProvider.vpnConfig = VpnConfig.fromJson(server.toJson());
      ToastHelper.showSuccess('${server.country} selected');
      Navigator.of(context).pop(); // Close current screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ServersProvider, VpnProvider>(
      builder: (context, controller, controllerVPN, child) {
        if (controller.areServersLoading) {
          return const Scaffold(
            backgroundColor: UIColors.darkBg,
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (widget.servers.isEmpty) {
          return Scaffold(
            backgroundColor: UIColors.darkBg,
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: UIColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: UIColors.accentTeal.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: UIColors.accentTeal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _hasInternetConnection
                            ? Icons.wifi_off
                            : Icons.signal_wifi_off,
                        color: UIColors.accentTeal,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _hasInternetConnection
                          ? "No Servers Found"
                          : "No Internet Connection",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasInternetConnection
                          ? "Please check your internet connection\nand try again"
                          : "Please connect to internet\nand refresh the servers",
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    // ✅ Retry button added here
                    if (_hasInternetConnection)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final serversProvider =
                                Provider.of<ServersProvider>(context,
                                    listen: false);
                            await serversProvider.getServers();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: UIColors.primaryPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                    if (!_hasInternetConnection) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await InternetConnectionManager.checkConnection();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Check Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: UIColors.primaryPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: UIColors.darkBg,
          body: Column(
            children: [
              // Header with server count and connection status
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: UIColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: UIColors.accentTeal.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: UIColors.accentTeal.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.location_on,
                              color: UIColors.accentTeal, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text('${widget.servers.length * 2} servers available',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        // Internet connection indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _hasInternetConnection
                                ? UIColors.connectGreen.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _hasInternetConnection
                                    ? Icons.wifi
                                    : Icons.wifi_off,
                                color: _hasInternetConnection
                                    ? UIColors.connectGreen
                                    : Colors.red,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _hasInternetConnection ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: _hasInternetConnection
                                      ? UIColors.connectGreen
                                      : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isProcessing) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: UIColors.accentTeal),
                          ),
                          const SizedBox(width: 8),
                          Text(
                              _currentStatus.isEmpty
                                  ? 'Processing...'
                                  : _currentStatus,
                              style: const TextStyle(
                                  color: UIColors.accentTeal, fontSize: 12)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Servers list
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView.separated(
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemCount: widget.servers.length * 2,
                    itemBuilder: (BuildContext context, int index) {
                      int adjustedIndex = index % widget.servers.length;
                      final server = widget.servers[adjustedIndex];

                      final isSelected =
                          index == controller.getSelectedIndex() &&
                              widget.tab == controller.getSelectedTab();

                      final borderColor = isSelected
                          ? (widget.isConnected
                              ? UIColors.connectGreen
                              : UIColors.primaryPurple)
                          : UIColors.lightPurple.withValues(alpha: 0.3);

                      final trailingColor = isSelected
                          ? (widget.isConnected
                              ? UIColors.connectGreen
                              : UIColors.primaryPurple)
                          : Colors.white54;

                      final cardColor = isSelected
                          ? (widget.isConnected
                              ? UIColors.connectedBg
                              : UIColors.cardBg)
                          : UIColors.cardBg;

                      return InkWell(
                        onTap: ()=>onServerClicked(server),
                        // onTap: _hasInternetConnection && !_isProcessing
                        //     ? () => _changeServerLocation(context, server)
                        //     : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Opacity(
                          opacity: _hasInternetConnection && !_isProcessing
                              ? 1.0
                              : 0.6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: borderColor,
                                  width: isSelected ? 2 : 1),
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: widget.isConnected
                                          ? [
                                              UIColors.connectGreen
                                                  .withValues(alpha: 0.1),
                                              UIColors.accentTeal
                                                  .withValues(alpha: 0.1)
                                            ]
                                          : [
                                              UIColors.primaryPurple
                                                  .withValues(alpha: 0.1),
                                              UIColors.accentTeal
                                                  .withValues(alpha: 0.1)
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              leading: Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                      color: isSelected
                                          ? (widget.isConnected
                                              ? UIColors.connectGreen
                                              : UIColors.primaryPurple)
                                          : UIColors.lightPurple
                                              .withValues(alpha: 0.5),
                                      width: 2),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: AssetImage(
                                        'assets/flags/${server.countryCode.toLowerCase()}.png'),
                                  ),
                                ),
                              ),
                              title: Text(server.country,
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (server.country.isNotEmpty)
                                    Text(server.country,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white60)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: _hasInternetConnection
                                              ? UIColors.connectGreen
                                                  .withValues(alpha: 0.2)
                                              : Colors.red
                                                  .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                            _hasInternetConnection
                                                ? Icons.signal_cellular_alt
                                                : Icons.signal_cellular_off,
                                            size: 14,
                                            color: _hasInternetConnection
                                                ? UIColors.connectGreen
                                                : Colors.red),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                          _hasInternetConnection
                                              ? 'Online'
                                              : 'Offline',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: _hasInternetConnection
                                                  ? UIColors.connectGreen
                                                  : Colors.red,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (widget.isConnected
                                          ? UIColors.connectGreen
                                              .withValues(alpha: 0.2)
                                          : UIColors.primaryPurple
                                              .withValues(alpha: 0.2))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    size: 28,
                                    color: trailingColor),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
