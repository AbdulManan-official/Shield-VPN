import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:vpnsheild/View/premium_access_screen.dart';
import 'package:vpnsheild/View/subscription_manager.dart';

import '../providers/ads_controller.dart';
import '../utils/app_theme.dart';
import 'allowed_app_screen.dart' show AllowedAppsScreen;

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  // final SubscriptionController subscriptionManager = Get.find();
  // final AdsController adsController = Get.find();

  // void _showSubscriptionDialog(BuildContext context) {
  //   final hasSubscription = subscriptionManager.isSubscribed.value;
  //
  //   if (hasSubscription) {
  //     _showAlreadySubscribedDialog();
  //     return;
  //   }
  //
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => PremiumAccessScreen(),
  //     ),
  //   );
  // }
  //
  // void _showAlreadySubscribedDialog() {
  //   final subscriptionType = subscriptionManager.subscriptionType.value;
  //   final subscriptionDate = subscriptionManager.subscriptionDate.value;
  //
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return BackdropFilter(
  //         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  //         child: AlertDialog(
  //           backgroundColor: AppTheme.getCardColor(context).withOpacity(0.95),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(24),
  //             side: BorderSide(
  //               color: AppTheme.success.withOpacity(0.3),
  //             ),
  //           ),
  //           title: Row(
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(8),
  //                 decoration: BoxDecoration(
  //                   color: AppTheme.success.withOpacity(0.2),
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //                 child: Icon(
  //                   Icons.verified_rounded,
  //                   color: AppTheme.success,
  //                   size: 24,
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               Text(
  //                 'Premium Active',
  //                 style: GoogleFonts.poppins(
  //                   color: AppTheme.getTextPrimaryColor(context),
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           content: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'You have an active premium subscription!',
  //                 style: GoogleFonts.poppins(
  //                   color: AppTheme.getTextSecondaryColor(context),
  //                   fontSize: 14,
  //                 ),
  //               ),
  //               if (subscriptionType != 'none') ...[
  //                 const SizedBox(height: 12),
  //                 Container(
  //                   padding: const EdgeInsets.all(12),
  //                   decoration: BoxDecoration(
  //                     color: AppTheme.success.withOpacity(0.1),
  //                     borderRadius: BorderRadius.circular(12),
  //                     border: Border.all(
  //                       color: AppTheme.success.withOpacity(0.3),
  //                     ),
  //                   ),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         'Type: ${subscriptionType.toUpperCase()}',
  //                         style: GoogleFonts.poppins(
  //                           color: AppTheme.success,
  //                           fontSize: 13,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                       if (subscriptionDate.isNotEmpty) ...[
  //                         const SizedBox(height: 4),
  //                         Text(
  //                           'Since: ${DateTime.parse(subscriptionDate).toLocal().toString().split(' ')[0]}',
  //                           style: GoogleFonts.poppins(
  //                             color: AppTheme.getTextSecondaryColor(context),
  //                             fontSize: 12,
  //                           ),
  //                         ),
  //                       ],
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ],
  //           ),
  //           actions: [
  //             ElevatedButton(
  //               onPressed: () => Navigator.of(context).pop(),
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: AppTheme.success,
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //               ),
  //               child: Text(
  //                 'OK',
  //                 style: GoogleFonts.poppins(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  void dispose() {
    // adsController.disposeBanner2();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(context),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Premium Card
            // Obx(() {
            //   final isSubscribed = subscriptionManager.isSubscribed.value;
            //   return _buildPremiumCard(context, isSubscribed);
            // }),

            const SizedBox(height: 24),

            // Settings List
            _buildSettingsTile(
              context,
              icon: Icons.apps_rounded,
              title: 'App Filter',
              subtitle: 'Manage VPN for specific apps',
              onTap: () => Get.to(() => AllowedAppsScreen()),
            ),

            const SizedBox(height: 12),

            _buildSettingsTile(
              context,
              icon: Icons.share_rounded,
              title: 'Share App',
              subtitle: 'Tell your friends about VPN Max',
              onTap: () {},
            ),

            const SizedBox(height: 12),

            _buildSettingsTile(
              context,
              icon: Icons.feedback_rounded,
              title: 'Feedback',
              subtitle: 'Share your thoughts with us',
              onTap: () {},
            ),

            const SizedBox(height: 12),

            _buildSettingsTile(
              context,
              icon: Icons.system_update_rounded,
              title: 'Check for Updates',
              subtitle: 'Get the latest version',
              onTap: () {},
            ),

            const SizedBox(height: 24),

            // Banner Ad
            // Obx(() {
            //   if (!adsController.isBannerAd2Loaded.value && adsController.banner2 == null) {
            //     return const SizedBox();
            //   }
            //
            //   return Container(
            //     margin: const EdgeInsets.only(bottom: 20),
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(16),
            //       border: Border.all(
            //         color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
            //       ),
            //     ),
            //     child: ClipRRect(
            //       borderRadius: BorderRadius.circular(16),
            //       child: SizedBox(
            //         width: adsController.banner2!.size.width.toDouble(),
            //         height: adsController.banner2!.size.height.toDouble(),
            //         child: AdWidget(ad: adsController.banner2!),
            //       ),
            //     ),
            //   );
            // }),
          ],
        ),
      ),
    );
  }

  // Widget _buildPremiumCard(BuildContext context, bool isSubscribed) {
  //   return Material(
  //     color: Colors.transparent,
  //     child: InkWell(
  //       // onTap: () => _showSubscriptionDialog(context),
  //       borderRadius: BorderRadius.circular(20),
  //       splashColor: isSubscribed
  //           ? AppTheme.premiumGold.withOpacity(0.1)
  //           : AppTheme.getPrimaryColor(context).withOpacity(0.1),
  //       highlightColor: isSubscribed
  //           ? AppTheme.premiumGold.withOpacity(0.05)
  //           : AppTheme.getPrimaryColor(context).withOpacity(0.05),
  //       child: Ink(
  //         decoration: BoxDecoration(
  //           gradient: isSubscribed
  //               ? LinearGradient(
  //             colors: [
  //               AppTheme.premiumGradientStart.withOpacity(0.15),
  //               AppTheme.premiumGradientEnd.withOpacity(0.1),
  //             ],
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //           )
  //               : null,
  //           color: !isSubscribed ? AppTheme.getCardColor(context).withOpacity(0.6) : null,
  //           borderRadius: BorderRadius.circular(20),
  //           border: Border.all(
  //             color: isSubscribed
  //                 ? AppTheme.premiumGold.withOpacity(0.5)
  //                 : AppTheme.getPrimaryColor(context).withOpacity(0.3),
  //             width: 2,
  //           ),
  //         ),
  //         child: ClipRRect(
  //           borderRadius: BorderRadius.circular(20),
  //           child: BackdropFilter(
  //             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  //             child: Container(
  //               padding: const EdgeInsets.all(20),
  //               child: Row(
  //                 children: [
  //                   Container(
  //                     padding: const EdgeInsets.all(12),
  //                     decoration: BoxDecoration(
  //                       gradient: isSubscribed
  //                           ? LinearGradient(
  //                         colors: [
  //                           AppTheme.premiumGold.withOpacity(0.3),
  //                           AppTheme.premiumGoldDark.withOpacity(0.2),
  //                         ],
  //                         begin: Alignment.topLeft,
  //                         end: Alignment.bottomRight,
  //                       )
  //                           : null,
  //                       color: !isSubscribed
  //                           ? AppTheme.getPrimaryColor(context).withOpacity(0.15)
  //                           : null,
  //                       borderRadius: BorderRadius.circular(12),
  //                     ),
  //                     child: Icon(
  //                       isSubscribed ? Icons.verified_rounded : Icons.workspace_premium_rounded,
  //                       color: isSubscribed ? AppTheme.premiumGold : AppTheme.getPrimaryColor(context),
  //                       size: 28,
  //                     ),
  //                   ),
  //                   const SizedBox(width: 16),
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           isSubscribed ? 'Premium Active' : 'Go Premium',
  //                           style: GoogleFonts.poppins(
  //                             fontSize: 16,
  //                             fontWeight: FontWeight.bold,
  //                             color: isSubscribed
  //                                 ? AppTheme.premiumGold
  //                                 : AppTheme.getTextPrimaryColor(context),
  //                           ),
  //                         ),
  //                         const SizedBox(height: 4),
  //                         Text(
  //                           isSubscribed ? 'Enjoy ad-free experience' : 'Remove ads & unlock features',
  //                           style: GoogleFonts.poppins(
  //                             fontSize: 12,
  //                             color: AppTheme.getTextSecondaryColor(context),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   Container(
  //                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //                     decoration: BoxDecoration(
  //                       gradient: isSubscribed
  //                           ? AppTheme.premiumGradient
  //                           : AppTheme.primaryGradient,
  //                       borderRadius: BorderRadius.circular(12),
  //                       boxShadow: isSubscribed
  //                           ? [
  //                         BoxShadow(
  //                           color: AppTheme.premiumGold.withOpacity(0.3),
  //                           blurRadius: 8,
  //                           offset: const Offset(0, 2),
  //                         ),
  //                       ]
  //                           : null,
  //                     ),
  //                     child: Text(
  //                       isSubscribed ? 'ACTIVE' : 'UNLOCK',
  //                       style: GoogleFonts.poppins(
  //                         fontSize: 12,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.white,
  //                         letterSpacing: 0.5,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSettingsTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppTheme.getPrimaryColor(context).withOpacity(0.1),
        highlightColor: AppTheme.getPrimaryColor(context).withOpacity(0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context).withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.getPrimaryColor(context).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: AppTheme.getPrimaryColor(context),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextPrimaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.getTextSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.getPrimaryColor(context),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}