import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceDetailProvider extends ChangeNotifier {
  AndroidDeviceInfo? androidInfo;
  String _uuid = "";

  String get uuid => _uuid;
  AndroidDeviceInfo? get deviceInfo => androidInfo;

  Future<void> getDeviceInfo(String id) async {
    try {
      androidInfo = await DeviceInfoPlugin().androidInfo;

      // Safely print known fields instead of raw `data`
      debugPrint("Device ID : ${androidInfo?.id ?? 'Unknown'}");
      debugPrint("Model: ${androidInfo?.model}");
      debugPrint("Brand: ${androidInfo?.brand}");
      debugPrint("Device: ${androidInfo?.device}");

      _uuid = id;
      notifyListeners();
    } catch (e, stack) {
      debugPrint("Error while fetching device info: $e");
      debugPrint(stack.toString());
    }
  }
}
