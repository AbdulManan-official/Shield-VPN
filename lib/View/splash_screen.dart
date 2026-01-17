import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../providers/servers_provider.dart';
import '../utils/logo_painter.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoadingServers = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Start animation once
    _controller.forward();

    _initializeApp();
  }


  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      // ✅ JUST INITIALIZE, DON'T FETCH - HomeScreen will handle fetching
      final serversProvider = Provider.of<ServersProvider>(context, listen: false);
      await serversProvider.initialize();

      if (mounted) {
        setState(() => _isLoadingServers = false);
        await _controller.forward();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Get.offAll(() => const HomeScreen());
      }
    } catch (e) {
      debugPrint('Error during splash initialization: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoadingServers = false;
        });
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isLoadingServers = true;
    });

    // Reset animation
    _controller.reset();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.forward();
      }
    });

    await _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Proportional sizes for any device
    double fontSize = screenWidth * 0.10;
    double iconSize = screenWidth * 0.18;
    double boxPadding = screenWidth * 0.05;
    double boxShadowBlur = screenWidth * 0.09;
    double boxShadowOffset = screenHeight * 0.012;
    double titleUnderlineWidth = fontSize * 2.5;
    double titleUnderlineHeight = screenHeight * 0.012;
    double titleUnderlineBlur = screenWidth * 0.03;
    double verticalSpacing1 = screenHeight * 0.04;
    double verticalSpacing2 = screenHeight * 0.02;
    double textPaddingH = screenWidth * 0.05;
    double smallTextSize = screenWidth * 0.035;
    double progressBarHeight = screenHeight * 0.012;
    double progressBarPaddingH = screenWidth * 0.08;
    double progressBarBottom =
        MediaQuery.of(context).padding.bottom + screenHeight * 0.04;

    // Clamp for extreme small/large screens
    fontSize = fontSize.clamp(18.0, 56.0);
    iconSize = iconSize.clamp(28.0, 100.0);
    boxPadding = boxPadding.clamp(8.0, 32.0);
    boxShadowBlur = boxShadowBlur.clamp(6.0, 32.0);
    boxShadowOffset = boxShadowOffset.clamp(2.0, 16.0);
    titleUnderlineWidth = titleUnderlineWidth.clamp(32.0, 180.0);
    titleUnderlineHeight = titleUnderlineHeight.clamp(2.0, 12.0);
    titleUnderlineBlur = titleUnderlineBlur.clamp(2.0, 12.0);
    verticalSpacing1 = verticalSpacing1.clamp(6.0, 32.0);
    verticalSpacing2 = verticalSpacing2.clamp(4.0, 18.0);
    textPaddingH = textPaddingH.clamp(8.0, 32.0);
    smallTextSize = smallTextSize.clamp(10.0, 18.0);
    progressBarHeight = progressBarHeight.clamp(3.0, 12.0);
    progressBarPaddingH = progressBarPaddingH.clamp(10.0, 64.0);
    progressBarBottom = progressBarBottom.clamp(
        MediaQuery.of(context).padding.bottom + 8.0,
        MediaQuery.of(context).padding.bottom + 64.0);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.bgGradientDark : AppTheme.bgGradientLight,
        ),
        child: _hasError ? _buildErrorView() : _buildNormalView(isDark),
      ),
    );
  }

  Widget _buildNormalView(bool isDark) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: Get.width * 0.8,
            height: Get.width * 0.32,
            child: CustomPaint(
              painter: VpnLogoPainter(
                progress: _controller.value,
                isDarkMode: isDark,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: AppTheme.error,
                  size: 64,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Failed to Load Servers',
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your internet connection and try again',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.getTextSecondaryColor(context),
                  fontSize: 14,
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryColor(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}