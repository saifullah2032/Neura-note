import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';

/// Repository for authentication operations
class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for users
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get the current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream of user document changes
  Stream<UserModel?> userStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserModel.fromJson(snapshot.data()!);
    });
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document
      if (userCredential.user != null) {
        await _createOrUpdateUserDocument(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      if (userCredential.user != null) {
        await _updateLastLogin(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Create account with email and password
  Future<UserCredential> createAccountWithEmail(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document
      if (userCredential.user != null) {
        await _createOrUpdateUserDocument(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Get user model by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final snapshot = await _usersCollection.doc(uid).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserModel.fromJson(snapshot.data()!);
    } catch (e) {
      rethrow;
    }
  }

  /// Create or update user document in Firestore
  Future<void> _createOrUpdateUserDocument(User user) async {
    final userDoc = _usersCollection.doc(user.uid);
    final snapshot = await userDoc.get();

    if (snapshot.exists) {
      // Update existing user
      await userDoc.update({
        'lastLoginAt': DateTime.now().toIso8601String(),
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
      });
    } else {
      // Create new user
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        preferences: const UserPreferences(),
        tokenBalance: const TokenBalance(
          totalTokens: 100, // Free signup tokens
          usedTokens: 0,
        ),
      );

      await userDoc.set(newUser.toJson());
    }
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    await _usersCollection.doc(uid).update({
      'lastLoginAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, {
    String? displayName,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    
    if (updates.isNotEmpty) {
      await _usersCollection.doc(uid).update(updates);
    }
  }

  /// Update user preferences
  Future<void> updateUserPreferences(
    String uid,
    UserPreferences preferences,
  ) async {
    await _usersCollection.doc(uid).update({
      'preferences': preferences.toJson(),
    });
  }

  /// Update user token balance
  Future<void> updateTokenBalance(String uid, TokenBalance balance) async {
    await _usersCollection.doc(uid).update({
      'tokenBalance': balance.toJson(),
    });
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Delete user account
  Future<void> deleteAccount(String uid) async {
    // Delete user document
    await _usersCollection.doc(uid).delete();
    
    // Delete Firebase auth account
    await _auth.currentUser?.delete();
  }

  /// Reauthenticate user (for sensitive operations)
  Future<UserCredential?> reauthenticateWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.currentUser?.reauthenticateWithCredential(credential);
  }

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    return methods.isNotEmpty;
  }
}
