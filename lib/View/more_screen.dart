import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:vpnsheild/View/premium_access_screen.dart';
import 'package:vpnsheild/View/subscription_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/ads_controller.dart';
import '../providers/vpn_connection_provider.dart';
import '../utils/app_theme.dart';
import '../utils/custom_toast.dart';
import 'allowed_app_screen.dart' show AllowedAppsScreen;

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  // final SubscriptionController subscriptionManager = Get.find();
  final AdsController adsController = Get.find();

  // App constants
  static const String appUrl = 'https://play.google.com/store/apps/details?id=com.technosofts.shieldVpn';
  static const String appName = 'Shield VPN';
  static const String supportEmail = 'technosofts.net@gmail.com';

  @override
  void initState() {
    super.initState();
    // Load banner ad when screen initializes
    adsController.loadBanner2();
  }

  // Share app function
  void _shareApp() {
    Share.share(
      'Check out $appName - Your ultimate VPN solution!\n\nDownload now: $appUrl',
      subject: 'Try $appName',
    );
  }

  // Rate app function
  Future<void> _rateApp() async {
    final Uri url = Uri.parse(appUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      showLogoToast(
        "Could not open Play Store",
        color: AppTheme.warning,
      );
    }
  }

  // Contact us via email
  Future<void> _contactUs() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=Feedback for $appName',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      showLogoToast(
        "Could not open email app",
        color: AppTheme.warning,
      );
    }
  }

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
    adsController.disposeBanner2();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // _buildPremiumBanner(),

              // Premium Card
              // Obx(() {
              //   final isSubscribed = subscriptionManager.isSubscribed.value;
              //   return _buildPremiumCard(context, isSubscribed);
              // }),

              const SizedBox(height: 16),

              // Banner Ad - Below Premium Section
              // Obx(() {
              //   final banner = adsController.banner2;
              //   final isLoaded = adsController.isBannerAd2Loaded.value;
              //
              //   if (!isLoaded || banner == null) {
              //     return const SizedBox();
              //   }
              //
              //   return Container(
              //     key: ValueKey(banner.hashCode), // Unique key for each ad instance
              //     margin: const EdgeInsets.only(bottom: 16),
              //     decoration: BoxDecoration(
              //       borderRadius: BorderRadius.circular(16),
              //       border: Border.all(
              //         color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
              //       ),
              //     ),
              //     child: SizedBox(
              //       width: banner.size.width.toDouble(),
              //       height: banner.size.height.toDouble(),
              //       child: AdWidget(ad: banner),
              //     ),
              //   );
              // }),

              // Settings List
              _buildSettingsTile(
                context,
                icon: Icons.apps_rounded,
                title: 'App Filter',
                subtitle: 'Manage VPN for specific apps',
                onTap: () {
                  final vpnProvider = Provider.of<VpnConnectionProvider>(context, listen: false);

                  if (vpnProvider.stage == VPNStage.connected) {
                    showLogoToast(
                      "Disconnect VPN to access App Filter",
                      color: AppTheme.warning,
                    );
                  } else {
                    Get.to(() => AllowedAppsScreen());
                  }
                },
              ),

              const SizedBox(height: 10),

              _buildSettingsTile(
                context,
                icon: Icons.share_rounded,
                title: 'Share App',
                subtitle: 'Tell your friends about $appName',
                onTap: _shareApp,
              ),

              const SizedBox(height: 10),

              _buildSettingsTile(
                context,
                icon: Icons.star_rounded,
                title: 'Rate this App',
                subtitle: 'Support us with 5 stars',
                onTap: _rateApp,
              ),

              const SizedBox(height: 10),

              _buildSettingsTile(
                context,
                icon: Icons.email_rounded,
                title: 'Contact Us',
                subtitle: 'Share your thoughts with us',
                onTap: _contactUs,
              ),

              const SizedBox(height: 10),

              _buildSettingsTile(
                context,
                icon: Icons.system_update_rounded,
                title: 'Check for Updates',
                subtitle: 'Get the latest version',
                onTap: _rateApp,
              ),

              // Bottom safe area padding
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
            ],
          ),
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

  // Widget _buildPremiumBanner() {
  //   final isDark = AppTheme.isDarkMode(context);
  //
  //   return GestureDetector(
  //     onTap: () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (context) => const PremiumAccessScreen()),
  //       );
  //     },
  //     child: Container(
  //       padding: const EdgeInsets.all(18),
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           colors: isDark
  //               ? [AppTheme.primaryDark, AppTheme.accentDark]
  //               : [AppTheme.primaryLight, AppTheme.accentLight],
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //         ),
  //         borderRadius: BorderRadius.circular(18),
  //         border: Border.all(
  //           color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
  //           width: 1.5,
  //         ),
  //         boxShadow: [
  //           BoxShadow(
  //             color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
  //             blurRadius: 15,
  //             spreadRadius: 2,
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         children: [
  //           Container(
  //             padding: const EdgeInsets.all(12),
  //             decoration: BoxDecoration(
  //               color: Colors.white.withOpacity(isDark ? 0.15 : 0.2),
  //               borderRadius: BorderRadius.circular(14),
  //             ),
  //             child: const Icon(
  //               Icons.workspace_premium,
  //               color: Colors.white,
  //               size: 30,
  //             ),
  //           ),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   "Upgrade to Premium",
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.white,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 4),
  //                 Text(
  //                   "Unlock all features & remove ads",
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 12,
  //                     color: Colors.white.withOpacity(0.9),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: Text(
  //               "GET",
  //               style: GoogleFonts.poppins(
  //                 fontSize: 13,
  //                 fontWeight: FontWeight.bold,
  //                 color: AppTheme.getPrimaryColor(context),
  //                 letterSpacing: 0.5,
  //               ),
  //             ),
  //           ),
  //         ],
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
        borderRadius: BorderRadius.circular(18),
        splashColor: AppTheme.getPrimaryColor(context).withOpacity(0.1),
        highlightColor: AppTheme.getPrimaryColor(context).withOpacity(0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context).withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.getPrimaryColor(context).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: AppTheme.getPrimaryColor(context),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextPrimaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.getTextSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.getPrimaryColor(context),
                      size: 16,
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