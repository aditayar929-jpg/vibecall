import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> verifyPhoneNumber(
    String phone,
    Function(String) onCodeSent,
    Function(String) onError,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> verifyOtp(String verificationId, String otp) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Firestore - Users
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Stream<UserModel?> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null,
        );
  }

  Future<List<UserModel>> getDiscoverUsers({
    String? gender,
    int? minAge,
    int? maxAge,
    int limit = 20,
  }) async {
    Query query = _firestore.collection('users');

    if (gender != null && gender != 'All') {
      query = query.where('gender', isEqualTo: gender);
    }

    query = query.limit(limit);
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Storage
  Future<String> uploadFile(String path, File file) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadProfilePhoto(String uid, File file) async {
    return await uploadFile('users/$uid/profile/${DateTime.now().millisecondsSinceEpoch}.jpg', file);
  }

  // Chat
  Future<void> sendMessage(String chatId, Map<String, dynamic> message) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      ...message,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message['text'],
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // Matching queue
  Future<void> addToMatchingQueue(String uid, Map<String, dynamic> preferences) async {
    await _firestore.collection('matching_queue').doc(uid).set({
      'uid': uid,
      'preferences': preferences,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'waiting',
    });
  }

  Future<void> removeFromMatchingQueue(String uid) async {
    await _firestore.collection('matching_queue').doc(uid).delete();
  }

  // Coins
  Future<void> updateCoins(String uid, int amount) async {
    await _firestore.collection('users').doc(uid).update({
      'coins': FieldValue.increment(amount),
    });
  }

  // Report
  Future<void> reportUser(String reporterId, String reportedId, String reason) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'reportedId': reportedId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  // Block
  Future<void> blockUser(String userId, String blockedUserId) async {
    await _firestore.collection('users').doc(userId).update({
      'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
    });
  }
}
