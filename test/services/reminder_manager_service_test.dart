import 'package:flutter_test/flutter_test.dart';
import 'package:neuranotteai/services/reminder_manager_service.dart';
import 'package:neuranotteai/model/reminder_model.dart' as model;

void main() {
  group('ReminderManagerException', () {
    test('creates exception with message only', () {
      const exception = ReminderManagerException('Test error');

      expect(exception.message, 'Test error');
      expect(exception.code, isNull);
      expect(exception.toString(), 'ReminderManagerException: Test error');
    });

    test('creates exception with message and code', () {
      const exception = ReminderManagerException(
        'Failed to create reminder',
        code: 'create_failed',
      );

      expect(exception.message, 'Failed to create reminder');
      expect(exception.code, 'create_failed');
      expect(
        exception.toString(),
        'ReminderManagerException: Failed to create reminder',
      );
    });
  });

  group('CreateReminderResult', () {
    late ReminderModel calendarReminder;
    late ReminderModel locationReminder;

    setUp(() {
      calendarReminder = ReminderModel(
        id: 'calendar-reminder-1',
        summaryId: 'summary-1',
        userId: 'user-1',
        title: 'Meeting Tomorrow',
        description: 'Team standup',
        type: ReminderType.calendar,
        status: ReminderStatus.pending,
        scheduledDateTime: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      locationReminder = ReminderModel(
        id: 'location-reminder-1',
        summaryId: 'summary-2',
        userId: 'user-1',
        title: 'Pick up groceries',
        description: 'Grocery store reminder',
        type: ReminderType.location,
        status: ReminderStatus.pending,
        targetLocation: const model.GeoLocation(
          latitude: 37.7749,
          longitude: -122.4194,
          address: '123 Market St',
          placeName: 'Grocery Store',
        ),
        radiusInMeters: 200,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('creates result for calendar reminder with defaults', () {
      final result = CreateReminderResult(
        reminder: calendarReminder,
      );

      expect(result.reminder, calendarReminder);
      expect(result.calendarEventCreated, false);
      expect(result.calendarEventId, isNull);
      expect(result.geofenceRegistered, false);
      expect(result.geofenceId, isNull);
      expect(result.error, isNull);
    });

    test('creates result for successfully synced calendar reminder', () {
      final result = CreateReminderResult(
        reminder: calendarReminder,
        calendarEventCreated: true,
        calendarEventId: 'cal-event-123',
      );

      expect(result.calendarEventCreated, true);
      expect(result.calendarEventId, 'cal-event-123');
      expect(result.isFullyConfigured, true);
    });

    test('creates result for failed calendar sync', () {
      final result = CreateReminderResult(
        reminder: calendarReminder,
        calendarEventCreated: false,
        error: 'Failed to sync to Google Calendar',
      );

      expect(result.calendarEventCreated, false);
      expect(result.error, 'Failed to sync to Google Calendar');
      expect(result.isFullyConfigured, false);
    });

    test('creates result for location reminder with geofence', () {
      final result = CreateReminderResult(
        reminder: locationReminder,
        geofenceRegistered: true,
        geofenceId: 'geofence-123',
      );

      expect(result.reminder, locationReminder);
      expect(result.geofenceRegistered, true);
      expect(result.geofenceId, 'geofence-123');
      expect(result.isFullyConfigured, true);
    });

    test('creates result for failed geofence registration', () {
      final result = CreateReminderResult(
        reminder: locationReminder,
        geofenceRegistered: false,
        error: 'Failed to register geofence',
      );

      expect(result.geofenceRegistered, false);
      expect(result.error, 'Failed to register geofence');
      expect(result.isFullyConfigured, false);
    });

    group('isFullyConfigured', () {
      test('returns true for calendar reminder with calendar event', () {
        final result = CreateReminderResult(
          reminder: calendarReminder,
          calendarEventCreated: true,
          calendarEventId: 'cal-123',
        );

        expect(result.isFullyConfigured, true);
      });

      test('returns false for calendar reminder without calendar event', () {
        final result = CreateReminderResult(
          reminder: calendarReminder,
          calendarEventCreated: false,
        );

        expect(result.isFullyConfigured, false);
      });

      test('returns true for location reminder with geofence', () {
        final result = CreateReminderResult(
          reminder: locationReminder,
          geofenceRegistered: true,
          geofenceId: 'geo-123',
        );

        expect(result.isFullyConfigured, true);
      });

      test('returns false for location reminder without geofence', () {
        final result = CreateReminderResult(
          reminder: locationReminder,
          geofenceRegistered: false,
        );

        expect(result.isFullyConfigured, false);
      });

      // Note: Only calendar and location types exist
      // Calendar requires calendarEventCreated = true
      // Location requires geofenceRegistered = true
    });
  });

  group('Type aliases', () {
    test('ReminderModel typedef works', () {
      final reminder = ReminderModel(
        id: 'test-1',
        summaryId: 'summary-1',
        userId: 'user-1',
        title: 'Test Reminder',
        description: 'Test description',
        type: ReminderType.calendar,
        status: ReminderStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(reminder.id, 'test-1');
      expect(reminder.type, ReminderType.calendar);
    });

    test('ReminderStatus typedef works', () {
      expect(ReminderStatus.pending, model.ReminderStatus.pending);
      expect(ReminderStatus.triggered, model.ReminderStatus.triggered);
      expect(ReminderStatus.completed, model.ReminderStatus.completed);
      expect(ReminderStatus.dismissed, model.ReminderStatus.dismissed);
      expect(ReminderStatus.expired, model.ReminderStatus.expired);
    });

    test('ReminderType typedef works', () {
      expect(ReminderType.calendar, model.ReminderType.calendar);
      expect(ReminderType.location, model.ReminderType.location);
    });

    test('GeoLocation typedef works', () {
      const location = GeoLocation(
        latitude: 40.7128,
        longitude: -74.0060,
        address: 'New York, NY',
        placeName: 'NYC',
      );

      expect(location.latitude, 40.7128);
      expect(location.longitude, -74.0060);
      expect(location.address, 'New York, NY');
      expect(location.placeName, 'NYC');
    });
  });
}
