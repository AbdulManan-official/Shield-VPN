import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VpnConnectionProvider with ChangeNotifier {
  double radius = 0;

  bool _isInitialized = false;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isChangingServer = false;

  late OpenVPN engine;
  VpnStatus? status;
  VPNStage? stage;

  final StreamController<VPNStage> _stageController =
      StreamController<VPNStage>.broadcast();

  Stream<VPNStage> get stageStream => _stageController.stream;

  bool get isConnected => _isConnected;

  bool get isConnecting => _isConnecting;

  bool get isChangingServer => _isChangingServer;

  bool get isInitialized => _isInitialized;

  @override
  void dispose() {
    _stageController.close();
    super.dispose();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    engine = OpenVPN(
      onVpnStatusChanged: (data) {
        status = data;
        notifyListeners();
      },
      onVpnStageChanged: (data, raw) {
        stage = data;
        _stageController.add(data);
        _handleStage(data);
      },
    );

    await engine.initialize(
      groupIdentifier: "group.com.laskarmedia.vpn",
      providerBundleIdentifier:
          "id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin",
      localizedDescription: "VPN by Nizwar",
      lastStage: (stage) {
        this.stage = stage;
        _stageController.add(stage); // ✅ REQUIRED
        _handleStage(stage);
      },
      lastStatus: (status) {
        this.status = status;
        notifyListeners();
      },
    );

    _isInitialized = true;
    notifyListeners();
  }

  void _handleStage(VPNStage data) {
    switch (data) {
      case VPNStage.connected:
        _isConnected = true;
        _isConnecting = false;
        saveVpnState();
        break;

      case VPNStage.disconnected:
      case VPNStage.denied:
      case VPNStage.error:
        _isConnected = false;
        _isConnecting = false;
        saveVpnState();
        break;

      case VPNStage.connecting:
      case VPNStage.authenticating:
      case VPNStage.prepare:
      case VPNStage.vpn_generate_config:
        _isConnecting = true;
        _isConnected = false;
        break;

      default:
        break;
    }
    notifyListeners();
  }

  Future<void> initPlatformState(
    String ovpn,
    String country,
    List<String> disallowList,
    String username,
    String password,
  ) async {
    await initialize();

    final bypassList = {
      "com.shieldvpn.vpnmax",
      ...disallowList,
    }.toList();

    _isConnecting = true;
    notifyListeners();

    debugPrint(bypassList.toString());

    engine.connect(
      ovpn,
      country,
      username: username,
      password: password,
      bypassPackages: bypassList,
      certIsRequired: true,
    );
  }

  Future<void> disconnect() async {
    try {
      engine.disconnect();
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
  }

  Future<void> saveVpnState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isConnected', _isConnected);
  }

  Future<void> restoreVpnState() async {
    await initialize();
  }

  void startServerChange() {
    _isChangingServer = true;
    notifyListeners();
  }

  void completeServerChange() {
    _isChangingServer = false;
    notifyListeners();
  }

  void setRadius() {
    radius = 0.25;
    notifyListeners();
  }

  void resetRadius() {
    radius = 0;
    notifyListeners();
  }
}

// import 'dart:async';
// import 'dart:developer';
//
// import 'package:flutter/foundation.dart';
// import 'package:openvpn_flutter/openvpn_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class VpnConnectionProvider with ChangeNotifier {
//   double radius = 0;
//   bool _isInitialized = false;
//   bool _isConnected = false;
//   bool _isConnecting = false; // Add this to track connection state
//
//   bool _isChangingServer = false;
//
//   bool get isChangingServer => _isChangingServer;
//
//   bool get isConnecting => _isConnecting; // Add getter
//
//   final StreamController<VPNStage> _stageController =
//       StreamController<VPNStage>.broadcast();
//
//   Stream<VPNStage> get stageStream => _stageController.stream;
//
//   @override
//   void dispose() {
//     _stageController.close();
//     super.dispose();
//   }
//
//   void startServerChange() {
//     _isChangingServer = true;
//     notifyListeners();
//   }
//
//   void completeServerChange() {
//     _isChangingServer = false;
//     notifyListeners();
//   }
//
//   bool get isConnected => _isConnected;
//
//   Future<void> saveVpnState() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     prefs.setBool('isConnected', _isConnected);
//   }
//
//   Future<void> restoreVpnState() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     _isConnected = prefs.getBool('isConnected') ?? false;
//
//     if (_isConnected) {
//       initialize();
//     }
//   }
//
//   void setRadius() {
//     radius = 0.25;
//     notifyListeners();
//   }
//
//   void resetRadius() {
//     radius = 0;
//     notifyListeners();
//   }
//
//   late OpenVPN engine;
//   VpnStatus? status;
//   VPNStage? stage;
//
//   // bool init = true;
//
//   bool getInitCheck() => _isInitialized;
//   String defaultVpnUsername = "freeopenvpn";
//   String defaultVpnPassword = "605196725";
//   String config = "YOUR OPENVPN CONFIG HERE";
//
//   Future<void> initialize() async {
//     if (_isInitialized) return;
//
//     engine = OpenVPN(
//       onVpnStatusChanged: (data) {
//         status = data;
//         notifyListeners();
//       },
//       onVpnStageChanged: (data, raw) {
//         stage = data;
//
//         _stageController.add(data);
//
//         // Update connection states based on actual VPN stage
//         if (data == VPNStage.connected) {
//           _isConnected = true;
//           _isConnecting = false;
//           saveVpnState();
//         } else if (data == VPNStage.disconnected) {
//           _isConnected = false;
//           _isConnecting = false;
//           saveVpnState();
//         } else if (data == VPNStage.connecting ||
//             data == VPNStage.authenticating ||
//             data == VPNStage.prepare ||
//             data == VPNStage.vpn_generate_config) {
//           _isConnecting = true;
//           _isConnected = false;
//         } else if (data == VPNStage.error ||
//             data == VPNStage.denied ||
//             data == VPNStage.unknown) {
//           _isConnecting = false;
//           _isConnected = false;
//           saveVpnState();
//         }
//
//         notifyListeners();
//       },
//     );
//
//     await engine.initialize(
//       groupIdentifier: "group.com.laskarmedia.vpn",
//       providerBundleIdentifier:
//           "id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin",
//       localizedDescription: "VPN by Nizwar",
//       lastStage: (stage) {
//         this.stage = stage;
//
//         _stageController.add(stage);
//
//         // Same logic as above for stage changes
//         if (stage == VPNStage.connected) {
//           _isConnected = true;
//           _isConnecting = false;
//           saveVpnState();
//         } else if (stage == VPNStage.disconnected) {
//           _isConnected = false;
//           _isConnecting = false;
//           saveVpnState();
//         } else if (stage == VPNStage.connecting ||
//             stage == VPNStage.authenticating ||
//             stage == VPNStage.prepare ||
//             stage == VPNStage.vpn_generate_config) {
//           _isConnecting = true;
//           _isConnected = false;
//         } else if (stage == VPNStage.error ||
//             stage == VPNStage.denied ||
//             stage == VPNStage.unknown) {
//           _isConnecting = false;
//           _isConnected = false;
//           saveVpnState();
//         }
//
//         notifyListeners();
//       },
//       lastStatus: (status) {
//         this.status = status;
//         notifyListeners();
//       },
//     );
//
//     _isInitialized = true;
//     notifyListeners();
//   }
//
//   Future<void> initPlatformState(
//     String ovpn,
//     String country,
//     List<String> disallowList,
//     String username,
//     String pass,
//   ) async {
//     try {
//       if (kDebugMode) {
//         debugPrint("username $username");
//         debugPrint("password $pass");
//       }
//       config = ovpn;
//
//       // Set connecting state instead of connected
//       _isConnecting = true;
//       _isConnected = false;
//       notifyListeners();
//
//       final myPackage = "com.shieldvpn.vpnmax";
//
//       final bypassList = {
//         myPackage,
//         ...disallowList,
//       }.toList();
//
//       debugPrint("BYPASS APPS: $bypassList");
//
//       await engine.connect(
//         config,
//         country,
//         username: username,
//         password: pass,
//         bypassPackages: bypassList,
//         certIsRequired: true,
//       );
//
//       // Don't set _isConnected = true here!
//       // Let the onVpnStageChanged callback handle the actual connection state
//     } catch (e) {
//       log(e.toString());
//       _isConnecting = false;
//       _isConnected = false;
//       notifyListeners();
//     }
//   }
//
//   // Add method to manually disconnect
//   Future<void> disconnect() async {
//     try {
//       _isConnecting = false;
//       _isConnected = false;
//       engine.disconnect();
//       await saveVpnState();
//       notifyListeners();
//     } catch (e) {
//       log('Disconnect error: $e');
//     }
//   }
// }
