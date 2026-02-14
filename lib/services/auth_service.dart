import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuranotteai/model/user_model.dart';

/// Exception thrown when authentication fails
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, [this.code]);

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// Service responsible for handling authentication operations
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  // Web Client ID from google-services.json (client_type: 3)
  static const String _webClientId = '648242658408-phuioch259vlcqv87mc3racv1psufj5s.apps.googleusercontent.com';

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          serverClientId: _webClientId,
          scopes: [
            'email',
            'https://www.googleapis.com/auth/calendar',
            'https://www.googleapis.com/auth/calendar.events',
          ],
        ),
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Get the current user's UID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Stream of auth state changes
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Stream of user changes (including token refresh)
  Stream<User?> userChanges() => _auth.userChanges();

  /// Sign in with Google
  /// Returns the authenticated Firebase User
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        // Create or update user document in Firestore
        await _createOrUpdateUserDocument(user, userCredential.additionalUserInfo?.isNewUser ?? false);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getReadableAuthError(e.code),
        e.code,
      );
    } catch (e) {
      throw AuthException('Failed to sign in with Google: $e');
    }
  }

  /// Sign out from both Firebase and Google
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  /// Disconnect Google account (revokes access)
  Future<void> disconnectGoogle() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      // Ignore disconnect errors
    }
  }

  /// Get the current Google Sign-In account (for Calendar access)
  Future<GoogleSignInAccount?> getGoogleAccount() async {
    return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  }

  /// Get Google auth headers for API calls
  Future<Map<String, String>?> getGoogleAuthHeaders() async {
    final account = await getGoogleAccount();
    return account?.authHeaders;
  }

  /// Refresh the ID token
  Future<String?> refreshIdToken({bool forceRefresh = false}) async {
    try {
      return await _auth.currentUser?.getIdToken(forceRefresh);
    } catch (e) {
      throw AuthException('Failed to refresh token: $e');
    }
  }

  /// Get the current ID token
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  /// Create or update user document in Firestore
  Future<void> _createOrUpdateUserDocument(User user, bool isNewUser) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final now = DateTime.now();

    if (isNewUser) {
      // Create new user document
      final newUserData = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        createdAt: now,
        lastLoginAt: now,
        preferences: const UserPreferences(),
        tokenBalance: const TokenBalance(
          totalTokens: 100, // Free tokens for new users
          usedTokens: 0,
        ),
      );

      await userRef.set(newUserData.toJson());
    } else {
      // Update last login time
      await userRef.update({
        'lastLoginAt': now.toIso8601String(),
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
      });
    }
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw AuthException('Failed to get user data: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('No user signed in');
    }

    try {
      // Update Firebase Auth profile
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
    } catch (e) {
      throw AuthException('Failed to update profile: $e');
    }
  }

  /// Update user preferences
  Future<void> updateUserPreferences(UserPreferences preferences) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('No user signed in');
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'preferences': preferences.toJson(),
      });
    } catch (e) {
      throw AuthException('Failed to update preferences: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('No user signed in');
    }

    try {
      // Delete Firestore document
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete Firebase Auth account
      await user.delete();
      
      // Sign out from Google
      await _googleSignIn.disconnect();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Please sign in again before deleting your account',
          e.code,
        );
      }
      throw AuthException('Failed to delete account: ${e.message}', e.code);
    } catch (e) {
      throw AuthException('Failed to delete account: $e');
    }
  }

  /// Re-authenticate user (required before sensitive operations)
  Future<void> reauthenticate() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Re-authentication cancelled');
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.currentUser?.reauthenticateWithCredential(credential);
    } catch (e) {
      throw AuthException('Re-authentication failed: $e');
    }
  }

  /// Convert Firebase Auth error codes to readable messages
  String _getReadableAuthError(String code) {
    switch (code) {
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials';
      default:
        return 'Authentication error occurred';
    }
  }
}
