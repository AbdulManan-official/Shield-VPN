import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vpnsheild/View/Widgets/internet_connection_manager.dart';
import 'package:vpnsheild/utils/custom_toast.dart';
import 'package:vpnsheild/utils/app_theme.dart';
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
  bool _hasInternetConnection = true;
  late List<VpnServer> _filteredServers;
  late List<VpnServer> _displayedServers;

  @override
  void initState() {
    super.initState();

    _filteredServers = widget.servers.where((server) {
      final country = server.country.toLowerCase();
      return country != 'spain' &&
          country != 'united kingdom' &&
          country != 'uk';
    }).toList();

    // Get 5 random servers initially
    _displayedServers = _getRandomServers();

    InternetConnectionManager.initialize(_onInternetConnectionChanged);
  }

  // Method to get 5 random servers from filtered list
  List<VpnServer> _getRandomServers() {
    if (_filteredServers.isEmpty) return [];
    if (_filteredServers.length <= 5) return List.from(_filteredServers);

    List<VpnServer> shuffled = List.from(_filteredServers)..shuffle();
    return shuffled.take(5).toList();
  }

  // Method to refresh servers
  Future<void> _refreshServers() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Small delay for UX
    if (mounted) {
      setState(() {
        _displayedServers = _getRandomServers();
      });
      ToastHelper.showSuccess('Servers refreshed');
    }
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
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sync_rounded,
                    color: AppTheme.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Switch Server?",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Text(
              "This will disconnect your current VPN connection and switch to the new server.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.getTextSecondaryColor(context),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: onConfirm,
                child: Text(
                  "Switch",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void onServerClicked(VpnServer server) async {
    final vpnProvider = Provider.of<VpnConnectionProvider>(context, listen: false);
    final controller = Provider.of<ServersProvider>(context, listen: false);
    final vpnConfigProvider = Provider.of<VpnProvider>(context, listen: false);
    final serverIndex = _filteredServers.indexOf(server);
    final isConnected = vpnProvider.stage == VPNStage.connected;
    bool isConnecting = vpnProvider.isConnecting;

    if (isConnected || isConnecting) {
      showCancelConfirmationDialog(
        context,
        onConfirm: () async {
          controller.setSelectedIndex(serverIndex);
          controller.setSelectedTab(widget.tab);
          controller.setSelectedServer(server);
          vpnConfigProvider.vpnConfig = VpnConfig.fromJson(server.toJson());

          await vpnProvider.disconnect();
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.of(context).pop();
            ToastHelper.showSuccess(
              '${server.country} selected',
              logoStr: 'assets/flags/${server.countryCode.toLowerCase()}.png',
            );
            Navigator.of(context).pop();
          }
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
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Loading recommended servers...",
                    style: GoogleFonts.poppins(
                      color: AppTheme.getTextSecondaryColor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (_displayedServers.isEmpty) {
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
                    color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.getPrimaryColor(context).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _hasInternetConnection ? Icons.dns_outlined : Icons.wifi_off_rounded,
                        color: AppTheme.getPrimaryColor(context),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _hasInternetConnection ? "No Servers Available" : "No Internet Connection",
                      style: GoogleFonts.poppins(
                        color: AppTheme.getTextPrimaryColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasInternetConnection
                          ? "Unable to load servers.\nPlease try again later."
                          : "Connect to the internet\nand try again.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppTheme.getTextSecondaryColor(context),
                        fontSize: 14,
                        height: 1.5,
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
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        _hasInternetConnection ? 'Retry' : 'Check Connection',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.getPrimaryColor(context),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
          body: RefreshIndicator(
            onRefresh: _refreshServers,
            color: AppTheme.getPrimaryColor(context),
            backgroundColor: AppTheme.getCardColor(context),
            child: Column(
              children: [
                // Modern Minimal Header with Star Icon
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.getCardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.getPrimaryColor(context).withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.getPrimaryColor(context).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          color: AppTheme.getPrimaryColor(context),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Server',
                              style: GoogleFonts.poppins(
                                color: AppTheme.getTextPrimaryColor(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_displayedServers.length} fast locations',
                              style: GoogleFonts.poppins(
                                color: AppTheme.getTextSecondaryColor(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _hasInternetConnection
                              ? AppTheme.success.withOpacity(0.1)
                              : AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
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

                // Optimized Server List with Pull to Refresh
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: _displayedServers.length,
                    cacheExtent: 500,
                    itemBuilder: (context, index) {
                      final server = _displayedServers[index];
                      final originalIndex = _filteredServers.indexOf(server);
                      final isSelected = originalIndex == controller.getSelectedIndex() &&
                          widget.tab == controller.getSelectedTab();

                      return _RecommendedServerTile(
                        server: server,
                        isSelected: isSelected,
                        isConnected: widget.isConnected,
                        onTap: () => onServerClicked(server),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Separate widget for better performance
class _RecommendedServerTile extends StatelessWidget {
  final VpnServer server;
  final bool isSelected;
  final bool isConnected;
  final VoidCallback onTap;

  const _RecommendedServerTile({
    required this.server,
    required this.isSelected,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isSelected && isConnected
        ? AppTheme.connected
        : AppTheme.getPrimaryColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected
                  ? effectiveColor.withOpacity(0.06)
                  : AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? effectiveColor.withOpacity(0.4)
                    : AppTheme.getPrimaryColor(context).withOpacity(0.12),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Flag with recommended badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? effectiveColor.withOpacity(0.5)
                                : AppTheme.getPrimaryColor(context).withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/flags/${server.countryCode.toLowerCase()}.png',
                            fit: BoxFit.cover,
                            cacheWidth: 104,
                            cacheHeight: 104,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                                child: Icon(
                                  Icons.flag_outlined,
                                  color: AppTheme.getPrimaryColor(context),
                                  size: 24,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Server Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.country,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: AppTheme.getTextPrimaryColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Show state if available
                        if (server.state.isNotEmpty)
                          Text(
                            server.state,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.getTextSecondaryColor(context),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        if (server.state.isNotEmpty)
                          const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.success,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Fast & Reliable',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.getTextSecondaryColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Selection Indicator
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: effectiveColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: effectiveColor,
                        size: 20,
                      ),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.getTextSecondaryColor(context).withOpacity(0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}