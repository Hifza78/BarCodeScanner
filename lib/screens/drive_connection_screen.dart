import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../utils/responsive.dart';
import '../main.dart';
import 'main_screen.dart';

/// Screen that shows Google Drive connection status after login
class DriveConnectionScreen extends StatefulWidget {
  const DriveConnectionScreen({super.key});

  @override
  State<DriveConnectionScreen> createState() => _DriveConnectionScreenState();
}

class _DriveConnectionScreenState extends State<DriveConnectionScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExistingConnection(); // Auto-skip if already connected
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  /// Check if Drive is already connected and skip this screen
  Future<void> _checkExistingConnection() async {
    final isAlreadyConnected = await _authService.isDriveConnected();
    if (isAlreadyConnected && mounted) {
      // Already connected, skip directly to main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _connectToDrive() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    try {
      if (_authService.isSignedIn) {
        await _authService.setDriveConnected(true);
        setState(() {
          _isConnecting = false;
          _isConnected = true;
        });
      } else {
        setState(() {
          _isConnecting = false;
          _error = 'auth_expired';
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _error = e.toString();
      });
    }
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final user = _authService.currentUser;
    final primaryColor = AppTheme.getPrimaryColor(context);
    final secondaryColor = AppTheme.getPurple900(context);
    final bgColor = AppTheme.getSlate900(context);
    final isTabletOrLarger = context.isTabletOrLarger;
    final horizontalPadding = Responsive.horizontalPadding(context);

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
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: isTabletOrLarger ? 350 : 250,
              height: isTabletOrLarger ? 350 : 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: isTabletOrLarger ? 400 : 300,
              height: isTabletOrLarger ? 400 : 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    secondaryColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTabletOrLarger ? 500 : double.infinity,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // App bar
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding / 2,
                          vertical: isTabletOrLarger ? 12 : 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              color: bgColor,
                              onSelected: (value) {
                                if (value == 'logout') {
                                  _signOut();
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                                      const SizedBox(width: 12),
                                      Text(lang.translate('logout'), style: const TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Column(
                            children: [
                              SizedBox(height: isTabletOrLarger ? 32 : 20),

                              // User Profile
                              _buildUserProfile(user, primaryColor),

                              SizedBox(height: isTabletOrLarger ? 48 : 40),

                              // Drive Card
                              _buildDriveCard(bgColor, lang),

                              SizedBox(height: isTabletOrLarger ? 40 : 32),

                              // Status indicator (only show when connecting/connected/error)
                              if (_isConnecting || _isConnected || _error != null)
                                _buildStatusIndicator(primaryColor, lang),

                              SizedBox(height: isTabletOrLarger ? 40 : 32),

                              // Action Button
                              _buildActionButton(bgColor, lang),

                              SizedBox(height: isTabletOrLarger ? 48 : 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(user, Color primaryColor) {
    return Column(
      children: [
        // Profile Picture with glow
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: user?.photoUrl != null
                  ? Image.network(
                      user!.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // User Name
        Text(
          _authService.displayName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),

        // User Email
        Text(
          _authService.email,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    final bgColor = AppTheme.getPurple900(context);
    return Container(
      color: bgColor,
      child: Icon(
        Icons.person,
        size: 45,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildDriveCard(Color bgColor, LanguageService lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Google Drive Icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Image.network(
                'https://ssl.gstatic.com/images/branding/product/2x/drive_2020q4_48dp.png',
                width: 42,
                height: 42,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.cloud,
                  size: 42,
                  color: bgColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            lang.translate('google_drive'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            lang.translate('connect_drive_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(Color primaryColor, LanguageService lang) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (_isConnecting) {
      statusColor = primaryColor;
      statusIcon = Icons.sync;
      statusText = lang.translate('connecting');
    } else if (_isConnected) {
      statusColor = Colors.greenAccent;
      statusIcon = Icons.check_circle;
      statusText = lang.translate('connected');
    } else {
      statusColor = Colors.redAccent;
      statusIcon = Icons.error;
      statusText = _error != null ? lang.translate(_error!) : lang.translate('connection_failed');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isConnecting)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            )
          else
            Icon(statusIcon, color: statusColor, size: 22),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Color bgColor, LanguageService lang) {
    if (_isConnecting) {
      return const SizedBox.shrink();
    }

    if (_isConnected) {
      return _buildButton(
        onPressed: _navigateToMainScreen,
        icon: Icons.arrow_forward,
        label: lang.translate('continue_to_app'),
        isPrimary: true,
        bgColor: bgColor,
      );
    }

    if (_error != null) {
      return _buildButton(
        onPressed: _connectToDrive,
        icon: Icons.refresh,
        label: lang.translate('retry'),
        isError: true,
        bgColor: bgColor,
      );
    }

    return _buildButton(
      onPressed: _connectToDrive,
      icon: Icons.cloud,
      label: lang.translate('connect_to_drive'),
      isPrimary: true,
      bgColor: bgColor,
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color bgColor,
    bool isPrimary = false,
    bool isError = false,
  }) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isError
            ? LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              )
            : const LinearGradient(
                colors: [Colors.white, Color(0xFFF0F4F8)],
              ),
        boxShadow: [
          BoxShadow(
            color: isError
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isError ? Colors.white : bgColor,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isError ? Colors.white : bgColor,
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
