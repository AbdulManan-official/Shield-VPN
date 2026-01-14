import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vpnprowithjava/View/premium_access_screen.dart';
import 'package:vpnprowithjava/View/subscription_manager.dart';

import '../providers/ads_controller.dart';
import '../utils/custom_toast.dart';
import '../utils/app_theme.dart'; // Import your theme file
import 'allowed_app_screen.dart' show AllowedAppsScreen;

// Extension for responsive design
extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  double get screenSize => screenWidth * screenHeight;

  EdgeInsets responsivePadding({
    double horizontal = 0,
    double vertical = 0,
    double all = 0,
  }) {
    if (all > 0) {
      return EdgeInsets.all(screenSize * all / 400000);
    }
    return EdgeInsets.symmetric(
      horizontal: screenSize * horizontal / 400000,
      vertical: screenSize * vertical / 400000,
    );
  }

  double responsiveSpacing(double spacing) {
    return screenSize * spacing / 400000;
  }

  double responsiveBorderRadius(double radius) {
    return screenSize * radius / 400000;
  }

  double responsiveIconSize(double size) {
    return screenSize * size / 400000;
  }

  TextStyle responsiveTextStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: screenSize >= 370000 ? fontSize : fontSize + 1,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? Theme.of(this).textTheme.bodyLarge?.color,
      letterSpacing: letterSpacing,
    );
  }
}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final SubscriptionController subscriptionManager = Get.find();

  Future<void> _launchEmailFeedback() async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: 'vpnapp@technosofts.net',
      query: 'subject=VPN Max Feedback&body=Dear VPN Max Team,\n\n',
    );

    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    } else {
      showLogoToast(
        'Could not launch email client. Please send your feedback to vpnapp@technosofts.net',
      );
    }
  }

  Future<void> _loadUuid() async {}

  void _showSubscriptionDialog(BuildContext context) {
    final hasSubscription = subscriptionManager.isSubscribed.value;

    if (hasSubscription) {
      _showAlreadySubscribedDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PremiumAccessScreen(),
      ),
    );
  }

  void _showAlreadySubscribedDialog() {
    final subscriptionType = subscriptionManager.subscriptionType.value;
    final subscriptionDate = subscriptionManager.subscriptionDate.value;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = AppTheme.isDarkMode(context);

        return AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.success,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Premium Active',
                style: GoogleFonts.poppins(
                  color: AppTheme.getTextPrimaryColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have an active premium subscription!',
                style: GoogleFonts.poppins(
                  color: AppTheme.getTextSecondaryColor(context),
                  fontSize: 14,
                ),
              ),
              if (subscriptionType != 'none') ...[
                const SizedBox(height: 8),
                Text(
                  'Type: ${subscriptionType.toUpperCase()}',
                  style: GoogleFonts.poppins(
                    color: AppTheme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (subscriptionDate.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Since: ${DateTime.parse(subscriptionDate).toLocal().toString().split(' ')[0]}',
                  style: GoogleFonts.poppins(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  final AdsController adsController = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUuid();
    });
  }

  @override
  void dispose() {
    adsController.disposeBanner2();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppTheme.getBackgroundColor(context),
          appBar: AppBar(
            backgroundColor: AppTheme.getBackgroundColor(context),
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Settings',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: context.responsivePadding(horizontal: 20, vertical: 28),
                  decoration: BoxDecoration(
                    gradient: AppTheme.getBackgroundGradient(context),
                  ),
                  child: Column(
                    children: [
                      // Premium Access Card
                      Obx(() {
                        return _MoreTile(
                          icon: subscriptionManager.isSubscribed.value
                              ? Icons.check_circle
                              : Icons.flash_on,
                          label: subscriptionManager.isSubscribed.value
                              ? 'Premium Active'
                              : 'Get Premium Access',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: subscriptionManager.isSubscribed.value
                                  ? LinearGradient(
                                colors: [
                                  AppTheme.textSecondaryLight,
                                  AppTheme.textSecondaryDark
                                ],
                              )
                                  : AppTheme.premiumGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              subscriptionManager.isSubscribed.value
                                  ? 'ACTIVE'
                                  : 'UNLOCK',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          onTap: () => _showSubscriptionDialog(context),
                        );
                      }),

                      SizedBox(height: context.responsiveSpacing(16)),
                      _MoreTile(
                        icon: Icons.apps,
                        label: "App Filter",
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppTheme.getPrimaryColor(context),
                          size: context.responsiveIconSize(20),
                        ),
                        onTap: () {
                          Get.to(() => AllowedAppsScreen());
                        },
                      ),

                      SizedBox(height: context.responsiveSpacing(16)),

                      // Share App
                      _MoreTile(
                        icon: Icons.share,
                        label: "Share App",
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppTheme.getPrimaryColor(context),
                          size: context.responsiveIconSize(20),
                        ),
                        onTap: () async {
                          await SharePlus.instance.share(ShareParams(
                              text:
                              'Check out VPN Max for fast and secure browsing! https://play.google.com/store/apps/details?id=com.technosofts.vpnmax'));
                        },
                      ),
                      SizedBox(height: context.responsiveSpacing(16)),

                      // Rate App
                      _MoreTile(
                        icon: Icons.star_border,
                        label: "Rate this app",
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppTheme.getPrimaryColor(context),
                          size: context.responsiveIconSize(20),
                        ),
                        onTap: () async {
                          StoreRedirect.redirect(
                              androidAppId: 'com.technosofts.vpnmax');
                        },
                      ),

                      SizedBox(height: context.responsiveSpacing(16)),

                      // Feedback
                      _MoreTile(
                        icon: Icons.feedback_outlined,
                        label: "Feedback",
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppTheme.getPrimaryColor(context),
                          size: context.responsiveIconSize(20),
                        ),
                        onTap: _launchEmailFeedback,
                      ),

                      SizedBox(height: context.responsiveSpacing(16)),

                      // Check for Updates
                      _MoreTile(
                        icon: Icons.system_update,
                        label: "Check for Updates",
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppTheme.getPrimaryColor(context),
                          size: context.responsiveIconSize(20),
                        ),
                        onTap: () async {
                          StoreRedirect.redirect(
                              androidAppId: 'com.technosofts.vpnmax');
                        },
                      ),

                      SizedBox(height: context.responsiveSpacing(16)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Obx(() {
                  if (!adsController.isBannerAd2Loaded.value &&
                      adsController.banner2 == null) {
                    return const SizedBox();
                  }

                  return SizedBox(
                    width: adsController.banner2!.size.width.toDouble(),
                    height: adsController.banner2!.size.height.toDouble(),
                    child: AdWidget(ad: adsController.banner2!),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced More Tile Widget
class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MoreTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Material(
      color: AppTheme.getCardColor(context),
      borderRadius: BorderRadius.circular(
        context.responsiveBorderRadius(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          context.responsiveBorderRadius(16),
        ),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              context.responsiveBorderRadius(16),
            ),
            border: Border.all(
              color: isDark
                  ? AppTheme.borderDark
                  : AppTheme.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppTheme.shadowDark
                    : AppTheme.shadowLight,
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveSpacing(17),
            vertical: context.responsiveSpacing(12),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing(8)),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(
                    context.responsiveBorderRadius(10),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: context.responsiveIconSize(20),
                ),
              ),
              SizedBox(width: context.responsiveSpacing(16)),
              Expanded(
                child: AutoSizeText(
                  label,
                  maxFontSize: 15,
                  style: context.responsiveTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}