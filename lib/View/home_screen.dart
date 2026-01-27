import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpnsheild/View/server_tabs.dart';
import 'package:vpnsheild/utils/custom_toast.dart';
import 'package:vpnsheild/utils/app_theme.dart';
import '../providers/ads_controller.dart';
import '../providers/apps_provider.dart';
import '../providers/servers_provider.dart';
import '../providers/vpn_connection_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'more_screen.dart';

// ✅ STEP 1: Define VPN Status Enum (ONE SOURCE OF TRUTH)
enum VpnUiStatus {
  disconnected,
  connecting,
  connected,
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ✅ STEP 2: Replace ALL boolean flags with ONE enum
  VpnUiStatus _vpnUiStatus = VpnUiStatus.disconnected;

  // Keep only necessary state
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isButtonPressed = false;

  late AnimationController _serverPressController;
  late AnimationController _pulseController;
  late AnimationController _meshController;
  late AnimationController _particleController;
  late AnimationController _progressController;
  late AnimationController _drawerIconController;
  late AnimationController _buttonPressController;
  late AnimationController _buttonMoveController;
  late AnimationController _borderAnimationController;
  Timer? _connectionTimeoutTimer;
  // final AdsController adsController = Get.find();
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();

    // adsController.loadBanner();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _drawerIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _buttonPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _buttonMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _serverPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _initializeParticles();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);

      final serversProvider = Provider.of<ServersProvider>(context, listen: false);
      final vpnConnectionProvider = Provider.of<VpnConnectionProvider>(context, listen: false);

      // ✅ OPTIMIZATION: Run VPN restore and server loading in parallel
      final vpnRestoreFuture = vpnConnectionProvider.restoreVpnState();

      final serverInitFuture = serversProvider.initialize().then((_) {
        if (serversProvider.freeServers.isEmpty) {
          return serversProvider.getServers();
        }
      });

      // ✅ Wait for VPN restore to complete (fastest operation)
      await vpnRestoreFuture;

      // ✅ Sync UI immediately with actual VPN state
      if (mounted) {
        final currentStage = vpnConnectionProvider.stage;
        if (currentStage == VPNStage.connected) {
          setState(() => _vpnUiStatus = VpnUiStatus.connected);
        }
      }

      // ✅ Wait for servers to finish loading
      await serverInitFuture;

      // ✅ VPN Listener - Maps VPN stages to UI status
      // ✅ VPN Listener - Maps VPN stages to UI status
      vpnConnectionProvider.addListener(() {
        if (!mounted) return;

        final stage = vpnConnectionProvider.stage;
        debugPrint('🔴 VPN Stage Changed: $stage');

        // Map VPN stages to UI status with SINGLE setState
        if (stage == VPNStage.connecting ||
            stage == VPNStage.authenticating ||
            stage == VPNStage.wait_connection ||
            stage == VPNStage.prepare) {

          if (_vpnUiStatus != VpnUiStatus.connecting) {
            setState(() => _vpnUiStatus = VpnUiStatus.connecting);
            if (!_progressController.isAnimating) {
              _progressController.repeat();
            }
            // ✅ START TIMEOUT TIMER
            _startConnectionTimeout();
          }
        }

        else if (stage == VPNStage.connected) {
          if (_vpnUiStatus != VpnUiStatus.connected) {
            // ✅ CANCEL TIMEOUT TIMER - Connection successful
            _cancelConnectionTimeout();

            setState(() => _vpnUiStatus = VpnUiStatus.connected);
            _progressController.stop();
            _progressController.reset();
            SharedPreferences.getInstance().then((prefs) => prefs.setBool('isConnected', true));
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                // final AdsController ads = Get.find();
                // ads.showInterstitial();
              }
            });
          }
        }

        else if (stage == VPNStage.disconnected || stage == VPNStage.error) {
          if (_vpnUiStatus != VpnUiStatus.disconnected) {
            // ✅ CANCEL TIMEOUT TIMER - Connection failed
            _cancelConnectionTimeout();

            setState(() => _vpnUiStatus = VpnUiStatus.disconnected);
            _progressController.stop();
            _progressController.reset();

            if (stage == VPNStage.error) {
              showLogoToast("Connection failed", color: AppTheme.error);
            }
          }
        }
      });
    });
  }
  void _startConnectionTimeout() {
    // Cancel any existing timer first
    _connectionTimeoutTimer?.cancel();

    // Start new 15-second timer
    _connectionTimeoutTimer = Timer(const Duration(seconds: 15), () async {
      if (mounted && _vpnUiStatus == VpnUiStatus.connecting) {
        // Still connecting after 15 seconds - timeout occurred

        // ✅ GET VPN PROVIDER AND DISCONNECT (just like cancel button)
        final vpnProvider = Provider.of<VpnConnectionProvider>(context, listen: false);
        await vpnProvider.disconnect();

        // Update UI state
        setState(() => _vpnUiStatus = VpnUiStatus.disconnected);

        // Stop and reset progress animation
        _progressController.stop();
        _progressController.reset();

        // Show timeout message
        showLogoToast(
          "Connection timeout - Try with another server",
          color: AppTheme.error,
        );

        debugPrint('🔴 Connection timeout after 15 seconds - VPN disconnected');
      }
    });
  }

  void _cancelConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
  }
  void _initializeParticles() {
    final random = Random();
    for (int i = 0; i < 50; i++) {
      particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        vx: (random.nextDouble() - 0.5) * 0.0005,
        vy: (random.nextDouble() - 0.5) * 0.0005,
        size: random.nextDouble() * 3 + 1,
        opacity: random.nextDouble() * 0.5 + 0.2,
      ));
    }
  }

  void _handleCancelConnection(VpnConnectionProvider vpnValue) {
    debugPrint('🔴 User cancelled connection');

    // ✅ CANCEL TIMEOUT TIMER
    _cancelConnectionTimeout();

    // Disconnect the VPN
    vpnValue.disconnect();

    // Update UI state
    setState(() => _vpnUiStatus = VpnUiStatus.disconnected);

    // Stop and reset progress animation
    _progressController.stop();
    _progressController.reset();

    // Show feedback to user
    showLogoToast("Connection cancelled", color: AppTheme.warning);
  }

  Widget _buildConnectionStatus(bool connected, bool isConnecting, VpnConnectionProvider vpnValue) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      child: (!connected && !isConnecting)
          ? const SizedBox.shrink()
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Existing CONNECTED/CONNECTING status badge
          Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: (connected ? AppTheme.connected : AppTheme.connecting)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (connected ? AppTheme.connected : AppTheme.connecting)
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected ? AppTheme.connected : AppTheme.connecting,
                    boxShadow: [
                      BoxShadow(
                        color: (connected ? AppTheme.connected : AppTheme.connecting)
                            .withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  connected ? "CONNECTED" : "CONNECTING...",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: connected ? AppTheme.connected : AppTheme.connecting,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // ✅ NEW: Cancel button (only shown when connecting)
          AnimatedSize(
            duration: const Duration(milliseconds: 2000),
            curve: Curves.easeInOut,
            child: isConnecting
                ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _handleCancelConnection(vpnValue);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.error.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "CANCEL",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.error,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
                : const SizedBox.shrink(),
          ),

          // Existing upload/download stats (shown when connected)
          AnimatedSize(
            duration: const Duration(milliseconds: 2000),
            curve: Curves.easeInOut,
            child: connected
                ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.getCardColor(context).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.connected.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.connected.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.arrow_upward_rounded, color: AppTheme.success, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "UPLOAD",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: AppTheme.getTextSecondaryColor(context),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formatSpeed(vpnValue.status?.byteOut),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: AppTheme.getTextPrimaryColor(context),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              height: 40,
                              width: 1.5,
                              color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
                            ),

                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentLight.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.arrow_downward_rounded, color: AppTheme.accentLight, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "DOWNLOAD",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: AppTheme.getTextSecondaryColor(context),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formatSpeed(vpnValue.status?.byteIn),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: AppTheme.getTextPrimaryColor(context),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
              ],
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectionTimeoutTimer?.cancel(); // ✅ ADD THIS

    _pulseController.dispose();
    _meshController.dispose();
    _particleController.dispose();
    _progressController.dispose();
    _drawerIconController.dispose();
    _buttonPressController.dispose();
    _serverPressController.dispose();
    _connectivitySubscription?.cancel();
    _buttonMoveController.dispose();
    _borderAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // void _loadAppState() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   bool wasConnected = prefs.getBool('isConnected') ?? false;
  //
  //   if (wasConnected && mounted) {
  //     setState(() => _vpnUiStatus = VpnUiStatus.connected);
  //   }
  // }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (result.contains(ConnectivityResult.none)) {
      showLogoToast("No Connection", color: AppTheme.error);
    }
  }

  String formatSpeed(String? bytes) {
    double b = double.tryParse(bytes ?? "0") ?? 0;
    if (b <= 0) return "0.0 Mbps";
    return "${((b * 8) / 1000000).toStringAsFixed(1)} Mbps";
  }

  Widget _buildParticleBackground(bool isConnected) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        for (var particle in particles) {
          particle.x += particle.vx;
          particle.y += particle.vy;

          if (particle.x < 0) particle.x = 1;
          if (particle.x > 1) particle.x = 0;
          if (particle.y < 0) particle.y = 1;
          if (particle.y > 1) particle.y = 0;
        }

        return CustomPaint(
          painter: ParticlePainter(
            particles: particles,
            isConnected: isConnected,
            isDark: AppTheme.isDarkMode(context),
            animationValue: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMeshBackground() {
    final isDark = AppTheme.isDarkMode(context);
    final isConnected = _vpnUiStatus == VpnUiStatus.connected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      decoration: BoxDecoration(
        color: isConnected
            ? const Color(0xFF10B981).withOpacity(isDark ? 0.15 : 0.08)
            : const Color(0xFF1D4ED8).withOpacity(isDark ? 0.15 : 0.08),
      ),
    );
  }

  Widget _buildSpeedCard(String label, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.42,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context).withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.getTextSecondaryColor(context),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AutoSizeText(
                value,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: AppTheme.getTextPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ STEP 4: Clean Power Orb with Switch Statement
  Widget _buildPowerOrb(VpnConnectionProvider vpnValue, ServersProvider serversProvider) {
    final isDark = AppTheme.isDarkMode(context);

    // ✅ Determine colors based on enum state
    Color statusColor;
    switch (_vpnUiStatus) {
      case VpnUiStatus.connected:
        statusColor = AppTheme.connected;
        break;
      case VpnUiStatus.connecting:
        statusColor = AppTheme.connecting;
        break;
      case VpnUiStatus.disconnected:
        statusColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
        break;
    }

    final connected = _vpnUiStatus == VpnUiStatus.connected;
    final isConnecting = _vpnUiStatus == VpnUiStatus.connecting;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isButtonPressed = true);
        _buttonPressController.forward();
      },
      onTapUp: (_) {
        setState(() => _isButtonPressed = false);
        _buttonPressController.reverse();
      },
      onTapCancel: () {
        setState(() => _isButtonPressed = false);
        _buttonPressController.reverse();
      },
      onTap: () async {
        HapticFeedback.mediumImpact();

        // ✅ STEP 5: Lock button during connecting
        if (_vpnUiStatus == VpnUiStatus.connecting) return;

        if (connected) {
          showEnhancedDisconnectDialog(context, () async {
            // adsController.showInterstitial();
            await vpnValue.disconnect();
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isConnected', false);
            setState(() => _vpnUiStatus = VpnUiStatus.disconnected);
            _progressController.reset();
            showLogoToast("Disconnected", color: AppTheme.error);
          });
        } else {
          if (serversProvider.freeServers.isEmpty) {
            showLogoToast("Loading servers...", color: AppTheme.warning);
            await serversProvider.getServers();
          }

          if (serversProvider.selectedServer == null) {
            return showLogoToast("Please select a server", color: AppTheme.error);
          }

          if (serversProvider.selectedServer!.ovpn.isEmpty) {
            showLogoToast("Server config missing, retrying...", color: AppTheme.warning);
            await serversProvider.getServers();

            if (serversProvider.selectedServer == null ||
                serversProvider.selectedServer!.ovpn.isEmpty) {
              return showLogoToast("Server data unavailable", color: AppTheme.error);
            }
          }

          debugPrint('🔵 Connecting to: ${serversProvider.selectedServer!.country}');
          debugPrint('🔵 OVPN config length: ${serversProvider.selectedServer!.ovpn.length}');

          // ✅ SINGLE STATE UPDATE - Set to connecting
          setState(() => _vpnUiStatus = VpnUiStatus.connecting);
          _progressController.repeat();

          // // Connection timeout
          // Future.delayed(const Duration(seconds: 30), () {
          //   if (mounted && _vpnUiStatus == VpnUiStatus.connecting) {
          //     setState(() => _vpnUiStatus = VpnUiStatus.disconnected);
          //     _progressController.stop();
          //     _progressController.reset();
          //     showLogoToast("Connection timeout - Please try again", color: AppTheme.error);
          //   }
          // });


// ✅ START 15-SECOND TIMEOUT
          _startConnectionTimeout();

          final AppsController apps = Get.find();
          vpnValue.initPlatformState(
            serversProvider.selectedServer!.ovpn,
            serversProvider.selectedServer!.country,
            apps.disallowList,
            serversProvider.selectedServer!.username ?? "",
            serversProvider.selectedServer!.password ?? "",
          );
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _progressController, _buttonPressController]),
        builder: (context, child) {
          final pressScale = 1.0 - (_buttonPressController.value * 0.05);

          return Transform.scale(
            scale: pressScale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (connected) ...[
                  Container(
                    width: 240 + (_pulseController.value * 20),
                    height: 240 + (_pulseController.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withOpacity(0.2 - (_pulseController.value * 0.15)),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 210 + (_pulseController.value * 15),
                    height: 210 + (_pulseController.value * 15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: statusColor.withOpacity(0.3 - (_pulseController.value * 0.2)),
                        width: 2,
                      ),
                    ),
                  ),
                ],

                if (isConnecting)
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: null,
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      backgroundColor: statusColor.withOpacity(0.1),
                    ),
                  ),

                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.6),
                        blurRadius: 50,
                        spreadRadius: connected ? 15 : 8,
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withOpacity(0.9),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _vpnUiStatus == VpnUiStatus.connected
                            ? Icons.shield_outlined
                            : _vpnUiStatus == VpnUiStatus.connecting
                            ? Icons.vpn_lock_rounded
                            : Icons.power_settings_new_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _vpnUiStatus == VpnUiStatus.connected
                            ? "DISCONNECT"
                            : _vpnUiStatus == VpnUiStatus.connecting
                            ? "CONNECTING"
                            : "CONNECT",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: _vpnUiStatus == VpnUiStatus.connected ? 12 : 14,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedDrawerIcon(bool isConnected) {
    return AnimatedBuilder(
      animation: _drawerIconController,
      builder: (context, child) {
        final scale = 1.0 - (_drawerIconController.value * 0.1);
        final iconColor = isConnected ? AppTheme.connected : AppTheme.getPrimaryColor(context);

        return Transform.scale(
          scale: scale,
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _drawerIconController.forward().then((_) {
                _drawerIconController.reverse();
              });
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MoreScreen()),
              );
            },
            icon: Icon(
              Icons.menu_rounded,
              color: iconColor,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VpnConnectionProvider, ServersProvider>(
      builder: (context, vpnValue, serversProvider, child) {
        // ✅ STEP 6: ONE SOURCE OF TRUTH - Use enum for all UI logic
        final connected = _vpnUiStatus == VpnUiStatus.connected;
        final isConnecting = _vpnUiStatus == VpnUiStatus.connecting;

        // Button movement animation
        if (connected && !_buttonMoveController.isCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _buttonMoveController.forward();
          });
        } else if (!connected && !isConnecting && _buttonMoveController.isCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _buttonMoveController.reverse();
          });
        }

        if (connected && !_borderAnimationController.isAnimating) {
          _borderAnimationController.repeat();
        } else if (!connected && _borderAnimationController.isAnimating) {
          _borderAnimationController.stop();
          _borderAnimationController.reset();
        }

        return Scaffold(
          backgroundColor: AppTheme.getBackgroundColor(context),
          // Replace your existing build method's body (inside Scaffold) with this:

          body: Stack(
            children: [
              _buildMeshBackground(),
              _buildParticleBackground(connected),

              // ✅ SOLUTION: Wrap SafeArea content in LayoutBuilder + SingleChildScrollView
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(), // Prevents bouncing
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight, // Takes full available height
                        ),
                        child: IntrinsicHeight( // ✅ Important: Makes Column fill available space
                          child: Column(
                            children: [
                              // 🔹 Header with Shield Logo & Menu
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: connected
                                                  ? [AppTheme.connected, AppTheme.connected.withOpacity(0.7)]
                                                  : [AppTheme.getPrimaryColor(context), AppTheme.getPrimaryColor(context).withOpacity(0.7)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (connected ? AppTheme.connected : AppTheme.getPrimaryColor(context)).withOpacity(0.3),
                                                blurRadius: 12,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.shield_outlined,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "SHIELD VPN",
                                              style: GoogleFonts.poppins(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: AppTheme.getTextPrimaryColor(context),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            Text(
                                              connected ? "Protected" : "Not Protected",
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: connected
                                                    ? AppTheme.connected
                                                    : AppTheme.getTextSecondaryColor(context).withOpacity(0.6),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 800),
                                          curve: Curves.easeInOut,
                                          decoration: BoxDecoration(
                                            color: AppTheme.getCardColor(context).withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: connected
                                                  ? AppTheme.connected.withOpacity(0.4)
                                                  : AppTheme.getPrimaryColor(context).withOpacity(0.2),
                                              width: 1.5,
                                            ),
                                            boxShadow: connected ? [
                                              BoxShadow(
                                                color: AppTheme.connected.withOpacity(0.15),
                                                blurRadius: 12,
                                                spreadRadius: 1,
                                              ),
                                            ] : [],
                                          ),
                                          child: _buildAnimatedDrawerIcon(connected),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 🔹 Banner Ad
                              // Obx(() {
                              //   if (adsController.banner != null) {
                              //     return Container(
                              //       margin: const EdgeInsets.only(bottom: 20),
                              //       alignment: Alignment.center,
                              //       width: adsController.banner!.size.width.toDouble(),
                              //       height: adsController.banner!.size.height.toDouble(),
                              //       child: AdWidget(ad: adsController.banner!),
                              //     );
                              //   }
                              //   return const SizedBox.shrink();
                              // }),

                              // ✅ KEEP SPACER - it will work correctly inside IntrinsicHeight
                              const Spacer(flex: 4),

                              // 🔹 Power Orb with Connection Status
                              AnimatedBuilder(
                                animation: _buttonMoveController,
                                builder: (context, child) {
                                  final moveOffset = _buttonMoveController.value * -30;

                                  return Transform.translate(
                                    offset: Offset(0, moveOffset),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildPowerOrb(vpnValue, serversProvider),
                                        _buildConnectionStatus(connected, isConnecting, vpnValue),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                              // 🔹 Server Selection Card
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                                child: AnimatedBuilder(
                                  animation: _serverPressController,
                                  builder: (context, child) {
                                    final pressScale = 1.0 - (_serverPressController.value * 0.05);

                                    return Transform.scale(
                                      scale: pressScale,
                                      child: GestureDetector(
                                        onTapDown: (_) {
                                          _serverPressController.forward();
                                          HapticFeedback.mediumImpact();
                                        },
                                        onTapUp: (_) {
                                          _serverPressController.reverse();
                                        },
                                        onTapCancel: () {
                                          _serverPressController.reverse();
                                        },
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            barrierColor: Colors.black.withOpacity(0.5),
                                            isDismissible: true,
                                            enableDrag: true,
                                            transitionAnimationController: AnimationController(
                                              vsync: Navigator.of(context),
                                              duration: Duration.zero,
                                            )..forward(),
                                            builder: (context) => Container(
                                              height: MediaQuery.of(context).size.height * 0.95,
                                              decoration: BoxDecoration(
                                                color: AppTheme.getBackgroundColor(context),
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(28),
                                                  topRight: Radius.circular(28),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 20,
                                                    spreadRadius: 5,
                                                    offset: const Offset(0, -5),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () => Navigator.pop(context),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      child: Container(
                                                        width: 40,
                                                        height: 5,
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.getTextSecondaryColor(context).withOpacity(0.4),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: ServerTabs(isConnected: connected),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(24),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 800),
                                              curve: Curves.easeInOut,
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: AppTheme.getCardColor(context).withOpacity(0.4),
                                                borderRadius: BorderRadius.circular(24),
                                                border: Border.all(
                                                  color: connected
                                                      ? AppTheme.connected.withOpacity(0.3)
                                                      : AppTheme.getPrimaryColor(context).withOpacity(0.3),
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: connected
                                                        ? AppTheme.connected.withOpacity(0.1)
                                                        : AppTheme.getPrimaryColor(context).withOpacity(0.1),
                                                    blurRadius: 20,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: connected
                                                            ? AppTheme.connected.withOpacity(0.6)
                                                            : AppTheme.getPrimaryColor(context).withOpacity(0.3),
                                                        width: 2,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
                                                          blurRadius: 10,
                                                        ),
                                                      ],
                                                    ),
                                                    child: ClipOval(
                                                      child: serversProvider.selectedServer != null
                                                          ? Image.asset(
                                                        'assets/flags/${serversProvider.selectedServer!.countryCode.toLowerCase()}.png',
                                                        fit: BoxFit.cover,
                                                        cacheWidth: 100,
                                                        cacheHeight: 100,
                                                      )
                                                          : Container(
                                                        color: connected
                                                            ? AppTheme.connected.withOpacity(0.1)
                                                            : AppTheme.getPrimaryColor(context).withOpacity(0.1),
                                                        child: Icon(
                                                          Icons.public,
                                                          color: connected ? AppTheme.connected : AppTheme.getPrimaryColor(context),
                                                          size: 24,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "SECURE LOCATION",
                                                          style: GoogleFonts.poppins(
                                                            color: AppTheme.getTextSecondaryColor(context),
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                            letterSpacing: 1,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          serversProvider.selectedServer?.country ?? "Select Smart Server",
                                                          style: GoogleFonts.poppins(
                                                            color: AppTheme.getTextPrimaryColor(context),
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: connected
                                                          ? AppTheme.connected.withOpacity(0.2)
                                                          : AppTheme.getPrimaryColor(context).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Icon(
                                                      Icons.arrow_forward_ios_rounded,
                                                      color: connected ? AppTheme.connected : AppTheme.getPrimaryColor(context),
                                                      size: 18,
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

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final bool isConnected;
  final bool isDark;
  final double animationValue;

  ParticlePainter({
    required this.particles,
    required this.isConnected,
    required this.isDark,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      final x = particle.x * size.width;
      final y = particle.y * size.height;

      Color particleColor;
      if (isConnected) {
        particleColor = AppTheme.connected;
      } else {
        particleColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
      }

      paint.color = particleColor.withOpacity(particle.opacity * (isConnected ? 0.8 : 0.4));
      canvas.drawCircle(Offset(x, y), particle.size, paint);

      if (isConnected) {
        paint.color = particleColor.withOpacity(particle.opacity * 0.2);
        canvas.drawCircle(Offset(x, y), particle.size * 3, paint);
      }
    }

    if (isConnected) {
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      for (int i = 0; i < particles.length; i++) {
        for (int j = i + 1; j < particles.length; j++) {
          final p1 = particles[i];
          final p2 = particles[j];

          final dx = (p1.x - p2.x) * size.width;
          final dy = (p1.y - p2.y) * size.height;
          final distance = sqrt(dx * dx + dy * dy);

          if (distance < 100) {
            final opacity = (1 - distance / 100) * 0.3;
            linePaint.color = AppTheme.connected.withOpacity(opacity);
            canvas.drawLine(
              Offset(p1.x * size.width, p1.y * size.height),
              Offset(p2.x * size.width, p2.y * size.height),
              linePaint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  const _GlowOrb({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 350,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

void showEnhancedDisconnectDialog(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (c) => BackdropFilter(
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
              size: 25,
            ),
            const SizedBox(width: 7),
            Text(
              "Stop Connection?",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to disconnect from this secure server?",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.getTextSecondaryColor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(
              "CANCEL",
              style: GoogleFonts.poppins(
                color: AppTheme.getTextSecondaryColor(context),
                fontWeight: FontWeight.w500,
                fontSize: 15,

              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(c);
              onConfirm();
            },
            child: Text(
              "DISCONNECT",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,

              ),
            ),
          ),
        ],
      ),
    ),
  );
}