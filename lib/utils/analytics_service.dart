import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static Future<void> logFirebaseEvent(String eventName) async {
    final firebaseAnalytics = FirebaseAnalytics.instance;
    await firebaseAnalytics.logEvent(name: eventName);
    debugPrint("Event fired: $eventName");
  }
}
