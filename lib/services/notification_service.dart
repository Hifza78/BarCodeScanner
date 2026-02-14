import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'preferences_service.dart';

/// Service for showing local notifications (e.g. upload complete)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final PreferencesService _prefs = PreferencesService();
  bool _isInitialized = false;
  int _notificationId = 0;

  /// Initialize the notification plugin
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);
    _isInitialized = true;

    // Request permission on Android 13+
    await _requestPermission();
  }

  Future<void> _requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  /// Show a notification for a completed upload
  Future<void> showUploadComplete({required String bcn}) async {
    final enabled = await _prefs.isNotificationsEnabled;
    if (!enabled) return;

    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'upload_channel',
      'Upload Notifications',
      channelDescription: 'Notifications for completed uploads',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: _notificationId++,
      title: 'Upload Complete',
      body: 'Barcode $bcn has been uploaded successfully.',
      notificationDetails: details,
    );
  }

  /// Show a notification for a failed upload
  Future<void> showUploadFailed({required String bcn}) async {
    final enabled = await _prefs.isNotificationsEnabled;
    if (!enabled) return;

    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'upload_channel',
      'Upload Notifications',
      channelDescription: 'Notifications for upload status',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: _notificationId++,
      title: 'Upload Failed',
      body: 'Upload for barcode $bcn failed. Tap to retry.',
      notificationDetails: details,
    );
  }
}
