import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:vpnprowithjava/View/premium_access_screen.dart';
import 'package:vpnprowithjava/View/subscription_manager.dart';
import 'package:vpnprowithjava/utils/colors.dart';

import '../providers/ads_provider.dart';
import '../utils/preferences.dart';

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
      color: color ?? Colors.white,
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
  String? _uuid;

  // late SubscriptionManager subscriptionManager;
  final SubscriptionController subscriptionManager = Get.find();

  // Color scheme constants
  static const Color darkBg = Color(0xFF0A0E27);
  static const Color cardBg = Color(0xFF1A1A2E);
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color lightPurple = Color(0xFF9B93FF);
  static const Color warmGold = Color(0xFFFFD700);
  static const Color softGold = Color(0xFFFFA500);

  Future<void> _launchEmailFeedback() async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: 'vpnapp@technosofts.net',
      query: 'subject=VPN Max Feedback&body=Dear VPN Max Team,\n\n',
    );

    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    } else {
      Fluttertoast.showToast(
        msg:
            'Could not launch email client. Please send your feedback to vpnapp@technosofts.net',
        backgroundColor: Colors.grey[800],
        textColor: Colors.white,
      );
    }
  }

  Future<void> _loadUuid() async {
    String? storedUuid = Prefs.getString('uuid');
    if (storedUuid == null) {
      final uuid = const Uuid().v4();
      await Prefs.setString('uuid', uuid);
      setState(() {
        _uuid = uuid;
      });
    } else {
      setState(() {
        _uuid = storedUuid;
      });
    }
  }

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
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Premium Active',
                style: GoogleFonts.poppins(
                  color: Colors.white,
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
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              if (subscriptionType != 'none') ...[
                const SizedBox(height: 8),
                Text(
                  'Type: ${subscriptionType.toUpperCase()}',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
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
                    color: Colors.white60,
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
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Future<void> _checkForUpdates() async {
  //   try {
  //     final packageInfo = await PackageInfo.fromPlatform();
  //     final currentVersion = packageInfo.version.trim();
  //     const playStoreUrl =
  //         'https://play.google.com/store/apps/details?id=com.technosofts.vpnmax';
  //
  //     final response = await http.get(Uri.parse(playStoreUrl));
  //     if (response.statusCode == 200) {
  //       final html = response.body;
  //       final versionRegExp =
  //           RegExp(r'Current Version.*?>([0-9.]+)<', dotAll: true);
  //       final match = versionRegExp.firstMatch(html);
  //
  //       if (match != null) {
  //         final storeVersion = match.group(1)?.trim() ?? '';
  //         if (storeVersion.isNotEmpty && storeVersion != currentVersion) {
  //           Fluttertoast.showToast(
  //             msg: "Update available! ($storeVersion)",
  //             backgroundColor: Colors.grey[800],
  //             textColor: Colors.white,
  //           );
  //         } else {
  //           Fluttertoast.showToast(
  //             msg: "App is up to date!",
  //             backgroundColor: Colors.grey[800],
  //             textColor: Colors.white,
  //           );
  //         }
  //       } else {
  //         Fluttertoast.showToast(
  //           msg: "Could not check version.",
  //           backgroundColor: Colors.grey[800],
  //           textColor: Colors.white,
  //         );
  //       }
  //     } else {
  //       Fluttertoast.showToast(
  //         msg: "Failed to reach Play Store.",
  //         backgroundColor: Colors.grey[800],
  //         textColor: Colors.white,
  //       );
  //     }
  //   } catch (e) {
  //     Fluttertoast.showToast(
  //       msg: "Error: ${e.toString()}",
  //       backgroundColor: Colors.grey[800],
  //       textColor: Colors.white,
  //     );
  //   }
  // }
  late AdsProvider _adsProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adsProvider = Provider.of<AdsProvider>(context, listen: false);
    // subscriptionManager =
    //     Provider.of<SubscriptionManager>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUuid();
      // _adsProvider.loadBanner2();
    });
  }

  @override
  void dispose() {
    _adsProvider.disposeBanner2();
    _adsProvider.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: darkBg,
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding:
                      context.responsivePadding(horizontal: 20, vertical: 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [darkBg, cardBg],
                    ),
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
                                        Colors.grey[700]!,
                                        Colors.grey[600]!
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [warmGold, softGold]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              subscriptionManager.isSubscribed.value
                                  ? 'ACTIVE'
                                  : 'UNLOCK',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          onTap: () => _showSubscriptionDialog(context),
                        );
                      }),

                      SizedBox(height: context.responsiveSpacing(16)),

                      // Share App
                      _MoreTile(
                        icon: Icons.share,
                        label: "Share App",
                        trailing: Icon(
                          Icons.chevron_right,
                          color: lightPurple,
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
                          color: lightPurple,
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
                          color: lightPurple,
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
                          color: lightPurple,
                          size: context.responsiveIconSize(20),
                        ),
                        onTap: () async {
                          StoreRedirect.redirect(
                              androidAppId: 'com.technosofts.vpnmax');
                        },
                      ),

                      SizedBox(height: context.responsiveSpacing(16)),

                      // UUID Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(
                            context.responsiveBorderRadius(16),
                          ),
                          border: Border.all(
                            color: lightPurple.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPurple.withValues(alpha: 0.1),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Device UUID",
                                    style: context.responsiveTextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(
                                      height: context.responsiveSpacing(4)),
                                  Text(
                                    _uuid ?? 'Loading UUID...',
                                    style: context.responsiveTextStyle(
                                      fontSize: 12.5,
                                      color: lightPurple,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: context.responsiveSpacing(12)),
                            GestureDetector(
                              onTap: () async {
                                if (_uuid != null) {
                                  await Clipboard.setData(
                                      ClipboardData(text: _uuid!));
                                  Fluttertoast.showToast(
                                    msg: "UUID copied!",
                                    backgroundColor: Colors.grey[800],
                                    textColor: Colors.white,
                                  );
                                }
                              },
                              child: Container(
                                padding: context.responsivePadding(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: UIColors.primaryPurple,
                                  borderRadius: BorderRadius.circular(
                                    context.responsiveBorderRadius(10),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: UIColors.primaryPurple
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "COPY",
                                  style: context.responsiveTextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Consumer<AdsProvider>(
                  builder: (_, ads, __) {
                    final banner = ads.getBannerAd2;
                    return banner != null
                        ? Container(
                            alignment: Alignment.center,
                            width: banner.size.width.toDouble(),
                            height: banner.size.height.toDouble(),
                            child: AdWidget(ad: banner),
                          )
                        : SizedBox.shrink();
                  },
                ),
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
    return Material(
      color: _MoreScreenState.cardBg,
      borderRadius: BorderRadius.circular(
        context.responsiveBorderRadius(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          context.responsiveBorderRadius(16),
        ),
        onTap: onTap,
        child: Container(
          // height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              context.responsiveBorderRadius(16),
            ),
            border: Border.all(
              color: _MoreScreenState.lightPurple.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _MoreScreenState.primaryPurple.withValues(alpha: 0.1),
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
                  color: _MoreScreenState.primaryPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(
                    context.responsiveBorderRadius(10),
                  ),
                ),
                child: Icon(
                  icon,
                  color: _MoreScreenState.lightPurple,
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
                    color: Colors.white,
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
