import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';
import '../repo/auth_repo.dart';

/// Authentication state
enum AuthState {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

/// Provider for authentication state management
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  
  AuthState _state = AuthState.initial;
  User? _firebaseUser;
  UserModel? _user;
  String? _errorMessage;
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<UserModel?>? _userSubscription;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository() {
    _init();
  }

  // Getters
  AuthState get state => _state;
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.authenticating;
  String? get userId => _firebaseUser?.uid;

  /// Initialize auth state listener
  void _init() {
    _authStateSubscription = _authRepository.authStateChanges.listen(
      _handleAuthStateChange,
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  /// Handle auth state changes
  Future<void> _handleAuthStateChange(User? user) async {
    _firebaseUser = user;

    if (user == null) {
      _user = null;
      _userSubscription?.cancel();
      _setState(AuthState.unauthenticated);
    } else {
      // Subscribe to user document changes
      _userSubscription?.cancel();
      _userSubscription = _authRepository.userStream(user.uid).listen(
        (userModel) {
          _user = userModel;
          _setState(AuthState.authenticated);
        },
        onError: (error) {
          _setError(error.toString());
        },
      );
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setState(AuthState.authenticating);
      _clearError();

      final userCredential = await _authRepository.signInWithGoogle();
      
      if (userCredential == null) {
        _setState(AuthState.unauthenticated);
        return false;
      }

      return true;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setState(AuthState.authenticating);
      _clearError();

      await _authRepository.signInWithEmail(email, password);
      return true;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    }
  }

  /// Create account with email and password
  Future<bool> createAccount(String email, String password) async {
    try {
      _setState(AuthState.authenticating);
      _clearError();

      await _authRepository.createAccountWithEmail(email, password);
      return true;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _clearError();
      await _authRepository.signOut();
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
    }
  }

  /// Update user profile
  Future<bool> updateProfile({String? displayName, String? photoUrl}) async {
    if (_firebaseUser == null) return false;

    try {
      _clearError();
      await _authRepository.updateUserProfile(
        _firebaseUser!.uid,
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Update user preferences
  Future<bool> updatePreferences(UserPreferences preferences) async {
    if (_firebaseUser == null) return false;

    try {
      _clearError();
      await _authRepository.updateUserPreferences(
        _firebaseUser!.uid,
        preferences,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    try {
      _clearError();
      await _authRepository.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    if (_firebaseUser == null) return false;

    try {
      _clearError();
      
      // Re-authenticate first for security
      final result = await _authRepository.reauthenticateWithGoogle();
      if (result == null) {
        _setError('Re-authentication required');
        return false;
      }

      await _authRepository.deleteAccount(_firebaseUser!.uid);
      return true;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    }
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    if (_firebaseUser == null) return;

    try {
      _user = await _authRepository.getUserById(_firebaseUser!.uid);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Set state and notify listeners
  void _setState(AuthState state) {
    _state = state;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _state = AuthState.error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Convert Firebase exceptions to user-friendly messages
  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'email-already-in-use':
          return 'An account already exists with this email';
        case 'invalid-email':
          return 'Invalid email address';
        case 'weak-password':
          return 'Password is too weak';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later';
        case 'network-request-failed':
          return 'Network error. Please check your connection';
        default:
          return error.message ?? 'Authentication error';
      }
    }
    return error.toString();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
