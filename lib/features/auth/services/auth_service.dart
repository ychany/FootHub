import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
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

  // Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple only provides name on first sign in, update if available
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        final displayName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].where((n) => n != null).join(' ');

        if (displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
        }
      }

      await _createOrUpdateUser(userCredential.user);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Generate random nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // SHA256 hash
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
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

  // Delete account - 모든 사용자 데이터 삭제 후 계정 탈퇴
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    final uid = user.uid;
    final batch = _firestore.batch();

    // 1. 직관 기록 (attendance_records) 삭제
    final attendanceRecords = await _firestore
        .collection(AppConstants.attendanceCollection)
        .where('userId', isEqualTo: uid)
        .get();
    for (final doc in attendanceRecords.docs) {
      batch.delete(doc.reference);
    }

    // 2. 커뮤니티 게시글 (posts) 삭제
    final posts = await _firestore
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .get();
    for (final doc in posts.docs) {
      batch.delete(doc.reference);
    }

    // 3. 커뮤니티 댓글 (comments) 삭제
    final comments = await _firestore
        .collection('comments')
        .where('authorId', isEqualTo: uid)
        .get();
    for (final doc in comments.docs) {
      batch.delete(doc.reference);
    }

    // 4. 좋아요 (likes) 삭제
    final likes = await _firestore
        .collection('likes')
        .where('userId', isEqualTo: uid)
        .get();
    for (final doc in likes.docs) {
      batch.delete(doc.reference);
    }

    // 5. 경기 댓글 (match_comments) 삭제
    final matchComments = await _firestore
        .collection('match_comments')
        .where('userId', isEqualTo: uid)
        .get();
    for (final doc in matchComments.docs) {
      batch.delete(doc.reference);
    }

    // 6. 알림 설정 서브컬렉션 삭제
    final notificationSettings = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection('settings')
        .get();
    for (final doc in notificationSettings.docs) {
      batch.delete(doc.reference);
    }

    // 7. 사용자 문서 삭제
    batch.delete(_firestore.collection(AppConstants.usersCollection).doc(uid));

    // Batch commit
    await batch.commit();

    // Google Sign-In 세션 해제
    await _googleSignIn.signOut();

    // Firebase Auth 계정 삭제 (마지막에 실행)
    await user.delete();
  }
}
