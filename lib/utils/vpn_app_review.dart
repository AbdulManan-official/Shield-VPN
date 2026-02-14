import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vpnsheild/utils/app_theme.dart';
import 'package:vpnsheild/utils/custom_toast.dart';


class VpnAppReview {
  // ========== CONFIGURATION ==========
// ========== CONFIGURATION ==========

  static const String _doneKey = 'vpn_feedback_done';
  static const String _lastShownKey = 'vpn_feedback_last_shown';
  static const String _connectionCountKey = 'vpn_connection_count'; // ADD THIS LINE
  static const int _cooldownDays = 3;
  static const int _requiredConnections = 2; // ADD THIS LINE
  static const double _showProbability = 1.0;
  static const String _supportEmail = 'vpnapp@technosofts.net';

  // ========== PUBLIC API ==========

  /// Call this when VPN disconnects
  /// Call this when VPN disconnects
  static Future<void> tryShowOnDisconnect(BuildContext context) async {
    debugPrint('🔍 [VpnAppReview] tryShowOnDisconnect() called');

    final prefs = await SharedPreferences.getInstance();

    // 1️⃣ Stop forever if user already rated
    if (prefs.getBool(_doneKey) == true) {
      debugPrint('✅ [VpnAppReview] User already rated, skipping');
      return;
    }

    // 2️⃣ Increment connection count
    final currentCount = prefs.getInt(_connectionCountKey) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(_connectionCountKey, newCount);
    debugPrint('📊 [VpnAppReview] Connection count: $newCount/$_requiredConnections');

    // 3️⃣ Check if user has connected enough times
    if (newCount < _requiredConnections) {
      debugPrint('⏳ [VpnAppReview] Not enough connections yet ($newCount/$_requiredConnections)');
      return;
    }

    // 4️⃣ Cooldown check
    final lastShown = prefs.getInt(_lastShownKey);
    if (lastShown != null) {
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastShown);
      final daysSince = DateTime.now().difference(lastDate).inDays;

      if (daysSince < _cooldownDays) {
        debugPrint('⏳ [VpnAppReview] Cooldown active ($daysSince/$_cooldownDays days)');
        return;
      }
    }

    // 5️⃣ Random chance
    if (Random().nextDouble() > _showProbability) {
      debugPrint('🎲 [VpnAppReview] Random check failed');
      return;
    }

    // 6️⃣ Update last shown timestamp
    await prefs.setInt(_lastShownKey, DateTime.now().millisecondsSinceEpoch);

    // 7️⃣ Show bottom sheet after a short delay
    await Future.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      debugPrint('🎉 [VpnAppReview] Showing review bottom sheet now');
      _showReviewBottomSheet(context);
    } else {
      debugPrint('⚠️ [VpnAppReview] Context unmounted before showing bottom sheet');
    }
  }

  // ========== PRIVATE METHODS ==========

  static void _showReviewBottomSheet(BuildContext context) {
    debugPrint('📌 [VpnAppReview] _showReviewBottomSheet() called');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (bottomSheetContext) {
        debugPrint('📌 [VpnAppReview] Bottom sheet builder executed');
        return _VpnReviewBottomSheet(bottomSheetContext: bottomSheetContext);
      },
    ).then((_) {
      debugPrint('👋 [VpnAppReview] Review bottom sheet dismissed');
    });
  }

  /// Handle positive feedback (thumbs up)
  static Future<void> _onPositive(BuildContext bottomSheetContext) async {
    debugPrint('👍 [VpnAppReview] _onPositive() CALLED');

    // Haptic feedback
    HapticFeedback.mediumImpact();

    final prefs = await SharedPreferences.getInstance();
    final alreadyReviewed = prefs.getBool(_doneKey) ?? false;

    // Close bottom sheet first
    if (bottomSheetContext.mounted) {
      Navigator.of(bottomSheetContext).pop();
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (alreadyReviewed) {
      // User already reviewed - just show thank you toast
      showLogoToast('Thanks for your feedback! ❤️', color: AppTheme.success);
      debugPrint('✅ [VpnAppReview] User already reviewed - showing thank you toast');
      return;
    }

    // User hasn't reviewed yet - start InAppReview
    final review = InAppReview.instance;

    try {
      final bool available = await review.isAvailable();

      if (available) {
        await review.requestReview();
        debugPrint('✅ [VpnAppReview] In-app review requested');
      } else {
        await review.openStoreListing();
        debugPrint('✅ [VpnAppReview] Opened store listing');
      }

      // Mark as done after successful review
      await prefs.setBool(_doneKey, true);

      // Show thank you toast
      showLogoToast('Thanks for your feedback! ❤️', color: AppTheme.success);
      debugPrint('✅ [VpnAppReview] Review completed and marked as done');
    } catch (e) {
      debugPrint('❌ [VpnAppReview] Error in InAppReview: $e');
      // Still show thank you toast even if there's an error
      showLogoToast('Thanks for your feedback! ❤️', color: AppTheme.success);
    }
  }

  /// Handle negative feedback (thumbs down)
  static Future<void> _onNegativeWithContext(
      BuildContext bottomSheetContext,
      BuildContext parentContext,
      ) async {
    debugPrint('👎 [VpnAppReview] _onNegativeWithContext() CALLED');

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Close main bottom sheet
    if (bottomSheetContext.mounted) {
      Navigator.of(bottomSheetContext).pop();
      debugPrint('✅ [VpnAppReview] Main bottom sheet closed');
    }

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 400));

    // Show email feedback bottom sheet using parent context
    if (parentContext.mounted) {
      debugPrint('📧 [VpnAppReview] Showing email feedback bottom sheet');
      showModalBottomSheet(
        context: parentContext,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
        builder: (emailBottomSheetContext) {
          debugPrint('📧 [VpnAppReview] Email bottom sheet builder executed');
          return _VpnFeedbackEmailBottomSheet(
            bottomSheetContext: emailBottomSheetContext,
          );
        },
      ).then((_) {
        debugPrint('👋 [VpnAppReview] Email bottom sheet dismissed');
      });
    } else {
      debugPrint('⚠️ [VpnAppReview] Parent context unmounted, cannot show email sheet');
    }
  }

  /// Update last shown timestamp (for cooldown)
  static Future<void> _updateLastShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
    debugPrint('⏰ [VpnAppReview] Updated last shown timestamp');
  }

  /// 🔄 Reset for testing - call this to test the bottom sheet again
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_doneKey);
    await prefs.remove(_lastShownKey);
    debugPrint('🔄 [VpnAppReview] Reset complete - bottom sheet will show again');
  }
}

// ========== UI WIDGETS ==========

/// Main review bottom sheet
class _VpnReviewBottomSheet extends StatefulWidget {
  final BuildContext bottomSheetContext;

  const _VpnReviewBottomSheet({required this.bottomSheetContext});

  @override
  State<_VpnReviewBottomSheet> createState() => _VpnReviewBottomSheetState();
}

class _VpnReviewBottomSheetState extends State<_VpnReviewBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late BuildContext _parentContext;

  @override
  void initState() {
    super.initState();

    // Store parent context
    _parentContext = Navigator.of(widget.bottomSheetContext, rootNavigator: true).context;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);

    // Clamp text scale factor to prevent extreme scaling
    final clampedScale = textScaleFactor.clamp(0.8, 1.3);

    // Adjust base size for different screen sizes
    double adjustedSize = baseSize;
    if (screenWidth < 360) {
      adjustedSize = baseSize * 0.9;
    } else if (screenWidth > 600) {
      adjustedSize = baseSize * 1.1;
    }

    return adjustedSize * clampedScale;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(screenWidth * 0.06),
            topRight: Radius.circular(screenWidth * 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
              top: screenHeight * 0.02,
              bottom: bottomPadding + screenHeight * 0.02,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: screenWidth * 0.12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                // Icon
                Container(
                  width: screenWidth * 0.2,
                  height: screenWidth * 0.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF5B86E5),
                        Color(0xFF36D1DC),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF5B86E5).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: screenWidth * 0.1,
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                // Title
                Text(
                  "Enjoying Shield VPN?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF2D3436),
                    fontSize: _getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                Text(
                  "If Shield VPN is keeping you safe and connected, would you mind leaving a quick review?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF636E72),
                    fontSize: _getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: screenHeight * 0.035),

                // Thumbs Up/Down Buttons (Side by Side)
                Row(
                  children: [
                    // Thumbs Down (Left - Negative)
                    Expanded(
                      child: _ThumbButton(
                        icon: Icons.thumb_down_alt_rounded,
                        label: "Not Really",
                        isPositive: false,
                        onTap: () => VpnAppReview._onNegativeWithContext(
                          widget.bottomSheetContext,
                          _parentContext,
                        ),
                        fontSize: _getResponsiveFontSize(context, 14),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    // Thumbs Up (Right - Positive)
                    Expanded(
                      child: _ThumbButton(
                        icon: Icons.thumb_up_alt_rounded,
                        label: "Love it!",
                        isPositive: true,
                        onTap: () => VpnAppReview._onPositive(widget.bottomSheetContext),
                        fontSize: _getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.01),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thumb button widget
class _ThumbButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPositive;
  final VoidCallback onTap;
  final double fontSize;

  const _ThumbButton({
    required this.icon,
    required this.label,
    required this.isPositive,
    required this.onTap,
    required this.fontSize,
  });

  @override
  State<_ThumbButton> createState() => _ThumbButtonState();
}

class _ThumbButtonState extends State<_ThumbButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.04,
          ),
          decoration: BoxDecoration(
            color: widget.isPositive ? Color(0xFFF5F5F5) : Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            border: Border.all(
              color: Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: Color(0xFF2D3436),
                size: screenWidth * 0.07,
              ),
              SizedBox(width: screenWidth * 0.025),
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  color: Color(0xFF2D3436),
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Email feedback bottom sheet (shown after thumbs down)
class _VpnFeedbackEmailBottomSheet extends StatefulWidget {
  final BuildContext bottomSheetContext;

  const _VpnFeedbackEmailBottomSheet({required this.bottomSheetContext});

  @override
  State<_VpnFeedbackEmailBottomSheet> createState() =>
      _VpnFeedbackEmailBottomSheetState();
}

class _VpnFeedbackEmailBottomSheetState
    extends State<_VpnFeedbackEmailBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);

    final clampedScale = textScaleFactor.clamp(0.8, 1.3);

    double adjustedSize = baseSize;
    if (screenWidth < 360) {
      adjustedSize = baseSize * 0.9;
    } else if (screenWidth > 600) {
      adjustedSize = baseSize * 1.1;
    }

    return adjustedSize * clampedScale;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(screenWidth * 0.06),
            topRight: Radius.circular(screenWidth * 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
              top: screenHeight * 0.02,
              bottom: bottomPadding + screenHeight * 0.02,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: screenWidth * 0.12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                // Icon
                Container(
                  width: screenWidth * 0.2,
                  height: screenWidth * 0.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF5B86E5),
                        Color(0xFF36D1DC),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF5B86E5).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: Colors.white,
                    size: screenWidth * 0.1,
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                // Title
                Text(
                  "Help us to Improve",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF2D3436),
                    fontSize: _getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: screenHeight * 0.015),

                // Subtitle
                Text(
                  "We will love to hear your suggestions!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF636E72),
                    fontSize: _getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: screenHeight * 0.035),

                // Action Buttons
                Row(
                  children: [
                    // Not Now
                    Expanded(
                      child: _EmailActionButton(
                        label: "Not Now",
                        isPrimary: false,
                        fontSize: _getResponsiveFontSize(context, 15),
                        onTap: () async {
                          HapticFeedback.lightImpact();

                          // Update last shown timestamp for cooldown
                          await VpnAppReview._updateLastShown();

                          // Close the bottom sheet
                          if (widget.bottomSheetContext.mounted) {
                            Navigator.of(widget.bottomSheetContext).pop();
                          }

                          debugPrint('⏰ [VpnAppReview] Not Now clicked - cooldown set for ${VpnAppReview._cooldownDays} days');
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    // Send Feedback
                    Expanded(
                      child: _EmailActionButton(
                        label: "Send Feedback",
                        isPrimary: true,
                        fontSize: _getResponsiveFontSize(context, 15),
                        onTap: () async {
                          HapticFeedback.mediumImpact();

                          // Prepare email
                          final emailUri = Uri(
                            scheme: 'mailto',
                            path: VpnAppReview._supportEmail,
                            queryParameters: {
                              'subject': 'VPN Shield Feedback',
                              'body': 'Hi VPN Shield Team,\n\nI have some feedback:\n\n',
                            },
                          );

                          try {
                            // Try to launch email
                            if (await canLaunchUrl(emailUri)) {
                              await launchUrl(emailUri);
                              debugPrint('✅ [VpnAppReview] Email client opened successfully');
                            } else {
                              debugPrint('❌ [VpnAppReview] Cannot launch email client');
                              showLogoToast('Cannot open email app', color: AppTheme.error);
                            }
                          } catch (e) {
                            debugPrint('❌ [VpnAppReview] Error launching email: $e');
                            showLogoToast('Error opening email app', color: AppTheme.error);
                          }

                          // Update last shown timestamp for cooldown
                          await VpnAppReview._updateLastShown();

                          // Close the bottom sheet
                          if (widget.bottomSheetContext.mounted) {
                            Navigator.of(widget.bottomSheetContext).pop();
                          }

                          debugPrint('📧 [VpnAppReview] Send Feedback clicked - email opened and cooldown set');
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.01),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Email action button
class _EmailActionButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  final double fontSize;

  const _EmailActionButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
    required this.fontSize,
  });

  @override
  State<_EmailActionButton> createState() => _EmailActionButtonState();
}

class _EmailActionButtonState extends State<_EmailActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.04,
          ),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5B86E5),
                Color(0xFF36D1DC),
              ],
            )
                : null,
            color: widget.isPrimary ? null : Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            border: Border.all(
              color: widget.isPrimary ? Colors.transparent : Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.poppins(
                color: widget.isPrimary ? Colors.white : Color(0xFF636E72),
                fontWeight: FontWeight.w500,
                fontSize: widget.fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}