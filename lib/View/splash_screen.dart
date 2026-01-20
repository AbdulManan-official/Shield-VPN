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
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoadingServers = true;

  @override
  void initState() {
    super.initState();

    // Logo animation (0-3s) - optimized timing
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Text animation (starts at 2.5s, lasts 1.5s)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuart, // Smoother curve
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInQuad, // Gentle fade
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), // Less slide for smoothness
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutQuart, // Smoother slide
    ));

    // Start animations
    _controller.forward();

    // Start text animation after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _textController.forward();
    });

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

        // Wait for animations to complete (3.5 seconds total)
        await Future.delayed(const Duration(milliseconds: 3000));

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

    // Reset animations
    _controller.reset();
    _textController.reset();

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _controller.forward();
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) _textController.forward();
      });
      await _initializeApp();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

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
    return RepaintBoundary( // Optimization: prevents unnecessary repaints
      child: Center(
        child: AnimatedBuilder(
          animation: _logoAnimation,
          builder: (context, child) {
            return RepaintBoundary(
              child: SizedBox(
                width: Get.width * 0.8,
                height: Get.width * 0.4, // Increased height for subtitle
                child: CustomPaint(
                  painter: VpnLogoPainter(
                    progress: _logoAnimation.value,
                    isDarkMode: isDark,
                  ),
                  willChange: true, // Performance hint
                ),
              ),
            );
          },
        ),
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