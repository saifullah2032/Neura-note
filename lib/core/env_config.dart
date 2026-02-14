/// Environment configuration for NeuraNote AI
///
/// This file provides a centralized place for all API keys and configuration.
/// For production, use environment variables or a secure secrets manager.
///
/// IMPORTANT: Never commit actual API keys to version control!
/// Use --dart-define or environment variables for sensitive values.
library;

import 'package:flutter/foundation.dart';

/// Environment configuration singleton
class EnvConfig {
  EnvConfig._();

  static final EnvConfig _instance = EnvConfig._();
  static EnvConfig get instance => _instance;

  // ============================================================
  // API Keys - Use --dart-define for production
  // Example: flutter run --dart-define=GEMINI_API_KEY=your_key
  // ============================================================

  /// Google Gemini API Key for AI summarization
  /// Set via: --dart-define=GEMINI_API_KEY=your_key
  String get geminiApiKey {
    const key = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: '',
    );
    if (key.isEmpty && kDebugMode) {
      debugPrint('WARNING: GEMINI_API_KEY not set. AI features will not work.');
    }
    return key;
  }

  /// Google Maps API Key for geocoding
  /// Set via: --dart-define=GOOGLE_MAPS_API_KEY=your_key
  String get googleMapsApiKey {
    const key = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: '',
    );
    if (key.isEmpty && kDebugMode) {
      debugPrint('WARNING: GOOGLE_MAPS_API_KEY not set. Geocoding will not work.');
    }
    return key;
  }

  /// Google OAuth Client ID for Calendar integration
  /// Set via: --dart-define=GOOGLE_CLIENT_ID=your_client_id
  String get googleClientId {
    const clientId = String.fromEnvironment(
      'GOOGLE_CLIENT_ID',
      defaultValue: '',
    );
    return clientId;
  }

  // ============================================================
  // Feature Flags
  // ============================================================

  /// Enable debug logging
  bool get enableDebugLogging {
    const enabled = bool.fromEnvironment(
      'ENABLE_DEBUG_LOGGING',
      defaultValue: kDebugMode,
    );
    return enabled;
  }

  /// Enable mock services for testing
  bool get useMockServices {
    const mock = bool.fromEnvironment(
      'USE_MOCK_SERVICES',
      defaultValue: false,
    );
    return mock;
  }

  /// Enable analytics
  bool get enableAnalytics {
    const enabled = bool.fromEnvironment(
      'ENABLE_ANALYTICS',
      defaultValue: !kDebugMode,
    );
    return enabled;
  }

  // ============================================================
  // Service Endpoints
  // ============================================================

  /// Gemini API base URL
  String get geminiBaseUrl {
    const url = String.fromEnvironment(
      'GEMINI_BASE_URL',
      defaultValue: 'https://generativelanguage.googleapis.com/v1beta',
    );
    return url;
  }

  /// Google Maps Geocoding API base URL
  String get geocodingBaseUrl {
    const url = String.fromEnvironment(
      'GEOCODING_BASE_URL',
      defaultValue: 'https://maps.googleapis.com/maps/api/geocode',
    );
    return url;
  }

  // ============================================================
  // App Configuration
  // ============================================================

  /// Default geofence radius in meters
  double get defaultGeofenceRadius {
    const radius = int.fromEnvironment(
      'DEFAULT_GEOFENCE_RADIUS',
      defaultValue: 200,
    );
    return radius.toDouble();
  }

  /// Minimum geofence radius in meters
  double get minGeofenceRadius {
    const radius = int.fromEnvironment(
      'MIN_GEOFENCE_RADIUS',
      defaultValue: 50,
    );
    return radius.toDouble();
  }

  /// Maximum geofence radius in meters
  double get maxGeofenceRadius {
    const radius = int.fromEnvironment(
      'MAX_GEOFENCE_RADIUS',
      defaultValue: 1000,
    );
    return radius.toDouble();
  }

  /// Default calendar reminder minutes before event
  int get defaultReminderMinutesBefore {
    const minutes = int.fromEnvironment(
      'DEFAULT_REMINDER_MINUTES',
      defaultValue: 15,
    );
    return minutes;
  }

  /// Maximum file size for uploads (in bytes)
  int get maxUploadFileSize {
    const size = int.fromEnvironment(
      'MAX_UPLOAD_FILE_SIZE',
      defaultValue: 10 * 1024 * 1024, // 10 MB
    );
    return size;
  }

  /// Maximum audio recording duration (in seconds)
  int get maxRecordingDuration {
    const duration = int.fromEnvironment(
      'MAX_RECORDING_DURATION',
      defaultValue: 300, // 5 minutes
    );
    return duration;
  }

  // ============================================================
  // Validation
  // ============================================================

  /// Check if all required API keys are configured
  bool get isFullyConfigured {
    return geminiApiKey.isNotEmpty && googleMapsApiKey.isNotEmpty;
  }

  /// Get list of missing configuration items
  List<String> get missingConfiguration {
    final missing = <String>[];
    if (geminiApiKey.isEmpty) missing.add('GEMINI_API_KEY');
    if (googleMapsApiKey.isEmpty) missing.add('GOOGLE_MAPS_API_KEY');
    return missing;
  }

  /// Print configuration status (debug only)
  void printConfigStatus() {
    if (!kDebugMode) return;

    debugPrint('=== EnvConfig Status ===');
    debugPrint('Gemini API Key: ${geminiApiKey.isNotEmpty ? "SET" : "NOT SET"}');
    debugPrint('Google Maps API Key: ${googleMapsApiKey.isNotEmpty ? "SET" : "NOT SET"}');
    debugPrint('Google Client ID: ${googleClientId.isNotEmpty ? "SET" : "NOT SET"}');
    debugPrint('Debug Logging: $enableDebugLogging');
    debugPrint('Mock Services: $useMockServices');
    debugPrint('Analytics: $enableAnalytics');
    debugPrint('Fully Configured: $isFullyConfigured');
    if (!isFullyConfigured) {
      debugPrint('Missing: ${missingConfiguration.join(", ")}');
    }
    debugPrint('========================');
  }
}

/// Convenience getter for EnvConfig
EnvConfig get envConfig => EnvConfig.instance;
