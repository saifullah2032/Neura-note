/// Type of reminder
enum ReminderType {
  calendar,   // Time-based, synced to Google Calendar
  location,   // Location-based, uses geofencing
}

extension ReminderTypeExtension on ReminderType {
  String get value {
    switch (this) {
      case ReminderType.calendar:
        return 'calendar';
      case ReminderType.location:
        return 'location';
    }
  }

  static ReminderType fromString(String value) {
    switch (value) {
      case 'calendar':
        return ReminderType.calendar;
      case 'location':
        return ReminderType.location;
      default:
        return ReminderType.calendar;
    }
  }
}

/// Status of a reminder
enum ReminderStatus {
  pending,    // Active and waiting to trigger
  triggered,  // Has been triggered (notification shown)
  dismissed,  // User dismissed the reminder
  completed,  // User marked as complete
  expired,    // Time-based reminder that passed without action
  cancelled,  // User cancelled the reminder
}

extension ReminderStatusExtension on ReminderStatus {
  String get value {
    switch (this) {
      case ReminderStatus.pending:
        return 'pending';
      case ReminderStatus.triggered:
        return 'triggered';
      case ReminderStatus.dismissed:
        return 'dismissed';
      case ReminderStatus.completed:
        return 'completed';
      case ReminderStatus.expired:
        return 'expired';
      case ReminderStatus.cancelled:
        return 'cancelled';
    }
  }

  static ReminderStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ReminderStatus.pending;
      case 'triggered':
        return ReminderStatus.triggered;
      case 'dismissed':
        return ReminderStatus.dismissed;
      case 'completed':
        return ReminderStatus.completed;
      case 'expired':
        return ReminderStatus.expired;
      case 'cancelled':
        return ReminderStatus.cancelled;
      default:
        return ReminderStatus.pending;
    }
  }
}

/// Model representing a reminder (calendar or location-based)
class ReminderModel {
  final String id;
  final String summaryId;
  final String userId;
  final ReminderType type;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Calendar Reminder Fields
  final DateTime? scheduledDateTime;
  final DateTime? endDateTime; // For calendar events with duration
  final String? calendarEventId;
  final bool allDayEvent;

  // Location Reminder Fields
  final GeoLocation? targetLocation;
  final double radiusInMeters;
  final String? geofenceId;
  final GeofenceTriggerType triggerType;

  // Status
  final ReminderStatus status;
  final DateTime? triggeredAt;
  final DateTime? completedAt;

  // Notification settings
  final bool notificationEnabled;
  final int? notificationMinutesBefore; // For calendar reminders

  const ReminderModel({
    required this.id,
    required this.summaryId,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    this.updatedAt,
    this.scheduledDateTime,
    this.endDateTime,
    this.calendarEventId,
    this.allDayEvent = false,
    this.targetLocation,
    this.radiusInMeters = 200,
    this.geofenceId,
    this.triggerType = GeofenceTriggerType.enter,
    this.status = ReminderStatus.pending,
    this.triggeredAt,
    this.completedAt,
    this.notificationEnabled = true,
    this.notificationMinutesBefore,
  });

  /// Check if this is a calendar reminder
  bool get isCalendarReminder => type == ReminderType.calendar;

  /// Check if this is a location reminder
  bool get isLocationReminder => type == ReminderType.location;

  /// Check if reminder is active
  bool get isActive => status == ReminderStatus.pending;

  /// Check if reminder has been triggered
  bool get hasTriggered => status == ReminderStatus.triggered;

  /// Check if calendar event is synced
  bool get isSyncedToCalendar => calendarEventId != null;

  /// Check if geofence is registered
  bool get hasGeofenceRegistered => geofenceId != null;

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      summaryId: json['summaryId'] as String,
      userId: json['userId'] as String,
      type: ReminderTypeExtension.fromString(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      scheduledDateTime: json['scheduledDateTime'] != null
          ? DateTime.parse(json['scheduledDateTime'] as String)
          : null,
      endDateTime: json['endDateTime'] != null
          ? DateTime.parse(json['endDateTime'] as String)
          : null,
      calendarEventId: json['calendarEventId'] as String?,
      allDayEvent: json['allDayEvent'] as bool? ?? false,
      targetLocation: json['targetLocation'] != null
          ? GeoLocation.fromJson(json['targetLocation'] as Map<String, dynamic>)
          : null,
      radiusInMeters: (json['radiusInMeters'] as num?)?.toDouble() ?? 200,
      geofenceId: json['geofenceId'] as String?,
      triggerType: GeofenceTriggerTypeExtension.fromString(
        json['triggerType'] as String? ?? 'enter',
      ),
      status: ReminderStatusExtension.fromString(json['status'] as String),
      triggeredAt: json['triggeredAt'] != null
          ? DateTime.parse(json['triggeredAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      notificationMinutesBefore: json['notificationMinutesBefore'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'summaryId': summaryId,
      'userId': userId,
      'type': type.value,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'scheduledDateTime': scheduledDateTime?.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'calendarEventId': calendarEventId,
      'allDayEvent': allDayEvent,
      'targetLocation': targetLocation?.toJson(),
      'radiusInMeters': radiusInMeters,
      'geofenceId': geofenceId,
      'triggerType': triggerType.value,
      'status': status.value,
      'triggeredAt': triggeredAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notificationEnabled': notificationEnabled,
      'notificationMinutesBefore': notificationMinutesBefore,
    };
  }

  ReminderModel copyWith({
    String? id,
    String? summaryId,
    String? userId,
    ReminderType? type,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledDateTime,
    DateTime? endDateTime,
    String? calendarEventId,
    bool? allDayEvent,
    GeoLocation? targetLocation,
    double? radiusInMeters,
    String? geofenceId,
    GeofenceTriggerType? triggerType,
    ReminderStatus? status,
    DateTime? triggeredAt,
    DateTime? completedAt,
    bool? notificationEnabled,
    int? notificationMinutesBefore,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      summaryId: summaryId ?? this.summaryId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      allDayEvent: allDayEvent ?? this.allDayEvent,
      targetLocation: targetLocation ?? this.targetLocation,
      radiusInMeters: radiusInMeters ?? this.radiusInMeters,
      geofenceId: geofenceId ?? this.geofenceId,
      triggerType: triggerType ?? this.triggerType,
      status: status ?? this.status,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      completedAt: completedAt ?? this.completedAt,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationMinutesBefore: notificationMinutesBefore ?? this.notificationMinutesBefore,
    );
  }

  @override
  String toString() {
    return 'ReminderModel(id: $id, type: ${type.value}, status: ${status.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Geographic location model
class GeoLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeName;
  final String? city;
  final String? country;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeName,
    this.city,
    this.country,
  });

  /// Get display name for the location
  String get displayName {
    if (placeName != null) return placeName!;
    if (address != null) return address!;
    return '$latitude, $longitude';
  }

  /// Calculate distance to another location (in meters)
  /// Uses Haversine formula
  double distanceTo(GeoLocation other) {
    const double earthRadius = 6371000; // meters
    final double lat1Rad = latitude * (3.14159265359 / 180);
    final double lat2Rad = other.latitude * (3.14159265359 / 180);
    final double deltaLatRad = (other.latitude - latitude) * (3.14159265359 / 180);
    final double deltaLngRad = (other.longitude - longitude) * (3.14159265359 / 180);

    final double a = _sin(deltaLatRad / 2) * _sin(deltaLatRad / 2) +
        _cos(lat1Rad) * _cos(lat2Rad) * _sin(deltaLngRad / 2) * _sin(deltaLngRad / 2);
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadius * c;
  }

  // Helper math functions (simplified implementations)
  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  double _sqrt(double x) {
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }
  double _atan(double x) => x - (x * x * x) / 3 + (x * x * x * x * x) / 5;

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      placeName: json['placeName'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'placeName': placeName,
      'city': city,
      'country': country,
    };
  }

  GeoLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? placeName,
    String? city,
    String? country,
  }) {
    return GeoLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      placeName: placeName ?? this.placeName,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }

  @override
  String toString() {
    return 'GeoLocation(lat: $latitude, lng: $longitude, place: $placeName)';
  }
}

/// Geofence trigger type
enum GeofenceTriggerType {
  enter,  // Trigger when entering the geofence
  exit,   // Trigger when exiting the geofence
  dwell,  // Trigger when staying in the geofence for a period
}

extension GeofenceTriggerTypeExtension on GeofenceTriggerType {
  String get value {
    switch (this) {
      case GeofenceTriggerType.enter:
        return 'enter';
      case GeofenceTriggerType.exit:
        return 'exit';
      case GeofenceTriggerType.dwell:
        return 'dwell';
    }
  }

  static GeofenceTriggerType fromString(String value) {
    switch (value) {
      case 'enter':
        return GeofenceTriggerType.enter;
      case 'exit':
        return GeofenceTriggerType.exit;
      case 'dwell':
        return GeofenceTriggerType.dwell;
      default:
        return GeofenceTriggerType.enter;
    }
  }
}
