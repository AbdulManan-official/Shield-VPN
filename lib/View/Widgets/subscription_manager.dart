// // Subscription Manager - Central place for all subscription logic
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// import '../../utils/preferences.dart';

// class SubscriptionManager {
//   static const String _subscriptionKey = 'isSubscribed';
//   static const String _subscriptionTypeKey = 'subscription_type';
//   static const String _subscriptionDateKey = 'subscription_date';
  
//   // Product IDs
//   static const String monthlyProductId = 'vpnmax_999_1m';
//   static const String yearlyProductId = 'vpnmax_99_1year';
//   static const String oneTimeProductId = 'one_time_purchase';
  
//   static final Set<String> productIds = {
//     monthlyProductId,
//     yearlyProductId,
//     oneTimeProductId,
//   };
  
//   // Check if user has active subscription
//   static bool hasActiveSubscription() {
//     return Prefs.getBool(_subscriptionKey) ?? false;
//   }
  
//   // Get subscription type
//   static String getSubscriptionType() {
//     return Prefs.getString(_subscriptionTypeKey) ?? 'none';
//   }
  
//   // Get subscription date
//   static String getSubscriptionDate() {
//     return Prefs.getString(_subscriptionDateKey) ?? '';
//   }
  
//   // Set subscription status
//   static Future<void> setSubscriptionStatus({
//     required bool isSubscribed,
//     String subscriptionType = 'premium',
//   }) async {
//     await Prefs.setBool(_subscriptionKey, isSubscribed);
//     if (isSubscribed) {
//       await Prefs.setString(_subscriptionTypeKey, subscriptionType);
//       await Prefs.setString(_subscriptionDateKey, DateTime.now().toIso8601String());
//     } else {
//       await Prefs.remove(_subscriptionTypeKey);
//       await Prefs.remove(_subscriptionDateKey);
//     }
//   }
  
//   // Clear subscription data
//   static Future<void> clearSubscriptionData() async {
//     await Prefs.remove(_subscriptionKey);
//     await Prefs.remove(_subscriptionTypeKey);
//     await Prefs.remove(_subscriptionDateKey);
//   }
// }

// // Extension for responsive design
// extension ResponsiveExtension on BuildContext {
//   double get screenWidth => MediaQuery.of(this).size.width;
//   double get screenHeight => MediaQuery.of(this).size.height;
//   double get screenSize => screenWidth * screenHeight;
  
//   EdgeInsets responsivePadding({
//     double horizontal = 0,
//     double vertical = 0,
//     double all = 0,
//   }) {
//     if (all > 0) {
//       return EdgeInsets.all(screenSize * all / 400000);
//     }
//     return EdgeInsets.symmetric(
//       horizontal: screenSize * horizontal / 400000,
//       vertical: screenSize * vertical / 400000,
//     );
//   }
  
//   double responsiveSpacing(double spacing) {
//     return screenSize * spacing / 400000;
//   }
  
//   double responsiveBorderRadius(double radius) {
//     return screenSize * radius / 400000;
//   }
  
//   double responsiveIconSize(double size) {
//     return screenSize * size / 400000;
//   }
  
//   TextStyle responsiveTextStyle({
//     required double fontSize,
//     FontWeight? fontWeight,
//     Color? color,
//     double? letterSpacing,
//   }) {
//     return GoogleFonts.poppins(
//       fontSize: screenSize >= 370000 ? fontSize : fontSize + 1,
//       fontWeight: fontWeight ?? FontWeight.normal,
//       color: color ?? Colors.white,
//       letterSpacing: letterSpacing,
//     );
//   }
// }