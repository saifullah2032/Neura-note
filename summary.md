# NeuraNote AI - Project Summary

## Overview

**NeuraNote AI** is a Flutter-based mobile application designed to help users summarize content through images and voice recordings. The project is currently in the **initial/early development stage**, focusing on UI refinement and establishing the foundational architecture.

**Version:** 1.0.0+1  
**SDK:** Flutter (Dart ^3.10.4)  
**Platforms:** Android, iOS, Web, Windows, macOS, Linux

---

## Project Architecture

The project follows a clean architecture pattern with clear separation of concerns:

```
lib/
├── core/                  # Core utilities and configurations
│   ├── constants.dart     # (Empty - Placeholder)
│   ├── routes.dart        # GoRouter navigation configuration
│   ├── themes.dart        # (Empty - Placeholder)
│   └── utils.dart         # (Empty - Placeholder)
│
├── model/                 # Data models
│   ├── api_response_model.dart   # (Empty - Placeholder)
│   ├── summary_model.dart        # (Empty - Placeholder)
│   ├── token_model.dart          # (Empty - Placeholder)
│   └── user_model.dart           # (Empty - Placeholder)
│
├── providers/             # State management
│   ├── app_state_provider.dart   # (Empty - Placeholder)
│   ├── auth_provider.dart        # (Empty - Placeholder)
│   ├── summary_provider.dart     # (Empty - Placeholder)
│   └── token_provider.dart       # (Empty - Placeholder)
│
├── repo/                  # Repositories (data layer abstraction)
│   ├── auth_repo.dart            # (Empty - Placeholder)
│   ├── summary_repo.dart         # (Empty - Placeholder)
│   └── token_repo.dart           # (Empty - Placeholder)
│
├── services/              # Business logic services
│   ├── api_service.dart          # (Empty - Placeholder)
│   ├── audio_service.dart        # (Empty - Placeholder)
│   ├── auth_service.dart         # (Empty - Placeholder)
│   ├── image_service.dart        # (Empty - Placeholder)
│   └── storage_service.dart      # (Empty - Placeholder)
│
├── screens/               # UI screens
│   ├── home/              # Home screen with summary grid
│   ├── login/             # Login screen with Google Sign-In
│   ├── profile/           # User profile screen
│   ├── summarize/         # Summary detail screen
│   └── widgets/           # Shared UI widgets (mostly empty)
│
├── dataconnect_generated/ # Firebase Data Connect generated files
├── firebase_options.dart  # Firebase configuration
└── main.dart              # Application entry point
```

---

## Current Implementation Status

### Completed/Functional

| Component | Status | Description |
|-----------|--------|-------------|
| **Main Entry** | Complete | Firebase initialization, MaterialApp with GoRouter |
| **Routing** | Complete | 4 routes: login, home, summary, profile |
| **Login Screen** | Complete | Google Sign-In with Firebase Auth, Rive animations |
| **Home Screen** | Complete | Summary grid layout, floating bottom bar, expandable panels |
| **Profile Screen** | Complete | Basic UI with token display and premium CTA |
| **Summarize Screen** | Complete | Summary detail view with reminder button |
| **Rive Animations** | Complete | Multiple animations (waving, beach wave, loading) |

### Pending Implementation (Placeholder Files)

| Layer | Files | Status |
|-------|-------|--------|
| **Models** | user, summary, token, api_response | Empty |
| **Providers** | app_state, auth, summary, token | Empty |
| **Repositories** | auth, summary, token | Empty |
| **Services** | api, audio, auth, image, storage | Empty |
| **Core** | constants, themes, utils | Empty |
| **Widgets** | ai_loading_animation, summary_card, token_indicator | Empty |

---

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Core framework |
| `firebase_core` | ^3.3.0 | Firebase initialization |
| `firebase_auth` | ^5.3.0 | Authentication |
| `google_sign_in` | ^6.2.1 | Google OAuth |
| `go_router` | ^14.0.2 | Declarative routing |
| `google_fonts` | ^6.2.1 | Poppins font family |
| `rive` | ^0.13.8 | Vector animations |

---

## UI/UX Design

### Design System

- **Primary Color:** Teal
- **Background:** Off-white (#F8F9FA)
- **Typography:** Google Fonts - Poppins
- **Design Language:** Material Design 3

### Screen Flow

```
Login Screen (/) 
    │
    ├── Google Sign-In ──► Home Screen (/home)
    │                           │
    │                           ├── Summary Cards Grid
    │                           │       │
    │                           │       └── Tap ──► Summarize Screen (/summary)
    │                           │
    │                           ├── + Button ──► Gallery Upload Panel
    │                           │
    │                           ├── Mic Button ──► Voice Recording Panel
    │                           │
    │                           └── Settings ──► Profile Screen (/profile)
```

### Key UI Elements

1. **Login Screen**
   - Diagonal gradient backgrounds (teal)
   - Animated waving character (Rive)
   - Beach wave animation at bottom
   - Google Sign-In button with loading state

2. **Home Screen**
   - Header with "SUMMARIZER" title
   - 2-column grid of summary cards
   - Floating bottom navigation bar (pill-shaped)
   - Expandable panels for gallery upload and voice recording

3. **Profile Screen**
   - User avatar and info
   - Token remaining indicator
   - Premium upgrade button

4. **Summarize Screen**
   - Image preview container
   - Summary text display
   - Add Reminder button

---

## Assets

### Rive Animations
- `waving.riv` - Welcome screen character animation
- `beach_wave.riv` - Login screen background wave
- `loading-lg.riv` - Loading indicator during sign-in
- `elk.riv` - Additional animation asset
- `voice.riv` - Voice recording animation
- `rd_btt.riv` - Additional animation asset

---

## Core Features

### 1. Content Summarization
- **Image Summarization:** Upload images from gallery, AI extracts and summarizes text/content
- **Voice Summarization:** Record voice notes, AI transcribes and summarizes spoken content

### 2. Google Calendar Integration (Time-Based Reminders)

When the AI detects **date/time references** in summarized content (from image or voice), the app intelligently offers to save it to Google Calendar.

**Flow:**
```
Image/Voice Input 
    │
    ▼
AI Summarization
    │
    ▼
Date/Time Detection (NLP parsing)
    │
    ├── Date/Time Found ──► "Add to Google Calendar" Button appears
    │                              │
    │                              ▼
    │                       User taps button
    │                              │
    │                              ▼
    │                       Google Calendar API creates event
    │                       with extracted date, time, and summary
    │
    └── No Date/Time ──► Standard summary display
```

**Examples:**
- Voice note: *"Meeting with John on March 15th at 3 PM about the project proposal"*
  - Detected: March 15th, 3:00 PM
  - Calendar Event: "Meeting with John - project proposal"
  
- Image of whiteboard: Contains text *"Deadline: Submit report by Friday 5pm"*
  - Detected: Next Friday, 5:00 PM
  - Calendar Event: "Deadline - Submit report"

**Technical Requirements:**
- Google Calendar API integration
- NLP date/time parsing (e.g., chrono-node equivalent for Dart, or server-side processing)
- OAuth scope for calendar write access
- Event creation with title, description, date/time

### 3. Location-Based Reminders (Geo-Fencing)

When the AI detects **geographic locations** in summarized content, users can flag it as a location-based reminder. When the device's current location matches the flagged location, a notification is triggered.

**Flow:**
```
Image/Voice Input 
    │
    ▼
AI Summarization
    │
    ▼
Location Detection (NLP + Geocoding)
    │
    ├── Location Found ──► "Set Location Reminder" Button appears
    │                              │
    │                              ▼
    │                       User taps button
    │                              │
    │                              ▼
    │                       Location flagged & stored with summary
    │                       Geofence registered in background service
    │                              │
    │                              ▼
    │                       [Background Monitoring Active]
    │                              │
    │                              ▼
    │                       Device enters geofence radius
    │                              │
    │                              ▼
    │                       Push Notification: Reminder triggered!
    │
    └── No Location ──► Standard summary display
```

**Examples:**
- Voice note: *"Remember to buy groceries at Walmart on Main Street"*
  - Detected Location: Walmart, Main Street
  - When user is near that Walmart → Notification: "Reminder: Buy groceries"

- Image of a business card: Contains address *"123 Oak Avenue, Downtown"*
  - Detected Location: 123 Oak Avenue
  - When user is near that address → Notification: "Reminder: [Summary content]"

**Technical Requirements:**
- Geolocation services (`geolocator` package)
- Geocoding API (convert place names/addresses to coordinates)
- Geofencing service (background location monitoring)
- Local notifications (`flutter_local_notifications`)
- Background service for iOS/Android
- Configurable radius (e.g., 100m, 500m, 1km)
- Battery-efficient location tracking

### Smart Reminder Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     SUMMARY CONTENT                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │      AI CONTENT ANALYSIS       │
              │  (NLP Entity Extraction)       │
              └───────────────────────────────┘
                              │
           ┌──────────────────┼──────────────────┐
           ▼                  ▼                  ▼
    ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
    │  DATE/TIME  │   │  LOCATION   │   │   GENERAL   │
    │  DETECTED   │   │  DETECTED   │   │   CONTENT   │
    └─────────────┘   └─────────────┘   └─────────────┘
           │                  │                  │
           ▼                  ▼                  ▼
    ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
    │  📅 Add to  │   │  📍 Set     │   │  💾 Save    │
    │  Calendar   │   │  Location   │   │  Summary    │
    │  Button     │   │  Reminder   │   │  Only       │
    └─────────────┘   └─────────────┘   └─────────────┘
           │                  │
           ▼                  ▼
    ┌─────────────┐   ┌─────────────┐
    │  Google     │   │  Geofence   │
    │  Calendar   │   │  Background │
    │  Event      │   │  Service    │
    └─────────────┘   └─────────────┘
                              │
                              ▼
                      ┌─────────────┐
                      │  Location   │
                      │  Match!     │
                      └─────────────┘
                              │
                              ▼
                      ┌─────────────┐
                      │  🔔 Push    │
                      │  Notification│
                      └─────────────┘
```

---

## Additional Dependencies Required

| Package | Purpose |
|---------|---------|
| `googleapis` / `googleapis_auth` | Google Calendar API integration |
| `geolocator` | Device location access |
| `geocoding` | Convert addresses to coordinates |
| `flutter_local_notifications` | Local push notifications |
| `workmanager` / `flutter_background_service` | Background geofence monitoring |
| `permission_handler` | Location & notification permissions |

---

## Development Priorities

### Immediate Next Steps

1. **Implement Data Models** - Define user, summary, and token data structures
2. **Complete Services Layer** - API, audio, image, and storage services
3. **State Management** - Implement providers for app state
4. **Repository Pattern** - Connect services to providers
5. **Extract Reusable Widgets** - SummaryCard, TokenIndicator, AILoadingAnimation

### Smart Reminder Features (Priority)

1. **NLP Entity Extraction Service** - Parse summaries for dates, times, and locations
2. **Google Calendar Service** - OAuth flow + event creation API
3. **Geolocation Service** - Device location tracking + geocoding
4. **Geofencing Service** - Background location monitoring with radius triggers
5. **Notification Service** - Local notifications for location-based reminders
6. **Reminder Model** - Data structure for storing flagged reminders with metadata

### Future Enhancements

- Actual image summarization functionality (AI integration)
- Voice recording and transcription
- Token-based usage system
- Premium subscription features
- Data persistence with Firebase/local storage
- Recurring calendar events support
- Multiple geofence radius options
- Reminder snooze/dismiss functionality
- Reminder history and management screen

---

## Technical Notes

- **Firebase Integration:** Configured with FlutterFire CLI
- **Navigation:** Uses GoRouter for declarative, type-safe routing
- **Material 3:** Enabled with teal color scheme seed
- **Animations:** Heavy use of Rive for smooth vector animations
- **Auth Flow:** Google Sign-In → Firebase Auth credential → Home navigation

---

## Conclusion

The NeuraNote AI project has a well-structured foundation with clean architecture patterns in place. The UI layer is substantially complete with polished screens and animations. The primary focus now should be on implementing the backend services, data models, and state management to bring the core summarization functionality to life.

**Current Progress:** ~40% (UI/Structure) | ~0% (Backend/Logic)

---

## Feature Summary Matrix

| Feature | Input | Detection | Action | Trigger |
|---------|-------|-----------|--------|---------|
| **Image Summary** | Gallery Image | AI OCR/Vision | Text Summary | Immediate |
| **Voice Summary** | Microphone | AI Transcription | Text Summary | Immediate |
| **Calendar Reminder** | Summary Text | Date/Time NLP | Google Calendar Event | Scheduled time |
| **Location Reminder** | Summary Text | Location NLP + Geocoding | Geofence Registration | Device proximity |
