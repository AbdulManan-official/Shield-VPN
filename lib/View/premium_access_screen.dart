import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vpnprowithjava/View/subscription_manager.dart';
import 'package:vpnprowithjava/utils/colors.dart';
import 'package:vpnprowithjava/utils/simple_loading_dialog.dart';

import '../providers/ads_controller.dart';

class PremiumAccessScreen extends StatefulWidget {
  // final VoidCallback onSubscriptionStatusChanged;

  const PremiumAccessScreen({
    super.key,
    // required this.onSubscriptionStatusChanged,
  });

  @override
  State<PremiumAccessScreen> createState() => _PremiumAccessScreenState();
}

class _PremiumAccessScreenState extends State<PremiumAccessScreen>
    with TickerProviderStateMixin {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  List<ProductDetails> _products = [];
  bool _isLoading = true;
  ProductDetails? _oneTimePurchaseProduct;
  bool _isPurchaseInProgress = false;

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  // late Animation<double> _pulseAnimation;

  // App theme colors
  static const Color primaryPurple = UIColors.primaryPurple;
  static const Color lightPurple = UIColors.lightPurple;
  static const Color accentTeal = UIColors.accentTeal;
  static const Color connectGreen = UIColors.connectGreen;
  static const Color warmGold = UIColors.warmGold;
  static const Color softGold = UIColors.softGold;
  static const Color darkBg = UIColors.darkBg;
  static const Color cardBg = UIColors.cardBg;

  // late SubscriptionManager _subscriptionManager;

  final SubscriptionController sub = Get.find();
  late NavigatorState _navigator;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePurchases();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _subscriptionManager =
    //     Provider.of<SubscriptionManager>(context, listen: false);
    _navigator = Navigator.of(context);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
    //   CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    // );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializePurchases() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      setState(() => _isLoading = false);
      return;
    }

    // Query products
    ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(
      sub.productIds,
    );

    if (response.error != null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _products = response.productDetails;
      _oneTimePurchaseProduct = _products.firstWhere(
        (product) => product.id == sub.oneTimeProductId,
        orElse: () => throw StateError('One time purchase product not found'),
      );
      _isLoading = false;
    });

    // Listen to purchase stream
    // _inAppPurchase.purchaseStream
    //     .listen((List<PurchaseDetails> purchaseDetailsList) {
    //   _handlePurchaseUpdates(purchaseDetailsList);
    // });
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    debugPrint('📦 Handling ${purchases.length} purchases');

    for (final purchase in purchases) {
      debugPrint('Purchase status: ${purchase.status}');

      if (purchase.status == PurchaseStatus.purchased) {
        // ✅ Determine subscription type
        String type = 'premium';
        if (purchase.productID == sub.monthlyProductId) {
          type = 'monthly';
        } else if (purchase.productID == sub.yearlyProductId) {
          type = 'yearly';
        } else if (purchase.productID == sub.oneTimeProductId) {
          type = 'lifetime';
        }

        debugPrint('✅ Purchase successful: $type');

        // ✅ Update subscription in SubscriptionManager
        // await _subscriptionManager.setSubscriptionStatus(
        //   isSubscribed: true,
        //   subscriptionType: type,
        // );

        await sub.setSubscriptionStatus(
          subscribed: true,
          type: type,
        );
        showLoadingDialog();
        // ✅ Complete the purchase (MUST DO THIS)
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
        hideLoadingDialog();

        // widget.onSubscriptionStatusChanged();

        final AdsController adsController = Get.find();
        adsController.setSubscriptionStatus();
        // ✅ Show success and navigate
        if (mounted) {
          _navigator.pop();
          _showSuccessDialog();
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('❌ Purchase error: ${purchase.error}');
        if (mounted) {
          _showErrorDialog('Purchase failed. Please try again.');
        }
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.pending) {
        debugPrint('⏳ Purchase pending');
      } else if (purchase.status == PurchaseStatus.restored) {
        debugPrint('🔄 Purchase restored');
        // Handle restored purchases
        String type = 'premium';
        if (purchase.productID == sub.monthlyProductId) {
          type = 'monthly';
        } else if (purchase.productID == sub.yearlyProductId) {
          type = 'yearly';
        } else if (purchase.productID == sub.oneTimeProductId) {
          type = 'lifetime';
        }

        await sub.setSubscriptionStatus(
          subscribed: true,
          type: type,
        );

        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      }
    }

    _isPurchaseInProgress = false;
  }

  void _buySubscription(ProductDetails product) {
    if (_isPurchaseInProgress) return; // Prevent double tap
    _isPurchaseInProgress = true;

    if (sub.isSubscribed.value) {
      _showAlreadySubscribedDialog();
      _isPurchaseInProgress = false;
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _buyOneTimePurchase() {
    if (_isPurchaseInProgress) return; // Prevent double tap
    _isPurchaseInProgress = true;

    if (sub.isSubscribed.value) {
      _showAlreadySubscribedDialog();
      _isPurchaseInProgress = false;
      return;
    }

    if (_oneTimePurchaseProduct != null) {
      final purchaseParam =
          PurchaseParam(productDetails: _oneTimePurchaseProduct!);
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [cardBg, darkBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: connectGreen.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: connectGreen.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient:
                        LinearGradient(colors: [connectGreen, accentTeal]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 20),
                Text(
                  'Success!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Premium access activated! Enjoy all the premium features.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [connectGreen, accentTeal]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _navigator.pop(),
                      child: Center(
                        child: Text(
                          'Great!',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAlreadySubscribedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [cardBg, darkBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: accentTeal.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient:
                        LinearGradient(colors: [connectGreen, accentTeal]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 20),
                Text(
                  'Already Premium',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You already have an active premium subscription.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [connectGreen, accentTeal]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(
                        child: Text(
                          'OK',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [cardBg, darkBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline,
                      color: Colors.red, size: 30),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(
                        child: Text(
                          'OK',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSubscription = sub.isSubscribed.value;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [darkBg, cardBg, darkBg.withValues(alpha: 0.9)],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkBg, cardBg, darkBg.withValues(alpha: 0.9)],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height -
                              MediaQuery.of(context).viewPadding.top -
                              MediaQuery.of(context).viewPadding.bottom,
                        ),
                        child: Column(
                          children: [
                            _buildCustomAppBar(context),
                            _buildEnhancedHeader(context, hasSubscription),
                            if (hasSubscription) ...[
                              _buildActiveSubscriptionCard(),
                              const SizedBox(height: 20),
                            ] else ...[
                              _buildEnhancedPlansSection(context),
                              _buildEnhancedFeaturesSection(context),
                            ],
                            _buildFooterNote(context),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardBg.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentTeal.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: accentTeal,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Text(
              "Premium Upgrade",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context, bool hasSubscription) {


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        children: [

          const SizedBox(height: 15),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(

              colors: [accentTeal,primaryPurple],
            ).createShader(bounds),
            child: Text(
              hasSubscription ? "Premium Already Active" : "Unlock VPN Max Pro",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSubscription
                ? "You already have access to all premium VPN services and features"
                : "Experience ultimate privacy and speed\nwith our premium VPN service",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscriptionCard() {
    final subscriptionType = sub.subscriptionType.value;
    final subscriptionDate = sub.subscriptionDate.value;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            connectGreen.withValues(alpha: 0.2),
            accentTeal.withValues(alpha: 0.1)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: connectGreen.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: connectGreen.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [connectGreen, accentTeal]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 15),
          Text(
            'Premium Active!',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'You\'re all set! Enjoy unlimited access to all premium features.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          if (subscriptionType != 'none') ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: [connectGreen, accentTeal]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${subscriptionType.toUpperCase()} SUBSCRIPTION',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (subscriptionDate.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Active since: ${DateTime.parse(subscriptionDate).toLocal().toString().split(' ')[0]}',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedPlansSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            "Choose Your Plan",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Unlock all premium features with any plan",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 20),
          _buildPlansColumn(context),
        ],
      ),
    );
  }

  Widget _buildPlansColumn(BuildContext context) {
    return Column(
      children: [
        // Monthly Plan
        ..._products
            .where((product) =>
                product.id.contains('vpnmax_999_1m') &&
                product.id != sub.oneTimeProductId)
            .map((product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEnhancedPlanCard(
                    context: context,
                    product: product,
                    title: "Monthly Plan",
                    subtitle: "Perfect for trying out",
                    color: primaryPurple,
                    isPopular: false,
                  ),
                )),

        // Yearly Plan
        ..._products
            .where((product) =>
                product.id.contains('vpnmax_99_1year') &&
                product.id != sub.oneTimeProductId)
            .map((product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEnhancedPlanCard(
                    context: context,
                    product: product,
                    title: "Yearly Plan",
                    subtitle: "Best value for money",
                    color: accentTeal,
                    isPopular: true,
                  ),
                )),

        // Lifetime Plan
        if (_oneTimePurchaseProduct != null)
          _buildEnhancedPlanCard(
            context: context,
            product: _oneTimePurchaseProduct!,
            title: "Lifetime Access",
            subtitle: "One Time Payment",
            color: connectGreen,
            isPopular: false,
            isLifetime: true,
          ),
      ],
    );
  }

  Widget _buildEnhancedPlanCard({
    required BuildContext context,
    required ProductDetails product,
    required String title,
    required String subtitle,
    required Color color,
    required bool isPopular,
    bool isLifetime = false,
  }) {
    final hasSubscription = sub.isSubscribed.value;
    final bool isYearly = product.id.contains('year');
    // final Color planBaseColor = isYearly ? primaryPurple : color;

    return GestureDetector(
      onTap: (hasSubscription || _isPurchaseInProgress)
          ? null
          : () {
              if (isLifetime) {
                _buyOneTimePurchase();
              } else {
                _buySubscription(product);
              }
            },
      child: AnimatedContainer(
        // height: 220, // Shorter height
        width: double.infinity,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isYearly && !hasSubscription
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryPurple.withValues(alpha: 0.9),
                    primaryPurple.withValues(alpha: 0.7),
                    primaryPurple.withValues(alpha: 0.5),
                  ],
                )
              : const LinearGradient(
                  colors: [Colors.transparent, Colors.transparent],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular && !hasSubscription
                ? warmGold
                : color.withValues(alpha: 0.3),
            width: isPopular && !hasSubscription ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isPopular ? warmGold : color).withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                if (isPopular && !hasSubscription)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(colors: [warmGold, softGold]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: darkBg,
                      ),
                    ),
                  )
                else if (isLifetime)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [connectGreen, accentTeal]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.diamond, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'LIFETIME',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Subtitle
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // if (!isLifetime)
                    Text(
                      "${formatPrice(product.rawPrice * 2)} ",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: warmGold,
                        decorationThickness: 3,
                      ),
                    ),
                    Text(
                      product.price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (!isLifetime)
                      Text(
                        isYearly ? '/year' : '/month',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Button
            Container(
              // width: 100,
              // // width: double.infinity,
              // height: 4,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 25),
              decoration: BoxDecoration(
                gradient: hasSubscription
                    ? LinearGradient(colors: [
                        Colors.grey.withValues(alpha: 0.3),
                        Colors.grey.withValues(alpha: 0.2)
                      ])
                    : const LinearGradient(colors: [warmGold, softGold]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (hasSubscription ? Colors.grey : warmGold)
                        .withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: hasSubscription
                      ? null
                      : () {
                          if (isLifetime) {
                            _buyOneTimePurchase();
                          } else {
                            _buySubscription(product);
                          }
                        },
                  child: Center(
                    child: Text(
                      _isPurchaseInProgress
                          ? 'Processing...'
                          : (hasSubscription ? 'Subscribed' : 'Buy'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: hasSubscription ? Colors.white60 : darkBg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatPrice(num value) {
    return value
        .toStringAsFixed(10) // enough precision
        .replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Widget _buildEnhancedFeaturesSection(BuildContext context) {
    final features = [
      {
        "icon": "🚀",
        "title": "Unlimited Speed",
        "subtitle": "No bandwidth limitations",
      },
      {
        "icon": "🌍",
        "title": "Global Servers",
        "subtitle": "Worldwide locations",
      },

      {
        "icon": "🛡️",
        "title": "Ad Blocker",
        "subtitle": "Block ads and malware",
      },

    ];

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardBg.withValues(alpha: 0.8),
            darkBg.withValues(alpha: 0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lightPurple.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [accentTeal, connectGreen]),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Premium Features",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Everything you need for secure browsing",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Features List
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feature emoji
                  Text(
                    feature["icon"]!,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  // Bullet point
                  Container(
                    margin: const EdgeInsets.only(top: 8, right: 12),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accentTeal,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Feature text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature["title"]!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          feature["subtitle"]!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: darkBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: lightPurple.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: accentTeal,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                "Important Information",
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: accentTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "YOU CAN CANCEL YOUR SUBSCRIPTION OR FREE TRIAL AT ANY TIME BY CANCELLING IT THROUGH YOUR GOOGLE ACCOUNT SETTINGS. "
            // "YOU CAN CANCEL YOUR SUBSCRIPTION AT ANY TIME BY CANCELLING IT THROUGH YOUR GOOGLE ACCOUNT SETTINGS. "
            "OTHERWISE, IT WILL AUTOMATICALLY RENEW. CANCELLATION MUST BE DONE 24 HOURS BEFORE THE END OF THE CURRENT PERIOD.",
            // "• Subscriptions auto-renew until cancelled\n• Manage subscriptions in account settings",
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
