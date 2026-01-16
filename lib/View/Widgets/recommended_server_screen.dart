import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vpnprowithjava/View/Widgets/internet_connection_manager.dart';
import 'package:vpnprowithjava/utils/colors.dart';
import 'package:vpnprowithjava/utils/custom_toast.dart';

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
    Duration duration = const Duration(milliseconds: 2500),
    bool preventDuplicates = true,
    bool forceClear = false,
    String? logoStr,
  }) {
    if (_isShowing && !forceClear) return;

    if (preventDuplicates && _lastMessage == message && !forceClear) {
      return;
    }

    _toastTimer?.cancel();

    if (forceClear) {
      Fluttertoast.cancel();
      Future.delayed(const Duration(milliseconds: 100), () {
        _showToastInternal(
          message,
          backgroundColor,
          duration: duration,
          logoStr: logoStr ?? 'assets/images/vpnlogo.png',
        );
      });
    } else {
      _showToastInternal(
        message,
        backgroundColor,
        duration: duration,
        logoStr: logoStr ?? 'assets/images/vpnlogo.png',
      );
    }
  }

  static void _showToastInternal(
    String message,
    Color backgroundColor, {
    Duration duration = const Duration(milliseconds: 2500),
    String? logoStr,
  }) {
    _lastMessage = message;
    _isShowing = true;

    showLogoToast(
      message,
      duration: duration,
      color: backgroundColor,
    );

    _toastTimer = Timer(duration, () {
      _lastMessage = null;
      _isShowing = false;
    });
  }

  static void showError(String message) {
    showToast(
      message: message,
      backgroundColor: Colors.red.shade600,
      duration: const Duration(milliseconds: 3000),
      forceClear: true,
    );
  }

  static void showSuccess(String message, {String? logoStr}) {
    showToast(
      message: message,
      backgroundColor: Colors.green.shade600,
      forceClear: true,
      logoStr: logoStr ?? 'assets/images/vpnlogo.png',
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
      duration: const Duration(milliseconds: 3000),
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

  late List<VpnServer> _filteredServers;

  @override
  void initState() {
    super.initState();

    // Remove Spain & United Kingdom for THIS page only
    _filteredServers = widget.servers.where((server) {
      final country = server.country.toLowerCase();
      return country != 'spain' &&
          country != 'united kingdom' &&
          country != 'uk'; // safety
    }).toList();

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
    final serverIndex = _filteredServers.indexOf(server);
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
          ToastHelper.showSuccess(
            '${server.country} selected',
            logoStr: 'assets/flags/${server.countryCode.toLowerCase()}.png',
          );
          Navigator.of(context).pop(); // Close current screen
        },
      );
    } else {
      controller.setSelectedIndex(serverIndex);
      controller.setSelectedTab(widget.tab);
      controller.setSelectedServer(server);
      vpnConfigProvider.vpnConfig = VpnConfig.fromJson(server.toJson());
      ToastHelper.showSuccess(
        '${server.country} selected',
        logoStr: 'assets/flags/${server.countryCode.toLowerCase()}.png',
      );
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
        } else if (_filteredServers.isEmpty) {
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
                        Text('${_filteredServers.length * 2} servers available',
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
                    itemCount: _filteredServers.length * 2,
                    itemBuilder: (BuildContext context, int index) {
                      int adjustedIndex = index % _filteredServers.length;
                      final server = _filteredServers[adjustedIndex];

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
                        onTap: () => onServerClicked(server),
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
                                  // if (server.country.isNotEmpty)
                                  //   Text(server.country,
                                  //       style: const TextStyle(
                                  //           fontSize: 14,
                                  //           color: Colors.white60)),
                                  const SizedBox(height: 2),
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
