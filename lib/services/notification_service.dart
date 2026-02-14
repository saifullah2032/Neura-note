import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Exception thrown when notification operations fail
class NotificationException implements Exception {
  final String message;
  final String? code;

  const NotificationException(this.message, [this.code]);

  @override
  String toString() => 'NotificationException: $message (code: $code)';
}

/// Notification types
enum NotificationType {
  summary,
  reminder,
  geofence,
  calendar,
  general,
}

/// Notification action callback
typedef NotificationCallback = void Function(String? payload);

/// Service responsible for handling local notifications
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  
  // Notification channels for Android
  static const String _summaryChannelId = 'summary_channel';
  static const String _reminderChannelId = 'reminder_channel';
  static const String _geofenceChannelId = 'geofence_channel';
  static const String _calendarChannelId = 'calendar_channel';
  static const String _generalChannelId = 'general_channel';

  // Callbacks
  NotificationCallback? _onNotificationTap;
  
  // Stream controllers for notification events
  final StreamController<String?> _notificationTapController = 
      StreamController<String?>.broadcast();

  NotificationService({
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  /// Stream of notification tap events
  Stream<String?> get onNotificationTap => _notificationTapController.stream;

  /// Initialize the notification service
  Future<bool> initialize({
    NotificationCallback? onTap,
  }) async {
    _onNotificationTap = onTap;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: _onIOSForegroundNotification,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    return initialized ?? false;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    }
    return true;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Show a summary completion notification
  Future<void> showSummaryNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      type: NotificationType.summary,
    );
  }

  /// Show a reminder notification
  Future<void> showReminderNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      type: NotificationType.reminder,
    );
  }

  /// Show a geofence trigger notification
  Future<void> showGeofenceNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      type: NotificationType.geofence,
    );
  }

  /// Show a calendar reminder notification
  Future<void> showCalendarNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      type: NotificationType.calendar,
    );
  }

  /// Show a general notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      type: NotificationType.general,
    );
  }

  /// Schedule a notification for a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationType type = NotificationType.reminder,
  }) async {
    try {
      final notificationDetails = _getNotificationDetails(type);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _convertToTZDateTime(scheduledDate),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      throw NotificationException('Failed to schedule notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Get active notifications (Android only)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (Platform.isAndroid) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.getActiveNotifications() ??
          [];
    }
    return [];
  }

  /// Show a notification with custom settings
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required NotificationType type,
  }) async {
    try {
      final notificationDetails = _getNotificationDetails(type);

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      throw NotificationException('Failed to show notification: $e');
    }
  }

  /// Get notification details based on type
  NotificationDetails _getNotificationDetails(NotificationType type) {
    final channelId = _getChannelId(type);
    final channelName = _getChannelName(type);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: _getChannelDescription(type),
      importance: _getImportance(type),
      priority: _getPriority(type),
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Get channel ID for notification type
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.summary:
        return _summaryChannelId;
      case NotificationType.reminder:
        return _reminderChannelId;
      case NotificationType.geofence:
        return _geofenceChannelId;
      case NotificationType.calendar:
        return _calendarChannelId;
      case NotificationType.general:
        return _generalChannelId;
    }
  }

  /// Get channel name for notification type
  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.summary:
        return 'Summary Notifications';
      case NotificationType.reminder:
        return 'Reminders';
      case NotificationType.geofence:
        return 'Location Reminders';
      case NotificationType.calendar:
        return 'Calendar Events';
      case NotificationType.general:
        return 'General';
    }
  }

  /// Get channel description for notification type
  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.summary:
        return 'Notifications for completed summaries';
      case NotificationType.reminder:
        return 'Reminder notifications';
      case NotificationType.geofence:
        return 'Location-based reminder notifications';
      case NotificationType.calendar:
        return 'Calendar event notifications';
      case NotificationType.general:
        return 'General app notifications';
    }
  }

  /// Get importance level for notification type
  Importance _getImportance(NotificationType type) {
    switch (type) {
      case NotificationType.geofence:
      case NotificationType.calendar:
        return Importance.high;
      case NotificationType.reminder:
        return Importance.high;
      case NotificationType.summary:
        return Importance.defaultImportance;
      case NotificationType.general:
        return Importance.defaultImportance;
    }
  }

  /// Get priority for notification type
  Priority _getPriority(NotificationType type) {
    switch (type) {
      case NotificationType.geofence:
      case NotificationType.calendar:
        return Priority.high;
      case NotificationType.reminder:
        return Priority.high;
      case NotificationType.summary:
        return Priority.defaultPriority;
      case NotificationType.general:
        return Priority.defaultPriority;
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (android == null) return;

    final channels = [
      AndroidNotificationChannel(
        _summaryChannelId,
        'Summary Notifications',
        description: 'Notifications for completed summaries',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        _reminderChannelId,
        'Reminders',
        description: 'Reminder notifications',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _geofenceChannelId,
        'Location Reminders',
        description: 'Location-based reminder notifications',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _calendarChannelId,
        'Calendar Events',
        description: 'Calendar event notifications',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _generalChannelId,
        'General',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await android.createNotificationChannel(channel);
    }
  }

  /// Handle iOS foreground notification (iOS < 10)
  void _onIOSForegroundNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    _notificationTapController.add(payload);
    _onNotificationTap?.call(payload);
  }

  /// Handle notification response
  void _onNotificationResponse(NotificationResponse response) {
    _notificationTapController.add(response.payload);
    _onNotificationTap?.call(response.payload);
  }

  /// Convert DateTime to TZDateTime for scheduling
  // Note: In production, use timezone package for proper timezone handling
  dynamic _convertToTZDateTime(DateTime dateTime) {
    // This is a simplified implementation
    // In production, use: tz.TZDateTime.from(dateTime, tz.local)
    return dateTime;
  }

  /// Dispose resources
  void dispose() {
    _notificationTapController.close();
  }
}

/// Background notification response handler
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  // Handle background notification tap
  // In production, you might want to use a shared isolate or store the payload
  debugPrint('Background notification tapped: ${response.payload}');
}
