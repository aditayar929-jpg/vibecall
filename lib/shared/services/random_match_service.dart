import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore-based random matching — no backend server needed.
///
/// Flow:
/// 1. User joins "random_queue" collection with their profile info
/// 2. Service polls for another waiting user
/// 3. When found, both users get matched atomically
/// 4. A "random_calls" doc is created with room info
class RandomMatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  /// Join the random matching queue
  Future<void> joinQueue({
    String genderFilter = 'All',
    int minAge = 18,
    int maxAge = 35,
    String callType = 'video',
  }) async {
    final myData = await _firestore.collection('users').doc(_uid).get();
    final data = myData.data() ?? {};

    await _firestore.collection('random_queue').doc(_uid).set({
      'uid': _uid,
      'name': data['name'] ?? 'User',
      'avatar': data['avatar'] ?? '',
      'gender': data['gender'] ?? '',
      'age': data['age'] ?? 18,
      'interests': data['interests'] ?? [],
      'location': data['location'] ?? '',
      'genderFilter': genderFilter,
      'minAge': minAge,
      'maxAge': maxAge,
      'callType': callType,
      'status': 'waiting',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Leave the queue
  Future<void> leaveQueue() async {
    try {
      await _firestore.collection('random_queue').doc(_uid).delete();
    } catch (_) {}
  }

  /// Try to find a match. Returns matched user data or null.
  /// Uses a Firestore transaction to prevent double-matching.
  Future<Map<String, dynamic>?> findMatch({
    String genderFilter = 'All',
    int minAge = 18,
    int maxAge = 35,
  }) async {
    // Get my profile data
    final myDoc = await _firestore.collection('users').doc(_uid).get();
    final myData = myDoc.data() ?? {};
    final myGender = myData['gender'] ?? '';
    final myAge = myData['age'] ?? 18;

    // Find waiting users (excluding self)
    final queueSnap = await _firestore
        .collection('random_queue')
        .where('status', isEqualTo: 'waiting')
        .orderBy('timestamp')
        .limit(30)
        .get();

    if (queueSnap.docs.isEmpty) return null;

    // Filter compatible matches
    final candidates = queueSnap.docs
        .map((doc) => doc.data())
        .where((entry) => entry['uid'] != _uid)
        .where((entry) {
      // Check gender compatibility (both directions)
      final theirGenderFilter = entry['genderFilter'] ?? 'All';
      final theirGender = entry['gender'] ?? '';
      final theirAge = entry['age'] ?? 0;
      final theirMinAge = entry['minAge'] ?? 18;
      final theirMaxAge = entry['maxAge'] ?? 99;

      // They want my gender?
      if (genderFilter != 'All' && theirGender != genderFilter) return false;
      // Their age in my range?
      if (theirAge < minAge || theirAge > maxAge) return false;
      // They want my age?
      if (theirGenderFilter != 'All' && myGender != theirGenderFilter) return false;
      // My age in their range?
      if (myAge < theirMinAge || myAge > theirMaxAge) return false;

      return true;
    }).toList();

    if (candidates.isEmpty) return null;

    // Pick a random candidate
    final random = Random();
    final partner = candidates[random.nextInt(candidates.length)];

    // Atomically claim the match
    try {
      final partnerUid = partner['uid'] as String;
      final roomName = 'random_${_uid.substring(0, 6)}_${partnerUid.substring(0, 6)}_${DateTime.now().millisecondsSinceEpoch}';

      await _firestore.runTransaction((transaction) async {
        final myQueueRef = _firestore.collection('random_queue').doc(_uid);
        final partnerQueueRef = _firestore.collection('random_queue').doc(partnerUid);

        final myQueueDoc = await transaction.get(myQueueRef);
        final partnerQueueDoc = await transaction.get(partnerQueueRef);

        // Both must still be waiting
        if (!myQueueDoc.exists || !partnerQueueDoc.exists) {
          throw Exception('One user already left');
        }
        if (myQueueDoc.data()?['status'] != 'waiting' ||
            partnerQueueDoc.data()?['status'] != 'waiting') {
          throw Exception('One user already matched');
        }

        // Mark both as matched
        transaction.update(myQueueRef, {
          'status': 'matched',
          'roomName': roomName,
          'partnerUid': partnerUid,
        });
        transaction.update(partnerQueueRef, {
          'status': 'matched',
          'roomName': roomName,
          'partnerUid': _uid,
        });

        // Create the call record
        transaction.set(_firestore.collection('random_calls').doc(roomName), {
          'roomName': roomName,
          'users': [_uid, partnerUid],
          'callType': 'video',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // Clean up queue entries
      await _firestore.collection('random_queue').doc(_uid).delete().catchError((_) {});
      await _firestore.collection('random_queue').doc(partnerUid).delete().catchError((_) {});

      return {
        'matched': true,
        'roomName': roomName,
        'partner': {
          'uid': partnerUid,
          'name': partner['name'] ?? 'Stranger',
          'avatar': partner['avatar'] ?? '',
          'gender': partner['gender'] ?? '',
          'age': partner['age'] ?? 18,
        },
      };
    } catch (e) {
      return null;
    }
  }

  /// Watch my queue entry for status changes (e.g. matched by someone else)
  Stream<DocumentSnapshot> watchMyQueue() {
    return _firestore.collection('random_queue').doc(_uid).snapshots();
  }

  /// Get count of users currently waiting in queue
  Future<int> getQueueCount() async {
    final snap = await _firestore
        .collection('random_queue')
        .where('status', isEqualTo: 'waiting')
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Mark user as online
  Future<void> setOnline() async {
    await _firestore.collection('users').doc(_uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  /// Mark user as offline
  Future<void> setOffline() async {
    await _firestore.collection('users').doc(_uid).update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }
}
