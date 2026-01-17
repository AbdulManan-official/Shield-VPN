import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vpnprowithjava/View/Widgets/internet_connection_manager.dart';
import 'package:vpnprowithjava/utils/custom_toast.dart';
import 'package:vpnprowithjava/utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

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

// Enhanced RecommendedServer Screen
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
  bool dialogClosed = false;
  late List<VpnServer> _filteredServers;

  @override
  void initState() {
    super.initState();

    _filteredServers = widget.servers.where((server) {
      final country = server.country.toLowerCase();
      return country != 'spain' &&
          country != 'united kingdom' &&
          country != 'uk';
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
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: AppTheme.getCardColor(context).withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.warning,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  "Disconnect VPN?",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Text(
              "Switch to a new server?",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "CANCEL",
                  style: GoogleFonts.poppins(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: onConfirm,
                child: Text(
                  "SWITCH",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void onServerClicked(VpnServer server) {
    final vpnProvider = Provider.of<VpnConnectionProvider>(context, listen: false);
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

          Navigator.of(context).pop();
          ToastHelper.showSuccess(
            '${server.country} selected',
            logoStr: 'assets/flags/${server.countryCode.toLowerCase()}.png',
          );
          Navigator.of(context).pop();
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
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ServersProvider, VpnProvider>(
      builder: (context, controller, controllerVPN, child) {
        if (controller.areServersLoading) {
          return Scaffold(
            backgroundColor: AppTheme.getBackgroundColor(context),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.getPrimaryColor(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Loading servers...",
                    style: GoogleFonts.poppins(
                      color: AppTheme.getTextSecondaryColor(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (_filteredServers.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.getBackgroundColor(context),
            body: Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _hasInternetConnection ? Icons.dns_outlined : Icons.wifi_off,
                        color: AppTheme.getPrimaryColor(context),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _hasInternetConnection ? "No Servers Found" : "No Internet",
                      style: GoogleFonts.poppins(
                        color: AppTheme.getTextPrimaryColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasInternetConnection
                          ? "Unable to load servers\nPlease try again"
                          : "Connect to internet\nand refresh",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppTheme.getTextSecondaryColor(context),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_hasInternetConnection) {
                          final serversProvider = Provider.of<ServersProvider>(context, listen: false);
                          await serversProvider.getServers();
                        } else {
                          await InternetConnectionManager.checkConnection();
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(_hasInternetConnection ? 'Retry' : 'Check Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.getPrimaryColor(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.getBackgroundColor(context),
          body: Column(
            children: [
              // Enhanced Header
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.getCardColor(context).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.getPrimaryColor(context).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.star_rounded,
                              color: AppTheme.getPrimaryColor(context),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RECOMMENDED',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.getTextSecondaryColor(context),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_filteredServers.length * 2} Locations',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.getTextPrimaryColor(context),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _hasInternetConnection
                                  ? AppTheme.success.withOpacity(0.15)
                                  : AppTheme.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _hasInternetConnection
                                    ? AppTheme.success.withOpacity(0.3)
                                    : AppTheme.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _hasInternetConnection ? AppTheme.success : AppTheme.error,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _hasInternetConnection ? 'Online' : 'Offline',
                                  style: GoogleFonts.poppins(
                                    color: _hasInternetConnection ? AppTheme.success : AppTheme.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Enhanced Server List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: _filteredServers.length * 2,
                  itemBuilder: (context, index) {
                    int adjustedIndex = index % _filteredServers.length;
                    final server = _filteredServers[adjustedIndex];
                    final isSelected = index == controller.getSelectedIndex() && widget.tab == controller.getSelectedTab();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => onServerClicked(server),
                        borderRadius: BorderRadius.circular(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected && widget.isConnected
                                    ? AppTheme.connected.withOpacity(0.08)
                                    : AppTheme.getCardColor(context).withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? (widget.isConnected
                                      ? AppTheme.connected.withOpacity(0.5)
                                      : AppTheme.getPrimaryColor(context).withOpacity(0.5))
                                      : AppTheme.getPrimaryColor(context).withOpacity(0.2),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Flag
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? (widget.isConnected
                                            ? AppTheme.connected.withOpacity(0.6)
                                            : AppTheme.getPrimaryColor(context).withOpacity(0.6))
                                            : AppTheme.getPrimaryColor(context).withOpacity(0.3),
                                        width: 2.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                        BoxShadow(
                                          color: (widget.isConnected
                                              ? AppTheme.connected
                                              : AppTheme.getPrimaryColor(context))
                                              .withOpacity(0.3),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                          : null,
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/flags/${server.countryCode.toLowerCase()}.png',
                                        fit: BoxFit.cover,
                                        cacheWidth: 112,
                                        cacheHeight: 112,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Server Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          server.country,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: AppTheme.getTextPrimaryColor(context),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppTheme.success,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Available',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: AppTheme.success,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Selection Indicator
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (widget.isConnected
                                          ? AppTheme.connected.withOpacity(0.2)
                                          : AppTheme.getPrimaryColor(context).withOpacity(0.2))
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                      color: isSelected
                                          ? (widget.isConnected ? AppTheme.connected : AppTheme.getPrimaryColor(context))
                                          : AppTheme.getTextSecondaryColor(context),
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}