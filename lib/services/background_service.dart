import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration for background service
class BackgroundServiceConfig {
  final int locationUpdateIntervalMinutes;
  final int distanceFilterMeters;
  final bool showNotificationOnStart;
  final String notificationTitle;
  final String notificationContent;

  const BackgroundServiceConfig({
    this.locationUpdateIntervalMinutes = 15,
    this.distanceFilterMeters = 100,
    this.showNotificationOnStart = true,
    this.notificationTitle = 'NeuraNote',
    this.notificationContent = 'Monitoring location reminders',
  });
}

/// Background service for location monitoring
/// Handles geofence checks when app is in background
class BackgroundService {
  static const String _serviceNotificationChannelId = 'neuranotteai_background';
  static const String _serviceNotificationChannelName = 'Background Service';
  static const String _prefKeyServiceEnabled = 'background_service_enabled';
  static const String _prefKeyUserId = 'background_service_user_id';

  final FlutterBackgroundService _service = FlutterBackgroundService();
  
  BackgroundServiceConfig _config = const BackgroundServiceConfig();
  bool _isInitialized = false;

  /// Singleton instance
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  /// Check if service is running
  Future<bool> get isRunning async => await _service.isRunning();

  /// Initialize the background service
  Future<bool> initialize({
    BackgroundServiceConfig? config,
  }) async {
    if (_isInitialized) return true;

    _config = config ?? const BackgroundServiceConfig();

    try {
      // Configure the notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _serviceNotificationChannelId,
        _serviceNotificationChannelName,
        description: 'Background location monitoring for reminders',
        importance: Importance.low,
        showBadge: false,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Configure the background service
      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: _serviceNotificationChannelId,
          initialNotificationTitle: _config.notificationTitle,
          initialNotificationContent: _config.notificationContent,
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: _onStart,
          onBackground: _onIosBackground,
        ),
      );

      _isInitialized = true;
      debugPrint('BackgroundService initialized');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize BackgroundService: $e');
      return false;
    }
  }

  /// Start the background service
  Future<bool> start({required String userId}) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      // Save user ID for the background isolate
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyUserId, userId);
      await prefs.setBool(_prefKeyServiceEnabled, true);

      final started = await _service.startService();
      debugPrint('BackgroundService started: $started');
      return started;
    } catch (e) {
      debugPrint('Failed to start BackgroundService: $e');
      return false;
    }
  }

  /// Stop the background service
  Future<void> stop() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyServiceEnabled, false);

      _service.invoke('stopService');
      debugPrint('BackgroundService stopped');
    } catch (e) {
      debugPrint('Failed to stop BackgroundService: $e');
    }
  }

  /// Update service configuration
  void updateConfig(BackgroundServiceConfig config) {
    _config = config;
    if (_isInitialized) {
      _service.invoke('updateConfig', {
        'intervalMinutes': config.locationUpdateIntervalMinutes,
        'distanceFilter': config.distanceFilterMeters,
      });
    }
  }

  /// Send data to the background service
  void sendData(Map<String, dynamic> data) {
    _service.invoke('data', data);
  }

  /// Listen to events from the background service
  Stream<Map<String, dynamic>?> get onEvent => _service.on('event');

  /// Listen to location updates from background
  Stream<Map<String, dynamic>?> get onLocationUpdate =>
      _service.on('locationUpdate');

  /// Listen to geofence trigger events from background
  Stream<Map<String, dynamic>?> get onGeofenceTrigger =>
      _service.on('geofenceTrigger');
}

/// Entry point for the background service (runs in isolate)
@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  // Ensure Flutter bindings are initialized
  DartPluginRegistrant.ensureInitialized();

  debugPrint('Background service started');

  // Track if service should continue running
  bool isRunning = true;

  // Location update timer
  Timer? locationTimer;

  // Load user preferences
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('background_service_user_id');
  int intervalMinutes = prefs.getInt('location_interval_minutes') ?? 15;
  int distanceFilter = prefs.getInt('distance_filter_meters') ?? 100;

  if (userId == null) {
    debugPrint('No user ID found, stopping background service');
    service.stopSelf();
    return;
  }

  // Handle stop request
  service.on('stopService').listen((event) {
    debugPrint('Background service stop requested');
    isRunning = false;
    locationTimer?.cancel();
    service.stopSelf();
  });

  // Handle config updates
  service.on('updateConfig').listen((event) {
    if (event != null) {
      intervalMinutes = event['intervalMinutes'] ?? intervalMinutes;
      distanceFilter = event['distanceFilter'] ?? distanceFilter;
      
      // Restart timer with new interval
      locationTimer?.cancel();
      locationTimer = Timer.periodic(
        Duration(minutes: intervalMinutes),
        (_) => _checkLocation(service, userId, distanceFilter),
      );
    }
  });

  // Set as foreground service on Android
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Initial location check
  await _checkLocation(service, userId, distanceFilter);

  // Start periodic location checks
  locationTimer = Timer.periodic(
    Duration(minutes: intervalMinutes),
    (_) {
      if (isRunning) {
        _checkLocation(service, userId, distanceFilter);
      }
    },
  );
}

/// Check location and evaluate geofences
Future<void> _checkLocation(
  ServiceInstance service,
  String userId,
  int distanceFilter,
) async {
  try {
    // Check location permission
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('Background service: Location permission denied');
      return;
    }

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Background service: Location services disabled');
      return;
    }

    // Get current position
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );

    debugPrint(
      'Background location: ${position.latitude}, ${position.longitude}',
    );

    // Send location update event
    service.invoke('locationUpdate', {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
    });

    // Note: Actual geofence checking is handled by the main app
    // when it receives the locationUpdate event. This is because
    // the background isolate doesn't have access to the full
    // reminder repository and geofence configurations.
    
  } catch (e) {
    debugPrint('Background location error: $e');
    service.invoke('event', {
      'type': 'error',
      'message': e.toString(),
    });
  }
}

/// iOS background fetch handler
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  debugPrint('iOS background fetch triggered');

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('background_service_user_id');
  final distanceFilter = prefs.getInt('distance_filter_meters') ?? 100;

  if (userId != null) {
    await _checkLocation(service, userId, distanceFilter);
  }

  return true;
}

/// Helper class for managing background service state
class BackgroundServiceState {
  final bool isRunning;
  final DateTime? lastLocationUpdate;
  final Position? lastPosition;
  final int activeGeofenceCount;
  final String? error;

  const BackgroundServiceState({
    this.isRunning = false,
    this.lastLocationUpdate,
    this.lastPosition,
    this.activeGeofenceCount = 0,
    this.error,
  });

  BackgroundServiceState copyWith({
    bool? isRunning,
    DateTime? lastLocationUpdate,
    Position? lastPosition,
    int? activeGeofenceCount,
    String? error,
  }) {
    return BackgroundServiceState(
      isRunning: isRunning ?? this.isRunning,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      lastPosition: lastPosition ?? this.lastPosition,
      activeGeofenceCount: activeGeofenceCount ?? this.activeGeofenceCount,
      error: error ?? this.error,
    );
  }
}

/// Extension to integrate background service with reminder manager
extension BackgroundServiceIntegration on BackgroundService {
  /// Start monitoring with reminder manager integration
  Future<bool> startWithReminders({
    required String userId,
    required int activeReminderCount,
  }) async {
    final started = await start(userId: userId);
    
    if (started) {
      sendData({
        'activeReminderCount': activeReminderCount,
      });
    }
    
    return started;
  }

  /// Update active reminder count
  void updateReminderCount(int count) {
    sendData({
      'activeReminderCount': count,
    });
  }
}
