/// User model representing authenticated user data
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final UserPreferences preferences;
  final TokenBalance tokenBalance;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    required this.preferences,
    required this.tokenBalance,
  });

  /// Create UserModel from Firebase User and additional data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      preferences: UserPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>? ?? {},
      ),
      tokenBalance: TokenBalance.fromJson(
        json['tokenBalance'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'preferences': preferences.toJson(),
      'tokenBalance': tokenBalance.toJson(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserPreferences? preferences,
    TokenBalance? tokenBalance,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      tokenBalance: tokenBalance ?? this.tokenBalance,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

/// User preferences for app behavior
class UserPreferences {
  final bool notificationsEnabled;
  final bool locationRemindersEnabled;
  final bool calendarSyncEnabled;
  final int defaultGeofenceRadius; // in meters
  final String preferredLanguage;

  const UserPreferences({
    this.notificationsEnabled = true,
    this.locationRemindersEnabled = true,
    this.calendarSyncEnabled = true,
    this.defaultGeofenceRadius = 200,
    this.preferredLanguage = 'en',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      locationRemindersEnabled: json['locationRemindersEnabled'] as bool? ?? true,
      calendarSyncEnabled: json['calendarSyncEnabled'] as bool? ?? true,
      defaultGeofenceRadius: json['defaultGeofenceRadius'] as int? ?? 200,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'locationRemindersEnabled': locationRemindersEnabled,
      'calendarSyncEnabled': calendarSyncEnabled,
      'defaultGeofenceRadius': defaultGeofenceRadius,
      'preferredLanguage': preferredLanguage,
    };
  }

  UserPreferences copyWith({
    bool? notificationsEnabled,
    bool? locationRemindersEnabled,
    bool? calendarSyncEnabled,
    int? defaultGeofenceRadius,
    String? preferredLanguage,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationRemindersEnabled: locationRemindersEnabled ?? this.locationRemindersEnabled,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
      defaultGeofenceRadius: defaultGeofenceRadius ?? this.defaultGeofenceRadius,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}

/// Token balance for usage tracking
class TokenBalance {
  final int totalTokens;
  final int usedTokens;
  final DateTime? lastRefreshedAt;
  final DateTime? expiresAt;

  const TokenBalance({
    this.totalTokens = 100,
    this.usedTokens = 0,
    this.lastRefreshedAt,
    this.expiresAt,
  });

  int get remainingTokens => totalTokens - usedTokens;
  
  double get usagePercentage => totalTokens > 0 ? (usedTokens / totalTokens) * 100 : 0;

  bool get hasTokens => remainingTokens > 0;

  factory TokenBalance.fromJson(Map<String, dynamic> json) {
    return TokenBalance(
      totalTokens: json['totalTokens'] as int? ?? 100,
      usedTokens: json['usedTokens'] as int? ?? 0,
      lastRefreshedAt: json['lastRefreshedAt'] != null
          ? DateTime.parse(json['lastRefreshedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTokens': totalTokens,
      'usedTokens': usedTokens,
      'lastRefreshedAt': lastRefreshedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  TokenBalance copyWith({
    int? totalTokens,
    int? usedTokens,
    DateTime? lastRefreshedAt,
    DateTime? expiresAt,
  }) {
    return TokenBalance(
      totalTokens: totalTokens ?? this.totalTokens,
      usedTokens: usedTokens ?? this.usedTokens,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
