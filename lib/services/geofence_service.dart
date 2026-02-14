import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:neuranotteai/services/location_service.dart';
import 'package:neuranotteai/services/notification_service.dart';

/// Exception thrown when geofence operations fail
class GeofenceException implements Exception {
  final String message;
  final String? code;

  const GeofenceException(this.message, [this.code]);

  @override
  String toString() => 'GeofenceException: $message (code: $code)';
}

/// Geofence trigger type
enum GeofenceTriggerType {
  enter,
  exit,
  dwell,
}

/// Geofence status
enum GeofenceStatus {
  active,
  inactive,
  triggered,
  expired,
}

/// Represents a geofence region
class GeofenceRegion {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusInMeters;
  final GeofenceTriggerType triggerType;
  final Duration? dwellDuration;
  final String? payload;
  final DateTime? expiresAt;

  GeofenceStatus _status = GeofenceStatus.inactive;
  DateTime? _enteredAt;
  bool _isInside = false;

  GeofenceRegion({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusInMeters = 200,
    this.triggerType = GeofenceTriggerType.enter,
    this.dwellDuration,
    this.payload,
    this.expiresAt,
  });

  GeofenceStatus get status => _status;
  bool get isInside => _isInside;
  DateTime? get enteredAt => _enteredAt;

  /// Check if geofence has expired
  bool get isExpired => 
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Mark geofence as entered
  void enter() {
    _isInside = true;
    _enteredAt = DateTime.now();
  }

  /// Mark geofence as exited
  void exit() {
    _isInside = false;
    _enteredAt = null;
  }

  /// Check if dwell time has been met
  bool get hasDwelt {
    if (dwellDuration == null || _enteredAt == null) return false;
    return DateTime.now().difference(_enteredAt!) >= dwellDuration!;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusInMeters': radiusInMeters,
      'triggerType': triggerType.name,
      'dwellDuration': dwellDuration?.inSeconds,
      'payload': payload,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory GeofenceRegion.fromJson(Map<String, dynamic> json) {
    return GeofenceRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusInMeters: (json['radiusInMeters'] as num?)?.toDouble() ?? 200,
      triggerType: GeofenceTriggerType.values.firstWhere(
        (t) => t.name == json['triggerType'],
        orElse: () => GeofenceTriggerType.enter,
      ),
      dwellDuration: json['dwellDuration'] != null
          ? Duration(seconds: json['dwellDuration'] as int)
          : null,
      payload: json['payload'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }
}

/// Geofence event
class GeofenceEvent {
  final GeofenceRegion region;
  final GeofenceTriggerType triggerType;
  final Position position;
  final DateTime timestamp;

  const GeofenceEvent({
    required this.region,
    required this.triggerType,
    required this.position,
    required this.timestamp,
  });
}

/// Geofence event callback
typedef GeofenceEventCallback = void Function(GeofenceEvent event);

/// Service responsible for handling geofencing operations
class GeofenceService {
  final LocationService _locationService;
  final NotificationService? _notificationService;

  final Map<String, GeofenceRegion> _regions = {};
  StreamSubscription<Position>? _positionSubscription;
  Timer? _dwellTimer;

  final StreamController<GeofenceEvent> _eventController =
      StreamController<GeofenceEvent>.broadcast();

  GeofenceEventCallback? _onEvent;
  bool _isMonitoring = false;

  GeofenceService({
    required LocationService locationService,
    NotificationService? notificationService,
  })  : _locationService = locationService,
        _notificationService = notificationService;

  /// Stream of geofence events
  Stream<GeofenceEvent> get eventStream => _eventController.stream;

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Get all registered regions
  List<GeofenceRegion> get regions => _regions.values.toList();

  /// Get a specific region by ID
  GeofenceRegion? getRegion(String id) => _regions[id];

  /// Add a geofence region
  void addRegion(GeofenceRegion region) {
    _regions[region.id] = region;
    debugPrint('Geofence region added: ${region.name} (${region.id})');
  }

  /// Add multiple geofence regions
  void addRegions(List<GeofenceRegion> regions) {
    for (final region in regions) {
      addRegion(region);
    }
  }

  /// Remove a geofence region
  void removeRegion(String id) {
    _regions.remove(id);
    debugPrint('Geofence region removed: $id');
  }

  /// Clear all geofence regions
  void clearRegions() {
    _regions.clear();
    debugPrint('All geofence regions cleared');
  }

  /// Start monitoring geofences
  Future<void> startMonitoring({
    GeofenceEventCallback? onEvent,
    int distanceFilter = 50, // meters
  }) async {
    if (_isMonitoring) {
      debugPrint('Geofence monitoring already active');
      return;
    }

    _onEvent = onEvent;

    try {
      // Check location permission
      final permission = await _locationService.checkPermission();
      if (permission != LocationPermissionStatus.granted) {
        throw GeofenceException(
          'Location permission not granted',
          'permission_denied',
        );
      }

      // Start listening to position updates
      await _locationService.startPositionUpdates(
        distanceFilter: distanceFilter,
      );

      _positionSubscription = _locationService.positionStream.listen(
        _onPositionUpdate,
        onError: (error) {
          debugPrint('Geofence position error: $error');
        },
      );

      // Start dwell timer for checking dwell triggers
      _dwellTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _checkDwellTriggers(),
      );

      _isMonitoring = true;
      debugPrint('Geofence monitoring started');
    } catch (e) {
      throw GeofenceException('Failed to start monitoring: $e');
    }
  }

  /// Stop monitoring geofences
  Future<void> stopMonitoring() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    
    _dwellTimer?.cancel();
    _dwellTimer = null;

    await _locationService.stopPositionUpdates();

    _isMonitoring = false;
    debugPrint('Geofence monitoring stopped');
  }

  /// Handle position update
  void _onPositionUpdate(Position position) {
    // Remove expired regions
    _regions.removeWhere((id, region) {
      if (region.isExpired) {
        debugPrint('Geofence expired: ${region.name}');
        return true;
      }
      return false;
    });

    // Check each region
    for (final region in _regions.values) {
      final isInside = _locationService.isWithinRadius(
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
        targetLatitude: region.latitude,
        targetLongitude: region.longitude,
        radiusInMeters: region.radiusInMeters,
      );

      // Check for enter trigger
      if (isInside && !region.isInside) {
        region.enter();
        
        if (region.triggerType == GeofenceTriggerType.enter) {
          _triggerEvent(region, GeofenceTriggerType.enter, position);
        }
      }
      // Check for exit trigger
      else if (!isInside && region.isInside) {
        region.exit();
        
        if (region.triggerType == GeofenceTriggerType.exit) {
          _triggerEvent(region, GeofenceTriggerType.exit, position);
        }
      }
    }
  }

  /// Check for dwell triggers
  void _checkDwellTriggers() async {
    for (final region in _regions.values) {
      if (region.triggerType == GeofenceTriggerType.dwell &&
          region.isInside &&
          region.hasDwelt &&
          region.status != GeofenceStatus.triggered) {
        
        // Get current position for the event
        try {
          final position = await _locationService.getCurrentPosition();
          _triggerEvent(region, GeofenceTriggerType.dwell, position);
        } catch (e) {
          debugPrint('Failed to get position for dwell trigger: $e');
        }
      }
    }
  }

  /// Trigger a geofence event
  void _triggerEvent(
    GeofenceRegion region,
    GeofenceTriggerType triggerType,
    Position position,
  ) {
    region._status = GeofenceStatus.triggered;

    final event = GeofenceEvent(
      region: region,
      triggerType: triggerType,
      position: position,
      timestamp: DateTime.now(),
    );

    _eventController.add(event);
    _onEvent?.call(event);

    // Show notification if notification service is available
    _showNotification(event);

    debugPrint(
      'Geofence triggered: ${region.name} (${triggerType.name})',
    );
  }

  /// Show notification for geofence event
  void _showNotification(GeofenceEvent event) {
    if (_notificationService == null) return;

    String title;
    String body;

    switch (event.triggerType) {
      case GeofenceTriggerType.enter:
        title = 'Location Reminder';
        body = 'You arrived at ${event.region.name}';
        break;
      case GeofenceTriggerType.exit:
        title = 'Location Reminder';
        body = 'You left ${event.region.name}';
        break;
      case GeofenceTriggerType.dwell:
        title = 'Location Reminder';
        body = 'You\'ve been at ${event.region.name} for a while';
        break;
    }

    _notificationService.showGeofenceNotification(
      id: event.region.id.hashCode,
      title: title,
      body: body,
      payload: event.region.payload,
    );
  }

  /// Check if a position is inside any registered geofence
  List<GeofenceRegion> getRegionsContaining(double latitude, double longitude) {
    return _regions.values.where((region) {
      return _locationService.isWithinRadius(
        currentLatitude: latitude,
        currentLongitude: longitude,
        targetLatitude: region.latitude,
        targetLongitude: region.longitude,
        radiusInMeters: region.radiusInMeters,
      );
    }).toList();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _eventController.close();
  }
}
