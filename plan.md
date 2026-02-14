# NeuraNote AI - Development Plan

## Project Timeline Overview

```
Phase 1: Foundation (Week 1-2)
    │
    ▼
Phase 2: Core Services (Week 3-4)
    │
    ▼
Phase 3: AI Integration (Week 5-6)
    │
    ▼
Phase 4: Smart Reminders (Week 7-9)
    │
    ▼
Phase 5: Polish & Testing (Week 10-11)
    │
    ▼
Phase 6: Launch Preparation (Week 12)
```

---

## Phase 1: Foundation (Week 1-2)

### 1.1 Data Models Implementation

| File | Priority | Description |
|------|----------|-------------|
| `user_model.dart` | High | User profile, auth tokens, preferences |
| `summary_model.dart` | High | Summary content, type, metadata, flags |
| `token_model.dart` | Medium | Usage tokens, limits, expiry |
| `api_response_model.dart` | Medium | Standardized API response wrapper |
| `reminder_model.dart` | High | NEW - Reminder type, location/time data |

#### Summary Model Structure
```dart
class SummaryModel {
  String id;
  String userId;
  SummaryType type;           // image, voice
  String originalContent;      // file path or audio URL
  String summarizedText;
  DateTime createdAt;
  
  // Smart Reminder Fields
  bool hasDateTimeEntity;
  DateTime? extractedDateTime;
  bool hasLocationEntity;
  GeoLocation? extractedLocation;
  
  // Reminder Flags
  bool isCalendarSynced;
  String? calendarEventId;
  bool isLocationReminderActive;
  String? geofenceId;
}
```

#### Reminder Model Structure
```dart
class ReminderModel {
  String id;
  String summaryId;
  ReminderType type;          // calendar, location
  String title;
  String description;
  
  // Calendar Reminder
  DateTime? scheduledDateTime;
  String? calendarEventId;
  
  // Location Reminder
  GeoLocation? targetLocation;
  double radiusInMeters;
  bool isActive;
  
  // Status
  ReminderStatus status;      // pending, triggered, dismissed
  DateTime? triggeredAt;
}
```

### 1.2 Core Utilities

| File | Tasks |
|------|-------|
| `constants.dart` | API endpoints, geofence radius options, token limits |
| `themes.dart` | Light/dark theme definitions, color palette |
| `utils.dart` | Date formatters, location helpers, validators |

### 1.3 State Management Setup

| Provider | Responsibility |
|----------|----------------|
| `app_state_provider.dart` | Global app state, loading states, errors |
| `auth_provider.dart` | Auth state, current user, session management |
| `summary_provider.dart` | Summary list, CRUD operations, filters |
| `token_provider.dart` | Token balance, usage tracking |
| `reminder_provider.dart` | NEW - Active reminders, geofence states |

**Deliverables:**
- [ ] All data models with serialization (toJson/fromJson)
- [ ] Provider classes with basic state structure
- [ ] Constants and theme files populated
- [ ] Unit tests for models

---

## Phase 2: Core Services (Week 3-4)

### 2.1 Authentication Service

```dart
// auth_service.dart
class AuthService {
  Future<User?> signInWithGoogle();
  Future<void> signOut();
  Stream<User?> authStateChanges();
  User? get currentUser;
}
```

**Tasks:**
- [ ] Complete Google Sign-In flow
- [ ] Handle auth state persistence
- [ ] Implement sign-out functionality
- [ ] Error handling and retry logic

### 2.2 Storage Service

```dart
// storage_service.dart
class StorageService {
  Future<String> uploadImage(File file);
  Future<String> uploadAudio(File file);
  Future<void> deleteFile(String url);
  Future<File> downloadFile(String url);
}
```

**Tasks:**
- [ ] Firebase Storage integration
- [ ] File compression before upload
- [ ] Progress tracking for uploads
- [ ] Secure URL generation

### 2.3 Image Service

```dart
// image_service.dart
class ImageService {
  Future<File?> pickFromGallery();
  Future<File?> captureFromCamera();
  Future<File> compressImage(File file);
  Future<String> extractText(File image);  // OCR placeholder
}
```

**Tasks:**
- [ ] Image picker integration
- [ ] Image compression utility
- [ ] Thumbnail generation
- [ ] OCR preparation (placeholder for AI)

### 2.4 Audio Service

```dart
// audio_service.dart
class AudioService {
  Future<void> startRecording();
  Future<File?> stopRecording();
  Future<void> pauseRecording();
  Future<void> resumeRecording();
  Stream<double> get amplitudeStream;
  Duration get currentDuration;
}
```

**Tasks:**
- [ ] Audio recording with `record` package
- [ ] Waveform visualization data
- [ ] Audio file format handling (m4a/wav)
- [ ] Recording state management

### 2.5 API Service

```dart
// api_service.dart
class ApiService {
  Future<ApiResponse> summarizeImage(String imageUrl);
  Future<ApiResponse> summarizeAudio(String audioUrl);
  Future<ApiResponse> extractEntities(String text);
}
```

**Tasks:**
- [ ] HTTP client setup (dio/http)
- [ ] Request/response interceptors
- [ ] Error handling middleware
- [ ] Retry mechanism with exponential backoff

**Deliverables:**
- [ ] All service classes implemented
- [ ] Repository layer connecting services to providers
- [ ] Integration tests for services
- [ ] Error handling standardized

---

## Phase 3: AI Integration (Week 5-6)

### 3.1 AI Summarization Backend

**Option A: Cloud Functions + AI API**
```
Client App ──► Firebase Cloud Function ──► OpenAI/Gemini API ──► Response
```

**Option B: Direct API Integration**
```
Client App ──► AI API (with API key security) ──► Response
```

### 3.2 Image Summarization Pipeline

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Upload    │────►│   Vision    │────►│  Generate   │
│   Image     │     │   AI/OCR    │     │   Summary   │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │   Entity    │
                                        │  Extraction │
                                        └─────────────┘
                                               │
                              ┌────────────────┼────────────────┐
                              ▼                ▼                ▼
                       [Date/Time]       [Location]       [General]
```

**Tasks:**
- [ ] Vision AI integration (Google Vision / OpenAI GPT-4V)
- [ ] OCR for text extraction from images
- [ ] Summarization prompt engineering
- [ ] Response parsing and formatting

### 3.3 Voice Summarization Pipeline

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Record    │────►│  Speech-to  │────►│  Generate   │
│   Audio     │     │    -Text    │     │   Summary   │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │   Entity    │
                                        │  Extraction │
                                        └─────────────┘
```

**Tasks:**
- [ ] Speech-to-text integration (Google STT / Whisper)
- [ ] Audio preprocessing (noise reduction)
- [ ] Transcription accuracy optimization
- [ ] Summarization of transcribed text

### 3.4 NLP Entity Extraction

```dart
class EntityExtractionService {
  Future<List<DateTimeEntity>> extractDateTimes(String text);
  Future<List<LocationEntity>> extractLocations(String text);
}

class DateTimeEntity {
  String originalText;    // "March 15th at 3 PM"
  DateTime parsedDateTime;
  DateTimeType type;      // specific, relative, recurring
}

class LocationEntity {
  String originalText;    // "Walmart on Main Street"
  String? resolvedAddress;
  double? latitude;
  double? longitude;
  LocationType type;      // address, place_name, landmark
}
```

**Tasks:**
- [ ] Date/time parsing (regex + NLP)
- [ ] Location entity recognition
- [ ] Geocoding integration (Google Geocoding API)
- [ ] Entity confidence scoring

**Deliverables:**
- [ ] AI summarization working end-to-end
- [ ] Entity extraction with >80% accuracy
- [ ] Geocoding for detected locations
- [ ] Performance optimization (<5s response time)

---

## Phase 4: Smart Reminders (Week 7-9)

### 4.1 Google Calendar Integration

```dart
// calendar_service.dart
class CalendarService {
  Future<void> authenticate();
  Future<String> createEvent(CalendarEvent event);
  Future<void> updateEvent(String eventId, CalendarEvent event);
  Future<void> deleteEvent(String eventId);
  Future<List<CalendarEvent>> getEvents(DateTime start, DateTime end);
}

class CalendarEvent {
  String title;
  String description;
  DateTime startTime;
  DateTime endTime;
  String? location;
  List<Reminder> reminders;
}
```

**Tasks:**
- [ ] Google Calendar API setup
- [ ] OAuth 2.0 flow for calendar scope
- [ ] Event creation from extracted entities
- [ ] Event sync status tracking
- [ ] Handle calendar permission denied

### 4.2 Geolocation Service

```dart
// location_service.dart
class LocationService {
  Future<Position> getCurrentLocation();
  Stream<Position> getLocationStream();
  Future<bool> requestPermission();
  Future<LocationPermission> checkPermission();
}
```

**Tasks:**
- [ ] Location permission handling
- [ ] Current location retrieval
- [ ] Background location updates
- [ ] Battery optimization considerations

### 4.3 Geocoding Service

```dart
// geocoding_service.dart
class GeocodingService {
  Future<GeoLocation?> addressToCoordinates(String address);
  Future<String?> coordinatesToAddress(double lat, double lng);
  Future<List<GeoLocation>> searchPlaces(String query);
}
```

**Tasks:**
- [ ] Google Geocoding API integration
- [ ] Place name resolution
- [ ] Address autocomplete suggestions
- [ ] Coordinate validation

### 4.4 Geofencing Service

```dart
// geofence_service.dart
class GeofenceService {
  Future<String> registerGeofence(Geofence geofence);
  Future<void> removeGeofence(String geofenceId);
  Future<List<Geofence>> getActiveGeofences();
  Stream<GeofenceEvent> get geofenceEvents;
}

class Geofence {
  String id;
  String reminderId;
  double latitude;
  double longitude;
  double radiusMeters;
  GeofenceTrigger trigger;  // enter, exit, dwell
}
```

**Tasks:**
- [ ] Geofence registration system
- [ ] Background geofence monitoring
- [ ] Trigger event handling
- [ ] Geofence persistence across app restarts

### 4.5 Notification Service

```dart
// notification_service.dart
class NotificationService {
  Future<void> initialize();
  Future<void> showLocalNotification(NotificationPayload payload);
  Future<void> scheduleNotification(NotificationPayload payload, DateTime time);
  Future<void> cancelNotification(int id);
  Stream<NotificationResponse> get onNotificationTap;
}
```

**Tasks:**
- [ ] Local notifications setup (Android/iOS)
- [ ] Notification channels configuration
- [ ] Deep linking from notifications
- [ ] Notification action buttons (Dismiss, Snooze)

### 4.6 Background Service

```dart
// background_service.dart
class BackgroundService {
  Future<void> initialize();
  Future<void> startLocationMonitoring();
  Future<void> stopLocationMonitoring();
  void onLocationUpdate(Position position);
  void checkGeofences(Position position);
}
```

**Tasks:**
- [ ] Background service setup (Android WorkManager / iOS Background Fetch)
- [ ] Periodic location checks
- [ ] Geofence proximity calculation
- [ ] Battery-efficient implementation

**Deliverables:**
- [ ] Calendar events created from summaries
- [ ] Geofences registered for location reminders
- [ ] Notifications triggered on geofence entry
- [ ] Background service running reliably

---

## Phase 5: Polish & Testing (Week 10-11)

### 5.1 UI Refinements

| Screen | Tasks |
|--------|-------|
| **Home Screen** | Real data binding, empty states, pull-to-refresh |
| **Summarize Screen** | Dynamic reminder buttons, loading states |
| **Profile Screen** | Real user data, token usage chart |
| **New: Reminders Screen** | List active reminders, edit/delete |

### 5.2 Widget Extraction

| Widget | Purpose |
|--------|---------|
| `summary_card.dart` | Reusable summary card with type indicator |
| `token_indicator.dart` | Token usage progress bar |
| `ai_loading_animation.dart` | AI processing animation |
| `reminder_chip.dart` | NEW - Calendar/Location reminder indicator |
| `entity_highlight.dart` | NEW - Highlight detected entities in text |
| `location_picker.dart` | NEW - Map-based location selection |

### 5.3 Error Handling & Edge Cases

- [ ] No internet connection handling
- [ ] API timeout and retry UI
- [ ] Empty states for all lists
- [ ] Permission denied states
- [ ] Token exhausted state
- [ ] Location services disabled
- [ ] Calendar access denied

### 5.4 Testing

| Type | Coverage Target |
|------|-----------------|
| Unit Tests | Models, Utils, Entity Extraction |
| Widget Tests | All screens, key widgets |
| Integration Tests | Auth flow, Summary creation, Reminder flow |
| E2E Tests | Critical user journeys |

**Test Scenarios:**
- [ ] User sign-in/sign-out flow
- [ ] Image upload → Summary → Calendar reminder
- [ ] Voice record → Summary → Location reminder
- [ ] Geofence trigger → Notification
- [ ] Token deduction on summarization

### 5.5 Performance Optimization

- [ ] Image compression before upload
- [ ] Lazy loading for summary list
- [ ] Caching for geocoding results
- [ ] Debounced location updates
- [ ] Memory leak detection

**Deliverables:**
- [ ] All UI screens polished
- [ ] Reusable widgets extracted
- [ ] >70% test coverage
- [ ] Performance benchmarks met

---

## Phase 6: Launch Preparation (Week 12)

### 6.1 Production Setup

- [ ] Firebase production project setup
- [ ] API keys secured (not in client code)
- [ ] Environment configuration (dev/staging/prod)
- [ ] Error tracking (Crashlytics/Sentry)
- [ ] Analytics integration

### 6.2 App Store Preparation

| Platform | Tasks |
|----------|-------|
| **Android** | App signing, Play Store listing, screenshots |
| **iOS** | Certificates, App Store Connect, TestFlight |

### 6.3 Documentation

- [ ] User onboarding flow
- [ ] Privacy policy (location data handling)
- [ ] Terms of service
- [ ] In-app help/FAQ

### 6.4 Beta Testing

- [ ] Internal testing (team)
- [ ] Closed beta (limited users)
- [ ] Feedback collection system
- [ ] Bug tracking and prioritization

**Deliverables:**
- [ ] Production-ready builds
- [ ] Store listings complete
- [ ] Beta testing completed
- [ ] Launch checklist verified

---

## Dependencies Checklist

### Current Dependencies
- [x] `flutter` - Core framework
- [x] `firebase_core` - Firebase initialization
- [x] `firebase_auth` - Authentication
- [x] `google_sign_in` - Google OAuth
- [x] `go_router` - Navigation
- [x] `google_fonts` - Typography
- [x] `rive` - Animations

### To Be Added

| Package | Purpose | Phase |
|---------|---------|-------|
| `firebase_storage` | File uploads | 2 |
| `cloud_firestore` | Database | 2 |
| `image_picker` | Gallery/camera access | 2 |
| `record` | Audio recording | 2 |
| `dio` | HTTP client | 2 |
| `googleapis` | Google Calendar API | 4 |
| `geolocator` | Device location | 4 |
| `geocoding` | Address resolution | 4 |
| `flutter_local_notifications` | Local notifications | 4 |
| `workmanager` | Background tasks (Android) | 4 |
| `permission_handler` | Runtime permissions | 4 |
| `flutter_riverpod` / `provider` | State management | 1 |
| `freezed` | Immutable models | 1 |
| `json_serializable` | JSON serialization | 1 |

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| AI API costs exceed budget | High | Token-based usage limits, caching |
| Background location drains battery | Medium | Significant motion detection, adaptive intervals |
| Geocoding accuracy issues | Medium | Manual location correction option |
| Google Calendar API rate limits | Low | Request batching, local queue |
| iOS background restrictions | Medium | Use significant location changes API |
| Entity extraction false positives | Medium | User confirmation before creating reminders |

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Summary generation time | < 5 seconds |
| Entity extraction accuracy | > 80% |
| Geofence trigger accuracy | < 100m variance |
| App crash rate | < 1% |
| User retention (Day 7) | > 40% |
| Calendar sync success rate | > 95% |

---

## Team Allocation (If Applicable)

| Role | Responsibilities |
|------|------------------|
| **Flutter Developer** | UI, state management, services |
| **Backend Developer** | Cloud Functions, AI integration |
| **UI/UX Designer** | Design refinements, new screens |
| **QA Engineer** | Testing, bug verification |

---

## Weekly Milestones

| Week | Milestone | Deliverable |
|------|-----------|-------------|
| 1 | Models & Providers | Data layer complete |
| 2 | Core utilities | Constants, themes, utils |
| 3 | Auth & Storage | User can sign in, upload files |
| 4 | Image & Audio | Recording and picking functional |
| 5 | AI Summarization | Summaries generated from content |
| 6 | Entity Extraction | Dates and locations detected |
| 7 | Calendar Integration | Events created in Google Calendar |
| 8 | Geofencing | Location reminders registered |
| 9 | Notifications | Reminders trigger notifications |
| 10 | UI Polish | All screens refined |
| 11 | Testing | Test coverage complete |
| 12 | Launch Prep | Ready for app stores |

---

## Next Immediate Actions

1. **Today:** Set up state management package (Riverpod/Provider)
2. **Day 2:** Implement all data models with freezed
3. **Day 3:** Complete auth_service.dart and auth_provider.dart
4. **Day 4:** Implement storage_service.dart with Firebase Storage
5. **Day 5:** Create image_service.dart and audio_service.dart
6. **End of Week 1:** All foundation code complete and tested

---

*Last Updated: February 14, 2026*
*Version: 1.0*
