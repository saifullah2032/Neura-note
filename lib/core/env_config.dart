/// Environment configuration for NeuraNote AI
///
/// This file provides a centralized place for all API keys and configuration.
/// For production, use environment variables or a secure secrets manager.
///
/// IMPORTANT: Never commit actual API keys to version control!
/// Use --dart-define or environment variables for sensitive values.
library;

import 'package:flutter/foundation.dart';
import 'package:neuranotteai/core/constants.dart';

/// Environment configuration singleton
class EnvConfig {
  EnvConfig._();

  static final EnvConfig _instance = EnvConfig._();
  static EnvConfig get instance => _instance;

  // ============================================================
  // API Keys - Use --dart-define for production
  // Example: flutter run --dart-define=GROQ_API_KEY=your_key
  // ============================================================

  /// Google Maps API Key for geocoding
  /// Set via: --dart-define=GOOGLE_MAPS_API_KEY=your_key
  /// Falls back to hardcoded value in AppConstants if not set
  String get googleMapsApiKey {
    const key = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: AppConstants.googleMapsApiKey,
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

  /// Groq API Key for Whisper audio transcription
  /// Set via: --dart-define=GROQ_API_KEY=your_key
  /// Falls back to hardcoded value in AppConstants if not set
  String get groqApiKey {
    const key = String.fromEnvironment(
      'GROQ_API_KEY',
      defaultValue: AppConstants.groqApiKey,
    );
    if (key.isEmpty && kDebugMode) {
      debugPrint('WARNING: GROQ_API_KEY not set. Using fallback or audio transcription will not work.');
    }
    return key;
  }

  /// Hugging Face API Key for image analysis
  /// Set via: --dart-define=HUGGINGFACE_API_KEY=your_key
  /// Falls back to hardcoded value in AppConstants if not set
  String get huggingFaceApiKey {
    const key = String.fromEnvironment(
      'HUGGINGFACE_API_KEY',
      defaultValue: AppConstants.huggingFaceApiKey,
    );
    if (key.isEmpty && kDebugMode) {
      debugPrint('WARNING: HUGGINGFACE_API_KEY not set. Using fallback or image analysis will not work.');
    }
    return key;
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

  /// Google Maps Geocoding API base URL
  String get geocodingBaseUrl {
    const url = String.fromEnvironment(
      'GEOCODING_BASE_URL',
      defaultValue: 'https://maps.googleapis.com/maps/api/geocode',
    );
    return url;
  }

  /// Groq API base URL
  String get groqBaseUrl {
    const url = String.fromEnvironment(
      'GROQ_BASE_URL',
      defaultValue: 'https://api.groq.com/openai/v1',
    );
    return url;
  }

  /// Hugging Face API base URL
  String get huggingFaceBaseUrl {
    const url = String.fromEnvironment(
      'HUGGINGFACE_BASE_URL',
      defaultValue: 'https://router.huggingface.co',
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
  // AI Model Configuration
  // ============================================================

  /// Groq Whisper model to use
  String get groqWhisperModel {
    const model = String.fromEnvironment(
      'GROQ_WHISPER_MODEL',
      defaultValue: AppConstants.groqWhisperModel,
    );
    return model;
  }

  /// Hugging Face model for image captioning/analysis
  String get huggingFaceImageModel {
    const model = String.fromEnvironment(
      'HUGGINGFACE_IMAGE_MODEL',
      defaultValue: AppConstants.huggingFaceImageModel,
    );
    return model;
  }

  // ============================================================
  // Validation
  // ============================================================

  /// Check if all required API keys are configured
  bool get isFullyConfigured {
    return googleMapsApiKey.isNotEmpty &&
           groqApiKey.isNotEmpty &&
           huggingFaceApiKey.isNotEmpty;
  }

  /// Get list of missing configuration items
  List<String> get missingConfiguration {
    final missing = <String>[];
    if (googleMapsApiKey.isEmpty) missing.add('GOOGLE_MAPS_API_KEY');
    if (groqApiKey.isEmpty) missing.add('GROQ_API_KEY');
    if (huggingFaceApiKey.isEmpty) missing.add('HUGGINGFACE_API_KEY');
    return missing;
  }

  /// Print configuration status (debug only)
  void printConfigStatus() {
    if (!kDebugMode) return;

    debugPrint('=== EnvConfig Status ===');
    debugPrint('Google Maps API Key: ${googleMapsApiKey.isNotEmpty ? "SET" : "NOT SET"}');
    debugPrint('Google Client ID: ${googleClientId.isNotEmpty ? "SET" : "NOT SET"}');
    debugPrint('Groq API Key: ${groqApiKey.isNotEmpty ? "SET" : "NOT SET"}');
    debugPrint('Hugging Face API Key: ${huggingFaceApiKey.isNotEmpty ? "SET" : "NOT SET"}');
    debugPrint('Groq Whisper Model: $groqWhisperModel');
    debugPrint('Hugging Face Image Model: $huggingFaceImageModel');
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
