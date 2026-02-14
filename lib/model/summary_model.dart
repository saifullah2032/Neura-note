/// Enum representing the type of summary source
enum SummaryType {
  image,
  voice,
}

/// Extension to provide string conversion for SummaryType
extension SummaryTypeExtension on SummaryType {
  String get value {
    switch (this) {
      case SummaryType.image:
        return 'image';
      case SummaryType.voice:
        return 'voice';
    }
  }

  static SummaryType fromString(String value) {
    switch (value) {
      case 'image':
        return SummaryType.image;
      case 'voice':
        return SummaryType.voice;
      default:
        return SummaryType.image;
    }
  }
}

/// Model representing a summarized content item
class SummaryModel {
  final String id;
  final String userId;
  final SummaryType type;
  final String originalContentUrl; // File path or URL to original image/audio
  final String? thumbnailUrl; // For images
  final String summarizedText;
  final String? rawTranscript; // For voice - raw speech-to-text output
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Smart Reminder - Extracted Entities
  final bool hasDateTimeEntity;
  final List<DateTimeEntity> extractedDateTimes;
  final bool hasLocationEntity;
  final List<LocationEntity> extractedLocations;

  // Reminder Status
  final bool isCalendarSynced;
  final String? calendarEventId;
  final bool hasActiveLocationReminder;
  final List<String> activeGeofenceIds;

  // Metadata
  final int tokensCost;
  final double? confidenceScore;
  final Map<String, dynamic>? metadata;

  const SummaryModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.originalContentUrl,
    this.thumbnailUrl,
    required this.summarizedText,
    this.rawTranscript,
    required this.createdAt,
    this.updatedAt,
    this.hasDateTimeEntity = false,
    this.extractedDateTimes = const [],
    this.hasLocationEntity = false,
    this.extractedLocations = const [],
    this.isCalendarSynced = false,
    this.calendarEventId,
    this.hasActiveLocationReminder = false,
    this.activeGeofenceIds = const [],
    this.tokensCost = 1,
    this.confidenceScore,
    this.metadata,
  });

  /// Check if summary has any actionable entities
  bool get hasActionableEntities => hasDateTimeEntity || hasLocationEntity;

  /// Get display title (first line or truncated text)
  String get displayTitle {
    final firstLine = summarizedText.split('\n').first;
    return firstLine.length > 50 ? '${firstLine.substring(0, 47)}...' : firstLine;
  }

  /// Get preview text
  String get previewText {
    return summarizedText.length > 100
        ? '${summarizedText.substring(0, 97)}...'
        : summarizedText;
  }

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: SummaryTypeExtension.fromString(json['type'] as String),
      originalContentUrl: json['originalContentUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      summarizedText: json['summarizedText'] as String,
      rawTranscript: json['rawTranscript'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      hasDateTimeEntity: json['hasDateTimeEntity'] as bool? ?? false,
      extractedDateTimes: (json['extractedDateTimes'] as List<dynamic>?)
              ?.map((e) => DateTimeEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hasLocationEntity: json['hasLocationEntity'] as bool? ?? false,
      extractedLocations: (json['extractedLocations'] as List<dynamic>?)
              ?.map((e) => LocationEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isCalendarSynced: json['isCalendarSynced'] as bool? ?? false,
      calendarEventId: json['calendarEventId'] as String?,
      hasActiveLocationReminder: json['hasActiveLocationReminder'] as bool? ?? false,
      activeGeofenceIds: (json['activeGeofenceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tokensCost: json['tokensCost'] as int? ?? 1,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'originalContentUrl': originalContentUrl,
      'thumbnailUrl': thumbnailUrl,
      'summarizedText': summarizedText,
      'rawTranscript': rawTranscript,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'hasDateTimeEntity': hasDateTimeEntity,
      'extractedDateTimes': extractedDateTimes.map((e) => e.toJson()).toList(),
      'hasLocationEntity': hasLocationEntity,
      'extractedLocations': extractedLocations.map((e) => e.toJson()).toList(),
      'isCalendarSynced': isCalendarSynced,
      'calendarEventId': calendarEventId,
      'hasActiveLocationReminder': hasActiveLocationReminder,
      'activeGeofenceIds': activeGeofenceIds,
      'tokensCost': tokensCost,
      'confidenceScore': confidenceScore,
      'metadata': metadata,
    };
  }

  SummaryModel copyWith({
    String? id,
    String? userId,
    SummaryType? type,
    String? originalContentUrl,
    String? thumbnailUrl,
    String? summarizedText,
    String? rawTranscript,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasDateTimeEntity,
    List<DateTimeEntity>? extractedDateTimes,
    bool? hasLocationEntity,
    List<LocationEntity>? extractedLocations,
    bool? isCalendarSynced,
    String? calendarEventId,
    bool? hasActiveLocationReminder,
    List<String>? activeGeofenceIds,
    int? tokensCost,
    double? confidenceScore,
    Map<String, dynamic>? metadata,
  }) {
    return SummaryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      originalContentUrl: originalContentUrl ?? this.originalContentUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      summarizedText: summarizedText ?? this.summarizedText,
      rawTranscript: rawTranscript ?? this.rawTranscript,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasDateTimeEntity: hasDateTimeEntity ?? this.hasDateTimeEntity,
      extractedDateTimes: extractedDateTimes ?? this.extractedDateTimes,
      hasLocationEntity: hasLocationEntity ?? this.hasLocationEntity,
      extractedLocations: extractedLocations ?? this.extractedLocations,
      isCalendarSynced: isCalendarSynced ?? this.isCalendarSynced,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      hasActiveLocationReminder: hasActiveLocationReminder ?? this.hasActiveLocationReminder,
      activeGeofenceIds: activeGeofenceIds ?? this.activeGeofenceIds,
      tokensCost: tokensCost ?? this.tokensCost,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'SummaryModel(id: $id, type: ${type.value}, hasEntities: $hasActionableEntities)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SummaryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents an extracted date/time entity from text
class DateTimeEntity {
  final String originalText; // e.g., "March 15th at 3 PM"
  final DateTime parsedDateTime;
  final DateTimeType type;
  final double confidence;

  const DateTimeEntity({
    required this.originalText,
    required this.parsedDateTime,
    required this.type,
    this.confidence = 1.0,
  });

  factory DateTimeEntity.fromJson(Map<String, dynamic> json) {
    return DateTimeEntity(
      originalText: json['originalText'] as String,
      parsedDateTime: DateTime.parse(json['parsedDateTime'] as String),
      type: DateTimeTypeExtension.fromString(json['type'] as String),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'parsedDateTime': parsedDateTime.toIso8601String(),
      'type': type.value,
      'confidence': confidence,
    };
  }
}

/// Type of date/time reference
enum DateTimeType {
  specific,   // "March 15, 2026 at 3:00 PM"
  relative,   // "tomorrow", "next week"
  recurring,  // "every Monday"
  dateOnly,   // "March 15"
  timeOnly,   // "at 3 PM"
}

extension DateTimeTypeExtension on DateTimeType {
  String get value {
    switch (this) {
      case DateTimeType.specific:
        return 'specific';
      case DateTimeType.relative:
        return 'relative';
      case DateTimeType.recurring:
        return 'recurring';
      case DateTimeType.dateOnly:
        return 'dateOnly';
      case DateTimeType.timeOnly:
        return 'timeOnly';
    }
  }

  static DateTimeType fromString(String value) {
    switch (value) {
      case 'specific':
        return DateTimeType.specific;
      case 'relative':
        return DateTimeType.relative;
      case 'recurring':
        return DateTimeType.recurring;
      case 'dateOnly':
        return DateTimeType.dateOnly;
      case 'timeOnly':
        return DateTimeType.timeOnly;
      default:
        return DateTimeType.specific;
    }
  }
}

/// Represents an extracted location entity from text
class LocationEntity {
  final String originalText; // e.g., "Walmart on Main Street"
  final String? resolvedAddress; // Full resolved address
  final double? latitude;
  final double? longitude;
  final LocationType type;
  final double confidence;

  const LocationEntity({
    required this.originalText,
    this.resolvedAddress,
    this.latitude,
    this.longitude,
    required this.type,
    this.confidence = 1.0,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory LocationEntity.fromJson(Map<String, dynamic> json) {
    return LocationEntity(
      originalText: json['originalText'] as String,
      resolvedAddress: json['resolvedAddress'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      type: LocationTypeExtension.fromString(json['type'] as String),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'resolvedAddress': resolvedAddress,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.value,
      'confidence': confidence,
    };
  }
}

/// Type of location reference
enum LocationType {
  address,      // "123 Main Street"
  placeName,    // "Walmart", "Starbucks"
  landmark,     // "Eiffel Tower", "Central Park"
  city,         // "New York"
  relative,     // "near the office"
}

extension LocationTypeExtension on LocationType {
  String get value {
    switch (this) {
      case LocationType.address:
        return 'address';
      case LocationType.placeName:
        return 'placeName';
      case LocationType.landmark:
        return 'landmark';
      case LocationType.city:
        return 'city';
      case LocationType.relative:
        return 'relative';
    }
  }

  static LocationType fromString(String value) {
    switch (value) {
      case 'address':
        return LocationType.address;
      case 'placeName':
        return LocationType.placeName;
      case 'landmark':
        return LocationType.landmark;
      case 'city':
        return LocationType.city;
      case 'relative':
        return LocationType.relative;
      default:
        return LocationType.placeName;
    }
  }
}
