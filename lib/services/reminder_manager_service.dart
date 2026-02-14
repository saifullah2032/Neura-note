import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:neuranotteai/model/reminder_model.dart' as model;
import 'package:neuranotteai/model/summary_model.dart';
import 'package:neuranotteai/repo/reminder_repo.dart';
import 'package:neuranotteai/repo/summary_repo.dart';
import 'package:neuranotteai/services/calendar_service.dart';
import 'package:neuranotteai/services/geofence_service.dart';
import 'package:neuranotteai/services/geocoding_service.dart';
import 'package:neuranotteai/services/notification_service.dart';

// Re-export commonly used types from reminder_model
typedef ReminderModel = model.ReminderModel;
typedef ReminderStatus = model.ReminderStatus;
typedef ReminderType = model.ReminderType;
typedef GeoLocation = model.GeoLocation;

/// Exception for reminder manager errors
class ReminderManagerException implements Exception {
  final String message;
  final String? code;

  const ReminderManagerException(this.message, {this.code});

  @override
  String toString() => 'ReminderManagerException: $message';
}

/// Result of creating a reminder
class CreateReminderResult {
  final ReminderModel reminder;
  final bool calendarEventCreated;
  final String? calendarEventId;
  final bool geofenceRegistered;
  final String? geofenceId;
  final String? error;

  const CreateReminderResult({
    required this.reminder,
    this.calendarEventCreated = false,
    this.calendarEventId,
    this.geofenceRegistered = false,
    this.geofenceId,
    this.error,
  });

  bool get isFullyConfigured {
    if (reminder.isCalendarReminder) {
      return calendarEventCreated;
    } else if (reminder.isLocationReminder) {
      return geofenceRegistered;
    }
    return true;
  }
}

/// Service that manages the lifecycle of reminders
/// Connects summaries to calendar events and geofences
class ReminderManagerService {
  final ReminderRepository _reminderRepo;
  final SummaryRepository _summaryRepo;
  final CalendarService _calendarService;
  final GeofenceService _geofenceService;
  final GeocodingService _geocodingService;
  final NotificationService _notificationService;

  // Stream controllers for events
  final StreamController<ReminderModel> _reminderCreatedController =
      StreamController<ReminderModel>.broadcast();
  final StreamController<ReminderModel> _reminderTriggeredController =
      StreamController<ReminderModel>.broadcast();
  final StreamController<String> _reminderDeletedController =
      StreamController<String>.broadcast();

  // Geofence event subscription
  StreamSubscription<GeofenceEvent>? _geofenceSubscription;

  ReminderManagerService({
    required ReminderRepository reminderRepository,
    required SummaryRepository summaryRepository,
    required CalendarService calendarService,
    required GeofenceService geofenceService,
    required GeocodingService geocodingService,
    required NotificationService notificationService,
  })  : _reminderRepo = reminderRepository,
        _summaryRepo = summaryRepository,
        _calendarService = calendarService,
        _geofenceService = geofenceService,
        _geocodingService = geocodingService,
        _notificationService = notificationService;

  /// Stream of created reminders
  Stream<ReminderModel> get onReminderCreated =>
      _reminderCreatedController.stream;

  /// Stream of triggered reminders
  Stream<ReminderModel> get onReminderTriggered =>
      _reminderTriggeredController.stream;

  /// Stream of deleted reminder IDs
  Stream<String> get onReminderDeleted => _reminderDeletedController.stream;

  /// Initialize the reminder manager
  Future<void> initialize(String userId) async {
    // Listen to geofence events
    _geofenceSubscription = _geofenceService.eventStream.listen(
      (event) => _handleGeofenceEvent(event, userId),
    );

    // Load and register existing location reminders
    await _loadActiveLocationReminders(userId);

    debugPrint('ReminderManagerService initialized for user: $userId');
  }

  /// Load and register active location reminders for geofencing
  Future<void> _loadActiveLocationReminders(String userId) async {
    try {
      final reminders = await _reminderRepo.getActiveLocationReminders(userId);

      for (final reminder in reminders) {
        if (reminder.targetLocation != null) {
          _registerGeofence(reminder);
        }
      }

      debugPrint('Loaded ${reminders.length} active location reminders');
    } catch (e) {
      debugPrint('Error loading active location reminders: $e');
    }
  }

  /// Create a calendar reminder from a date/time entity
  Future<CreateReminderResult> createCalendarReminder({
    required String summaryId,
    required String userId,
    required DateTimeEntity dateTimeEntity,
    required String title,
    String? description,
    Duration duration = const Duration(hours: 1),
    int notificationMinutesBefore = 30,
    bool syncToGoogleCalendar = true,
  }) async {
    try {
      // Create reminder in database
      final reminder = await _reminderRepo.createCalendarReminder(
        summaryId: summaryId,
        userId: userId,
        title: title,
        description: description ?? 'Reminder from NeuraNote',
        scheduledDateTime: dateTimeEntity.parsedDateTime,
        endDateTime: dateTimeEntity.parsedDateTime.add(duration),
        notificationMinutesBefore: notificationMinutesBefore,
      );

      String? calendarEventId;
      bool calendarEventCreated = false;
      String? error;

      // Sync to Google Calendar if requested
      if (syncToGoogleCalendar) {
        try {
          final calendarEvent = await _calendarService.createEventFromEntity(
            title: title,
            dateTime: dateTimeEntity.parsedDateTime,
            description: description,
            duration: duration,
            reminderMinutes: notificationMinutesBefore,
          );

          calendarEventId = calendarEvent.id;
          calendarEventCreated = true;

          // Update reminder with calendar event ID
          await _reminderRepo.updateCalendarEventId(
            reminder.id,
            calendarEventId!,
          );
        } on CalendarException catch (e) {
          error = 'Failed to sync to Google Calendar: ${e.message}';
          debugPrint(error);
        }
      }

      // Schedule local notification
      await _scheduleCalendarNotification(reminder);

      // Update summary with calendar sync status
      await _updateSummaryCalendarStatus(
        summaryId,
        isCalendarSynced: calendarEventCreated,
        calendarEventId: calendarEventId,
      );

      _reminderCreatedController.add(reminder);

      return CreateReminderResult(
        reminder: reminder,
        calendarEventCreated: calendarEventCreated,
        calendarEventId: calendarEventId,
        error: error,
      );
    } catch (e) {
      throw ReminderManagerException(
        'Failed to create calendar reminder: $e',
        code: 'create_calendar_reminder_failed',
      );
    }
  }

  /// Create a location reminder from a location entity
  Future<CreateReminderResult> createLocationReminder({
    required String summaryId,
    required String userId,
    required LocationEntity locationEntity,
    required String title,
    String? description,
    double radiusInMeters = 200,
    model.GeofenceTriggerType triggerType = model.GeofenceTriggerType.enter,
  }) async {
    try {
      // Resolve location coordinates if needed
      double? latitude = locationEntity.latitude;
      double? longitude = locationEntity.longitude;
      String? resolvedAddress = locationEntity.resolvedAddress;

      if (latitude == null || longitude == null) {
        // Try to geocode the location
        final geocodeResult = await _geocodingService.geocodeAddress(
          locationEntity.originalText,
        );

        if (geocodeResult != null) {
          latitude = geocodeResult.latitude;
          longitude = geocodeResult.longitude;
          resolvedAddress = geocodeResult.formattedAddress;
        } else {
          throw ReminderManagerException(
            'Could not resolve location: ${locationEntity.originalText}',
            code: 'geocode_failed',
          );
        }
      }

      // Create GeoLocation
      final geoLocation = GeoLocation(
        latitude: latitude,
        longitude: longitude,
        address: resolvedAddress,
        placeName: locationEntity.originalText,
      );

      // Create reminder in database
      final reminder = await _reminderRepo.createLocationReminder(
        summaryId: summaryId,
        userId: userId,
        title: title,
        description: description ?? 'Location reminder from NeuraNote',
        targetLocation: geoLocation,
        radiusInMeters: radiusInMeters,
        triggerType: triggerType,
      );

      // Register geofence
      final geofenceId = _registerGeofence(reminder);
      bool geofenceRegistered = geofenceId != null;

      // Update reminder with geofence ID
      if (geofenceRegistered) {
        await _reminderRepo.updateGeofenceId(reminder.id, geofenceId);
      }

      // Update summary with location reminder status
      await _updateSummaryLocationStatus(
        summaryId,
        hasActiveReminder: true,
        geofenceId: geofenceId,
      );

      _reminderCreatedController.add(reminder);

      return CreateReminderResult(
        reminder: reminder,
        geofenceRegistered: geofenceRegistered,
        geofenceId: geofenceId,
      );
    } catch (e) {
      if (e is ReminderManagerException) rethrow;
      throw ReminderManagerException(
        'Failed to create location reminder: $e',
        code: 'create_location_reminder_failed',
      );
    }
  }

  /// Register a geofence for a location reminder
  String? _registerGeofence(ReminderModel reminder) {
    if (reminder.targetLocation == null) return null;

    try {
      final geofenceId = 'reminder_${reminder.id}';

      final region = GeofenceRegion(
        id: geofenceId,
        name: reminder.title,
        latitude: reminder.targetLocation!.latitude,
        longitude: reminder.targetLocation!.longitude,
        radiusInMeters: reminder.radiusInMeters,
        triggerType: _mapTriggerType(reminder.triggerType),
        payload: reminder.id, // Store reminder ID in payload
      );

      _geofenceService.addRegion(region);
      debugPrint('Registered geofence: $geofenceId for reminder: ${reminder.id}');

      return geofenceId;
    } catch (e) {
      debugPrint('Failed to register geofence: $e');
      return null;
    }
  }

  /// Map reminder trigger type to geofence trigger type
  GeofenceTriggerType _mapTriggerType(
      model.GeofenceTriggerType triggerType) {
    switch (triggerType) {
      case model.GeofenceTriggerType.enter:
        return GeofenceTriggerType.enter;
      case model.GeofenceTriggerType.exit:
        return GeofenceTriggerType.exit;
      case model.GeofenceTriggerType.dwell:
        return GeofenceTriggerType.dwell;
    }
  }

  /// Handle geofence trigger event
  Future<void> _handleGeofenceEvent(
      GeofenceEvent event, String userId) async {
    final reminderId = event.region.payload;
    if (reminderId == null) return;

    try {
      final reminder = await _reminderRepo.getReminderById(reminderId);
      if (reminder == null || reminder.userId != userId) return;

      // Check if reminder is still pending
      if (reminder.status != ReminderStatus.pending) return;

      // Mark reminder as triggered
      await _reminderRepo.markAsTriggered(reminderId);

      // Show notification
      await _notificationService.showGeofenceNotification(
        id: reminderId.hashCode,
        title: 'Location Reminder',
        body: reminder.title,
        payload: reminderId,
      );

      // Update summary status
      await _updateSummaryLocationStatus(
        reminder.summaryId,
        hasActiveReminder: false,
        geofenceId: null,
      );

      // Emit event
      final updatedReminder = reminder.copyWith(
        status: ReminderStatus.triggered,
        triggeredAt: DateTime.now(),
      );
      _reminderTriggeredController.add(updatedReminder);

      debugPrint('Location reminder triggered: $reminderId');
    } catch (e) {
      debugPrint('Error handling geofence event: $e');
    }
  }

  /// Schedule a local notification for a calendar reminder
  Future<void> _scheduleCalendarNotification(ReminderModel reminder) async {
    if (reminder.scheduledDateTime == null) return;
    if (!reminder.notificationEnabled) return;

    final notifyAt = reminder.scheduledDateTime!.subtract(
      Duration(minutes: reminder.notificationMinutesBefore ?? 15),
    );

    // Only schedule if notification time is in the future
    if (notifyAt.isAfter(DateTime.now())) {
      await _notificationService.scheduleNotification(
        id: reminder.id.hashCode,
        title: 'Upcoming Reminder',
        body: reminder.title,
        scheduledDate: notifyAt,
        payload: reminder.id,
      );
    }
  }

  /// Update summary calendar sync status
  Future<void> _updateSummaryCalendarStatus(
    String summaryId, {
    required bool isCalendarSynced,
    String? calendarEventId,
  }) async {
    try {
      final summary = await _summaryRepo.getSummaryById(summaryId);
      if (summary != null) {
        final updated = summary.copyWith(
          isCalendarSynced: isCalendarSynced,
          calendarEventId: calendarEventId,
          updatedAt: DateTime.now(),
        );
        await _summaryRepo.updateSummary(updated);
      }
    } catch (e) {
      debugPrint('Error updating summary calendar status: $e');
    }
  }

  /// Update summary location reminder status
  Future<void> _updateSummaryLocationStatus(
    String summaryId, {
    required bool hasActiveReminder,
    String? geofenceId,
  }) async {
    try {
      final summary = await _summaryRepo.getSummaryById(summaryId);
      if (summary != null) {
        List<String> geofenceIds = List.from(summary.activeGeofenceIds);

        if (hasActiveReminder && geofenceId != null) {
          if (!geofenceIds.contains(geofenceId)) {
            geofenceIds.add(geofenceId);
          }
        } else if (!hasActiveReminder && geofenceId != null) {
          geofenceIds.remove(geofenceId);
        }

        final updated = summary.copyWith(
          hasActiveLocationReminder: geofenceIds.isNotEmpty,
          activeGeofenceIds: geofenceIds,
          updatedAt: DateTime.now(),
        );
        await _summaryRepo.updateSummary(updated);
      }
    } catch (e) {
      debugPrint('Error updating summary location status: $e');
    }
  }

  /// Get all reminders for a summary
  Future<List<ReminderModel>> getRemindersForSummary(String summaryId) async {
    return _reminderRepo.getRemindersBySummaryId(summaryId);
  }

  /// Get all reminders for a user
  Future<List<ReminderModel>> getRemindersForUser(String userId) async {
    return _reminderRepo.getRemindersByUserId(userId);
  }

  /// Get active reminders for a user
  Future<List<ReminderModel>> getActiveReminders(String userId) async {
    return _reminderRepo.getActiveReminders(userId);
  }

  /// Get upcoming calendar reminders
  Future<List<ReminderModel>> getUpcomingCalendarReminders(
    String userId, {
    Duration? within,
  }) async {
    return _reminderRepo.getUpcomingCalendarReminders(userId, within: within);
  }

  /// Mark reminder as completed
  Future<void> completeReminder(String reminderId) async {
    final reminder = await _reminderRepo.getReminderById(reminderId);
    if (reminder == null) return;

    await _reminderRepo.markAsCompleted(reminderId);

    // Unregister geofence if location reminder
    if (reminder.isLocationReminder && reminder.geofenceId != null) {
      _geofenceService.removeRegion(reminder.geofenceId!);
    }

    // Cancel scheduled notification
    await _notificationService.cancelNotification(reminderId.hashCode);
  }

  /// Dismiss reminder
  Future<void> dismissReminder(String reminderId) async {
    final reminder = await _reminderRepo.getReminderById(reminderId);
    if (reminder == null) return;

    await _reminderRepo.markAsDismissed(reminderId);

    // Unregister geofence if location reminder
    if (reminder.isLocationReminder && reminder.geofenceId != null) {
      _geofenceService.removeRegion(reminder.geofenceId!);
    }

    // Cancel scheduled notification
    await _notificationService.cancelNotification(reminderId.hashCode);
  }

  /// Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    final reminder = await _reminderRepo.getReminderById(reminderId);
    if (reminder == null) return;

    // Delete from Google Calendar if synced
    if (reminder.calendarEventId != null) {
      try {
        await _calendarService.deleteEvent(reminder.calendarEventId!);
      } catch (e) {
        debugPrint('Error deleting calendar event: $e');
      }
    }

    // Unregister geofence if location reminder
    if (reminder.geofenceId != null) {
      _geofenceService.removeRegion(reminder.geofenceId!);
    }

    // Cancel scheduled notification
    await _notificationService.cancelNotification(reminderId.hashCode);

    // Delete from database
    await _reminderRepo.deleteReminder(reminderId);

    // Update summary status
    if (reminder.isCalendarReminder) {
      await _updateSummaryCalendarStatus(
        reminder.summaryId,
        isCalendarSynced: false,
        calendarEventId: null,
      );
    } else if (reminder.isLocationReminder) {
      await _updateSummaryLocationStatus(
        reminder.summaryId,
        hasActiveReminder: false,
        geofenceId: reminder.geofenceId,
      );
    }

    _reminderDeletedController.add(reminderId);
  }

  /// Delete all reminders for a summary
  Future<void> deleteRemindersForSummary(String summaryId) async {
    final reminders = await _reminderRepo.getRemindersBySummaryId(summaryId);

    for (final reminder in reminders) {
      await deleteReminder(reminder.id);
    }
  }

  /// Start geofence monitoring
  Future<void> startLocationMonitoring() async {
    if (!_geofenceService.isMonitoring) {
      await _geofenceService.startMonitoring();
    }
  }

  /// Stop geofence monitoring
  Future<void> stopLocationMonitoring() async {
    if (_geofenceService.isMonitoring) {
      await _geofenceService.stopMonitoring();
    }
  }

  /// Expire old calendar reminders
  Future<void> expireOldReminders(String userId) async {
    await _reminderRepo.expireOldReminders(userId);
  }

  /// Dispose resources
  void dispose() {
    _geofenceSubscription?.cancel();
    _reminderCreatedController.close();
    _reminderTriggeredController.close();
    _reminderDeletedController.close();
  }
}
