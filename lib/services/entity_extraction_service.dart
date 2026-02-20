import 'dart:convert';

import 'package:neuranotteai/model/summary_model.dart';

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

/// Service for extracting entities from text using basic pattern matching
/// 
/// Note: This is a simplified implementation without AI. For production use,
/// consider integrating with Hugging Face NER models or another NLP service.
class EntityExtractionService {
  const EntityExtractionService();

  /// Extract all entities from text
  /// 
  /// Currently returns empty results. In a production implementation,
  /// this would use Hugging Face NER models or regex pattern matching.
  Future<EntityExtractionResult> extractEntities(String text) async {
    if (text.trim().isEmpty) {
      return const EntityExtractionResult();
    }

    // Return empty entities - entity extraction is complex and requires
    // either AI models or sophisticated NLP libraries
    // For now, users can manually add reminders based on the summary
    return const EntityExtractionResult();
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
  /// 
  /// Basic implementation that attempts to parse ISO 8601 format
  Future<DateTime?> parseDateTime(String text) async {
    if (text.trim().isEmpty) return null;

    try {
      return DateTime.parse(text.trim());
    } catch (_) {
      return null;
    }
  }

  /// Validate and normalize a location string
  /// 
  /// Returns a basic LocationEntity with the original text
  Future<LocationEntity?> normalizeLocation(String text) async {
    if (text.trim().isEmpty) return null;

    return LocationEntity(
      originalText: text.trim(),
      type: LocationType.placeName,
      confidence: 0.5,
    );
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
