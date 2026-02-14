import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../services/language_service.dart';
import '../utils/responsive.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final primaryColor = AppTheme.getPrimaryColor(context);
    final bgColor = AppTheme.getSlate900(context);
    final isTabletOrLarger = context.isTabletOrLarger;
    final horizontalPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTabletOrLarger ? 600 : double.infinity,
              ),
              child: Column(
                children: [
                  // Top bar with Skip button
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isTabletOrLarger ? 8 : 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_currentPage < 2)
                          TextButton(
                            onPressed: _skip,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              lang.translate('skip'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: isTabletOrLarger ? 17 : 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Page content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        _buildWelcomePage(context, primaryColor, lang),
                        _buildBarcodePage(context, primaryColor, lang),
                        _buildDocumentPage(context, primaryColor, lang),
                      ],
                    ),
                  ),

                  // Bottom section
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      isTabletOrLarger ? 16 : 12,
                      horizontalPadding,
                      horizontalPadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Page dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (index) => _buildDot(index, primaryColor),
                          ),
                        ),
                        SizedBox(height: isTabletOrLarger ? 24 : 16),

                        // Action button
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: AppTheme.getPrimaryGradient(context),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isTabletOrLarger ? 18 : 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentPage == 2 ? lang.translate('get_started') : lang.translate('next'),
                                    style: TextStyle(
                                      fontSize: isTabletOrLarger ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentPage == 2
                                        ? Icons.auto_awesome
                                        : Icons.arrow_forward,
                                    size: isTabletOrLarger ? 22 : 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        if (_currentPage < 2) ...[
                          const SizedBox(height: 10),
                          Text(
                            '${lang.translate('swipe_continue')} \u2192',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // PAGE 1: Welcome to Inspector
  // ============================================================================
  Widget _buildWelcomePage(BuildContext context, Color primaryColor, LanguageService lang) {
    final isTabletOrLarger = context.isTabletOrLarger;
    final horizontalPadding = Responsive.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Main circular icon
          _buildMainIcon(context, primaryColor),

          SizedBox(height: isTabletOrLarger ? 32 : 24),

          // Title
          Text(
            lang.translate('welcome_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTabletOrLarger ? 34 : 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),

          SizedBox(height: isTabletOrLarger ? 16 : 10),

          // Description
          Text(
            lang.translate('welcome_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: isTabletOrLarger ? 16 : 14,
              height: 1.4,
            ),
          ),

          SizedBox(height: isTabletOrLarger ? 28 : 20),

          // Feature list
          _buildFeatureItem(
            context,
            Icons.qr_code_scanner,
            lang.translate('quick_scanning'),
            primaryColor,
          ),
          SizedBox(height: isTabletOrLarger ? 12 : 8),
          _buildFeatureItem(
            context,
            Icons.camera_alt_outlined,
            lang.translate('multi_angle_capture'),
            primaryColor,
          ),
          SizedBox(height: isTabletOrLarger ? 12 : 8),
          _buildFeatureItem(
            context,
            Icons.cloud_outlined,
            lang.translate('secure_cloud_storage'),
            primaryColor,
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildMainIcon(BuildContext context, Color primaryColor) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 150 * _pulseAnimation.value,
                height: 150 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              );
            },
          ),

          // Inner glow
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.2),
                  primaryColor.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),

          // Main circle
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.getPrimaryGradient(context),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.center_focus_strong,
              size: 48,
              color: Colors.white,
            ),
          ),

          // Badge icon
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String text,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // PAGE 2: Instant Barcode Recognition
  // ============================================================================
  Widget _buildBarcodePage(BuildContext context, Color primaryColor, LanguageService lang) {
    final isTabletOrLarger = context.isTabletOrLarger;
    final horizontalPadding = Responsive.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Scanner illustration
          _buildScannerIllustration(context, primaryColor),

          SizedBox(height: isTabletOrLarger ? 36 : 28),

          // Title
          Text(
            lang.translate('instant_recognition'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTabletOrLarger ? 34 : 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),

          SizedBox(height: isTabletOrLarger ? 16 : 10),

          // Description
          Text(
            lang.translate('recognition_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: isTabletOrLarger ? 16 : 14,
              height: 1.4,
            ),
          ),

          SizedBox(height: isTabletOrLarger ? 32 : 24),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatBox('0.5s', lang.translate('scan_speed'), primaryColor),
              ),
              SizedBox(width: isTabletOrLarger ? 16 : 10),
              Expanded(
                child: _buildStatBox('99%', lang.translate('accuracy'), primaryColor),
              ),
              SizedBox(width: isTabletOrLarger ? 16 : 10),
              Expanded(
                child: _buildStatBox('15+', lang.translate('formats'), primaryColor),
              ),
            ],
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildScannerIllustration(BuildContext context, Color primaryColor) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Scanner frame
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Corner brackets
                _buildCornerBracket(Alignment.topLeft, primaryColor),
                _buildCornerBracket(Alignment.topRight, primaryColor),
                _buildCornerBracket(Alignment.bottomLeft, primaryColor),
                _buildCornerBracket(Alignment.bottomRight, primaryColor),

                // Center scanner icon
                Center(
                  child: Icon(
                    Icons.center_focus_strong,
                    size: 50,
                    color: primaryColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Success badge
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.success.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBracket(Alignment alignment, Color color) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: CustomPaint(
          size: const Size(32, 32),
          painter: CornerBracketPainter(
            color: color,
            alignment: alignment,
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: primaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // PAGE 3: Document & Upload Instantly
  // ============================================================================
  Widget _buildDocumentPage(BuildContext context, Color primaryColor, LanguageService lang) {
    final isTabletOrLarger = context.isTabletOrLarger;
    final horizontalPadding = Responsive.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Photo grid illustration
          _buildPhotoGrid(context, primaryColor),

          SizedBox(height: isTabletOrLarger ? 36 : 28),

          // Title
          Text(
            lang.translate('document_upload'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTabletOrLarger ? 34 : 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),

          SizedBox(height: isTabletOrLarger ? 16 : 10),

          // Description
          Text(
            lang.translate('document_upload_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: isTabletOrLarger ? 16 : 14,
              height: 1.4,
            ),
          ),

          SizedBox(height: isTabletOrLarger ? 28 : 20),

          // Checklist
          _buildChecklistItem(lang.translate('upload_5_photos'), primaryColor),
          SizedBox(height: isTabletOrLarger ? 12 : 8),
          _buildChecklistItem(lang.translate('auto_sync_cloud'), primaryColor),
          SizedBox(height: isTabletOrLarger ? 12 : 8),
          _buildChecklistItem(lang.translate('encryption'), primaryColor),

          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, Color primaryColor) {
    return SizedBox(
      width: 180,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 170,
            height: 140,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPhotoSlot(1, primaryColor, filled: true),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildPhotoSlot(2, primaryColor, filled: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPhotoSlot(3, primaryColor, filled: true),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildPhotoSlot(null, primaryColor, filled: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Checkmark badge
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.getPrimaryGradient(context),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot(int? number, Color primaryColor, {required bool filled}) {
    return Container(
      decoration: BoxDecoration(
        color: filled
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: filled
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              )
            : null,
      ),
      child: Stack(
        children: [
          if (!filled)
            Positioned.fill(
              child: CustomPaint(
                painter: DashedBorderPainter(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: 10,
                ),
              ),
            ),
          Center(
            child: Icon(
              Icons.camera_alt_outlined,
              color: Colors.white.withValues(alpha: filled ? 0.5 : 0.3),
              size: 22,
            ),
          ),
          if (number != null)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text, Color primaryColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: primaryColor,
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // Common Widgets
  // ============================================================================
  Widget _buildDot(int index, Color primaryColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? primaryColor
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        boxShadow: _currentPage == index
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }
}

// ============================================================================
// Custom Painters
// ============================================================================
class CornerBracketPainter extends CustomPainter {
  final Color color;
  final Alignment alignment;

  CornerBracketPainter({required this.color, required this.alignment});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const length = 16.0;

    if (alignment == Alignment.topLeft) {
      path.moveTo(0, length);
      path.lineTo(0, 0);
      path.lineTo(length, 0);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(size.width - length, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, length);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(0, size.height - length);
      path.lineTo(0, size.height);
      path.lineTo(length, size.height);
    } else if (alignment == Alignment.bottomRight) {
      path.moveTo(size.width - length, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height - length);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  DashedBorderPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rect);
    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    final dashedPath = Path();
    const dashLength = 5.0;
    const gapLength = 3.0;

    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashLength).clamp(0, metric.length);
        dashedPath.addPath(
          metric.extractPath(start, end.toDouble()),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
