import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ─── User Operations ─────────────────────────────────────────────

  Stream<DocumentSnapshot> get userStream =>
      _firestore.collection('users').doc(_uid).snapshots();

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? gender,
    int? age,
    List<String>? interests,
    String? location,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (bio != null) data['bio'] = bio;
    if (gender != null) data['gender'] = gender;
    if (age != null) data['age'] = age;
    if (interests != null) data['interests'] = interests;
    if (location != null) data['location'] = location;
    data['profileCompletion'] = _calculateCompletion(data);

    await _firestore.collection('users').doc(_uid).update(data);
  }

  Future<void> updateAvatar(String imageUrl) async {
    await _firestore.collection('users').doc(_uid).update({
      'avatar': imageUrl,
    });
  }

  Future<void> updatePhotos(List<String> photoUrls) async {
    await _firestore.collection('users').doc(_uid).update({
      'photos': photoUrls,
    });
  }

  Future<void> updateFcmToken(String token) async {
    await _firestore.collection('users').doc(_uid).update({
      'fcmToken': token,
    });
  }

  // ─── Photo Upload ────────────────────────────────────────────────

  Future<String> uploadPhoto(File file, String folder) async {
    final ref = _storage.ref().child('users/$_uid/$folder/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadProfilePhoto(File file) async {
    return uploadPhoto(file, 'profile');
  }

  // ─── Discovery / Matching ────────────────────────────────────────

  Stream<QuerySnapshot> getOnlineUsers() {
    return _firestore
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .where('uid', isNotEqualTo: _uid)
        .limit(30)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getDiscoverUsers({
    String? genderFilter,
    int? minAge,
    int? maxAge,
    int limit = 20,
  }) async {
    Query query = _firestore.collection('users').where('uid', isNotEqualTo: _uid);

    if (genderFilter != null && genderFilter != 'All') {
      query = query.where('gender', isEqualTo: genderFilter);
    }

    final snapshot = await query.limit(limit).get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .where((user) {
      final age = user['age'] ?? 0;
      if (minAge != null && age < minAge) return false;
      if (maxAge != null && age > maxAge) return false;
      return true;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getTrendingUsers() async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('followers', descending: true)
        .limit(20)
        .get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  // ─── Random Matching ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> findRandomMatch({
    String? genderFilter,
  }) async {
    Query query = _firestore
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .where('uid', isNotEqualTo: _uid);

    if (genderFilter != null && genderFilter != 'All') {
      query = query.where('gender', isEqualTo: genderFilter);
    }

    final snapshot = await query.limit(50).get();
    if (snapshot.docs.isEmpty) return null;

    final users = snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();

    users.shuffle();
    return users.first;
  }

  Future<void> addToMatchingQueue({
    required String genderFilter,
    required int minAge,
    required int maxAge,
  }) async {
    await _firestore.collection('matching_queue').doc(_uid).set({
      'uid': _uid,
      'genderFilter': genderFilter,
      'minAge': minAge,
      'maxAge': maxAge,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'waiting',
    });
  }

  Future<void> removeFromMatchingQueue() async {
    await _firestore.collection('matching_queue').doc(_uid).delete();
  }

  Stream<QuerySnapshot> watchMatchingQueue({String? genderFilter}) {
    Query query = _firestore.collection('matching_queue');
    if (genderFilter != null && genderFilter != 'All') {
      query = query.where('genderFilter', isEqualTo: genderFilter);
    }
    return query.orderBy('timestamp', descending: true).limit(50).snapshots();
  }

  // ─── Follow / Unfollow ───────────────────────────────────────────

  Future<void> followUser(String targetUid) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('users').doc(_uid), {
      'following': FieldValue.increment(1),
    });
    batch.update(_firestore.collection('users').doc(targetUid), {
      'followers': FieldValue.increment(1),
    });

    batch.set(
      _firestore.collection('users').doc(_uid).collection('following').doc(targetUid),
      {'uid': targetUid, 'timestamp': FieldValue.serverTimestamp()},
    );
    batch.set(
      _firestore.collection('users').doc(targetUid).collection('followers').doc(_uid),
      {'uid': _uid, 'timestamp': FieldValue.serverTimestamp()},
    );

    await batch.commit();
  }

  Future<void> unfollowUser(String targetUid) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('users').doc(_uid), {
      'following': FieldValue.increment(-1),
    });
    batch.update(_firestore.collection('users').doc(targetUid), {
      'followers': FieldValue.increment(-1),
    });

    batch.delete(
      _firestore.collection('users').doc(_uid).collection('following').doc(targetUid),
    );
    batch.delete(
      _firestore.collection('users').doc(targetUid).collection('followers').doc(_uid),
    );

    await batch.commit();
  }

  // ─── Like / Match ────────────────────────────────────────────────

  Future<bool> likeUser(String targetUid) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('likes')
        .doc(targetUid)
        .set({'timestamp': FieldValue.serverTimestamp()});

    // Check if they already liked us
    final theirLike = await _firestore
        .collection('users')
        .doc(targetUid)
        .collection('likes')
        .doc(_uid)
        .get();

    if (theirLike.exists) {
      // It's a match!
      await _createMatch(targetUid);
      return true;
    }
    return false;
  }

  Future<void> dislikeUser(String targetUid) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('dislikes')
        .doc(targetUid)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  Future<void> _createMatch(String targetUid) async {
    final matchId = _uid.compareTo(targetUid) < 0
        ? '$_uid\_$targetUid'
        : '${targetUid}\_$_uid';

    await _firestore.collection('matches').doc(matchId).set({
      'users': [_uid, targetUid],
      'matchId': matchId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // Create chat
    await _firestore.collection('chats').doc(matchId).set({
      'matchId': matchId,
      'users': [_uid, targetUid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMatches() {
    return _firestore
        .collection('matches')
        .where('users', arrayContains: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ─── Chat ────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String chatId,
    required String text,
    String type = 'text',
    String? mediaUrl,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    await messageRef.add({
      'senderId': _uid,
      'text': text,
      'type': type,
      'mediaUrl': mediaUrl ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': _uid,
    });
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserChats() {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: _uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final unread = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: _uid)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    await _firestore.collection('chats').doc(chatId).update({
      'typing_$_uid': isTyping,
    });
  }

  Stream<DocumentSnapshot> getChatStream(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots();
  }

  // ─── Video/Audio Call ────────────────────────────────────────────

  Future<String> createCall({
    required String calleeId,
    required String type,
  }) async {
    final callRef = _firestore.collection('calls').doc();
    final channelName = 'vibecall_${callRef.id}';

    await callRef.set({
      'callId': callRef.id,
      'callerId': _uid,
      'calleeId': calleeId,
      'channelName': channelName,
      'type': type,
      'status': 'ringing',
      'startedAt': FieldValue.serverTimestamp(),
    });

    return callRef.id;
  }

  Stream<DocumentSnapshot> getCallStream(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots();
  }

  Stream<QuerySnapshot> getIncomingCalls() {
    return _firestore
        .collection('calls')
        .where('calleeId', isEqualTo: _uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots();
  }

  Future<void> answerCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'active',
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'rejected',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Coins ───────────────────────────────────────────────────────

  Future<int> getCoins() async {
    final doc = await _firestore.collection('users').doc(_uid).get();
    return doc.data()?['coins'] ?? 0;
  }

  Future<void> addCoins(int amount, String reason) async {
    await _firestore.collection('users').doc(_uid).update({
      'coins': FieldValue.increment(amount),
    });
    await _firestore.collection('users').doc(_uid).collection('transactions').add({
      'amount': amount,
      'type': 'earn',
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deductCoins(int amount, String reason) async {
    await _firestore.collection('users').doc(_uid).update({
      'coins': FieldValue.increment(-amount),
    });
    await _firestore.collection('users').doc(_uid).collection('transactions').add({
      'amount': -amount,
      'type': 'spend',
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> hasEnoughCoins(int amount) async {
    final coins = await getCoins();
    return coins >= amount;
  }

  // ─── Matching Queue ──────────────────────────────────────────────

  Future<void> addToMatchingQueue({
    String genderFilter = 'All',
    int minAge = 18,
    int maxAge = 35,
  }) async {
    await _firestore.collection('matching_queue').doc(_uid).set({
      'uid': _uid,
      'genderFilter': genderFilter,
      'minAge': minAge,
      'maxAge': maxAge,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'waiting',
    });
  }

  Future<void> removeFromMatchingQueue() async {
    await _firestore.collection('matching_queue').doc(_uid).delete();
  }

  // ─── Report / Block ──────────────────────────────────────────────

  Future<void> reportUser(String targetUid, String reason) async {
    await _firestore.collection('reports').add({
      'reporterId': _uid,
      'reportedId': targetUid,
      'reason': reason,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser(String targetUid) async {
    await _firestore.collection('users').doc(_uid).update({
      'blockedUsers': FieldValue.arrayUnion([targetUid]),
    });
  }

  Future<void> unblockUser(String targetUid) async {
    await _firestore.collection('users').doc(_uid).update({
      'blockedUsers': FieldValue.arrayRemove([targetUid]),
    });
  }

  // ─── Notifications ───────────────────────────────────────────────

  Stream<QuerySnapshot> getNotifications() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  int _calculateCompletion(Map<String, dynamic> data) {
    int score = 0;
    if (data['name']?.toString().isNotEmpty ?? false) score += 15;
    if (data['bio']?.toString().isNotEmpty ?? false) score += 15;
    if (data['gender']?.toString().isNotEmpty ?? false) score += 10;
    if ((data['age'] ?? 0) > 0) score += 10;
    if ((data['interests'] as List?)?.isNotEmpty ?? false) score += 15;
    if (data['location']?.toString().isNotEmpty ?? false) score += 10;
    return score.clamp(0, 100);
  }
}
