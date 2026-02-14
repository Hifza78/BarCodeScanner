import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'services/auth_service.dart';
import 'services/preferences_service.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'services/upload_queue_service.dart';
import 'screens/drive_connection_screen.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/common/loading_widget.dart';
import 'widgets/common/app_logo.dart';
import 'utils/responsive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize preferences service first
  final prefsService = PreferencesService();
  await prefsService.initialize();

  // Initialize upload queue service (requires Hive setup)
  final uploadQueueService = UploadQueueService();
  await uploadQueueService.initialize();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()..initialize()),
        ChangeNotifierProvider(create: (_) => LanguageService()..initialize()),
        ChangeNotifierProvider.value(value: uploadQueueService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, LanguageService>(
      builder: (context, themeService, languageService, child) {
        final isDark = themeService.themeMode == AppThemeMode.dark ||
            (themeService.themeMode == AppThemeMode.system &&
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.dark);

        final primaryColor = isDark ? AppTheme.darkAmber500 : AppTheme.lightBlue600;
        final scaffoldColor = isDark ? AppTheme.darkSlate900 : AppTheme.lightSlate950;

        return MaterialApp(
          title: 'AssetCapture',
          debugShowCheckedModeBanner: false,
          locale: languageService.locale,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              primary: primaryColor,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: scaffoldColor,
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: scaffoldColor,
              foregroundColor: Colors.white,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: AppTheme.cardGlassBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
                ),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: scaffoldColor,
              contentTextStyle: const TextStyle(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          ),
          builder: (context, child) {
            return Directionality(
              textDirection: languageService.isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },
          home: const AppStartup(),
        );
      },
    );
  }
}

/// Startup widget that shows splash screen first, then onboarding for new users
class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  final PreferencesService _prefs = PreferencesService();

  bool _showSplash = true;
  bool _showOnboarding = false;
  bool _checkingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final onboardingComplete = await _prefs.isOnboardingComplete;
    setState(() {
      _showOnboarding = !onboardingComplete;
      _checkingOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    }

    if (_showOnboarding && !_checkingOnboarding) {
      return OnboardingScreen(
        onComplete: () {
          setState(() {
            _showOnboarding = false;
          });
        },
      );
    }

    return const AuthWrapper();
  }
}

/// Auth state - consolidated for DRY principle
class _AuthState {
  final bool isLoading;
  final bool isSignedIn;
  final bool isDriveConnected;
  final String? error;

  const _AuthState({
    this.isLoading = true,
    this.isSignedIn = false,
    this.isDriveConnected = false,
    this.error,
  });

  _AuthState copyWith({
    bool? isLoading,
    bool? isSignedIn,
    bool? isDriveConnected,
    String? error,
  }) {
    return _AuthState(
      isLoading: isLoading ?? this.isLoading,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      isDriveConnected: isDriveConnected ?? this.isDriveConnected,
      error: error,
    );
  }
}

/// Wrapper widget that handles authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  _AuthState _state = const _AuthState();

  @override
  void initState() {
    super.initState();
    _updateAuthState(initialize: true);
  }

  /// Consolidated auth state update - eliminates duplicate code
  /// Follows DRY principle
  Future<void> _updateAuthState({bool initialize = false}) async {
    setState(() {
      _state = _state.copyWith(isLoading: true, error: null);
    });

    try {
      final success = initialize
          ? await _authService.initialize()
          : await _authService.signIn();

      bool driveConnected = false;
      if (success) {
        driveConnected = await _authService.isDriveConnected();
      }

      setState(() {
        _state = _state.copyWith(
          isLoading: false,
          isSignedIn: success,
          isDriveConnected: driveConnected,
          // Only show error when user actively tried to sign in, not during auto-init
          error: success || initialize ? null : 'Sign-in was cancelled or failed',
        );
      });
    } catch (e) {
      setState(() {
        _state = _state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state.isLoading) {
      return LoadingWidget.fullScreen(
        context: context,
        message: 'Signing in...',
      );
    }

    if (_state.isSignedIn) {
      return _state.isDriveConnected
          ? const MainScreen()
          : const DriveConnectionScreen();
    }

    return _SignInScreen(
      error: _state.error,
      onSignIn: () => _updateAuthState(initialize: false),
    );
  }
}

/// Sign-in screen widget - extracted for cleaner code
class _SignInScreen extends StatelessWidget {
  final String? error;
  final VoidCallback onSignIn;

  const _SignInScreen({
    this.error,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.getPrimaryColor(context);
    final secondaryColor = AppTheme.getPurple900(context);
    final isTabletOrLarger = context.isTabletOrLarger;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: AppTheme.getBackgroundGradient(context),
            ),
          ),

          // Decorative circles
          _buildDecorativeCircle(
            top: -100,
            right: -100,
            size: isTabletOrLarger ? 400 : 300,
            color: primaryColor.withValues(alpha: 0.15),
          ),
          _buildDecorativeCircle(
            bottom: -50,
            left: -50,
            size: isTabletOrLarger ? 280 : 200,
            color: secondaryColor.withValues(alpha: 0.3),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTabletOrLarger ? 500 : double.infinity,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxHeight < 650;
                    final mascotSize = isSmallScreen
                        ? 200.0
                        : (isTabletOrLarger ? 280.0 : 260.0);

                    // Use row layout for wide screens in landscape
                    if (isTabletOrLarger && constraints.maxWidth > constraints.maxHeight) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildLogoSection(context, mascotSize, primaryColor),
                          ),
                          Expanded(
                            child: _buildSignInSection(context, primaryColor),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildLogoSection(context, mascotSize, primaryColor),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildSignInSection(context, primaryColor),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeCircle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context, double size, Color primaryColor) {
    return Center(
      child: AppLogo(size: size),
    );
  }

  Widget _buildSignInSection(BuildContext context, Color primaryColor) {
    final isTabletOrLarger = context.isTabletOrLarger;
    final horizontalPadding = isTabletOrLarger ? 48.0 : 32.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.glassWhite(0.05),
        borderRadius: isTabletOrLarger
            ? BorderRadius.circular(40)
            : const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
        border: Border(
          top: BorderSide(
            color: AppTheme.glassWhite(0.1),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'AssetCapture',
              style: TextStyle(
                fontSize: isTabletOrLarger ? 32 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quality Inspection Made Easy',
              style: TextStyle(
                fontSize: isTabletOrLarger ? 17 : 15,
                color: AppTheme.getAccentMedium(context),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: isTabletOrLarger ? 40 : 32),

            // Error message
            if (error != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Google Sign in button
            _GoogleSignInButton(onTap: onSignIn),

            const SizedBox(height: 20),

            // Helper text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppTheme.glassWhite(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  'Secure authentication with Google',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.glassWhite(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Google Sign-In button widget
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GoogleSignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CustomPaint(
                    painter: GoogleLogoPainter(),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getSlate900(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Professional Google "G" logo painter with official brand colors
class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double centerX = width / 2;
    final double centerY = height / 2;
    final double radius = width * 0.45;
    final double strokeWidth = width * 0.18;

    const Color blue = Color(0xFF4285F4);
    const Color red = Color(0xFFEA4335);
    const Color yellow = Color(0xFFFBBC05);
    const Color green = Color(0xFF34A853);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Rect rect = Rect.fromCircle(center: Offset(centerX, centerY), radius: radius);

    // Blue arc
    paint.color = blue;
    canvas.drawArc(rect, -0.785, 1.57, false, paint);

    // Green arc
    paint.color = green;
    canvas.drawArc(rect, 0.785, 1.57, false, paint);

    // Yellow arc
    paint.color = yellow;
    canvas.drawArc(rect, 2.356, 0.785, false, paint);

    // Red arc
    paint.color = red;
    canvas.drawArc(rect, 3.14159, 1.57, false, paint);

    // Blue horizontal bar
    paint.color = blue;
    paint.style = PaintingStyle.fill;
    final double barHeight = strokeWidth;
    final double barLeft = centerX - width * 0.05;
    final double barRight = width - width * 0.08;
    final double barTop = centerY - barHeight / 2;
    canvas.drawRect(
      Rect.fromLTRB(barLeft, barTop, barRight, barTop + barHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
