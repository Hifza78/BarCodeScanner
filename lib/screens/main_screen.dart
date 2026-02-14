import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../main.dart';
import '../models/session_data.dart';
import '../services/auth_service.dart';
import '../services/barcode_service.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/upload_queue_service.dart';
import '../utils/app_dialogs.dart';
import '../utils/responsive.dart';
import '../utils/ui_utils.dart';
import '../widgets/camera_capture_screen.dart';
import '../widgets/common/app_logo.dart';
import 'settings_screen.dart';
import 'upload_queue_screen.dart';

/// Main screen of the AssetCapture app
/// Redesigned with tabbed UI (Scan, Photos, Details)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _descriptionController = TextEditingController();
  final SessionData _sessionData = SessionData();
  final AuthService _authService = AuthService();
  final PreferencesService _prefs = PreferencesService();
  final NotificationService _notificationService = NotificationService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  int _selectedTabIndex = 0;
  int _bottomNavIndex = 0;
  StreamSubscription? _completedTaskSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });

    // Listen for completed uploads and automatically open the shareable link
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final queueService = context.read<UploadQueueService>();
      _completedTaskSubscription = queueService.onTaskCompleted.listen((task) {
        _openShareableLinkInBrowser(task.driveUrl);
        _notificationService.showUploadComplete(bcn: task.bcn);
      });
    });
  }

  @override
  void dispose() {
    _completedTaskSubscription?.cancel();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Opens the shareable Drive link in the device's default browser
  Future<void> _openShareableLinkInBrowser(String? driveUrl) async {
    if (driveUrl == null || driveUrl.isEmpty) return;
    final lang = context.read<LanguageService>();

    try {
      final uri = Uri.parse(driveUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          context.showSuccess(lang.translate('upload_complete_opening_link'));
        }
      } else {
        if (mounted) {
          context.showError(lang.translate('could_not_open_browser'));
        }
      }
    } catch (e) {
      if (mounted) {
        context.showError('${lang.translate('failed_open_link')}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = context.isTabletOrLarger;
    final horizontalPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _ModernDrawer(
        authService: _authService,
        onProfilePressed: _showProfileDialog,
        onLogoutPressed: _signOut,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: isTabletOrLarger ? 24 : 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: _buildTabBar(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(),
                    _buildPhotosTab(),
                  ],
                ),
              ),
              _buildUploadButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final horizontalPadding = Responsive.horizontalPadding(context);
    final isTabletOrLarger = context.isTabletOrLarger;
    final maxWidth = isTabletOrLarger ? 600.0 : double.infinity;
    final lang = context.watch<LanguageService>();

    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, horizontalPadding),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassWhite(0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.glassWhite(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTabletOrLarger ? 24 : 12,
                vertical: isTabletOrLarger ? 14 : 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: lang.translate('home'),
                    onTap: () => setState(() => _bottomNavIndex = 0),
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.qr_code_scanner_rounded,
                    label: lang.translate('scanner'),
                    onTap: () {
                      setState(() => _bottomNavIndex = 1);
                      _openBarcodeScanner();
                    },
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.logout_rounded,
                    label: lang.translate('logout'),
                    onTap: () {
                      setState(() => _bottomNavIndex = 2);
                      _signOut();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.getPrimaryGradient(context) : null,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? AppTheme.getGlowShadow(context) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.glassWhite(0.6),
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final lang = context.watch<LanguageService>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(gradient: AppTheme.getTealGradient(context)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.translate('app_name'), style: AppTheme.appTitleStyle),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: AppTheme.glassWhite(0.8)),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.glassWhite(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.glassWhite(0.1)),
      ),
      child: Row(
        children: [
          _buildTabButton(0, Icons.description_outlined, context.watch<LanguageService>().translate('details')),
          _buildTabButton(1, Icons.photo_library_outlined, context.watch<LanguageService>().translate('photos')),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _selectedTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: isSelected
              ? AppTheme.getTabSelectedDecoration(context)
              : BoxDecoration(borderRadius: BorderRadius.circular(25)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.glassWhite(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.glassWhite(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PHOTOS TAB
  // ===========================================================================

  Widget _buildPhotosTab() {
    final padding = Responsive.horizontalPadding(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          _buildPhotoHeader(),
          SizedBox(height: padding),
          _buildPhotoGrid(),
        ],
      ),
    );
  }

  Widget _buildPhotoHeader() {
    final lang = context.watch<LanguageService>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.translate('photos'),
                  style: AppTheme.cardTitleStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_sessionData.photos.length} / ${AppConfig.maxPhotos} ${lang.translate('uploaded')}',
                  style: AppTheme.subtitleStyle(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppTheme.getPrimaryGradient(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_sessionData.photos.length}/${AppConfig.maxPhotos}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final crossAxisCount = Responsive.gridCrossAxisCount(context);
    final spacing = Responsive.spacing(context, baseSpacing: 12);

    // Calculate item count dynamically to show all photos
    final hasAddButton = _sessionData.photos.length < AppConfig.maxPhotos;
    final actualItems = _sessionData.photos.length + (hasAddButton ? 1 : 0);
    // Round up to fill the last row, with a minimum of 2 rows
    final minItems = crossAxisCount * 2;
    final itemCount = actualItems > minItems
        ? ((actualItems + crossAxisCount - 1) ~/ crossAxisCount) * crossAxisCount
        : minItems;

    return Container(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      decoration: AppTheme.glassCardDecoration(),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0 && _sessionData.photos.length < AppConfig.maxPhotos) {
            return _buildAddPhotoButton();
          }

          final photoIndex = _sessionData.photos.length < AppConfig.maxPhotos
              ? index - 1
              : index;

          if (photoIndex >= 0 && photoIndex < _sessionData.photos.length) {
            return _buildPhotoTile(_sessionData.photos[photoIndex], photoIndex);
          }

          return _buildEmptyPhotoSlot();
        },
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    final lang = context.watch<LanguageService>();
    return GestureDetector(
      onTap: _sessionData.isUploading ? null : _openCameraScreen,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.getPrimaryGradient(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.getGlowShadow(context),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang.translate('add_photo'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTile(File photo, int index) {
    return GestureDetector(
      onTap: () => _viewPhoto(photo),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassWhite(0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                photo,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: 200,
                cacheHeight: 200,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.glassWhite(0.05),
                  child: Icon(
                    Icons.broken_image,
                    color: AppTheme.glassWhite(0.3),
                  ),
                ),
              ),
            ),
          ),
          if (!_sessionData.isUploading)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _confirmDeletePhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyPhotoSlot() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.glassWhite(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassWhite(0.1)),
      ),
    );
  }

  // ===========================================================================
  // DETAILS TAB
  // ===========================================================================

  Widget _buildDetailsTab() {
    final padding = Responsive.horizontalPadding(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          _buildDescriptionSection(),
          SizedBox(height: padding),
          _buildScannerSection(),
          SizedBox(height: padding),
          _buildDeviceInfoSection(),
          SizedBox(height: padding),
          _buildCompletionStatus(),
        ],
      ),
    );
  }

  Widget _buildScannerSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        children: [
          if (_sessionData.bcn.isNotEmpty) ...[
            Text(
              _sessionData.bcn,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppTheme.getAccentLight(context),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text(
                        context.watch<LanguageService>().translate('scanned'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          // Start Scanning & Add Photos buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.getPrimaryGradient(context),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: AppTheme.getGlowShadow(context),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _sessionData.isUploading ? null : _openBarcodeScanner,
                    icon: Icon(
                      _sessionData.bcn.isEmpty ? Icons.qr_code_scanner : Icons.refresh,
                      size: 20,
                    ),
                    label: Text(
                      _sessionData.bcn.isEmpty
                          ? context.watch<LanguageService>().translate('start_scanning')
                          : context.watch<LanguageService>().translate('scan_again'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.getPrimaryGradient(context),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: AppTheme.getGlowShadow(context),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _sessionData.isUploading ? null : _navigateToPhotosAndOpenCamera,
                    icon: const Icon(Icons.add_a_photo, size: 20),
                    label: Text(
                      context.watch<LanguageService>().translate('add_photos'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(builder: (context) {
            final lang = context.watch<LanguageService>();
            return Row(
              children: [
                Text(lang.translate('asset_description'), style: AppTheme.cardTitleStyle),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.glassWhite(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lang.translate('optional'),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.glassWhite(0.6),
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            enabled: !_sessionData.isUploading,
            minLines: 4,
            maxLines: 6,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: AppTheme.textFieldDecoration(
              hintText: context.watch<LanguageService>().translate('description_hint'),
            ),
            onChanged: (value) {
              setState(() => _sessionData.description = value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${_descriptionController.text.length} ${context.watch<LanguageService>().translate('characters')}',
            style: AppTheme.subtitleStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoSection() {
    final lang = context.watch<LanguageService>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.translate('device_info'), style: AppTheme.cardTitleStyle),
          const SizedBox(height: 16),
          Builder(builder: (context) {
            final lang = context.watch<LanguageService>();
            return Column(
              children: [
                _buildInfoRow(
                  lang.translate('barcode_id'),
                  _sessionData.bcn.isEmpty ? lang.translate('not_scanned') : _sessionData.bcn,
                  isHighlighted: _sessionData.bcn.isNotEmpty,
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildInfoRow(
                  lang.translate('photos'),
                  _sessionData.photos.isEmpty
                      ? '0 ${lang.translate('uploaded')}'
                      : '${_sessionData.photos.length} ${lang.translate('uploaded')}',
                  valueColor: _sessionData.photos.isNotEmpty ? AppTheme.getPrimaryColor(context) : null,
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildInfoRow(
                  lang.translate('description'),
                  _sessionData.description.isEmpty ? lang.translate('empty') : lang.translate('added'),
                  valueColor: _sessionData.description.isNotEmpty ? AppTheme.success : null,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.subtitleStyle()),
        if (isHighlighted)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              context.showSnackBar(context.read<LanguageService>().translate('barcode_copied'));
            },
            child: Row(
              children: [
                Text(
                  value.length > 15 ? '${value.substring(0, 15)}...' : value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.copy, size: 16, color: AppTheme.glassWhite(0.5)),
              ],
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildCompletionStatus() {
    final lang = context.watch<LanguageService>();
    final barcodeScanned = _sessionData.bcn.isNotEmpty;
    final photosAdded = _sessionData.photos.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.getPrimaryColor(context), size: 20),
              const SizedBox(width: 8),
              Text(lang.translate('completion_status'), style: AppTheme.cardTitleStyle),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusItem(
            lang.translate('device_scanned'),
            barcodeScanned,
          ),
          const SizedBox(height: 12),
          _buildStatusItem(
            lang.translate('photos_taken'),
            photosAdded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isCompleted) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppTheme.success.withValues(alpha: 0.2)
                : AppTheme.glassWhite(0.1),
            border: Border.all(
              color: isCompleted ? AppTheme.success : AppTheme.glassWhite(0.3),
              width: 2,
            ),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 12, color: AppTheme.success)
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isCompleted ? Colors.white : AppTheme.glassWhite(0.6),
            fontSize: 14,
            fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // UPLOAD BUTTON
  // ===========================================================================

  Widget _buildUploadButton() {
    // Photos tab → show only SAVE button
    if (_selectedTabIndex == 1) {
      return _buildSaveButton();
    }

    // Details tab → show upload queue button
    final isEnabled = _sessionData.isReadyForUpload;

    return Consumer<UploadQueueService>(
      builder: (context, queueService, child) {
        final hasActiveUploads = queueService.activeCount > 0;
        final currentTask = queueService.currentTask;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show queue status bar if there are active uploads
              if (hasActiveUploads)
                GestureDetector(
                  onTap: _openQueueScreen,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.glassWhite(0.2)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: currentTask?.progress,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.getPrimaryColor(context),
                            ),
                            backgroundColor: AppTheme.glassWhite(0.2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentTask != null
                                    ? '${context.read<LanguageService>().translate('uploading')}: ${currentTask.bcn}'
                                    : '${queueService.pendingCount} ${context.read<LanguageService>().translate('n_uploads_in_queue')}',
                                style: TextStyle(
                                  color: AppTheme.glassWhite(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (currentTask != null)
                                Text(
                                  '${(currentTask.progress * 100).toInt()}% • ${queueService.pendingCount} ${context.read<LanguageService>().translate('more_in_queue')}',
                                  style: TextStyle(
                                    color: AppTheme.glassWhite(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppTheme.glassWhite(0.6),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

              // Main upload button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isEnabled ? AppTheme.getPrimaryGradient(context) : null,
                    color: isEnabled ? null : AppTheme.glassWhite(0.1),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isEnabled ? AppTheme.getGlowShadow(context) : null,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: isEnabled ? _uploadAndFinish : null,
                    icon: const Icon(Icons.add_to_queue, size: 22),
                    label: Text(
                      context.read<LanguageService>().translate('add_to_upload_queue'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: AppTheme.glassWhite(0.5),
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    final hasPhotos = _sessionData.photos.isNotEmpty;
    final lang = context.watch<LanguageService>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            gradient: hasPhotos ? AppTheme.getPrimaryGradient(context) : null,
            color: hasPhotos ? null : AppTheme.glassWhite(0.1),
            borderRadius: BorderRadius.circular(30),
            boxShadow: hasPhotos ? AppTheme.getGlowShadow(context) : null,
          ),
          child: ElevatedButton.icon(
            onPressed: hasPhotos
                ? () {
                    context.showSuccess(
                      '${_sessionData.photos.length} ${lang.translate('photos_saved_go_details')}',
                    );
                  }
                : null,
            icon: const Icon(Icons.save_rounded, size: 22),
            label: Text(
              hasPhotos
                  ? '${lang.translate('save')} (${_sessionData.photos.length})'
                  : lang.translate('save'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: AppTheme.glassWhite(0.5),
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openQueueScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const UploadQueueScreen()),
    );
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _navigateToPhotosAndOpenCamera() async {
    // Open camera first, then switch tab after photos are taken
    await _openCameraScreen();
    if (mounted) {
      _tabController.animateTo(1);
      setState(() => _selectedTabIndex = 1);
    }
  }

  Future<void> _openBarcodeScanner() async {
    try {
      final result = await BarcodeService.scanBarcode(context);
      if (result != null && mounted) {
        setState(() {
          _sessionData.bcn = result.value;
        });
        _tryAutoUpload();
      }
    } catch (e) {
      debugPrint('Error opening barcode scanner: $e');
      if (mounted) {
        context.showError(context.read<LanguageService>().translate('failed_open_scanner'));
      }
    }
  }

  Future<void> _openCameraScreen() async {
    try {
      final result = await Navigator.of(context).push<List<File>>(
        MaterialPageRoute(
          builder: (context) => CameraCaptureScreen(
            maxPhotos: AppConfig.maxPhotos,
            currentPhotoCount: _sessionData.photos.length,
          ),
        ),
      );

      if (result != null && result.isNotEmpty && mounted) {
        setState(() => _sessionData.addPhotos(result));
        _tryAutoUpload();
      }
    } catch (e) {
      debugPrint('Error opening camera screen: $e');
      if (mounted) {
        context.showError(context.read<LanguageService>().translate('failed_open_camera'));
      }
    }
  }

  void _viewPhoto(File photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoViewScreen(photo: photo),
      ),
    );
  }

  Future<void> _confirmDeletePhoto(int index) async {
    final lang = context.read<LanguageService>();
    final confirmed = await AppDialogs.showConfirmation(
      context: context,
      title: lang.translate('delete_photo'),
      message: lang.translate('delete_photo_confirm'),
      confirmText: lang.translate('delete'),
      isDangerous: true,
    );

    if (confirmed) {
      setState(() => _sessionData.removePhoto(index));
    }
  }

  /// Checks if auto-upload is enabled and session is ready, then queues upload
  Future<void> _tryAutoUpload() async {
    if (!_sessionData.isReadyForUpload) return;

    final autoUpload = await _prefs.isAutoUploadEnabled;
    if (!autoUpload || !mounted) return;

    _uploadAndFinish();
  }

  Future<void> _uploadAndFinish() async {
    final lang = context.read<LanguageService>();
    if (_sessionData.bcn.isEmpty) {
      context.showError(lang.translate('scan_barcode_first'));
      return;
    }
    if (_sessionData.photos.isEmpty) {
      context.showError(lang.translate('take_photo_first'));
      return;
    }
    if (!_sessionData.isReadyForUpload) {
      context.showSnackBar(lang.translate('enter_barcode_and_photo'));
      return;
    }

    // Save description to session data
    _sessionData.description = _descriptionController.text;

    try {
      // Get queue service and enqueue the task
      final queueService = context.read<UploadQueueService>();
      await queueService.enqueue(_sessionData);

      // Clear session immediately so user can start next scan
      await _sessionData.clearPhotos();
      _descriptionController.clear();
      setState(() => _sessionData.reset());

      if (mounted) {
        context.showSuccess(lang.translate('upload_queued'));
      }
    } catch (e) {
      if (mounted) context.showError('${lang.translate('failed_queue_upload')}: $e');
    }
  }

  void _showUploadSuccessDialog({
    required String bcn,
    required String description,
    required int photoCount,
    required bool hasBarcodeImage,
    required String driveUrl,
  }) {
    AppDialogs.showSuccess(
      context: context,
      title: context.read<LanguageService>().translate('upload_successful'),
      content: _UploadSuccessContent(
        bcn: bcn,
        description: description,
        photoCount: photoCount,
        hasBarcodeImage: hasBarcodeImage,
        driveUrl: driveUrl,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.read<LanguageService>().translate('close')),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            _submitToWarehouse(bcn: bcn, description: description, driveUrl: driveUrl);
          },
          icon: const Icon(Icons.warehouse),
          label: Text(context.read<LanguageService>().translate('submit_to_warehouse')),
          style: AppTheme.secondaryButtonStyle(),
        ),
      ],
    );
  }

  Future<void> _submitToWarehouse({
    required String bcn,
    required String description,
    required String driveUrl,
  }) async {
    final warehouseUrl = AppConfig.buildWmsUrl(
      bcn: bcn,
      driveUrl: driveUrl,
      description: description,
    );

    context.showSnackBar(context.read<LanguageService>().translate('opening_warehouse'));

    final uri = Uri.parse(warehouseUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) context.showError(context.read<LanguageService>().translate('could_not_open_browser'));
    }
  }

  void _showProfileDialog() {
    AppDialogs.showProfile(
      context: context,
      displayName: _authService.displayName,
      email: _authService.email,
      photoUrl: _authService.currentUser?.photoUrl,
    );
  }

  Future<void> _signOut() async {
    final confirmed = await AppDialogs.showConfirmation(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDangerous: true,
    );

    if (confirmed) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }
}

/// Modern drawer widget with professional design
class _ModernDrawer extends StatelessWidget {
  final AuthService authService;
  final VoidCallback onProfilePressed;
  final VoidCallback onLogoutPressed;

  const _ModernDrawer({
    required this.authService,
    required this.onProfilePressed,
    required this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final lang = context.watch<LanguageService>();

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f0f23),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _ModernDrawerHeader(user: user, authService: authService),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(lang.translate('general')),
                      const SizedBox(height: 8),
                      _ModernDrawerTile(
                        icon: Icons.person_outline_rounded,
                        label: lang.translate('Profile'),
                        subtitle: lang.translate('View your profile'),
                        onTap: () {
                          Navigator.pop(context);
                          onProfilePressed();
                        },
                      ),
                      _ModernDrawerTile(
                        icon: Icons.settings_outlined,
                        label: lang.translate('settings'),
                        subtitle: lang.translate('App preferences'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel(lang.translate('about')),
                      const SizedBox(height: 8),
                      _ModernDrawerTile(
                        icon: Icons.info_outline_rounded,
                        label: lang.translate('about'),
                        subtitle: 'AssetCapture v1.0.0',
                        onTap: () {
                          Navigator.pop(context);
                          _showModernAboutDialog(context, lang);
                        },
                      ),
                      _ModernDrawerTile(
                        icon: Icons.help_outline_rounded,
                        label: lang.translate('support'),
                        subtitle: lang.translate('Get help'),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              _buildLogoutSection(context, lang),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.glassWhite(0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, LanguageService lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.glassWhite(0.08)),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onLogoutPressed();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.error.withValues(alpha: 0.15),
                AppTheme.error.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
              const SizedBox(width: 10),
              Text(
                lang.translate('logout'),
                style: const TextStyle(
                  color: AppTheme.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showModernAboutDialog(BuildContext context, LanguageService lang) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1a1a2e),
                const Color(0xFF16213e),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.glassWhite(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 72),
              const SizedBox(height: 20),
              const Text(
                'AssetCapture',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.glassWhite(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${lang.translate('version')} 1.0.0',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.glassWhite(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                lang.translate('app_description'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.glassWhite(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppTheme.glassWhite(0.1),
                  ),
                  child: Text(
                    lang.translate('close'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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

/// Modern drawer header widget with elegant design
class _ModernDrawerHeader extends StatelessWidget {
  final dynamic user;
  final AuthService authService;

  const _ModernDrawerHeader({required this.user, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.getPrimaryColor(context),
            AppTheme.getPrimaryColor(context).withValues(alpha: 0.8),
            AppTheme.getAccentMedium(context),
          ],
        ),
      ),
      child: Column(
        children: [
          // Close button row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Avatar with status indicator
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? const Icon(Icons.person_rounded, size: 45, color: Colors.white)
                      : null,
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            authService.displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Email pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              authService.email,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern drawer tile with hover effect
class _ModernDrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ModernDrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.glassWhite(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.glassWhite(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.getPrimaryColor(context).withValues(alpha: 0.2),
                        AppTheme.getPrimaryColor(context).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.getPrimaryColor(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.glassWhite(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing ?? Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.glassWhite(0.3),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Upload success dialog content
class _UploadSuccessContent extends StatelessWidget {
  final String bcn;
  final String description;
  final int photoCount;
  final bool hasBarcodeImage;
  final String driveUrl;

  const _UploadSuccessContent({
    required this.bcn,
    required this.description,
    required this.photoCount,
    required this.hasBarcodeImage,
    required this.driveUrl,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageService>();
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.translate('verify_data'),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          InfoRow(
            icon: Icons.qr_code,
            label: lang.translate('barcode_number'),
            value: bcn,
            iconColor: AppTheme.accent,
          ),
          const Divider(height: 24),
          InfoRow(
            icon: Icons.photo_library,
            label: lang.translate('photos_uploaded'),
            value: '$photoCount photo${photoCount > 1 ? 's' : ''}',
            iconColor: AppTheme.warning,
          ),
          const Divider(height: 24),
          InfoRow(
            icon: Icons.image,
            label: lang.translate('barcode_image'),
            value: hasBarcodeImage ? lang.translate('included') : lang.translate('not_available'),
            iconColor: AppTheme.info,
          ),
          const Divider(height: 24),
          InfoRow(
            icon: Icons.description,
            label: lang.translate('description'),
            value: description.isNotEmpty ? description : lang.translate('no_description'),
            iconColor: AppTheme.success,
            isMultiLine: true,
          ),
          const Divider(height: 24),
          _DriveLink(driveUrl: driveUrl),
        ],
      ),
    );
  }
}

/// Drive link widget
class _DriveLink extends StatelessWidget {
  final String driveUrl;

  const _DriveLink({required this.driveUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.read<LanguageService>().translate('drive_folder'),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final uri = Uri.parse(driveUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_shared, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    driveUrl,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.open_in_new, size: 16, color: Colors.blue.shade700),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen photo view
class _PhotoViewScreen extends StatelessWidget {
  final File photo;

  const _PhotoViewScreen({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(context.read<LanguageService>().translate('photo_preview')),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            photo,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
