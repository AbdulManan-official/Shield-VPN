// Internet Connection Manager
import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vpnsheild/utils/custom_toast.dart';
import 'package:vpnsheild/utils/app_theme.dart'; // ✅ IMPORTED THEME!

class InternetConnectionManager {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  static bool _isConnected = true;
  static Function(bool)? _onConnectionChanged;

  static void initialize(Function(bool) onConnectionChanged) {
    _onConnectionChanged = onConnectionChanged;

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((connectivityResult) {
          _checkInternetConnection();
        });

    // Initial check
    _checkInternetConnection();
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
    _onConnectionChanged = null;
  }

  static Future<void> _checkInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        _updateConnectionStatus(false);
        return;
      }

      // Additional check with actual internet connectivity
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw const SocketException('Timeout'),
      );

      _updateConnectionStatus(
          result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    } catch (e) {
      _updateConnectionStatus(false);
    }
  }

  static void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _onConnectionChanged?.call(isConnected);

      if (!isConnected) {
        // ✅ USING AppTheme.error - RED COLOR!
        showLogoToast(
          'No internet connection',
          color: AppTheme.error,
        );
      } else {
        // ✅ USING AppTheme.success - GREEN COLOR!
        showLogoToast(
          'Internet connection restored',
          color: AppTheme.success,
        );
      }
    }
  }

  static bool get isConnected => _isConnected;

  static Future<bool> checkConnection() async {
    await _checkInternetConnection();
    return _isConnected;
  }
}