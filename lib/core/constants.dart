import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide constants
class AppConstants {
  AppConstants._();

  static Future<void> loadEnv() async {
    await dotenv.load(fileName: ".env");
  }

  // App Info
  static const String appName = 'NeuraNote AI';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // API Endpoints (placeholder - replace with actual endpoints)
  static const String baseUrl = 'https://api.neuranote.ai';
  static const String apiVersion = 'v1';
  
  // API Routes
  static const String summarizeImageEndpoint = '/summarize/image';
  static const String summarizeAudioEndpoint = '/summarize/audio';
  static const String extractEntitiesEndpoint = '/extract/entities';
  static const String userEndpoint = '/user';
  static const String tokensEndpoint = '/tokens';
  static const String remindersEndpoint = '/reminders';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String summariesCollection = 'summaries';
  static const String remindersCollection = 'reminders';
  static const String tokensCollection = 'token_transactions';

  // Storage Paths
  static const String imagesStoragePath = 'images';
  static const String audioStoragePath = 'audio';
  static const String thumbnailsStoragePath = 'thumbnails';

  // Token Configuration
  static const int defaultTokensForNewUser = 100;
  static const int tokensPerImageSummary = 1;
  static const int tokensPerVoiceSummary = 2;
  static const int maxFreeTokens = 100;

  // Geofence Configuration
  static const double defaultGeofenceRadiusMeters = 200;
  static const double minGeofenceRadiusMeters = 50;
  static const double maxGeofenceRadiusMeters = 5000;
  static const List<double> geofenceRadiusOptions = [100, 200, 500, 1000, 2000];

  // Location Configuration
  static const int locationUpdateIntervalMs = 30000; // 30 seconds
  static const int locationFastestIntervalMs = 15000; // 15 seconds
  static const double locationMinDisplacementMeters = 50;

  // AI Configuration
  static const int maxSummaryLength = 500;
  static const double minConfidenceScore = 0.7;
  static const int apiTimeoutSeconds = 30;

  // Image Configuration
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int thumbnailSize = 200;
  static const int imageQuality = 85;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];

  // Audio Configuration
  static const int maxAudioDurationSeconds = 300; // 5 minutes
  static const int audioSampleRate = 44100;
  static const List<String> supportedAudioFormats = ['m4a', 'wav', 'mp3'];

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardBorderRadius = 18.0;
  static const double buttonBorderRadius = 30.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Cache Configuration
  static const int cacheMaxAgeHours = 24;
  static const int maxCachedItems = 100;

  // Notification Configuration
  static const String notificationChannelId = 'neuranote_reminders';
  static const String notificationChannelName = 'Reminders';
  static const String notificationChannelDescription = 'Location and calendar reminders';

  // Calendar Configuration
  static const int defaultReminderMinutesBefore = 15;
  static const List<int> reminderMinutesOptions = [5, 10, 15, 30, 60];

  // Error Messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'No internet connection. Please check your network.';
  static const String authErrorMessage = 'Authentication failed. Please sign in again.';
  static const String tokenErrorMessage = 'Insufficient tokens. Please purchase more.';
  static const String locationErrorMessage = 'Location services are disabled. Please enable them.';
  static const String permissionErrorMessage = 'Permission denied. Please grant the required permissions.';

  // API Keys Configuration
  // Loaded from .env file
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get huggingFaceApiKey => dotenv.env['HUGGINGFACE_API_KEY'] ?? '';
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Cloudinary Configuration
  static String get cloudinaryCloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get cloudinaryApiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get cloudinaryApiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  // AI Service Base URLs
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String huggingFaceBaseUrl = 'https://router.huggingface.co';

  // AI Model Configuration
  static const String groqWhisperModel = 'whisper-large-v3';
  static const String huggingFaceImageModel = 'Salesforce/blip-image-captioning-base';
  static const String huggingFaceTextModel = 'facebook/bart-large-cnn';
}

/// Route names for navigation
class RouteNames {
  RouteNames._();

  static const String login = 'login';
  static const String home = 'home';
  static const String summary = 'summary';
  static const String profile = 'profile';
  static const String reminders = 'reminders';
  static const String settings = 'settings';
  static const String premium = 'premium';
}

/// Route paths for navigation
class RoutePaths {
  RoutePaths._();

  static const String login = '/';
  static const String home = '/home';
  static const String summary = '/summary';
  static const String summaryDetail = '/summary/:id';
  static const String profile = '/profile';
  static const String reminders = '/reminders';
  static const String settings = '/settings';
  static const String premium = '/premium';
}

/// Asset paths
class AssetPaths {
  AssetPaths._();

  // Animations
  static const String wavingAnimation = 'assets/animations/waving.riv';
  static const String beachWaveAnimation = 'assets/animations/beach_wave.riv';
  static const String loadingAnimation = 'assets/animations/loading-lg.riv';
  static const String elkAnimation = 'assets/animations/elk.riv';
  static const String voiceAnimation = 'assets/animations/voice.riv';

  // Images (if any)
  static const String imagesPath = 'assets/images/';
}

/// Shared Preferences Keys
class PrefsKeys {
  PrefsKeys._();

  static const String isFirstLaunch = 'is_first_launch';
  static const String userId = 'user_id';
  static const String authToken = 'auth_token';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String locationRemindersEnabled = 'location_reminders_enabled';
  static const String calendarSyncEnabled = 'calendar_sync_enabled';
  static const String defaultGeofenceRadius = 'default_geofence_radius';
  static const String preferredLanguage = 'preferred_language';
  static const String themeMode = 'theme_mode';
  static const String lastSyncTime = 'last_sync_time';
}

/// App Colors
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Colors.teal;
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color primaryDark = Color(0xFF00796B);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Other Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);

  // Summary Type Colors
  static const Color imageType = Color(0xFF26A69A);
  static const Color voiceType = Color(0xFF5C6BC0);

  // Reminder Type Colors
  static const Color calendarReminder = Color(0xFF42A5F5);
  static const Color locationReminder = Color(0xFFEF5350);
}
