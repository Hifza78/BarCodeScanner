import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/language_service.dart';
import '../utils/responsive.dart';
import '../widgets/common/app_logo.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
    _startLoading();
  }

  Future<void> _startLoading() async {
    // Simulate loading progress (5 seconds total)
    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 90));
      if (mounted) {
        setState(() {
          _progress = i / 100;
        });
      }
    }

    // Small delay before navigating
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors and language
    final lang = context.watch<LanguageService>();
    final primaryColor = AppTheme.getPrimaryColor(context);
    final isTabletOrLarger = context.isTabletOrLarger;
    final logoSize = isTabletOrLarger ? 180.0 : 140.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTabletOrLarger ? 500 : double.infinity,
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // App Logo
                    AppLogo(size: logoSize),

                    SizedBox(height: isTabletOrLarger ? 40 : 32),

                    // App Name
                    Text(
                      'AssetCapture',
                      style: TextStyle(
                        fontSize: isTabletOrLarger ? 34 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      lang.translate('quality_inspection'),
                      style: TextStyle(
                        fontSize: isTabletOrLarger ? 16 : 14,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Loading Progress Section
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.horizontalPadding(context) * 2,
                      ),
                      child: Column(
                        children: [
                          // Progress percentage
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: isTabletOrLarger ? 18 : 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),

                          SizedBox(height: isTabletOrLarger ? 16 : 12),

                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: isTabletOrLarger ? 10 : 8,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          ),

                          SizedBox(height: isTabletOrLarger ? 20 : 16),

                          // Loading text
                          Text(
                            lang.translate('loading'),
                            style: TextStyle(
                              fontSize: isTabletOrLarger ? 16 : 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Footer
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),

                    SizedBox(height: isTabletOrLarger ? 32 : 24),
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
