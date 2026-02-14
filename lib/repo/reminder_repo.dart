import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../model/reminder_model.dart';

/// Repository for reminder operations
class ReminderRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  ReminderRepository({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  /// Collection reference for reminders
  CollectionReference<Map<String, dynamic>> get _remindersCollection =>
      _firestore.collection('reminders');

  /// Create a new reminder
  Future<ReminderModel> createReminder({
    required String summaryId,
    required String userId,
    required ReminderType type,
    required String title,
    required String description,
    DateTime? scheduledDateTime,
    DateTime? endDateTime,
    bool allDayEvent = false,
    GeoLocation? targetLocation,
    double radiusInMeters = 200,
    GeofenceTriggerType triggerType = GeofenceTriggerType.enter,
    bool notificationEnabled = true,
    int? notificationMinutesBefore,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final reminder = ReminderModel(
      id: id,
      summaryId: summaryId,
      userId: userId,
      type: type,
      title: title,
      description: description,
      createdAt: now,
      scheduledDateTime: scheduledDateTime,
      endDateTime: endDateTime,
      allDayEvent: allDayEvent,
      targetLocation: targetLocation,
      radiusInMeters: radiusInMeters,
      triggerType: triggerType,
      status: ReminderStatus.pending,
      notificationEnabled: notificationEnabled,
      notificationMinutesBefore: notificationMinutesBefore,
    );

    await _remindersCollection.doc(id).set(reminder.toJson());
    return reminder;
  }

  /// Create calendar reminder
  Future<ReminderModel> createCalendarReminder({
    required String summaryId,
    required String userId,
    required String title,
    required String description,
    required DateTime scheduledDateTime,
    DateTime? endDateTime,
    bool allDayEvent = false,
    int notificationMinutesBefore = 15,
  }) async {
    return createReminder(
      summaryId: summaryId,
      userId: userId,
      type: ReminderType.calendar,
      title: title,
      description: description,
      scheduledDateTime: scheduledDateTime,
      endDateTime: endDateTime,
      allDayEvent: allDayEvent,
      notificationMinutesBefore: notificationMinutesBefore,
    );
  }

  /// Create location reminder
  Future<ReminderModel> createLocationReminder({
    required String summaryId,
    required String userId,
    required String title,
    required String description,
    required GeoLocation targetLocation,
    double radiusInMeters = 200,
    GeofenceTriggerType triggerType = GeofenceTriggerType.enter,
  }) async {
    return createReminder(
      summaryId: summaryId,
      userId: userId,
      type: ReminderType.location,
      title: title,
      description: description,
      targetLocation: targetLocation,
      radiusInMeters: radiusInMeters,
      triggerType: triggerType,
    );
  }

  /// Get reminder by ID
  Future<ReminderModel?> getReminderById(String id) async {
    final snapshot = await _remindersCollection.doc(id).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return ReminderModel.fromJson(snapshot.data()!);
  }

  /// Get all reminders for a user
  Future<List<ReminderModel>> getRemindersByUserId(
    String userId, {
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _remindersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ReminderModel.fromJson(doc.data()))
        .toList();
  }

  /// Stream of reminders for a user
  Stream<List<ReminderModel>> remindersStream(String userId, {int? limit}) {
    Query<Map<String, dynamic>> query = _remindersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ReminderModel.fromJson(doc.data())).toList());
  }

  /// Get reminders by summary ID
  Future<List<ReminderModel>> getRemindersBySummaryId(String summaryId) async {
    final snapshot = await _remindersCollection
        .where('summaryId', isEqualTo: summaryId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ReminderModel.fromJson(doc.data()))
        .toList();
  }

  /// Get active reminders for a user
  Future<List<ReminderModel>> getActiveReminders(String userId) async {
    final snapshot = await _remindersCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: ReminderStatus.pending.value)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ReminderModel.fromJson(doc.data()))
        .toList();
  }

  /// Get calendar reminders
  Future<List<ReminderModel>> getCalendarReminders(String userId) async {
    final snapshot = await _remindersCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: ReminderType.calendar.value)
        .orderBy('scheduledDateTime', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => ReminderModel.fromJson(doc.data()))
        .toList();
  }

  /// Get location reminders
  Future<List<ReminderModel>> getLocationReminders(String userId) async {
    final snapshot = await _remindersCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: ReminderType.location.value)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ReminderModel.fromJson(doc.data()))
        .toList();
  }

  /// Get active location reminders (for geofencing)
  Future<List<ReminderModel>> getActiveLocationReminders(String userId) async {
    final snapshot = await _remindersCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: ReminderType.location.value)
        .where('status', isEqualTo: ReminderStatus.pending.value)
        .get();

    return snapshot.docs
        .map((doc) => ReminderModel.fromJson(doc.data()))
        .toList();
  }

  /// Get upcoming calendar reminders
  Future<List<ReminderModel>> getUpcomingCalendarReminders(
    String userId, {
    Duration? within,
  }) async {
    final now = DateTime.now();
    Query<Map<String, dynamic>> query = _remindersCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: ReminderType.calendar.value)
        .where('status', isEqualTo: ReminderStatus.pending.value)
        .where('scheduledDateTime', isGreaterThanOrEqualTo: now.toIso8601String());

    if (within != null) {
      final endTime = now.add(within);
      query = query.where('scheduledDateTime',
          isLessThanOrEqualTo: endTime.toIso8601String());
    }

    query = query.orderBy('scheduledDateTime', descending: false);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ReminderModel.fromJson(doc.data()))
        .toList();
  }

  /// Update reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    final updatedReminder = reminder.copyWith(updatedAt: DateTime.now());
    await _remindersCollection.doc(reminder.id).update(updatedReminder.toJson());
  }

  /// Update reminder status
  Future<void> updateReminderStatus(
    String reminderId,
    ReminderStatus status, {
    DateTime? triggeredAt,
    DateTime? completedAt,
  }) async {
    final updates = <String, dynamic>{
      'status': status.value,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (triggeredAt != null) {
      updates['triggeredAt'] = triggeredAt.toIso8601String();
    }

    if (completedAt != null) {
      updates['completedAt'] = completedAt.toIso8601String();
    }

    await _remindersCollection.doc(reminderId).update(updates);
  }

  /// Mark reminder as triggered
  Future<void> markAsTriggered(String reminderId) async {
    await updateReminderStatus(
      reminderId,
      ReminderStatus.triggered,
      triggeredAt: DateTime.now(),
    );
  }

  /// Mark reminder as completed
  Future<void> markAsCompleted(String reminderId) async {
    await updateReminderStatus(
      reminderId,
      ReminderStatus.completed,
      completedAt: DateTime.now(),
    );
  }

  /// Mark reminder as dismissed
  Future<void> markAsDismissed(String reminderId) async {
    await updateReminderStatus(reminderId, ReminderStatus.dismissed);
  }

  /// Cancel reminder
  Future<void> cancelReminder(String reminderId) async {
    await updateReminderStatus(reminderId, ReminderStatus.cancelled);
  }

  /// Update calendar event ID
  Future<void> updateCalendarEventId(
    String reminderId,
    String calendarEventId,
  ) async {
    await _remindersCollection.doc(reminderId).update({
      'calendarEventId': calendarEventId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update geofence ID
  Future<void> updateGeofenceId(
    String reminderId,
    String geofenceId,
  ) async {
    await _remindersCollection.doc(reminderId).update({
      'geofenceId': geofenceId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Delete reminder
  Future<void> deleteReminder(String id) async {
    await _remindersCollection.doc(id).delete();
  }

  /// Delete all reminders for a summary
  Future<void> deleteRemindersBySummaryId(String summaryId) async {
    final reminders = await getRemindersBySummaryId(summaryId);
    final batch = _firestore.batch();

    for (final reminder in reminders) {
      batch.delete(_remindersCollection.doc(reminder.id));
    }

    await batch.commit();
  }

  /// Batch delete reminders
  Future<void> batchDeleteReminders(List<String> reminderIds) async {
    final batch = _firestore.batch();
    for (final id in reminderIds) {
      batch.delete(_remindersCollection.doc(id));
    }
    await batch.commit();
  }

  /// Get reminder count for user
  Future<int> getReminderCount(String userId) async {
    final snapshot = await _remindersCollection
        .where('userId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get active reminder count
  Future<int> getActiveReminderCount(String userId) async {
    final snapshot = await _remindersCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: ReminderStatus.pending.value)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Expire old calendar reminders
  Future<void> expireOldReminders(String userId) async {
    final now = DateTime.now();
    final snapshot = await _remindersCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: ReminderType.calendar.value)
        .where('status', isEqualTo: ReminderStatus.pending.value)
        .where('scheduledDateTime', isLessThan: now.toIso8601String())
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': ReminderStatus.expired.value,
        'updatedAt': now.toIso8601String(),
      });
    }

    await batch.commit();
  }
}
