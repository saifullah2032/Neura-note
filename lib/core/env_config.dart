library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:neuranotteai/core/constants.dart';

class EnvConfig {
  EnvConfig._();

  static final EnvConfig _instance = EnvConfig._();
  static EnvConfig get instance => _instance;

  String get googleMapsApiKey {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (key.isEmpty && kDebugMode) {
      debugPrint('WARNING: GOOGLE_MAPS_API_KEY not set. Geocoding will not work.');
    }
    return key;
  }

  String get googleClientId {
    return dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  }

  String get groqApiKey {
    final key = dotenv.env['GROQ_API_KEY'] ?? AppConstants.groqApiKey;
    if (key.isEmpty && kDebugMode) {
      debugPrint('WARNING: GROQ_API_KEY not set. Audio transcription will not work.');
    }
    return key;
  }

  String get huggingFaceApiKey {
    final key = dotenv.env['HUGGINGFACE_API_KEY'] ?? AppConstants.huggingFaceApiKey;
    if (key.isEmpty && kDebugMode) {
      debugPrint('WARNING: HUGGINGFACE_API_KEY not set. Image analysis will not work.');
    }
    return key;
  }

  bool get enableDebugLogging {
    final enabled = dotenv.env['ENABLE_DEBUG_LOGGING'] ?? kDebugMode.toString();
    return enabled == 'true';
  }

  bool get useMockServices {
    final mock = dotenv.env['USE_MOCK_SERVICES'] ?? 'false';
    return mock == 'true';
  }

  bool get enableAnalytics {
    final enabled = dotenv.env['ENABLE_ANALYTICS'] ?? (!kDebugMode).toString();
    return enabled == 'true';
  }

  String get geocodingBaseUrl {
    return dotenv.env['GEOCODING_BASE_URL'] ?? 'https://maps.googleapis.com/maps/api/geocode';
  }

  String get groqBaseUrl {
    return dotenv.env['GROQ_BASE_URL'] ?? AppConstants.groqBaseUrl;
  }

  String get huggingFaceBaseUrl {
    return dotenv.env['HUGGINGFACE_BASE_URL'] ?? AppConstants.huggingFaceBaseUrl;
  }

  double get defaultGeofenceRadius {
    final radius = dotenv.env['DEFAULT_GEOFENCE_RADIUS'] ?? '200';
    return double.tryParse(radius) ?? 200.0;
  }

  double get minGeofenceRadius {
    final radius = dotenv.env['MIN_GEOFENCE_RADIUS'] ?? '50';
    return double.tryParse(radius) ?? 50.0;
  }

  double get maxGeofenceRadius {
    final radius = dotenv.env['MAX_GEOFENCE_RADIUS'] ?? '1000';
    return double.tryParse(radius) ?? 1000.0;
  }

  int get defaultReminderMinutesBefore {
    final minutes = dotenv.env['DEFAULT_REMINDER_MINUTES'] ?? '15';
    return int.tryParse(minutes) ?? 15;
  }

  int get maxUploadFileSize {
    final size = dotenv.env['MAX_UPLOAD_FILE_SIZE'] ?? (10 * 1024 * 1024).toString();
    return int.tryParse(size) ?? 10485760;
  }

  int get maxRecordingDuration {
    final duration = dotenv.env['MAX_RECORDING_DURATION'] ?? '300';
    return int.tryParse(duration) ?? 300;
  }

  String get groqWhisperModel {
    return dotenv.env['GROQ_WHISPER_MODEL'] ?? AppConstants.groqWhisperModel;
  }

  String get huggingFaceImageModel {
    return dotenv.env['HUGGINGFACE_IMAGE_MODEL'] ?? AppConstants.huggingFaceImageModel;
  }

  bool get isFullyConfigured {
    return googleMapsApiKey.isNotEmpty &&
           groqApiKey.isNotEmpty &&
           huggingFaceApiKey.isNotEmpty;
  }

  List<String> get missingConfiguration {
    final missing = <String>[];
    if (googleMapsApiKey.isEmpty) missing.add('GOOGLE_MAPS_API_KEY');
    if (groqApiKey.isEmpty) missing.add('GROQ_API_KEY');
    if (huggingFaceApiKey.isEmpty) missing.add('HUGGINGFACE_API_KEY');
    return missing;
  }

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

EnvConfig get envConfig => EnvConfig.instance;
