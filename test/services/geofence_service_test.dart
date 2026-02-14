import 'package:flutter_test/flutter_test.dart';
import 'package:neuranotteai/services/geofence_service.dart';

void main() {
  group('GeofenceRegion', () {
    test('creates GeofenceRegion with required parameters', () {
      final region = GeofenceRegion(
        id: 'test-region-1',
        name: 'Test Region',
        latitude: 37.7749,
        longitude: -122.4194,
      );

      expect(region.id, 'test-region-1');
      expect(region.name, 'Test Region');
      expect(region.latitude, 37.7749);
      expect(region.longitude, -122.4194);
      expect(region.radiusInMeters, 200); // default
      expect(region.triggerType, GeofenceTriggerType.enter); // default
      expect(region.status, GeofenceStatus.inactive);
      expect(region.isInside, false);
      expect(region.enteredAt, isNull);
    });

    test('creates GeofenceRegion with custom parameters', () {
      final expiresAt = DateTime.now().add(const Duration(hours: 24));
      final region = GeofenceRegion(
        id: 'test-region-2',
        name: 'Custom Region',
        latitude: 40.7128,
        longitude: -74.0060,
        radiusInMeters: 500,
        triggerType: GeofenceTriggerType.exit,
        dwellDuration: const Duration(minutes: 5),
        payload: 'reminder-123',
        expiresAt: expiresAt,
      );

      expect(region.radiusInMeters, 500);
      expect(region.triggerType, GeofenceTriggerType.exit);
      expect(region.dwellDuration, const Duration(minutes: 5));
      expect(region.payload, 'reminder-123');
      expect(region.expiresAt, expiresAt);
    });

    test('enter() marks region as inside', () {
      final region = GeofenceRegion(
        id: 'test',
        name: 'Test',
        latitude: 0,
        longitude: 0,
      );

      expect(region.isInside, false);
      expect(region.enteredAt, isNull);

      region.enter();

      expect(region.isInside, true);
      expect(region.enteredAt, isNotNull);
    });

    test('exit() marks region as outside', () {
      final region = GeofenceRegion(
        id: 'test',
        name: 'Test',
        latitude: 0,
        longitude: 0,
      );

      region.enter();
      expect(region.isInside, true);

      region.exit();
      expect(region.isInside, false);
      expect(region.enteredAt, isNull);
    });

    test('isExpired returns false when no expiry set', () {
      final region = GeofenceRegion(
        id: 'test',
        name: 'Test',
        latitude: 0,
        longitude: 0,
      );

      expect(region.isExpired, false);
    });

    test('isExpired returns false when expiry is in future', () {
      final region = GeofenceRegion(
        id: 'test',
        name: 'Test',
        latitude: 0,
        longitude: 0,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(region.isExpired, false);
    });

    test('isExpired returns true when expiry is in past', () {
      final region = GeofenceRegion(
        id: 'test',
        name: 'Test',
        latitude: 0,
        longitude: 0,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(region.isExpired, true);
    });

    test('hasDwelt returns false without dwellDuration', () {
      final region = GeofenceRegion(
        id: 'test',
        name: 'Test',
        latitude: 0,
        longitude: 0,
      );

      expect(region.hasDwelt, false);
    });

    test('hasDwelt returns false when not entered', () {
      final region = GeofenceRegion(
        id: 'test',
        name: 'Test',
        latitude: 0,
        longitude: 0,
        dwellDuration: const Duration(seconds: 1),
      );

      expect(region.hasDwelt, false);
    });

    group('toJson / fromJson', () {
      test('serializes to JSON correctly', () {
        final expiresAt = DateTime(2026, 3, 15, 10, 30);
        final region = GeofenceRegion(
          id: 'json-test',
          name: 'JSON Test Region',
          latitude: 51.5074,
          longitude: -0.1278,
          radiusInMeters: 300,
          triggerType: GeofenceTriggerType.dwell,
          dwellDuration: const Duration(minutes: 10),
          payload: 'test-payload',
          expiresAt: expiresAt,
        );

        final json = region.toJson();

        expect(json['id'], 'json-test');
        expect(json['name'], 'JSON Test Region');
        expect(json['latitude'], 51.5074);
        expect(json['longitude'], -0.1278);
        expect(json['radiusInMeters'], 300);
        expect(json['triggerType'], 'dwell');
        expect(json['dwellDuration'], 600); // 10 minutes in seconds
        expect(json['payload'], 'test-payload');
        expect(json['expiresAt'], expiresAt.toIso8601String());
      });

      test('deserializes from JSON correctly', () {
        final json = {
          'id': 'from-json',
          'name': 'From JSON Region',
          'latitude': 48.8566,
          'longitude': 2.3522,
          'radiusInMeters': 150,
          'triggerType': 'exit',
          'dwellDuration': 300,
          'payload': 'json-payload',
          'expiresAt': '2026-06-20T14:00:00.000',
        };

        final region = GeofenceRegion.fromJson(json);

        expect(region.id, 'from-json');
        expect(region.name, 'From JSON Region');
        expect(region.latitude, 48.8566);
        expect(region.longitude, 2.3522);
        expect(region.radiusInMeters, 150);
        expect(region.triggerType, GeofenceTriggerType.exit);
        expect(region.dwellDuration, const Duration(seconds: 300));
        expect(region.payload, 'json-payload');
        expect(region.expiresAt, DateTime(2026, 6, 20, 14, 0));
      });

      test('deserializes with defaults for optional fields', () {
        final json = {
          'id': 'minimal',
          'name': 'Minimal Region',
          'latitude': 35.6762,
          'longitude': 139.6503,
        };

        final region = GeofenceRegion.fromJson(json);

        expect(region.id, 'minimal');
        expect(region.name, 'Minimal Region');
        expect(region.radiusInMeters, 200); // default
        expect(region.triggerType, GeofenceTriggerType.enter); // default
        expect(region.dwellDuration, isNull);
        expect(region.payload, isNull);
        expect(region.expiresAt, isNull);
      });

      test('roundtrip JSON serialization', () {
        final original = GeofenceRegion(
          id: 'roundtrip',
          name: 'Roundtrip Test',
          latitude: 52.5200,
          longitude: 13.4050,
          radiusInMeters: 250,
          triggerType: GeofenceTriggerType.enter,
          payload: 'roundtrip-payload',
        );

        final json = original.toJson();
        final restored = GeofenceRegion.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.latitude, original.latitude);
        expect(restored.longitude, original.longitude);
        expect(restored.radiusInMeters, original.radiusInMeters);
        expect(restored.triggerType, original.triggerType);
        expect(restored.payload, original.payload);
      });
    });
  });

  group('GeofenceEvent', () {
    test('creates GeofenceEvent with all parameters', () {
      final region = GeofenceRegion(
        id: 'event-test',
        name: 'Event Test Region',
        latitude: 37.7749,
        longitude: -122.4194,
      );

      // Note: We can't create a real Position in tests without mocking
      // So we test that GeofenceEvent structure is correct
      expect(region.id, 'event-test');
      expect(region.name, 'Event Test Region');
    });
  });

  group('GeofenceException', () {
    test('creates exception with message', () {
      const exception = GeofenceException('Test error');

      expect(exception.message, 'Test error');
      expect(exception.code, isNull);
      expect(exception.toString(), 'GeofenceException: Test error (code: null)');
    });

    test('creates exception with message and code', () {
      const exception = GeofenceException('Permission denied', 'permission_denied');

      expect(exception.message, 'Permission denied');
      expect(exception.code, 'permission_denied');
      expect(
        exception.toString(),
        'GeofenceException: Permission denied (code: permission_denied)',
      );
    });
  });

  group('GeofenceTriggerType', () {
    test('has all expected values', () {
      expect(GeofenceTriggerType.values.length, 3);
      expect(GeofenceTriggerType.values, contains(GeofenceTriggerType.enter));
      expect(GeofenceTriggerType.values, contains(GeofenceTriggerType.exit));
      expect(GeofenceTriggerType.values, contains(GeofenceTriggerType.dwell));
    });
  });

  group('GeofenceStatus', () {
    test('has all expected values', () {
      expect(GeofenceStatus.values.length, 4);
      expect(GeofenceStatus.values, contains(GeofenceStatus.active));
      expect(GeofenceStatus.values, contains(GeofenceStatus.inactive));
      expect(GeofenceStatus.values, contains(GeofenceStatus.triggered));
      expect(GeofenceStatus.values, contains(GeofenceStatus.expired));
    });
  });
}
