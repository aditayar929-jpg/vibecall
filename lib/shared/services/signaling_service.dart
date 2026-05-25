import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Send Offer (Caller → Firestore) ──────────────────────────────

  Future<void> sendOffer(String callId, Map<String, dynamic> sdp) async {
    await _firestore
        .collection('calls')
        .doc(callId)
        .collection('signaling')
        .doc('offer')
        .set({
      'sdp': sdp['sdp'],
      'type': sdp['type'],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ─── Send Answer (Callee → Firestore) ─────────────────────────────

  Future<void> sendAnswer(String callId, Map<String, dynamic> sdp) async {
    await _firestore
        .collection('calls')
        .doc(callId)
        .collection('signaling')
        .doc('answer')
        .set({
      'sdp': sdp['sdp'],
      'type': sdp['type'],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ─── Send ICE Candidate ───────────────────────────────────────────

  Future<void> sendIceCandidate(
    String callId,
    String uid,
    Map<String, dynamic> candidate,
  ) async {
    await _firestore
        .collection('calls')
        .doc(callId)
        .collection('signaling')
        .doc('candidates')
        .update({
      'candidates_$uid': FieldValue.arrayUnion([
        {
          'candidate': candidate['candidate'],
          'sdpMid': candidate['sdpMid'],
          'sdpMLineIndex': candidate['sdpMLineIndex'],
        }
      ]),
    });
  }

  // ─── Initialize Candidates Doc ────────────────────────────────────

  Future<void> initCandidatesDoc(String callId) async {
    await _firestore
        .collection('calls')
        .doc(callId)
        .collection('signaling')
        .doc('candidates')
        .set({
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Listen for Offer (Callee listens) ────────────────────────────

  Stream<DocumentSnapshot> listenForOffer(String callId) {
    return _firestore
        .collection('calls')
        .doc(callId)
        .collection('signaling')
        .doc('offer')
        .snapshots();
  }

  // ─── Listen for Answer (Caller listens) ───────────────────────────

  Stream<DocumentSnapshot> listenForAnswer(String callId) {
    return _firestore
        .collection('calls')
        .doc(callId)
        .collection('signaling')
        .doc('answer')
        .snapshots();
  }

  // ─── Listen for ICE Candidates ────────────────────────────────────

  Stream<DocumentSnapshot> listenForIceCandidates(String callId) {
    return _firestore
        .collection('calls')
        .doc(callId)
        .collection('signaling')
        .doc('candidates')
        .snapshots();
  }

  // ─── Cleanup after call ends ──────────────────────────────────────

  Future<void> cleanup(String callId) async {
    final signalingRef = _firestore
        .collection('calls')
        .doc(callId)
        .collection('signaling');

    final docs = await signalingRef.get();
    for (final doc in docs.docs) {
      await doc.reference.delete();
    }
  }
}
