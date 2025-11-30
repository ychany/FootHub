import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create/update user document in Firestore
      await _createOrUpdateUser(userCredential.user);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _createOrUpdateUser(userCredential.user);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      await _createOrUpdateUser(userCredential.user);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Create or update user document in Firestore
  Future<void> _createOrUpdateUser(User? user) async {
    if (user == null) return;

    final userDoc = _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid);

    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // Create new user document
      final newUser = UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        favoriteTeamIds: [],
        favoritePlayerIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await userDoc.set(newUser.toFirestore());
    } else {
      // Update last login
      await userDoc.update({
        'updatedAt': Timestamp.now(),
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
      });
    }
  }

  // Get user model
  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Stream user model
  Stream<UserModel?> userModelStream(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'updatedAt': Timestamp.now(),
    };

    if (displayName != null) {
      updates['displayName'] = displayName;
      await user.updateDisplayName(displayName);
    }

    if (photoUrl != null) {
      updates['photoUrl'] = photoUrl;
      await user.updatePhotoURL(photoUrl);
    }

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update(updates);

    // Firebase User 객체 갱신
    await user.reload();
  }

  // Delete account
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    // Delete user document
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .delete();

    // Delete Firebase Auth user
    await user.delete();
  }
}
