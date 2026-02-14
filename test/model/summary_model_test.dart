import 'package:flutter_test/flutter_test.dart';
import 'package:neuranotteai/model/summary_model.dart';

void main() {
  group('SummaryType', () {
    test('value returns correct string', () {
      expect(SummaryType.image.value, 'image');
      expect(SummaryType.voice.value, 'voice');
    });

    test('fromString parses correctly', () {
      expect(SummaryTypeExtension.fromString('image'), SummaryType.image);
      expect(SummaryTypeExtension.fromString('voice'), SummaryType.voice);
      expect(SummaryTypeExtension.fromString('invalid'), SummaryType.image);
    });
  });

  group('DateTimeType', () {
    test('value returns correct string', () {
      expect(DateTimeType.specific.value, 'specific');
      expect(DateTimeType.relative.value, 'relative');
      expect(DateTimeType.recurring.value, 'recurring');
      expect(DateTimeType.dateOnly.value, 'dateOnly');
      expect(DateTimeType.timeOnly.value, 'timeOnly');
    });

    test('fromString parses correctly', () {
      expect(DateTimeTypeExtension.fromString('specific'), DateTimeType.specific);
      expect(DateTimeTypeExtension.fromString('relative'), DateTimeType.relative);
      expect(DateTimeTypeExtension.fromString('recurring'), DateTimeType.recurring);
      expect(DateTimeTypeExtension.fromString('invalid'), DateTimeType.specific);
    });
  });

  group('LocationType', () {
    test('value returns correct string', () {
      expect(LocationType.address.value, 'address');
      expect(LocationType.placeName.value, 'placeName');
      expect(LocationType.landmark.value, 'landmark');
      expect(LocationType.city.value, 'city');
      expect(LocationType.relative.value, 'relative');
    });

    test('fromString parses correctly', () {
      expect(LocationTypeExtension.fromString('address'), LocationType.address);
      expect(LocationTypeExtension.fromString('placeName'), LocationType.placeName);
      expect(LocationTypeExtension.fromString('landmark'), LocationType.landmark);
      expect(LocationTypeExtension.fromString('invalid'), LocationType.placeName);
    });
  });

  group('DateTimeEntity', () {
    test('creates instance with required parameters', () {
      final entity = DateTimeEntity(
        originalText: 'tomorrow at 3 PM',
        parsedDateTime: DateTime(2026, 2, 15, 15, 0),
        type: DateTimeType.relative,
      );

      expect(entity.originalText, 'tomorrow at 3 PM');
      expect(entity.parsedDateTime, DateTime(2026, 2, 15, 15, 0));
      expect(entity.type, DateTimeType.relative);
      expect(entity.confidence, 1.0);
    });

    test('creates instance with custom confidence', () {
      final entity = DateTimeEntity(
        originalText: 'next week',
        parsedDateTime: DateTime(2026, 2, 21),
        type: DateTimeType.relative,
        confidence: 0.8,
      );

      expect(entity.confidence, 0.8);
    });

    test('toJson and fromJson round trip', () {
      final original = DateTimeEntity(
        originalText: 'March 15, 2026 at 3:00 PM',
        parsedDateTime: DateTime(2026, 3, 15, 15, 0),
        type: DateTimeType.specific,
        confidence: 0.95,
      );

      final json = original.toJson();
      final restored = DateTimeEntity.fromJson(json);

      expect(restored.originalText, original.originalText);
      expect(restored.parsedDateTime, original.parsedDateTime);
      expect(restored.type, original.type);
      expect(restored.confidence, original.confidence);
    });
  });

  group('LocationEntity', () {
    test('creates instance with required parameters', () {
      final entity = LocationEntity(
        originalText: 'Walmart',
        type: LocationType.placeName,
      );

      expect(entity.originalText, 'Walmart');
      expect(entity.type, LocationType.placeName);
      expect(entity.hasCoordinates, isFalse);
      expect(entity.confidence, 1.0);
    });

    test('creates instance with coordinates', () {
      final entity = LocationEntity(
        originalText: 'Walmart on Main Street',
        resolvedAddress: '123 Main Street, New York, NY',
        latitude: 40.7128,
        longitude: -74.0060,
        type: LocationType.placeName,
        confidence: 0.9,
      );

      expect(entity.hasCoordinates, isTrue);
      expect(entity.latitude, 40.7128);
      expect(entity.longitude, -74.0060);
      expect(entity.resolvedAddress, '123 Main Street, New York, NY');
    });

    test('toJson and fromJson round trip', () {
      final original = LocationEntity(
        originalText: 'Central Park',
        resolvedAddress: 'Central Park, New York, NY',
        latitude: 40.7829,
        longitude: -73.9654,
        type: LocationType.landmark,
        confidence: 0.99,
      );

      final json = original.toJson();
      final restored = LocationEntity.fromJson(json);

      expect(restored.originalText, original.originalText);
      expect(restored.resolvedAddress, original.resolvedAddress);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.type, original.type);
      expect(restored.confidence, original.confidence);
    });
  });

  group('SummaryModel', () {
    final now = DateTime.now();

    SummaryModel createImageSummary() {
      return SummaryModel(
        id: 'summary-1',
        userId: 'user-1',
        type: SummaryType.image,
        originalContentUrl: 'https://storage.example.com/image.jpg',
        thumbnailUrl: 'https://storage.example.com/thumb.jpg',
        summarizedText: 'Meeting notes from project kickoff.\nDiscussed timeline and deliverables.',
        createdAt: now,
      );
    }

    SummaryModel createVoiceSummary() {
      return SummaryModel(
        id: 'summary-2',
        userId: 'user-1',
        type: SummaryType.voice,
        originalContentUrl: 'https://storage.example.com/audio.m4a',
        summarizedText: 'Reminder to buy groceries at Walmart tomorrow at 3 PM.',
        rawTranscript: 'Hey, remind me to buy groceries at Walmart tomorrow at 3 PM.',
        createdAt: now,
        hasDateTimeEntity: true,
        extractedDateTimes: [
          DateTimeEntity(
            originalText: 'tomorrow at 3 PM',
            parsedDateTime: now.add(const Duration(days: 1)),
            type: DateTimeType.relative,
          ),
        ],
        hasLocationEntity: true,
        extractedLocations: [
          const LocationEntity(
            originalText: 'Walmart',
            type: LocationType.placeName,
          ),
        ],
      );
    }

    test('creates image summary with correct defaults', () {
      final summary = createImageSummary();

      expect(summary.type, SummaryType.image);
      expect(summary.hasDateTimeEntity, isFalse);
      expect(summary.hasLocationEntity, isFalse);
      expect(summary.hasActionableEntities, isFalse);
      expect(summary.isCalendarSynced, isFalse);
      expect(summary.hasActiveLocationReminder, isFalse);
      expect(summary.tokensCost, 1);
    });

    test('creates voice summary with entities', () {
      final summary = createVoiceSummary();

      expect(summary.type, SummaryType.voice);
      expect(summary.hasDateTimeEntity, isTrue);
      expect(summary.hasLocationEntity, isTrue);
      expect(summary.hasActionableEntities, isTrue);
      expect(summary.extractedDateTimes.length, 1);
      expect(summary.extractedLocations.length, 1);
      expect(summary.rawTranscript, isNotNull);
    });

    test('displayTitle returns first line truncated', () {
      final summary = createImageSummary();
      expect(summary.displayTitle, 'Meeting notes from project kickoff.');
    });

    test('displayTitle truncates long lines', () {
      final summary = SummaryModel(
        id: 'summary-long',
        userId: 'user-1',
        type: SummaryType.image,
        originalContentUrl: 'url',
        summarizedText: 'This is a very long first line that exceeds fifty characters and should be truncated accordingly.',
        createdAt: now,
      );

      expect(summary.displayTitle.length, 50);
      expect(summary.displayTitle.endsWith('...'), isTrue);
    });

    test('previewText returns truncated summary', () {
      final summary = SummaryModel(
        id: 'summary-long',
        userId: 'user-1',
        type: SummaryType.voice,
        originalContentUrl: 'url',
        summarizedText: 'A' * 200, // 200 character string
        createdAt: now,
      );

      expect(summary.previewText.length, 100);
      expect(summary.previewText.endsWith('...'), isTrue);
    });

    test('previewText returns full text if short', () {
      final summary = createImageSummary();
      expect(summary.previewText, summary.summarizedText);
    });

    test('toJson and fromJson round trip for image summary', () {
      final original = createImageSummary();

      final json = original.toJson();
      final restored = SummaryModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.type, original.type);
      expect(restored.originalContentUrl, original.originalContentUrl);
      expect(restored.thumbnailUrl, original.thumbnailUrl);
      expect(restored.summarizedText, original.summarizedText);
    });

    test('toJson and fromJson round trip for voice summary with entities', () {
      final original = createVoiceSummary();

      final json = original.toJson();
      final restored = SummaryModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.rawTranscript, original.rawTranscript);
      expect(restored.hasDateTimeEntity, original.hasDateTimeEntity);
      expect(restored.extractedDateTimes.length, original.extractedDateTimes.length);
      expect(restored.hasLocationEntity, original.hasLocationEntity);
      expect(restored.extractedLocations.length, original.extractedLocations.length);
      expect(
        restored.extractedLocations.first.originalText,
        original.extractedLocations.first.originalText,
      );
    });

    test('copyWith creates new instance with updated values', () {
      final original = createImageSummary();

      final updated = original.copyWith(
        isCalendarSynced: true,
        calendarEventId: 'cal-123',
      );

      expect(updated.id, original.id);
      expect(updated.isCalendarSynced, isTrue);
      expect(updated.calendarEventId, 'cal-123');
      expect(original.isCalendarSynced, isFalse);
      expect(original.calendarEventId, isNull);
    });

    test('copyWith updates entity lists', () {
      final original = createImageSummary();

      final newEntity = DateTimeEntity(
        originalText: 'next Monday',
        parsedDateTime: now.add(const Duration(days: 7)),
        type: DateTimeType.relative,
      );

      final updated = original.copyWith(
        hasDateTimeEntity: true,
        extractedDateTimes: [newEntity],
      );

      expect(updated.hasDateTimeEntity, isTrue);
      expect(updated.extractedDateTimes.length, 1);
      expect(updated.extractedDateTimes.first.originalText, 'next Monday');
    });

    test('equality based on id', () {
      final summary1 = createImageSummary();
      final summary2 = SummaryModel(
        id: 'summary-1', // Same ID
        userId: 'different-user',
        type: SummaryType.voice, // Different type
        originalContentUrl: 'different-url',
        summarizedText: 'Different text',
        createdAt: now.add(const Duration(days: 1)),
      );

      expect(summary1 == summary2, isTrue);
      expect(summary1.hashCode, summary2.hashCode);
    });

    test('inequality for different ids', () {
      final summary1 = createImageSummary();
      final summary2 = SummaryModel(
        id: 'summary-different',
        userId: 'user-1',
        type: SummaryType.image,
        originalContentUrl: 'url',
        summarizedText: 'text',
        createdAt: now,
      );

      expect(summary1 == summary2, isFalse);
    });

    test('toString returns formatted string', () {
      final summary = createVoiceSummary();

      final str = summary.toString();

      expect(str, contains('summary-2'));
      expect(str, contains('voice'));
      expect(str, contains('hasEntities: true'));
    });

    test('hasActionableEntities returns true when has datetime entities', () {
      final summary = SummaryModel(
        id: 'test',
        userId: 'user',
        type: SummaryType.image,
        originalContentUrl: 'url',
        summarizedText: 'text',
        createdAt: now,
        hasDateTimeEntity: true,
        hasLocationEntity: false,
      );

      expect(summary.hasActionableEntities, isTrue);
    });

    test('hasActionableEntities returns true when has location entities', () {
      final summary = SummaryModel(
        id: 'test',
        userId: 'user',
        type: SummaryType.image,
        originalContentUrl: 'url',
        summarizedText: 'text',
        createdAt: now,
        hasDateTimeEntity: false,
        hasLocationEntity: true,
      );

      expect(summary.hasActionableEntities, isTrue);
    });

    test('hasActionableEntities returns false when no entities', () {
      final summary = createImageSummary();
      expect(summary.hasActionableEntities, isFalse);
    });
  });
}
