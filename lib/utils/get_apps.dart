// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class GetApps {
  // USER INSTALLED APPS (NON-SYSTEM)
  static Future<List<AppInfo>> getInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(withIcon: true);

      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return apps;
    } catch (e) {
      debugPrint('Error fetching installed apps: $e');
      return [];
    }
  }

  // ALL SYSTEM APPS
  static Future<List<AppInfo>> getSystemApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        withIcon: true,
      );

      // System apps = those NOT installed by user
      final systemApps = apps.where((app) => app.isSystemApp == true).toList();

      systemApps
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return systemApps;
    } catch (e) {
      debugPrint('Error fetching system apps: $e');
      return [];
    }
  }
}
