import 'package:flutter/material.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vpnprowithjava/View/Widgets/internet_connection_manager.dart';
import 'package:vpnprowithjava/utils/app_theme.dart'; // ✅ IMPORTED THEME

import '../../Model/vpn_config.dart';
import '../../Model/vpn_server.dart';
import '../../providers/servers_provider.dart';
import '../../providers/vpn_connection_provider.dart';
import '../../providers/vpn_provider.dart';
import 'recommended_server_screen.dart';

class ServersScreen extends StatefulWidget {
  final String tab;
  final List<VpnServer> servers;
  final bool isConnected;

  const ServersScreen({
    super.key,
    required this.servers,
    required this.isConnected,
    required this.tab,
  });

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  bool _isProcessing = false;
  String _currentStatus = '';
  bool _hasInternetConnection = true;

  bool dialogClosed = false;

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
        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.3),
            ),
          ),
          title: Text(
            "Cancel Confirmation",
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 21,
            ),
          ),
          content: Text(
            "Disconnect the connected VPN?",
            style: TextStyle(
              color: AppTheme.getTextSecondaryColor(context),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getPrimaryColor(context),
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
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
          return Scaffold(
            backgroundColor: AppTheme.getBackgroundColor(context),
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.getPrimaryColor(context),
              ),
            ),
          );
        } else if (controller.freeServers.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.getBackgroundColor(context),
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _hasInternetConnection
                            ? Icons.wifi_off
                            : Icons.signal_wifi_off,
                        color: AppTheme.getPrimaryColor(context),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _hasInternetConnection
                          ? "No Servers Found"
                          : "No Internet Connection",
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasInternetConnection
                          ? "Please check your internet connection\nand try again"
                          : "Please connect to internet\nand refresh the servers",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context),
                        fontSize: 14,
                      ),
                    ),

                    // Retry button
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
                            backgroundColor: AppTheme.getPrimaryColor(context),
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
                          backgroundColor: AppTheme.getPrimaryColor(context),
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
          backgroundColor: AppTheme.getBackgroundColor(context),
          body: Column(
            children: [
              // Header with server count and connection status
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: AppTheme.getPrimaryColor(context),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.servers.length} servers available',
                          style: TextStyle(
                            color: AppTheme.getTextPrimaryColor(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // Internet connection indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _hasInternetConnection
                                ? AppTheme.success.withValues(alpha: 0.2)
                                : AppTheme.error.withValues(alpha: 0.2),
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
                                    ? AppTheme.success
                                    : AppTheme.error,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _hasInternetConnection ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: _hasInternetConnection
                                      ? AppTheme.success
                                      : AppTheme.error,
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
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.getPrimaryColor(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentStatus.isEmpty
                                ? 'Processing...'
                                : _currentStatus,
                            style: TextStyle(
                              color: AppTheme.getPrimaryColor(context),
                              fontSize: 12,
                            ),
                          ),
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
                    itemCount: widget.servers.length,
                    itemBuilder: (context, index) {
                      final server = widget.servers[index];
                      final isSelected = controller.isServerSelected(
                        server,
                        index,
                        widget.tab,
                      );

                      return InkWell(
                        onTap: () => onServerClicked(server),
                        borderRadius: BorderRadius.circular(16),
                        child: Opacity(
                          opacity: _hasInternetConnection && !_isProcessing
                              ? 1.0
                              : 0.6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (widget.isConnected
                                  ? AppTheme.connected.withValues(alpha: 0.1)
                                  : AppTheme.getCardColor(context))
                                  : AppTheme.getCardColor(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? (widget.isConnected
                                    ? AppTheme.connected
                                    : AppTheme.getPrimaryColor(context))
                                    : AppTheme.isDarkMode(context)
                                    ? AppTheme.borderDark
                                    : AppTheme.borderLight,
                                width: isSelected ? 2 : 1,
                              ),
                              gradient: isSelected
                                  ? LinearGradient(
                                colors: widget.isConnected
                                    ? [
                                  AppTheme.connected
                                      .withValues(alpha: 0.1),
                                  AppTheme.success
                                      .withValues(alpha: 0.05)
                                ]
                                    : [
                                  AppTheme.getPrimaryColor(context)
                                      .withValues(alpha: 0.1),
                                  AppTheme.accentLight
                                      .withValues(alpha: 0.05)
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
                                        ? AppTheme.connected
                                        : AppTheme.getPrimaryColor(context))
                                        : AppTheme.isDarkMode(context)
                                        ? AppTheme.borderDark
                                        : AppTheme.borderLight,
                                    width: 2,
                                  ),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: AssetImage(
                                        'assets/flags/${server.countryCode.toLowerCase()}.png'),
                                  ),
                                ),
                              ),
                              title: Text(
                                server.country,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.getTextPrimaryColor(context),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: _hasInternetConnection
                                              ? AppTheme.success
                                              .withValues(alpha: 0.2)
                                              : AppTheme.error
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
                                              ? AppTheme.success
                                              : AppTheme.error,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _hasInternetConnection
                                            ? 'Online'
                                            : 'Offline',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _hasInternetConnection
                                              ? AppTheme.success
                                              : AppTheme.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (widget.isConnected
                                      ? AppTheme.connected
                                      .withValues(alpha: 0.2)
                                      : AppTheme.getPrimaryColor(context)
                                      .withValues(alpha: 0.2))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 28,
                                  color: isSelected
                                      ? (widget.isConnected
                                      ? AppTheme.connected
                                      : AppTheme.getPrimaryColor(context))
                                      : AppTheme.getTextSecondaryColor(context),
                                ),
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

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}