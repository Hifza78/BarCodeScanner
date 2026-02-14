import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/preferences_service.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import '../utils/responsive.dart';

/// Settings screen with basic app settings
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefs = PreferencesService();
  bool _notificationsEnabled = true;
  bool _autoUpload = false;

  final List<String> _languages = ['English', 'Spanish', 'French', 'German', 'Arabic', 'Chinese'];
  final List<String> _themes = ['Dark', 'Light', 'System'];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final autoUpload = await _prefs.isAutoUploadEnabled;
    final notifications = await _prefs.isNotificationsEnabled;
    if (mounted) {
      setState(() {
        _autoUpload = autoUpload;
        _notificationsEnabled = notifications;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for language and theme changes to rebuild UI
    final languageService = context.watch<LanguageService>();
    final themeService = context.watch<ThemeService>();
    final selectedLanguage = languageService.getLanguageDisplayName();
    final selectedTheme = themeService.getThemeModeDisplayName();
    final padding = Responsive.horizontalPadding(context);
    final isTabletOrLarger = context.isTabletOrLarger;

    return Scaffold(
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
                  _buildHeader(context, languageService),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(padding),
                      children: [
                        _buildSectionTitle(languageService.translate('general')),
                        SizedBox(height: isTabletOrLarger ? 16 : 12),
                        _buildSettingsCard([
                          _buildLanguageTile(selectedLanguage, languageService),
                          _buildDivider(),
                          _buildThemeTile(selectedTheme, languageService),
                        ]),
                        SizedBox(height: isTabletOrLarger ? 32 : 24),
                        _buildSectionTitle(languageService.translate('preferences')),
                        SizedBox(height: isTabletOrLarger ? 16 : 12),
                        _buildSettingsCard([
                          _buildSwitchTile(
                            icon: Icons.notifications_outlined,
                            title: languageService.translate('notifications'),
                            subtitle: languageService.translate('receive_updates'),
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() => _notificationsEnabled = value);
                              _prefs.setNotifications(value);
                            },
                          ),
                          _buildDivider(),
                          _buildSwitchTile(
                            icon: Icons.cloud_upload_outlined,
                            title: languageService.translate('auto_upload'),
                            subtitle: languageService.translate('auto_upload_subtitle'),
                            value: _autoUpload,
                            onChanged: (value) {
                              setState(() => _autoUpload = value);
                              _prefs.setAutoUpload(value);
                            },
                          ),
                        ]),
                        SizedBox(height: isTabletOrLarger ? 32 : 24),
                        _buildSectionTitle(languageService.translate('legal')),
                        SizedBox(height: isTabletOrLarger ? 16 : 12),
                        _buildSettingsCard([
                          _buildNavigationTile(
                            icon: Icons.description_outlined,
                            title: languageService.translate('terms_of_service'),
                            onTap: () => _showLegalPage(context, languageService.translate('terms_of_service')),
                          ),
                          _buildDivider(),
                          _buildNavigationTile(
                            icon: Icons.privacy_tip_outlined,
                            title: languageService.translate('privacy_policy'),
                            onTap: () => _showLegalPage(context, languageService.translate('privacy_policy')),
                          ),
                        ]),
                        SizedBox(height: isTabletOrLarger ? 32 : 24),
                        _buildSectionTitle(languageService.translate('about')),
                        SizedBox(height: isTabletOrLarger ? 16 : 12),
                        _buildSettingsCard([
                          _buildNavigationTile(
                            icon: Icons.info_outline,
                            title: languageService.translate('about'),
                            onTap: () => _showAboutPage(context),
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.verified_outlined,
                            title: languageService.translate('version'),
                            value: '1.0.0',
                          ),
                        ]),
                        const SizedBox(height: 40),
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

  Widget _buildHeader(BuildContext context, LanguageService languageService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.glassWhite(0.8)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(languageService.translate('settings'), style: AppTheme.appTitleStyle),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: AppTheme.glassCardDecoration(),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AppTheme.glassWhite(0.1),
      indent: 56,
    );
  }

  Widget _buildLanguageTile(String selectedLanguage, LanguageService languageService) {
    return ListTile(
      leading: _buildIconContainer(Icons.language),
      title: Text(
        languageService.translate('language'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        selectedLanguage,
        style: TextStyle(color: AppTheme.glassWhite(0.6), fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.glassWhite(0.4)),
      onTap: () => _showLanguagePicker(),
    );
  }

  Widget _buildThemeTile(String selectedTheme, LanguageService languageService) {
    return ListTile(
      leading: _buildIconContainer(Icons.palette_outlined),
      title: Text(
        languageService.translate('theme'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        selectedTheme,
        style: TextStyle(color: AppTheme.glassWhite(0.6), fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.glassWhite(0.4)),
      onTap: () => _showThemePicker(),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final primaryColor = AppTheme.getPrimaryColor(context);
    return ListTile(
      leading: _buildIconContainer(icon),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTheme.glassWhite(0.6), fontSize: 13),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
        activeTrackColor: primaryColor.withValues(alpha: 0.4),
        inactiveThumbColor: AppTheme.glassWhite(0.6),
        inactiveTrackColor: AppTheme.glassWhite(0.2),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: _buildIconContainer(icon),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.glassWhite(0.4)),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: _buildIconContainer(icon),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        value,
        style: TextStyle(color: AppTheme.glassWhite(0.6), fontSize: 14),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.glassWhite(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppTheme.getPrimaryColor(context), size: 22),
    );
  }

  void _showLanguagePicker() {
    final languageService = context.read<LanguageService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSlate900(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _buildLanguagePickerSheet(sheetContext, languageService),
    );
  }

  Widget _buildLanguagePickerSheet(BuildContext sheetContext, LanguageService languageService) {
    final primaryColor = AppTheme.getPrimaryColor(context);
    final currentLanguage = languageService.getLanguageDisplayName();

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.glassWhite(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(languageService.translate('select_language'), style: AppTheme.cardTitleStyle),
            const SizedBox(height: 16),
            ..._languages.map((option) => ListTile(
              title: Text(
                option,
                style: TextStyle(
                  color: option == currentLanguage ? primaryColor : Colors.white,
                  fontWeight: option == currentLanguage ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: option == currentLanguage
                  ? Icon(Icons.check, color: primaryColor)
                  : null,
              onTap: () {
                languageService.setLanguageByName(option);
                Navigator.pop(sheetContext);
                setState(() {}); // Refresh UI
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showThemePicker() {
    final themeService = context.read<ThemeService>();
    final languageService = context.read<LanguageService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getSlate900(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _buildThemePickerSheet(
        sheetContext,
        themeService,
        languageService,
      ),
    );
  }

  Widget _buildThemePickerSheet(BuildContext sheetContext, ThemeService themeService, LanguageService languageService) {
    final primaryColor = AppTheme.getPrimaryColor(context);
    final currentTheme = themeService.getThemeModeDisplayName();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.glassWhite(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(languageService.translate('select_theme'), style: AppTheme.cardTitleStyle),
          const SizedBox(height: 16),
          ..._themes.map((option) => ListTile(
            title: Text(
              option,
              style: TextStyle(
                color: option == currentTheme ? primaryColor : Colors.white,
                fontWeight: option == currentTheme ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            trailing: option == currentTheme
                ? Icon(Icons.check, color: primaryColor)
                : null,
            onTap: () {
              AppThemeMode mode;
              switch (option) {
                case 'Light':
                  mode = AppThemeMode.light;
                  break;
                case 'System':
                  mode = AppThemeMode.system;
                  break;
                default:
                  mode = AppThemeMode.dark;
              }
              themeService.setThemeMode(mode);
              Navigator.pop(sheetContext);
            },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLegalPage(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _LegalScreen(title: title),
      ),
    );
  }

  void _showAboutPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _AboutScreen(),
      ),
    );
  }
}

/// Legal content screen (Terms, Privacy)
class _LegalScreen extends StatelessWidget {
  final String title;

  const _LegalScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    final isTabletOrLarger = context.isTabletOrLarger;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTabletOrLarger ? 700 : double.infinity,
              ),
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(padding),
                      child: Container(
                        padding: EdgeInsets.all(padding),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Text(
                          _getLegalContent(),
                          style: TextStyle(
                            color: AppTheme.glassWhite(0.8),
                            fontSize: isTabletOrLarger ? 16 : 14,
                            height: 1.6,
                          ),
                        ),
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.glassWhite(0.8)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(title, style: AppTheme.appTitleStyle),
        ],
      ),
    );
  }

  String _getLegalContent() {
    if (title == 'Terms of Service') {
      return '''Terms of Service

Last updated: January 2026

1. Acceptance of Terms
By accessing and using the AssetCapture application, you agree to be bound by these Terms of Service.

2. Use of Service
The AssetCapture app is designed for quality inspection and asset documentation purposes. You agree to use this service only for its intended purpose.

3. User Responsibilities
- You are responsible for maintaining the confidentiality of your account
- You agree to provide accurate information when using the service
- You will not use the service for any illegal purposes

4. Data Collection
We collect photos and barcode data that you submit through the app. This data is stored in your connected Google Drive account.

5. Intellectual Property
All content, features, and functionality of the app are owned by us and are protected by international copyright laws.

6. Limitation of Liability
We shall not be liable for any indirect, incidental, special, or consequential damages resulting from the use of our service.

7. Changes to Terms
We reserve the right to modify these terms at any time. Continued use of the service constitutes acceptance of modified terms.

8. Contact
For questions about these Terms, please contact us at support@example.com.''';
    } else {
      return '''Privacy Policy

Last updated: January 2026

1. Information We Collect
- Photos you capture using the app
- Barcode data you scan
- Asset descriptions you enter
- Google account information for authentication

2. How We Use Your Information
- To provide and maintain our service
- To upload your data to Google Drive
- To improve our service

3. Data Storage
Your photos and data are stored in your personal Google Drive account. We do not store your data on our servers.

4. Third-Party Services
We use Google Drive API to store your data. Please review Google's privacy policy for their data handling practices.

5. Data Security
We implement appropriate security measures to protect your data during transmission.

6. Your Rights
You have the right to:
- Access your data
- Delete your data
- Opt out of data collection

7. Children's Privacy
Our service is not intended for children under 13. We do not knowingly collect data from children.

8. Changes to Policy
We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy in the app.

9. Contact Us
If you have questions about this Privacy Policy, please contact us at privacy@example.com.''';
    }
  }
}

/// About screen
class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    final padding = Responsive.horizontalPadding(context);
    final isTabletOrLarger = context.isTabletOrLarger;

    return Scaffold(
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
                  _buildHeader(context, languageService),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        children: [
                          SizedBox(height: isTabletOrLarger ? 32 : 20),
                          Container(
                            padding: EdgeInsets.all(isTabletOrLarger ? 32 : 24),
                            decoration: BoxDecoration(
                              gradient: AppTheme.getPrimaryGradient(context),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppTheme.getGlowShadow(context),
                            ),
                            child: Icon(
                              Icons.qr_code_scanner,
                              size: isTabletOrLarger ? 80 : 64,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isTabletOrLarger ? 32 : 24),
                          Text(
                            'AssetCapture',
                            style: TextStyle(
                              fontSize: isTabletOrLarger ? 32 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${languageService.translate('version')} 1.0.0',
                            style: TextStyle(
                              fontSize: isTabletOrLarger ? 18 : 16,
                              color: AppTheme.glassWhite(0.6),
                            ),
                          ),
                          SizedBox(height: isTabletOrLarger ? 40 : 32),
                          Container(
                            padding: EdgeInsets.all(isTabletOrLarger ? 28 : 20),
                            decoration: AppTheme.glassCardDecoration(),
                            child: Text(
                              languageService.translate('app_description'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.glassWhite(0.8),
                                fontSize: isTabletOrLarger ? 17 : 15,
                                height: 1.6,
                              ),
                            ),
                          ),
                          SizedBox(height: isTabletOrLarger ? 32 : 24),
                          Container(
                            padding: EdgeInsets.all(isTabletOrLarger ? 28 : 20),
                            decoration: AppTheme.glassCardDecoration(),
                            child: Column(
                              children: [
                                _buildAboutRow(context, Icons.business, 'Company', 'Your Company Name'),
                                Divider(color: AppTheme.glassWhite(0.1), height: 24),
                                _buildAboutRow(context, Icons.email_outlined, 'Contact', 'support@example.com'),
                                Divider(color: AppTheme.glassWhite(0.1), height: 24),
                                _buildAboutRow(context, Icons.language, 'Website', 'www.example.com'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            '2026 Your Company. All rights reserved.',
                            style: TextStyle(
                              color: AppTheme.glassWhite(0.4),
                              fontSize: 12,
                            ),
                          ),
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
    );
  }

  Widget _buildHeader(BuildContext context, LanguageService languageService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.glassWhite(0.8)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(languageService.translate('about'), style: AppTheme.appTitleStyle),
        ],
      ),
    );
  }

  Widget _buildAboutRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.getPrimaryColor(context), size: 22),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.glassWhite(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
