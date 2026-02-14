import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/reminder_model.dart';
import '../model/summary_model.dart';
import '../repo/reminder_repo.dart';
import '../services/reminder_manager_service.dart' hide ReminderModel, ReminderStatus, ReminderType, GeoLocation;
import '../services/background_service.dart';

/// State for reminder operations
enum ReminderState {
  initial,
  loading,
  loaded,
  error,
  creating,
  syncing,
}

/// Provider for reminder state management
class ReminderProvider extends ChangeNotifier {
  final ReminderRepository _reminderRepository;
  ReminderManagerService? _reminderManager;
  final BackgroundService _backgroundService = BackgroundService();

  ReminderState _state = ReminderState.initial;
  List<ReminderModel> _reminders = [];
  List<ReminderModel> _activeReminders = [];
  String? _errorMessage;
  String? _userId;
  bool _isBackgroundServiceRunning = false;
  StreamSubscription<List<ReminderModel>>? _remindersSubscription;
  StreamSubscription<ReminderModel>? _reminderCreatedSubscription;
  StreamSubscription<ReminderModel>? _reminderTriggeredSubscription;
  StreamSubscription<String>? _reminderDeletedSubscription;

  ReminderProvider({
    ReminderRepository? reminderRepository,
    ReminderManagerService? reminderManager,
  })  : _reminderRepository = reminderRepository ?? ReminderRepository(),
        _reminderManager = reminderManager;

  // Getters
  ReminderState get state => _state;
  List<ReminderModel> get reminders => _reminders;
  List<ReminderModel> get activeReminders => _activeReminders;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ReminderState.loading;
  bool get isCreating => _state == ReminderState.creating;
  bool get isSyncing => _state == ReminderState.syncing;
  bool get isBackgroundServiceRunning => _isBackgroundServiceRunning;
  bool get hasReminderManager => _reminderManager != null;

  /// Set the reminder manager service
  void setReminderManager(ReminderManagerService manager) {
    _reminderManager = manager;
    _setupManagerListeners();
  }

  /// Setup listeners for reminder manager events
  void _setupManagerListeners() {
    if (_reminderManager == null) return;

    _reminderCreatedSubscription?.cancel();
    _reminderTriggeredSubscription?.cancel();
    _reminderDeletedSubscription?.cancel();

    _reminderCreatedSubscription = _reminderManager!.onReminderCreated.listen(
      (reminder) {
        _addToLocalCache(reminder);
        notifyListeners();
      },
    );

    _reminderTriggeredSubscription = _reminderManager!.onReminderTriggered.listen(
      (reminder) {
        _updateLocalReminder(reminder.id, (r) => reminder);
        notifyListeners();
      },
    );

    _reminderDeletedSubscription = _reminderManager!.onReminderDeleted.listen(
      (reminderId) {
        _reminders.removeWhere((r) => r.id == reminderId);
        _activeReminders.removeWhere((r) => r.id == reminderId);
        notifyListeners();
      },
    );
  }

  /// Add reminder to local cache
  void _addToLocalCache(ReminderModel reminder) {
    if (!_reminders.any((r) => r.id == reminder.id)) {
      _reminders = [reminder, ..._reminders];
    }
    if (reminder.isActive && !_activeReminders.any((r) => r.id == reminder.id)) {
      _activeReminders = [reminder, ..._activeReminders];
    }
  }

  // Filtered getters
  List<ReminderModel> get calendarReminders =>
      _reminders.where((r) => r.isCalendarReminder).toList();

  List<ReminderModel> get locationReminders =>
      _reminders.where((r) => r.isLocationReminder).toList();

  List<ReminderModel> get pendingReminders =>
      _reminders.where((r) => r.status == ReminderStatus.pending).toList();

  List<ReminderModel> get completedReminders =>
      _reminders.where((r) => r.status == ReminderStatus.completed).toList();

  List<ReminderModel> get upcomingCalendarReminders {
    final now = DateTime.now();
    return calendarReminders
        .where((r) =>
            r.isActive &&
            r.scheduledDateTime != null &&
            r.scheduledDateTime!.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledDateTime!.compareTo(b.scheduledDateTime!));
  }

  /// Subscribe to reminders for a user
  void subscribeTo(String userId) {
    _remindersSubscription?.cancel();
    _setState(ReminderState.loading);

    _remindersSubscription = _reminderRepository.remindersStream(userId).listen(
      (reminders) {
        _reminders = reminders;
        _activeReminders = reminders.where((r) => r.isActive).toList();
        _setState(ReminderState.loaded);
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  /// Load reminders for a user
  Future<void> loadReminders(String userId) async {
    try {
      _setState(ReminderState.loading);
      _clearError();

      _reminders = await _reminderRepository.getRemindersByUserId(userId);
      _activeReminders = await _reminderRepository.getActiveReminders(userId);
      
      _setState(ReminderState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Load reminders for a specific summary
  Future<List<ReminderModel>> loadRemindersForSummary(String summaryId) async {
    try {
      return await _reminderRepository.getRemindersBySummaryId(summaryId);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Create calendar reminder
  Future<ReminderModel?> createCalendarReminder({
    required String summaryId,
    required String userId,
    required String title,
    required String description,
    required DateTime scheduledDateTime,
    DateTime? endDateTime,
    bool allDayEvent = false,
    int notificationMinutesBefore = 15,
  }) async {
    try {
      _setState(ReminderState.creating);
      _clearError();

      final reminder = await _reminderRepository.createCalendarReminder(
        summaryId: summaryId,
        userId: userId,
        title: title,
        description: description,
        scheduledDateTime: scheduledDateTime,
        endDateTime: endDateTime,
        allDayEvent: allDayEvent,
        notificationMinutesBefore: notificationMinutesBefore,
      );

      _reminders = [reminder, ..._reminders];
      _activeReminders = [reminder, ..._activeReminders];
      _setState(ReminderState.loaded);

      return reminder;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Create location reminder
  Future<ReminderModel?> createLocationReminder({
    required String summaryId,
    required String userId,
    required String title,
    required String description,
    required GeoLocation targetLocation,
    double radiusInMeters = 200,
    GeofenceTriggerType triggerType = GeofenceTriggerType.enter,
  }) async {
    try {
      _setState(ReminderState.creating);
      _clearError();

      final reminder = await _reminderRepository.createLocationReminder(
        summaryId: summaryId,
        userId: userId,
        title: title,
        description: description,
        targetLocation: targetLocation,
        radiusInMeters: radiusInMeters,
        triggerType: triggerType,
      );

      _reminders = [reminder, ..._reminders];
      _activeReminders = [reminder, ..._activeReminders];
      _setState(ReminderState.loaded);

      return reminder;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // ============================================================
  // ENTITY-BASED REMINDER CREATION (via ReminderManagerService)
  // ============================================================

  /// Create calendar reminder from a DateTimeEntity (with Google Calendar sync)
  Future<CreateReminderResult?> createCalendarReminderFromEntity({
    required String summaryId,
    required String userId,
    required DateTimeEntity dateTimeEntity,
    required String title,
    String? description,
    Duration duration = const Duration(hours: 1),
    int notificationMinutesBefore = 30,
    bool syncToGoogleCalendar = true,
  }) async {
    if (_reminderManager == null) {
      _setError('Reminder manager not initialized');
      return null;
    }

    try {
      _setState(ReminderState.syncing);
      _clearError();

      final result = await _reminderManager!.createCalendarReminder(
        summaryId: summaryId,
        userId: userId,
        dateTimeEntity: dateTimeEntity,
        title: title,
        description: description,
        duration: duration,
        notificationMinutesBefore: notificationMinutesBefore,
        syncToGoogleCalendar: syncToGoogleCalendar,
      );

      _addToLocalCache(result.reminder);
      _setState(ReminderState.loaded);

      if (result.error != null) {
        debugPrint('Calendar reminder created with warning: ${result.error}');
      }

      return result;
    } on ReminderManagerException catch (e) {
      _setError(e.message);
      return null;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Create location reminder from a LocationEntity (with geofence registration)
  Future<CreateReminderResult?> createLocationReminderFromEntity({
    required String summaryId,
    required String userId,
    required LocationEntity locationEntity,
    required String title,
    String? description,
    double radiusInMeters = 200,
    GeofenceTriggerType triggerType = GeofenceTriggerType.enter,
  }) async {
    if (_reminderManager == null) {
      _setError('Reminder manager not initialized');
      return null;
    }

    try {
      _setState(ReminderState.syncing);
      _clearError();

      final result = await _reminderManager!.createLocationReminder(
        summaryId: summaryId,
        userId: userId,
        locationEntity: locationEntity,
        title: title,
        description: description,
        radiusInMeters: radiusInMeters,
        triggerType: triggerType,
      );

      _addToLocalCache(result.reminder);
      _setState(ReminderState.loaded);

      return result;
    } on ReminderManagerException catch (e) {
      _setError(e.message);
      return null;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // ============================================================
  // BACKGROUND SERVICE MANAGEMENT
  // ============================================================

  /// Initialize and start background location monitoring
  Future<bool> startBackgroundService(String userId) async {
    try {
      _userId = userId;
      
      await _backgroundService.initialize();
      final started = await _backgroundService.startWithReminders(
        userId: userId,
        activeReminderCount: _activeReminders.length,
      );

      _isBackgroundServiceRunning = started;
      notifyListeners();

      if (started) {
        debugPrint('Background service started for user: $userId');
      }

      return started;
    } catch (e) {
      debugPrint('Failed to start background service: $e');
      return false;
    }
  }

  /// Stop background location monitoring
  Future<void> stopBackgroundService() async {
    try {
      await _backgroundService.stop();
      _isBackgroundServiceRunning = false;
      notifyListeners();
      debugPrint('Background service stopped');
    } catch (e) {
      debugPrint('Failed to stop background service: $e');
    }
  }

  /// Check if background service is running
  Future<bool> checkBackgroundServiceStatus() async {
    _isBackgroundServiceRunning = await _backgroundService.isRunning;
    notifyListeners();
    return _isBackgroundServiceRunning;
  }

  /// Start location monitoring via reminder manager
  Future<void> startLocationMonitoring() async {
    await _reminderManager?.startLocationMonitoring();
  }

  /// Stop location monitoring via reminder manager
  Future<void> stopLocationMonitoring() async {
    await _reminderManager?.stopLocationMonitoring();
  }

  // ============================================================
  // REMINDER STATUS UPDATES
  // ============================================================
  Future<bool> updateReminderStatus(
    String reminderId,
    ReminderStatus status,
  ) async {
    try {
      await _reminderRepository.updateReminderStatus(reminderId, status);

      // Update local cache
      _updateLocalReminder(reminderId, (r) => r.copyWith(status: status));
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Mark reminder as triggered
  Future<bool> markAsTriggered(String reminderId) async {
    try {
      await _reminderRepository.markAsTriggered(reminderId);
      _updateLocalReminder(
        reminderId,
        (r) => r.copyWith(
          status: ReminderStatus.triggered,
          triggeredAt: DateTime.now(),
        ),
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Mark reminder as completed
  Future<bool> markAsCompleted(String reminderId) async {
    try {
      await _reminderRepository.markAsCompleted(reminderId);
      _updateLocalReminder(
        reminderId,
        (r) => r.copyWith(
          status: ReminderStatus.completed,
          completedAt: DateTime.now(),
        ),
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Mark reminder as dismissed
  Future<bool> markAsDismissed(String reminderId) async {
    try {
      await _reminderRepository.markAsDismissed(reminderId);
      _updateLocalReminder(
        reminderId,
        (r) => r.copyWith(status: ReminderStatus.dismissed),
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Cancel reminder
  Future<bool> cancelReminder(String reminderId) async {
    try {
      await _reminderRepository.cancelReminder(reminderId);
      _updateLocalReminder(
        reminderId,
        (r) => r.copyWith(status: ReminderStatus.cancelled),
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Update calendar event ID (after syncing with Google Calendar)
  Future<bool> updateCalendarEventId(
    String reminderId,
    String calendarEventId,
  ) async {
    try {
      await _reminderRepository.updateCalendarEventId(reminderId, calendarEventId);
      _updateLocalReminder(
        reminderId,
        (r) => r.copyWith(calendarEventId: calendarEventId),
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Update geofence ID (after registering geofence)
  Future<bool> updateGeofenceId(
    String reminderId,
    String geofenceId,
  ) async {
    try {
      await _reminderRepository.updateGeofenceId(reminderId, geofenceId);
      _updateLocalReminder(
        reminderId,
        (r) => r.copyWith(geofenceId: geofenceId),
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Delete reminder
  Future<bool> deleteReminder(String reminderId) async {
    try {
      await _reminderRepository.deleteReminder(reminderId);

      _reminders.removeWhere((r) => r.id == reminderId);
      _activeReminders.removeWhere((r) => r.id == reminderId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Delete all reminders for a summary
  Future<bool> deleteRemindersForSummary(String summaryId) async {
    try {
      await _reminderRepository.deleteRemindersBySummaryId(summaryId);

      _reminders.removeWhere((r) => r.summaryId == summaryId);
      _activeReminders.removeWhere((r) => r.summaryId == summaryId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Get upcoming reminders within a duration
  Future<List<ReminderModel>> getUpcomingReminders(
    String userId, {
    Duration within = const Duration(days: 7),
  }) async {
    try {
      return await _reminderRepository.getUpcomingCalendarReminders(
        userId,
        within: within,
      );
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Get active location reminders (for geofencing service)
  Future<List<ReminderModel>> getActiveLocationReminders(String userId) async {
    try {
      return await _reminderRepository.getActiveLocationReminders(userId);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Expire old reminders
  Future<void> expireOldReminders(String userId) async {
    try {
      await _reminderRepository.expireOldReminders(userId);
      // Reload to get updated statuses
      await loadReminders(userId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Get reminder count
  Future<int> getReminderCount(String userId) async {
    try {
      return await _reminderRepository.getReminderCount(userId);
    } catch (e) {
      return _reminders.length;
    }
  }

  /// Get active reminder count
  Future<int> getActiveReminderCount(String userId) async {
    try {
      return await _reminderRepository.getActiveReminderCount(userId);
    } catch (e) {
      return _activeReminders.length;
    }
  }

  /// Clear all reminders (for logout)
  void clear() {
    _remindersSubscription?.cancel();
    _reminderCreatedSubscription?.cancel();
    _reminderTriggeredSubscription?.cancel();
    _reminderDeletedSubscription?.cancel();
    _reminders = [];
    _activeReminders = [];
    _errorMessage = null;
    _userId = null;
    _state = ReminderState.initial;
    notifyListeners();
  }

  /// Update local reminder in cache
  void _updateLocalReminder(
    String reminderId,
    ReminderModel Function(ReminderModel) update,
  ) {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      _reminders[index] = update(_reminders[index]);
    }

    final activeIndex = _activeReminders.indexWhere((r) => r.id == reminderId);
    if (activeIndex != -1) {
      final updated = update(_activeReminders[activeIndex]);
      if (updated.isActive) {
        _activeReminders[activeIndex] = updated;
      } else {
        _activeReminders.removeAt(activeIndex);
      }
    }

    notifyListeners();
  }

  /// Set state and notify listeners
  void _setState(ReminderState state) {
    _state = state;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _state = ReminderState.error;
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _remindersSubscription?.cancel();
    _reminderCreatedSubscription?.cancel();
    _reminderTriggeredSubscription?.cancel();
    _reminderDeletedSubscription?.cancel();
    super.dispose();
  }
}
