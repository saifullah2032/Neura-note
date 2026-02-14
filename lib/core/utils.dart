import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility functions for the app
class AppUtils {
  AppUtils._();

  // ==================== ID Generation ====================

  /// Generate a unique ID
  static String generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final randomPart = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    return '$timestamp$randomPart';
  }

  /// Generate a short ID (8 characters)
  static String generateShortId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // ==================== Date/Time Formatting ====================

  /// Format date to readable string (e.g., "Mar 15, 2026")
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Format date to short string (e.g., "Mar 15")
  static String formatDateShort(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  /// Format time to readable string (e.g., "3:30 PM")
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  /// Format date and time (e.g., "Mar 15, 2026 at 3:30 PM")
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y \'at\' h:mm a').format(dateTime);
  }

  /// Format date as relative time (e.g., "2 hours ago", "Yesterday")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime); // Day name
    } else {
      return formatDate(dateTime);
    }
  }

  /// Format duration (e.g., "5:30" for 5 minutes 30 seconds)
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ==================== String Utilities ====================

  /// Truncate string with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitalize each word
  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Check if string is valid email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Remove extra whitespace
  static String normalizeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ==================== Number Formatting ====================

  /// Format number with commas (e.g., 1,234,567)
  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  /// Format file size (e.g., "1.5 MB")
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Format percentage
  static String formatPercentage(double value, {int decimals = 0}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  // ==================== Distance Utilities ====================

  /// Format distance (e.g., "500 m", "2.5 km")
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Calculate distance between two coordinates (Haversine formula)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000; // meters
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;
    final deltaLat = (lat2 - lat1) * pi / 180;
    final deltaLon = (lon2 - lon1) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // ==================== Validation Utilities ====================

  /// Validate coordinates
  static bool isValidCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // ==================== Color Utilities ====================

  /// Get color with opacity (uses modern withValues API)
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity.clamp(0.0, 1.0));
  }

  /// Lighten a color
  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Darken a color
  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  // ==================== Misc Utilities ====================

  /// Delay execution
  static Future<void> delay([int milliseconds = 300]) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// Safe parse int
  static int? tryParseInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Safe parse double
  static double? tryParseDouble(String? value) {
    if (value == null) return null;
    return double.tryParse(value);
  }

  /// Get initials from name (e.g., "John Doe" -> "JD")
  static String getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  /// Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

/// Extension methods for DateTime
extension DateTimeExtensions on DateTime {
  /// Check if this date is today
  bool get isToday => AppUtils.isToday(this);

  /// Check if this date is tomorrow
  bool get isTomorrow => AppUtils.isTomorrow(this);

  /// Check if this date is in the past
  bool get isPast => AppUtils.isPast(this);

  /// Format to readable string
  String get formatted => AppUtils.formatDateTime(this);

  /// Format to relative time
  String get relative => AppUtils.formatRelativeTime(this);

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}

/// Extension methods for String
extension StringExtensions on String {
  /// Truncate with ellipsis
  String truncate(int maxLength) => AppUtils.truncate(this, maxLength);

  /// Capitalize first letter
  String get capitalized => AppUtils.capitalize(this);

  /// Capitalize each word
  String get capitalizedWords => AppUtils.capitalizeWords(this);

  /// Check if valid email
  bool get isValidEmail => AppUtils.isValidEmail(this);

  /// Normalize whitespace
  String get normalized => AppUtils.normalizeWhitespace(this);
}

/// Extension methods for int
extension IntExtensions on int {
  /// Format with commas
  String get formatted => AppUtils.formatNumber(this);

  /// Format as file size
  String get asFileSize => AppUtils.formatFileSize(this);
}

/// Extension methods for double
extension DoubleExtensions on double {
  /// Format as distance
  String get asDistance => AppUtils.formatDistance(this);

  /// Format as percentage
  String asPercentage({int decimals = 0}) =>
      AppUtils.formatPercentage(this, decimals: decimals);
}

/// Extension methods for Duration
extension DurationExtensions on Duration {
  /// Format as MM:SS
  String get formatted => AppUtils.formatDuration(this);
}
