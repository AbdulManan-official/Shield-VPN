// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class GetApps {
  // Your existing function for user-installed apps
  static Future<List<AppInfo>> GetAllAppInfo() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true, "");
    debugPrint(apps[0].name);
    return apps;
  }

  // New function for social system apps only
  static Future<List<AppInfo>> GetSocialSystemApps() async {
    // Define social system apps package names
    final Set<String> socialSystemPackages = {
      'com.android.chrome',
      'com.google.android.youtube',
      'com.android.vending', // Google Play Store
      'com.google.android.gm', // Gmail
      'com.google.android.apps.maps', // Google Maps
      'com.google.android.talk', // Google Hangouts
      'com.google.android.apps.messaging', // Messages
      'com.google.android.contacts', // Contacts
      'com.google.android.dialer', // Phone
      'com.google.android.gallery3d', // Gallery
      'com.google.android.calendar', // Calendar
      'com.google.android.apps.photos', // Google Photos
      'com.google.android.music', // Google Play Music
      'com.google.android.videos', // Google Play Movies & TV
      'com.android.browser', // Default Browser
      'com.sec.android.app.sbrowser', // Samsung Internet
      'com.miui.browser', // MIUI Browser (Xiaomi)
      'com.huawei.browser', // Huawei Browser
      'com.opera.browser', // Opera Browser
      'com.microsoft.emmx', // Microsoft Edge
      'com.android.email', // Email app
      'com.google.android.apps.docs', // Google Docs
      'com.google.android.apps.sheets', // Google Sheets
      'com.google.android.apps.slides', // Google Slides
      'com.google.android.drive', // Google Drive
      'com.google.android.youtube.music', // YouTube Music
      'com.google.android.apps.plus', // Google+
      // Add more social system apps as needed
    };

    try {
      // Get all apps including system apps (false = include system apps)
      List<AppInfo> allApps =
          await InstalledApps.getInstalledApps(false, true, "");

      // Filter to get only social system apps
      List<AppInfo> socialSystemApps = allApps.where((app) {
        return socialSystemPackages.contains(app.packageName);
      }).toList();

      // Sort alphabetically by app name
      socialSystemApps.sort((a, b) =>
          (a.name).toLowerCase().compareTo((b.name).toLowerCase()));

      debugPrint('Found ${socialSystemApps.length} social system apps');
      return socialSystemApps;
    } catch (e) {
      debugPrint('Error getting social system apps: $e');
      return [];
    }
  }

  // Helper function to check if an app is a social system app
  static bool isSocialSystemApp(String packageName) {
    final Set<String> socialSystemPackages = {
      'com.android.chrome',
      'com.google.android.youtube',
      'com.android.vending',
      'com.google.android.gm',
      'com.google.android.apps.maps',
      'com.google.android.talk',
      'com.google.android.apps.messaging',
      'com.google.android.contacts',
      'com.google.android.dialer',
      'com.google.android.gallery3d',
      'com.google.android.calendar',
      'com.google.android.apps.photos',
      'com.google.android.music',
      'com.google.android.videos',
      'com.android.browser',
      'com.sec.android.app.sbrowser',
      'com.miui.browser',
      'com.huawei.browser',
      'com.opera.browser',
      'com.microsoft.emmx',
      'com.android.email',
      'com.google.android.apps.docs',
      'com.google.android.apps.sheets',
      'com.google.android.apps.slides',
      'com.google.android.drive',
      'com.google.android.youtube.music',
      'com.google.android.apps.plus',
    };

    return socialSystemPackages.contains(packageName);
  }
}
