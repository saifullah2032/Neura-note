import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Application-wide state provider
/// Manages UI state, connectivity, and global settings
class AppStateProvider extends ChangeNotifier {
  // Theme
  ThemeMode _themeMode = ThemeMode.system;
  
  // Navigation
  int _currentNavIndex = 0;
  String? _currentRoute;
  
  // Connectivity
  bool _isOnline = true;
  
  // Loading states
  bool _isInitializing = true;
  bool _isGlobalLoading = false;
  String? _loadingMessage;
  
  // Snackbar/Toast messages
  String? _snackBarMessage;
  bool _isSnackBarError = false;
  
  // Feature flags
  bool _locationServicesEnabled = false;
  bool _notificationsEnabled = false;
  bool _calendarAccessGranted = false;
  
  // App lifecycle
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  // Getters
  ThemeMode get themeMode => _themeMode;
  int get currentNavIndex => _currentNavIndex;
  String? get currentRoute => _currentRoute;
  bool get isOnline => _isOnline;
  bool get isInitializing => _isInitializing;
  bool get isGlobalLoading => _isGlobalLoading;
  String? get loadingMessage => _loadingMessage;
  String? get snackBarMessage => _snackBarMessage;
  bool get isSnackBarError => _isSnackBarError;
  bool get locationServicesEnabled => _locationServicesEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get calendarAccessGranted => _calendarAccessGranted;
  AppLifecycleState get lifecycleState => _lifecycleState;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  bool get isAppActive => _lifecycleState == AppLifecycleState.resumed;

  /// Initialize app state
  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    try {
      // Load saved preferences
      await _loadSavedPreferences();
      
      // Check permissions status
      await _checkPermissionsStatus();
      
    } catch (e) {
      debugPrint('AppStateProvider initialization error: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Load saved preferences (theme, etc.)
  Future<void> _loadSavedPreferences() async {
    // TODO: Load from SharedPreferences
    // For now, use defaults
  }

  /// Check permissions status
  Future<void> _checkPermissionsStatus() async {
    // TODO: Check actual permissions
    // For now, use defaults
  }

  // Theme methods
  
  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      // TODO: Save to SharedPreferences
    }
  }

  /// Toggle between light and dark
  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  /// Use system theme
  void useSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  // Navigation methods

  /// Set current navigation index
  void setNavIndex(int index) {
    if (_currentNavIndex != index) {
      _currentNavIndex = index;
      notifyListeners();
    }
  }

  /// Set current route
  void setCurrentRoute(String route) {
    _currentRoute = route;
    notifyListeners();
  }

  // Connectivity methods

  /// Update online status
  void setOnlineStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      notifyListeners();
      
      if (!isOnline) {
        showSnackBar('You are offline', isError: true);
      }
    }
  }

  // Loading methods

  /// Set global loading state
  void setGlobalLoading(bool isLoading, {String? message}) {
    _isGlobalLoading = isLoading;
    _loadingMessage = isLoading ? message : null;
    notifyListeners();
  }

  /// Start loading with message
  void startLoading([String? message]) {
    setGlobalLoading(true, message: message);
  }

  /// Stop loading
  void stopLoading() {
    setGlobalLoading(false);
  }

  // Snackbar methods

  /// Show snackbar message
  void showSnackBar(String message, {bool isError = false}) {
    _snackBarMessage = message;
    _isSnackBarError = isError;
    notifyListeners();
  }

  /// Clear snackbar message
  void clearSnackBar() {
    _snackBarMessage = null;
    _isSnackBarError = false;
    notifyListeners();
  }

  /// Show success message
  void showSuccess(String message) {
    showSnackBar(message, isError: false);
  }

  /// Show error message
  void showError(String message) {
    showSnackBar(message, isError: true);
  }

  // Permission methods

  /// Update location services status
  void setLocationServicesEnabled(bool enabled) {
    if (_locationServicesEnabled != enabled) {
      _locationServicesEnabled = enabled;
      notifyListeners();
    }
  }

  /// Update notifications status
  void setNotificationsEnabled(bool enabled) {
    if (_notificationsEnabled != enabled) {
      _notificationsEnabled = enabled;
      notifyListeners();
    }
  }

  /// Update calendar access status
  void setCalendarAccessGranted(bool granted) {
    if (_calendarAccessGranted != granted) {
      _calendarAccessGranted = granted;
      notifyListeners();
    }
  }

  /// Check if all required permissions are granted
  bool get hasRequiredPermissions =>
      _locationServicesEnabled && _notificationsEnabled;

  /// Check if all optional permissions are granted
  bool get hasAllPermissions =>
      _locationServicesEnabled &&
      _notificationsEnabled &&
      _calendarAccessGranted;

  // Lifecycle methods

  /// Update app lifecycle state
  void setLifecycleState(AppLifecycleState state) {
    if (_lifecycleState != state) {
      _lifecycleState = state;
      notifyListeners();

      // Handle lifecycle changes
      switch (state) {
        case AppLifecycleState.resumed:
          _onAppResumed();
          break;
        case AppLifecycleState.paused:
          _onAppPaused();
          break;
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
        case AppLifecycleState.hidden:
          break;
      }
    }
  }

  void _onAppResumed() {
    // Refresh data, check permissions, etc.
  }

  void _onAppPaused() {
    // Save state, stop background tasks, etc.
  }

  // Utility methods

  /// Reset app state (for logout)
  void reset() {
    _currentNavIndex = 0;
    _currentRoute = null;
    _isGlobalLoading = false;
    _loadingMessage = null;
    _snackBarMessage = null;
    _isSnackBarError = false;
    notifyListeners();
  }

  /// Complete initialization
  void completeInitialization() {
    _isInitializing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
