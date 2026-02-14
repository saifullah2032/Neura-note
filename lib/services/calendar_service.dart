import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:neuranotteai/services/auth_service.dart';

/// Exception thrown when calendar operations fail
class CalendarException implements Exception {
  final String message;
  final String? code;

  const CalendarException(this.message, [this.code]);

  @override
  String toString() => 'CalendarException: $message (code: $code)';
}

/// Calendar event model (simplified wrapper)
class CalendarEvent {
  final String? id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final bool isAllDay;
  final List<String> attendees;
  final String? recurrence;
  final int? reminderMinutes;

  const CalendarEvent({
    this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.isAllDay = false,
    this.attendees = const [],
    this.recurrence,
    this.reminderMinutes,
  });

  /// Create from Google Calendar Event
  factory CalendarEvent.fromGoogleEvent(calendar.Event event) {
    final start = event.start;
    final end = event.end;
    
    DateTime startTime;
    DateTime endTime;
    bool isAllDay = false;

    if (start?.dateTime != null) {
      startTime = start!.dateTime!;
      endTime = end?.dateTime ?? startTime.add(const Duration(hours: 1));
    } else if (start?.date != null) {
      // All-day event - date field is DateTime in googleapis package
      startTime = start!.date!;
      endTime = end?.date ?? startTime.add(const Duration(days: 1));
      isAllDay = true;
    } else {
      startTime = DateTime.now();
      endTime = startTime.add(const Duration(hours: 1));
    }

    return CalendarEvent(
      id: event.id,
      title: event.summary ?? 'Untitled Event',
      description: event.description,
      startTime: startTime,
      endTime: endTime,
      location: event.location,
      isAllDay: isAllDay,
      attendees: event.attendees
          ?.map((a) => a.email ?? '')
          .where((e) => e.isNotEmpty)
          .toList() ?? [],
    );
  }

  /// Convert to Google Calendar Event
  calendar.Event toGoogleEvent() {
    final event = calendar.Event();
    
    event.summary = title;
    event.description = description;
    event.location = location;

    if (isAllDay) {
      // For all-day events, use date field (DateTime at midnight)
      event.start = calendar.EventDateTime(
        date: DateTime(startTime.year, startTime.month, startTime.day),
      );
      event.end = calendar.EventDateTime(
        date: DateTime(endTime.year, endTime.month, endTime.day),
      );
    } else {
      event.start = calendar.EventDateTime(
        dateTime: startTime,
        timeZone: 'UTC',
      );
      event.end = calendar.EventDateTime(
        dateTime: endTime,
        timeZone: 'UTC',
      );
    }

    // Add reminders
    if (reminderMinutes != null) {
      event.reminders = calendar.EventReminders(
        useDefault: false,
        overrides: [
          calendar.EventReminder(
            method: 'popup',
            minutes: reminderMinutes,
          ),
        ],
      );
    }

    // Add attendees
    if (attendees.isNotEmpty) {
      event.attendees = attendees
          .map((email) => calendar.EventAttendee(email: email))
          .toList();
    }

    // Add recurrence
    if (recurrence != null) {
      event.recurrence = [recurrence!];
    }

    return event;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'isAllDay': isAllDay,
      'attendees': attendees,
      'recurrence': recurrence,
      'reminderMinutes': reminderMinutes,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      location: json['location'] as String?,
      isAllDay: json['isAllDay'] as bool? ?? false,
      attendees: (json['attendees'] as List?)?.cast<String>() ?? [],
      recurrence: json['recurrence'] as String?,
      reminderMinutes: json['reminderMinutes'] as int?,
    );
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    bool? isAllDay,
    List<String>? attendees,
    String? recurrence,
    int? reminderMinutes,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      isAllDay: isAllDay ?? this.isAllDay,
      attendees: attendees ?? this.attendees,
      recurrence: recurrence ?? this.recurrence,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }
}

/// Service responsible for handling Google Calendar operations
class CalendarService {
  final AuthService _authService;
  
  calendar.CalendarApi? _calendarApi;
  http.Client? _httpClient;

  static const String _primaryCalendarId = 'primary';

  CalendarService({
    required AuthService authService,
  }) : _authService = authService;

  /// Initialize the calendar API
  Future<void> initialize() async {
    await _ensureAuthenticated();
  }

  /// Ensure we have an authenticated calendar API client
  Future<void> _ensureAuthenticated() async {
    if (_calendarApi != null) return;

    try {
      final headers = await _authService.getGoogleAuthHeaders();
      if (headers == null) {
        throw CalendarException(
          'Not authenticated with Google',
          'not_authenticated',
        );
      }

      // Create an authenticated HTTP client
      _httpClient = _AuthenticatedHttpClient(headers);
      _calendarApi = calendar.CalendarApi(_httpClient!);
    } catch (e) {
      throw CalendarException('Failed to authenticate with Google Calendar: $e');
    }
  }

  /// Get list of user's calendars
  Future<List<calendar.CalendarListEntry>> getCalendarList() async {
    await _ensureAuthenticated();
    
    try {
      final calendarList = await _calendarApi!.calendarList.list();
      return calendarList.items ?? [];
    } catch (e) {
      throw CalendarException('Failed to get calendar list: $e');
    }
  }

  /// Get events from a calendar
  Future<List<CalendarEvent>> getEvents({
    String calendarId = _primaryCalendarId,
    DateTime? timeMin,
    DateTime? timeMax,
    int maxResults = 100,
    String? query,
  }) async {
    await _ensureAuthenticated();

    try {
      final events = await _calendarApi!.events.list(
        calendarId,
        timeMin: timeMin?.toUtc(),
        timeMax: timeMax?.toUtc(),
        maxResults: maxResults,
        q: query,
        singleEvents: true,
        orderBy: 'startTime',
      );

      return events.items
          ?.map((e) => CalendarEvent.fromGoogleEvent(e))
          .toList() ?? [];
    } catch (e) {
      throw CalendarException('Failed to get events: $e');
    }
  }

  /// Get upcoming events
  Future<List<CalendarEvent>> getUpcomingEvents({
    String calendarId = _primaryCalendarId,
    int maxResults = 10,
  }) async {
    return getEvents(
      calendarId: calendarId,
      timeMin: DateTime.now(),
      maxResults: maxResults,
    );
  }

  /// Get a specific event
  Future<CalendarEvent> getEvent(
    String eventId, {
    String calendarId = _primaryCalendarId,
  }) async {
    await _ensureAuthenticated();

    try {
      final event = await _calendarApi!.events.get(calendarId, eventId);
      return CalendarEvent.fromGoogleEvent(event);
    } catch (e) {
      throw CalendarException('Failed to get event: $e');
    }
  }

  /// Create a new event
  Future<CalendarEvent> createEvent(
    CalendarEvent event, {
    String calendarId = _primaryCalendarId,
  }) async {
    await _ensureAuthenticated();

    try {
      final googleEvent = event.toGoogleEvent();
      final createdEvent = await _calendarApi!.events.insert(
        googleEvent,
        calendarId,
      );
      
      debugPrint('Calendar event created: ${createdEvent.id}');
      return CalendarEvent.fromGoogleEvent(createdEvent);
    } catch (e) {
      throw CalendarException('Failed to create event: $e');
    }
  }

  /// Update an existing event
  Future<CalendarEvent> updateEvent(
    CalendarEvent event, {
    String calendarId = _primaryCalendarId,
  }) async {
    if (event.id == null) {
      throw CalendarException('Event ID is required for update');
    }

    await _ensureAuthenticated();

    try {
      final googleEvent = event.toGoogleEvent();
      googleEvent.id = event.id;
      
      final updatedEvent = await _calendarApi!.events.update(
        googleEvent,
        calendarId,
        event.id!,
      );
      
      debugPrint('Calendar event updated: ${updatedEvent.id}');
      return CalendarEvent.fromGoogleEvent(updatedEvent);
    } catch (e) {
      throw CalendarException('Failed to update event: $e');
    }
  }

  /// Delete an event
  Future<void> deleteEvent(
    String eventId, {
    String calendarId = _primaryCalendarId,
  }) async {
    await _ensureAuthenticated();

    try {
      await _calendarApi!.events.delete(calendarId, eventId);
      debugPrint('Calendar event deleted: $eventId');
    } catch (e) {
      throw CalendarException('Failed to delete event: $e');
    }
  }

  /// Quick add event (parses natural language)
  Future<CalendarEvent> quickAddEvent(
    String text, {
    String calendarId = _primaryCalendarId,
  }) async {
    await _ensureAuthenticated();

    try {
      final event = await _calendarApi!.events.quickAdd(calendarId, text);
      debugPrint('Calendar event quick added: ${event.id}');
      return CalendarEvent.fromGoogleEvent(event);
    } catch (e) {
      throw CalendarException('Failed to quick add event: $e');
    }
  }

  /// Create event from extracted date/time entity
  Future<CalendarEvent> createEventFromEntity({
    required String title,
    required DateTime dateTime,
    String? description,
    String? location,
    Duration duration = const Duration(hours: 1),
    int reminderMinutes = 30,
  }) async {
    final event = CalendarEvent(
      title: title,
      description: description,
      startTime: dateTime,
      endTime: dateTime.add(duration),
      location: location,
      reminderMinutes: reminderMinutes,
    );

    return createEvent(event);
  }

  /// Check if calendar access is available
  Future<bool> hasCalendarAccess() async {
    try {
      await _ensureAuthenticated();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clear the cached API client
  void clearCache() {
    _calendarApi = null;
    _httpClient?.close();
    _httpClient = null;
  }

  /// Dispose resources
  void dispose() {
    clearCache();
  }
}

/// Simple authenticated HTTP client using auth headers
class _AuthenticatedHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _AuthenticatedHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    _headers.forEach((key, value) {
      request.headers[key] = value;
    });
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Helper class for recurrence rules
class RecurrenceRule {
  /// Daily recurrence
  static String daily({int interval = 1, int? count, DateTime? until}) {
    return _buildRule('DAILY', interval, count, until);
  }

  /// Weekly recurrence
  static String weekly({
    int interval = 1,
    List<String>? byDay,
    int? count,
    DateTime? until,
  }) {
    var rule = _buildRule('WEEKLY', interval, count, until);
    if (byDay != null && byDay.isNotEmpty) {
      rule += ';BYDAY=${byDay.join(",")}';
    }
    return rule;
  }

  /// Monthly recurrence
  static String monthly({int interval = 1, int? count, DateTime? until}) {
    return _buildRule('MONTHLY', interval, count, until);
  }

  /// Yearly recurrence
  static String yearly({int interval = 1, int? count, DateTime? until}) {
    return _buildRule('YEARLY', interval, count, until);
  }

  static String _buildRule(
    String freq,
    int interval,
    int? count,
    DateTime? until,
  ) {
    var rule = 'RRULE:FREQ=$freq;INTERVAL=$interval';
    if (count != null) {
      rule += ';COUNT=$count';
    }
    if (until != null) {
      rule += ';UNTIL=${until.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.')[0]}Z';
    }
    return rule;
  }
}
