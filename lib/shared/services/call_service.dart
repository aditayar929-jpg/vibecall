import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // Call status constants
  static const String statusRinging = 'ringing';
  static const String statusActive = 'active';
  static const String statusEnded = 'ended';
  static const String statusRejected = 'rejected';

  // ─── Create Call ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> initiateCall({
    required String calleeId,
    required String calleeName,
    required String calleeAvatar,
    String callType = 'video',
  }) async {
    final callerDoc = await _firestore.collection('users').doc(_uid).get();
    final callerData = callerDoc.data() ?? {};

    final callRef = _firestore.collection('calls').doc();

    final callData = {
      'callId': callRef.id,
      'callerId': _uid,
      'callerName': callerData['name'] ?? 'User',
      'callerAvatar': callerData['avatar'] ?? '',
      'calleeId': calleeId,
      'calleeName': calleeName,
      'calleeAvatar': calleeAvatar,
      'type': callType,
      'status': statusRinging,
      'startedAt': FieldValue.serverTimestamp(),
      'endedAt': null,
      'duration': 0,
    };

    await callRef.set(callData);

    // Create notification for callee
    await _firestore
        .collection('users')
        .doc(calleeId)
        .collection('notifications')
        .add({
      'type': 'call',
      'title': 'Incoming ${callType == 'video' ? 'Video' : 'Audio'} Call',
      'body': '${callerData['name'] ?? 'Someone'} is calling you',
      'callerId': _uid,
      'callId': callRef.id,
      'callType': callType,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    return {
      'callId': callRef.id,
    };
  }

  // ─── Answer Call ──────────────────────────────────────────────────

  Future<void> answerCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': statusActive,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── End Call ─────────────────────────────────────────────────────

  Future<void> endCall(String callId) async {
    final callDoc = await _firestore.collection('calls').doc(callId).get();
    final callData = callDoc.data();

    int duration = 0;
    if (callData?['answeredAt'] != null) {
      final answeredAt = (callData!['answeredAt'] as Timestamp).toDate();
      duration = DateTime.now().difference(answeredAt).inSeconds;
    }

    await _firestore.collection('calls').doc(callId).update({
      'status': statusEnded,
      'endedAt': FieldValue.serverTimestamp(),
      'duration': duration,
    });

    // Deduct coins from caller (15 coins per minute)
    if (duration > 0) {
      final coinsToDeduct = ((duration / 60).ceil() * 15);
      await _firestore.collection('users').doc(_uid).update({
        'coins': FieldValue.increment(-coinsToDeduct),
      });
    }
  }

  // ─── Reject Call ──────────────────────────────────────────────────

  Future<void> rejectCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': statusRejected,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Call Streams ─────────────────────────────────────────────────

  Stream<DocumentSnapshot> getCallStream(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots();
  }

  Stream<QuerySnapshot> getIncomingCalls() {
    return _firestore
        .collection('calls')
        .where('calleeId', isEqualTo: _uid)
        .where('status', isEqualTo: statusRinging)
        .snapshots();
  }

  Stream<QuerySnapshot> getOutgoingCalls() {
    return _firestore
        .collection('calls')
        .where('callerId', isEqualTo: _uid)
        .where('status', isEqualTo: statusRinging)
        .snapshots();
  }

  // ─── Call History ─────────────────────────────────────────────────

  Stream<QuerySnapshot> getCallHistory() {
    return _firestore
        .collection('calls')
        .where('callerId', isEqualTo: _uid)
        .orderBy('startedAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getCallHistoryList() async {
    final callerCalls = await _firestore
        .collection('calls')
        .where('callerId', isEqualTo: _uid)
        .orderBy('startedAt', descending: true)
        .limit(25)
        .get();

    final calleeCalls = await _firestore
        .collection('calls')
        .where('calleeId', isEqualTo: _uid)
        .orderBy('startedAt', descending: true)
        .limit(25)
        .get();

    final allCalls = [
      ...callerCalls.docs.map((d) => {'id': d.id, ...d.data()}),
      ...calleeCalls.docs.map((d) => {'id': d.id, ...d.data()}),
    ];

    allCalls.sort((a, b) {
      final aTime = a['startedAt'] as Timestamp?;
      final bTime = b['startedAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    return allCalls.take(50).toList();
  }

  // ─── Random Match + Call ──────────────────────────────────────────

  Future<Map<String, dynamic>?> findAndConnect({
    String? genderFilter,
  }) async {
    // Add self to queue
    await _firestore.collection('matching_queue').doc(_uid).set({
      'uid': _uid,
      'genderFilter': genderFilter ?? 'All',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'waiting',
    });

    // Wait and find match
    await Future.delayed(const Duration(seconds: 2));

    // Look for others in queue
    Query query = _firestore
        .collection('matching_queue')
        .where('uid', isNotEqualTo: _uid)
        .orderBy('timestamp', descending: true)
        .limit(10);

    if (genderFilter != null && genderFilter != 'All') {
      // Can't filter on other user's gender preference easily, so get all
    }

    final queueSnapshot = await query.get();

    if (queueSnapshot.docs.isNotEmpty) {
      final matched = queueSnapshot.docs.first;
      final matchedUid = matched['uid'];

      // Get matched user data
      final userDoc = await _firestore.collection('users').doc(matchedUid).get();
      final userData = userDoc.data();

      if (userData != null) {
        // Remove both from queue
        await _firestore.collection('matching_queue').doc(_uid).delete();
        await _firestore.collection('matching_queue').doc(matchedUid).delete();

        return {
          'uid': matchedUid,
          'name': userData['name'] ?? 'User',
          'avatar': userData['avatar'] ?? '',
          ...userData,
        };
      }
    }

    return null;
  }

  Future<void> leaveMatchingQueue() async {
    await _firestore.collection('matching_queue').doc(_uid).delete();
  }
}
