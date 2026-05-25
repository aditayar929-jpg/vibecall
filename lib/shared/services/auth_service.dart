import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isLoggedIn => _auth.currentUser != null;
  bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  // ─── Email & Password Login ───────────────────────────────────────

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _updateUserOnlineStatus(true);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Create user document in Firestore
      await _createUserDocument(credential.user!, name: name);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ─── Google Sign-In ──────────────────────────────────────────────

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create user doc if new
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(
          userCredential.user!,
          name: googleUser.displayName ?? 'User',
        );
      }

      await _updateUserOnlineStatus(true);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  // ─── Guest / Anonymous Login ─────────────────────────────────────

  Future<UserCredential> signInAsGuest() async {
    try {
      final credential = await _auth.signInAnonymously();

      await _createUserDocument(
        credential.user!,
        name: 'Guest User',
        isGuest: true,
      );

      await _updateUserOnlineStatus(true);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ─── Phone OTP ───────────────────────────────────────────────────

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(UserCredential credential) onVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCredential = await _auth.signInWithCredential(credential);
        await _createUserDocument(userCredential.user!, name: 'User');
        onVerified(userCredential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(_handleAuthError(e));
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> verifyOtpCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      await _updateUserOnlineStatus(true);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _updateUserOnlineStatus(false);
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── Password Reset ──────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ─── Delete Account ──────────────────────────────────────────────

  Future<void> deleteAccount() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).delete();
      }
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ─── Private Helpers ─────────────────────────────────────────────

  Future<void> _createUserDocument(
    User user, {
    String name = 'User',
    bool isGuest = false,
  }) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final doc = await userDoc.get();

    if (!doc.exists) {
      await userDoc.set({
        'uid': user.uid,
        'name': name,
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'avatar': user.photoURL ?? '',
        'photos': <String>[],
        'bio': '',
        'gender': '',
        'age': 0,
        'location': '',
        'interests': <String>[],
        'isOnline': true,
        'isVerified': false,
        'isPremium': false,
        'isGuest': isGuest,
        'coins': 50,
        'followers': 0,
        'following': 0,
        'profileCompletion': isGuest ? 10 : 30,
        'blockedUsers': <String>[],
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'fcmToken': '',
      });
    }
  }

  Future<void> _updateUserOnlineStatus(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'No internet connection';
      case 'invalid-verification-code':
        return 'Invalid OTP code';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
