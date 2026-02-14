import 'dart:convert';

import 'package:neuranotteai/model/summary_model.dart';
import 'package:neuranotteai/services/ai_service.dart';

/// Exception for entity extraction errors
class EntityExtractionException implements Exception {
  final String message;
  final String? code;

  const EntityExtractionException(this.message, {this.code});

  @override
  String toString() => 'EntityExtractionException: $message';
}

/// Result of entity extraction
class EntityExtractionResult {
  final List<DateTimeEntity> dateTimes;
  final List<LocationEntity> locations;
  final List<PersonEntity> people;
  final List<OrganizationEntity> organizations;
  final List<String> actionItems;
  final int tokensUsed;
  final Map<String, dynamic>? rawResponse;

  const EntityExtractionResult({
    this.dateTimes = const [],
    this.locations = const [],
    this.people = const [],
    this.organizations = const [],
    this.actionItems = const [],
    this.tokensUsed = 0,
    this.rawResponse,
  });

  bool get hasDateTimes => dateTimes.isNotEmpty;
  bool get hasLocations => locations.isNotEmpty;
  bool get hasPeople => people.isNotEmpty;
  bool get hasOrganizations => organizations.isNotEmpty;
  bool get hasActionItems => actionItems.isNotEmpty;
  bool get hasAnyEntities =>
      hasDateTimes || hasLocations || hasPeople || hasOrganizations;
}

/// Represents a person entity
class PersonEntity {
  final String name;
  final String? role;
  final double confidence;

  const PersonEntity({
    required this.name,
    this.role,
    this.confidence = 1.0,
  });

  factory PersonEntity.fromJson(Map<String, dynamic> json) {
    return PersonEntity(
      name: json['name'] as String? ?? '',
      role: json['role'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'confidence': confidence,
    };
  }
}

/// Represents an organization entity
class OrganizationEntity {
  final String name;
  final OrganizationType type;
  final double confidence;

  const OrganizationEntity({
    required this.name,
    this.type = OrganizationType.other,
    this.confidence = 1.0,
  });

  factory OrganizationEntity.fromJson(Map<String, dynamic> json) {
    return OrganizationEntity(
      name: json['name'] as String? ?? '',
      type: OrganizationTypeExtension.fromString(json['type'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.value,
      'confidence': confidence,
    };
  }
}

/// Types of organizations
enum OrganizationType {
  company,
  institution,
  government,
  nonprofit,
  other,
}

extension OrganizationTypeExtension on OrganizationType {
  String get value {
    switch (this) {
      case OrganizationType.company:
        return 'company';
      case OrganizationType.institution:
        return 'institution';
      case OrganizationType.government:
        return 'government';
      case OrganizationType.nonprofit:
        return 'nonprofit';
      case OrganizationType.other:
        return 'other';
    }
  }

  static OrganizationType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'company':
        return OrganizationType.company;
      case 'institution':
        return OrganizationType.institution;
      case 'government':
        return OrganizationType.government;
      case 'nonprofit':
        return OrganizationType.nonprofit;
      default:
        return OrganizationType.other;
    }
  }
}

/// Service for extracting entities from text using NLP
class EntityExtractionService {
  final AIService _aiService;

  EntityExtractionService({required AIService aiService})
      : _aiService = aiService;

  /// Extract all entities from text
  Future<EntityExtractionResult> extractEntities(String text) async {
    if (text.trim().isEmpty) {
      return const EntityExtractionResult();
    }

    try {
      final response = await _aiService.extractEntities(text);
      return _parseResponse(response.text, response.totalTokens);
    } on AIException catch (e) {
      throw EntityExtractionException(
        'Entity extraction failed: ${e.message}',
        code: e.errorCode,
      );
    }
  }

  /// Extract only date/time entities
  Future<List<DateTimeEntity>> extractDateTimes(String text) async {
    final result = await extractEntities(text);
    return result.dateTimes;
  }

  /// Extract only location entities
  Future<List<LocationEntity>> extractLocations(String text) async {
    final result = await extractEntities(text);
    return result.locations;
  }

  /// Parse date/time from natural language
  Future<DateTime?> parseDateTime(String text) async {
    if (text.trim().isEmpty) return null;

    try {
      final prompt = '''
Parse the following natural language date/time expression and return the result as ISO 8601 format.
Consider the current date as reference for relative expressions.
Current date: ${DateTime.now().toIso8601String()}

Text: "$text"

Return ONLY the ISO 8601 datetime string, nothing else. If parsing fails, return "null".
''';

      final response = await _aiService.generateText(prompt);
      final result = response.text.trim();

      if (result == 'null' || result.isEmpty) return null;

      try {
        return DateTime.parse(result);
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Validate and normalize a location string
  Future<LocationEntity?> normalizeLocation(String text) async {
    if (text.trim().isEmpty) return null;

    try {
      final prompt = '''
Analyze the following location text and return information about it as JSON:
{
  "originalText": "the input text",
  "type": "address|placeName|landmark|city|relative",
  "confidence": 0.0-1.0,
  "normalizedName": "standardized name if applicable"
}

Text: "$text"

Return ONLY the JSON object, nothing else.
''';

      final response = await _aiService.generateText(prompt);
      final parsed = _parseJsonResponse(response.text);

      if (parsed == null) return null;

      return LocationEntity(
        originalText: parsed['originalText'] as String? ?? text,
        type: _parseLocationType(parsed['type'] as String?),
        confidence: (parsed['confidence'] as num?)?.toDouble() ?? 0.8,
      );
    } catch (_) {
      return null;
    }
  }

  /// Parse the JSON response from AI
  EntityExtractionResult _parseResponse(String text, int tokensUsed) {
    final parsed = _parseJsonResponse(text);
    if (parsed == null) {
      return EntityExtractionResult(tokensUsed: tokensUsed);
    }

    return EntityExtractionResult(
      dateTimes: _parseDateTimes(parsed['dateTimes']),
      locations: _parseLocations(parsed['locations']),
      people: _parsePeople(parsed['people']),
      organizations: _parseOrganizations(parsed['organizations']),
      actionItems: _parseActionItems(parsed['actionItems']),
      tokensUsed: tokensUsed,
      rawResponse: parsed,
    );
  }

  /// Parse JSON from text (handles markdown code blocks)
  Map<String, dynamic>? _parseJsonResponse(String text) {
    var cleanText = text.trim();

    // Remove markdown code blocks if present
    if (cleanText.startsWith('```json')) {
      cleanText = cleanText.substring(7);
    } else if (cleanText.startsWith('```')) {
      cleanText = cleanText.substring(3);
    }
    if (cleanText.endsWith('```')) {
      cleanText = cleanText.substring(0, cleanText.length - 3);
    }
    cleanText = cleanText.trim();

    try {
      return json.decode(cleanText) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Parse date/time entities from response
  List<DateTimeEntity> _parseDateTimes(dynamic data) {
    if (data == null) return [];

    final list = data as List<dynamic>;
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return DateTimeEntity(
        originalText: map['originalText'] as String? ?? '',
        parsedDateTime: _parseDateTime(map['parsedDateTime']),
        type: _parseDateTimeType(map['type'] as String?),
        confidence: (map['confidence'] as num?)?.toDouble() ?? 0.8,
      );
    }).where((e) => e.originalText.isNotEmpty).toList();
  }

  /// Parse a date/time string
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      return DateTime.parse(value as String);
    } catch (_) {
      // Try to parse relative dates
      return _parseRelativeDateTime(value as String?) ?? DateTime.now();
    }
  }

  /// Parse relative date/time expressions
  DateTime? _parseRelativeDateTime(String? text) {
    if (text == null) return null;

    final now = DateTime.now();
    final lower = text.toLowerCase().trim();

    // Common relative expressions
    if (lower == 'today') return DateTime(now.year, now.month, now.day);
    if (lower == 'tomorrow') {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    }
    if (lower == 'yesterday') {
      return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    }

    // "next X" patterns
    if (lower.startsWith('next ')) {
      final dayOfWeek = _parseDayOfWeek(lower.substring(5));
      if (dayOfWeek != null) {
        return _getNextDayOfWeek(now, dayOfWeek);
      }
    }

    // "in X days/weeks/months"
    final inDaysMatch = RegExp(r'in (\d+) days?').firstMatch(lower);
    if (inDaysMatch != null) {
      final days = int.parse(inDaysMatch.group(1)!);
      return now.add(Duration(days: days));
    }

    final inWeeksMatch = RegExp(r'in (\d+) weeks?').firstMatch(lower);
    if (inWeeksMatch != null) {
      final weeks = int.parse(inWeeksMatch.group(1)!);
      return now.add(Duration(days: weeks * 7));
    }

    return null;
  }

  /// Parse day of week name to integer (1=Monday, 7=Sunday)
  int? _parseDayOfWeek(String text) {
    switch (text.toLowerCase().trim()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  /// Get the next occurrence of a day of week
  DateTime _getNextDayOfWeek(DateTime from, int targetDay) {
    var daysUntil = targetDay - from.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    return DateTime(from.year, from.month, from.day).add(Duration(days: daysUntil));
  }

  /// Parse date/time type
  DateTimeType _parseDateTimeType(String? type) {
    switch (type?.toLowerCase()) {
      case 'specific':
        return DateTimeType.specific;
      case 'relative':
        return DateTimeType.relative;
      case 'recurring':
        return DateTimeType.recurring;
      case 'dateonly':
        return DateTimeType.dateOnly;
      case 'timeonly':
        return DateTimeType.timeOnly;
      default:
        return DateTimeType.specific;
    }
  }

  /// Parse location entities from response
  List<LocationEntity> _parseLocations(dynamic data) {
    if (data == null) return [];

    final list = data as List<dynamic>;
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return LocationEntity(
        originalText: map['originalText'] as String? ?? '',
        resolvedAddress: map['resolvedAddress'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        type: _parseLocationType(map['type'] as String?),
        confidence: (map['confidence'] as num?)?.toDouble() ?? 0.8,
      );
    }).where((e) => e.originalText.isNotEmpty).toList();
  }

  /// Parse location type
  LocationType _parseLocationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'address':
        return LocationType.address;
      case 'placename':
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

  /// Parse people entities from response
  List<PersonEntity> _parsePeople(dynamic data) {
    if (data == null) return [];

    final list = data as List<dynamic>;
    return list.map((item) {
      if (item is String) {
        return PersonEntity(name: item);
      }
      return PersonEntity.fromJson(item as Map<String, dynamic>);
    }).where((e) => e.name.isNotEmpty).toList();
  }

  /// Parse organization entities from response
  List<OrganizationEntity> _parseOrganizations(dynamic data) {
    if (data == null) return [];

    final list = data as List<dynamic>;
    return list.map((item) {
      if (item is String) {
        return OrganizationEntity(name: item);
      }
      return OrganizationEntity.fromJson(item as Map<String, dynamic>);
    }).where((e) => e.name.isNotEmpty).toList();
  }

  /// Parse action items from response
  List<String> _parseActionItems(dynamic data) {
    if (data == null) return [];

    final list = data as List<dynamic>;
    return list.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
  }
}

/// Helper class for date/time parsing patterns
class DateTimePatterns {
  /// Common date patterns
  static final List<RegExp> datePatterns = [
    // ISO format: 2024-03-15
    RegExp(r'\d{4}-\d{2}-\d{2}'),
    // US format: 03/15/2024
    RegExp(r'\d{1,2}/\d{1,2}/\d{4}'),
    // Written format: March 15, 2024
    RegExp(
      r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2}(st|nd|rd|th)?,?\s*\d{4}',
      caseSensitive: false,
    ),
    // Written format: 15 March 2024
    RegExp(
      r'\d{1,2}(st|nd|rd|th)?\s+(January|February|March|April|May|June|July|August|September|October|November|December),?\s*\d{4}',
      caseSensitive: false,
    ),
  ];

  /// Common time patterns
  static final List<RegExp> timePatterns = [
    // 24-hour format: 14:30
    RegExp(r'\d{1,2}:\d{2}(:\d{2})?'),
    // 12-hour format: 2:30 PM
    RegExp(r'\d{1,2}:\d{2}\s*(AM|PM|am|pm)'),
    // Written format: 2 PM
    RegExp(r'\d{1,2}\s*(AM|PM|am|pm)'),
  ];

  /// Common relative date patterns
  static final List<RegExp> relativePatterns = [
    RegExp(r'today', caseSensitive: false),
    RegExp(r'tomorrow', caseSensitive: false),
    RegExp(r'yesterday', caseSensitive: false),
    RegExp(r'next\s+(week|month|year)', caseSensitive: false),
    RegExp(r'next\s+(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)',
        caseSensitive: false),
    RegExp(r'in\s+\d+\s+(days?|weeks?|months?)', caseSensitive: false),
  ];

  /// Check if text contains any date pattern
  static bool containsDate(String text) {
    return datePatterns.any((p) => p.hasMatch(text)) ||
        relativePatterns.any((p) => p.hasMatch(text));
  }

  /// Check if text contains any time pattern
  static bool containsTime(String text) {
    return timePatterns.any((p) => p.hasMatch(text));
  }
}

/// Helper class for location parsing patterns
class LocationPatterns {
  /// Common address patterns
  static final List<RegExp> addressPatterns = [
    // Street address: 123 Main Street
    RegExp(r'\d+\s+\w+\s+(Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Drive|Dr|Lane|Ln)',
        caseSensitive: false),
    // ZIP code
    RegExp(r'\d{5}(-\d{4})?'),
  ];

  /// Common place patterns
  static final List<RegExp> placePatterns = [
    // Common place prefixes
    RegExp(r'at\s+the\s+\w+', caseSensitive: false),
    RegExp(r'near\s+\w+', caseSensitive: false),
  ];

  /// Check if text contains an address pattern
  static bool containsAddress(String text) {
    return addressPatterns.any((p) => p.hasMatch(text));
  }
}
