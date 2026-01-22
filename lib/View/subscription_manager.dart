// // Subscription Manager - Central place for all subscription logic
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:vpnsheild/utils/preferences.dart';
//
// class SubscriptionController extends GetxController {
//    String _subscriptionKey = 'isSubscribed';
//    String _subscriptionTypeKey = 'subscription_type';
//    String _subscriptionDateKey = 'subscription_date';
//
//   // Product IDs
//    String monthlyProductId = 'vpnmax_999_1m';
//     String yearlyProductId = 'vpnmax_99_1year';
//    String oneTimeProductId = 'one_time_purchase';
//
//   late final Set<String> productIds = {
//     monthlyProductId,
//     yearlyProductId,
//     oneTimeProductId,
//   };
//
//   // ---------------- STATE ----------------
//   final RxBool isSubscribed = false.obs;
//   final RxString subscriptionType = 'none'.obs;
//   final RxString subscriptionDate = ''.obs;
//
//   // ---------------- LIFECYCLE ----------------
//   @override
//   void onInit() {
//     super.onInit();
//     loadSubscriptionStatus();
//   }
//
//   // ---------------- LOGIC ----------------
//   Future<void> loadSubscriptionStatus() async {
//     isSubscribed.value = Prefs.getBool(_subscriptionKey) ?? false;
//     subscriptionType.value =
//         Prefs.getString(_subscriptionTypeKey) ?? 'none';
//     subscriptionDate.value =
//         Prefs.getString(_subscriptionDateKey) ?? '';
//
//     debugPrint(
//       '📊 Subscription loaded: ${isSubscribed.value} (${subscriptionType.value})',
//     );
//   }
//
//   Future<void> setSubscriptionStatus({
//     required bool subscribed,
//     required String type,
//   }) async {
//     debugPrint('🔥 setSubscriptionStatus: $subscribed / $type');
//
//     if (subscribed) {
//       await Prefs.setBool(_subscriptionKey, true);
//       await Prefs.setString(_subscriptionTypeKey, type);
//       await Prefs.setString(
//         _subscriptionDateKey,
//         DateTime.now().toIso8601String(),
//       );
//
//       isSubscribed.value = true;
//       subscriptionType.value = type;
//       subscriptionDate.value = DateTime.now().toIso8601String();
//     } else {
//       await Prefs.setBool(_subscriptionKey, false);
//       await Prefs.remove(_subscriptionTypeKey);
//       await Prefs.remove(_subscriptionDateKey);
//
//       isSubscribed.value = false;
//       subscriptionType.value = 'none';
//       subscriptionDate.value = '';
//     }
//   }
//
//   Future<void> clearSubscription() async {
//     await Prefs.remove(_subscriptionKey);
//     await Prefs.remove(_subscriptionTypeKey);
//     await Prefs.remove(_subscriptionDateKey);
//
//     isSubscribed.value = false;
//     subscriptionType.value = 'none';
//     subscriptionDate.value = '';
//   }
// }
//
// // class SubscriptionManager extends ChangeNotifier {
// //   static const String _subscriptionKey = 'isSubscribed';
// //   static const String _subscriptionTypeKey = 'subscription_type';
// //   static const String _subscriptionDateKey = 'subscription_date';
// //
// //   // Product IDs
// //   static const String monthlyProductId = 'vpnmax_999_1m';
// //   static const String yearlyProductId = 'vpnmax_99_1year';
// //   static const String oneTimeProductId = 'one_time_purchase';
// //
// //   bool _isSubscribed = false;
// //   String _subscriptionType = 'none';
// //   String _subscriptionDate = '';
// //
// //   // ---------------- GETTERS ----------------
// //
// //   bool get isSubscribed => _isSubscribed;
// //
// //   String get subscriptionType => _subscriptionType;
// //
// //   String get subscriptionDate => _subscriptionDate;
// //
// //   // ---------------- INIT / REFRESH ----------------
// //
// //   /// Call this on app start OR when tab becomes visible
// //   Future<void> loadSubscriptionStatus() async {
// //     _isSubscribed = Prefs.getBool(_subscriptionKey) ?? false;
// //     _subscriptionType = Prefs.getString(_subscriptionTypeKey) ?? 'none';
// //     _subscriptionDate = Prefs.getString(_subscriptionDateKey) ?? '';
// //
// //     notifyListeners();
// //   }
// //
// //   static final Set<String> productIds = {
// //     monthlyProductId,
// //     yearlyProductId,
// //     oneTimeProductId,
// //   };
// //
// //   // Check if user has active subscription
// //   static bool hasActiveSubscription() {
// //     return Prefs.getBool(_subscriptionKey) ?? false;
// //   }
// //
// //   // Get subscription type
// //   static String getSubscriptionType() {
// //     return Prefs.getString(_subscriptionTypeKey) ?? 'none';
// //   }
// //
// //   // Get subscription date
// //   static String getSubscriptionDate() {
// //     return Prefs.getString(_subscriptionDateKey) ?? '';
// //   }
// //
// //   // Set subscription status
// //   Future<void> setSubscriptionStatus({
// //     required bool isSubscribed,
// //     String subscriptionType = 'premium',
// //   }) async {
// //     debugPrint('🔥 setSubscriptionStatus CALLED: $isSubscribed');
// //     await Prefs.setBool(_subscriptionKey, isSubscribed);
// //     if (isSubscribed) {
// //       await Prefs.setString(_subscriptionTypeKey, subscriptionType);
// //       await Prefs.setString(
// //           _subscriptionDateKey, DateTime.now().toIso8601String());
// //     } else {
// //       await Prefs.remove(_subscriptionTypeKey);
// //       await Prefs.remove(_subscriptionDateKey);
// //     }
// //     await loadSubscriptionStatus();
// //   }
// //
// //   // Clear subscription data
// //   static Future<void> clearSubscriptionData() async {
// //     await Prefs.remove(_subscriptionKey);
// //     await Prefs.remove(_subscriptionTypeKey);
// //     await Prefs.remove(_subscriptionDateKey);
// //   }
// // }
