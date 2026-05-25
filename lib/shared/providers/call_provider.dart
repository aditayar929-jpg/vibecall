import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/call_service.dart';

enum CallState {
  idle,
  calling,
  ringing,
  connected,
  ended,
  error,
}

class CallProvider extends ChangeNotifier {
  final CallService _callService = CallService();

  CallState _callState = CallState.idle;
  String? _callId;
  String? _channelName;
  Map<String, dynamic>? _remoteUser;
  String? _errorMessage;
  StreamSubscription? _callSubscription;
  StreamSubscription? _incomingSubscription;
  int _callDuration = 0;
  Timer? _durationTimer;

  CallState get callState => _callState;
  String? get callId => _callId;
  String? get channelName => _channelName;
  Map<String, dynamic>? get remoteUser => _remoteUser;
  String? get errorMessage => _errorMessage;
  int get callDuration => _callDuration;

  CallProvider() {
    _listenForIncomingCalls();
  }

  void _listenForIncomingCalls() {
    _incomingSubscription = _callService.getIncomingCalls().listen((snapshot) {
      for (final doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final data = doc.doc.data() as Map<String, dynamic>;
          _remoteUser = {
            'uid': data['callerId'],
            'name': data['callerName'] ?? 'User',
            'avatar': data['callerAvatar'] ?? '',
          };
          _callId = data['callId'];
          _channelName = data['channelName'];
          _callState = CallState.ringing;
          notifyListeners();
        }
      }
    });
  }

  // ─── Start Call ───────────────────────────────────────────────────

  Future<void> startCall({
    required String calleeId,
    required String calleeName,
    required String calleeAvatar,
    String callType = 'video',
  }) async {
    _callState = CallState.calling;
    _remoteUser = {
      'uid': calleeId,
      'name': calleeName,
      'avatar': calleeAvatar,
    };
    notifyListeners();

    try {
      final result = await _callService.initiateCall(
        calleeId: calleeId,
        calleeName: calleeName,
        calleeAvatar: calleeAvatar,
        callType: callType,
      );

      _callId = result['callId'];
      _channelName = result['channelName'];

      // Listen for call status changes
      _callSubscription = _callService.getCallStream(_callId!).listen((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return;

        switch (data['status']) {
          case 'ringing':
            _callState = CallState.ringing;
            break;
          case 'active':
            _callState = CallState.connected;
            _startDurationTimer();
            break;
          case 'ended':
          case 'rejected':
            _callState = CallState.ended;
            _stopDurationTimer();
            break;
        }
        notifyListeners();
      });
    } catch (e) {
      _callState = CallState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ─── Answer Call ──────────────────────────────────────────────────

  Future<void> answerCall() async {
    if (_callId == null) return;

    try {
      await _callService.answerCall(_callId!);
      _callState = CallState.connected;
      _startDurationTimer();
      notifyListeners();

      // Listen for end
      _callSubscription = _callService.getCallStream(_callId!).listen((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data?['status'] == 'ended' || data?['status'] == 'rejected') {
          _callState = CallState.ended;
          _stopDurationTimer();
          notifyListeners();
        }
      });
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ─── End Call ─────────────────────────────────────────────────────

  Future<void> endCall() async {
    if (_callId != null) {
      await _callService.endCall(_callId!);
    }
    _callState = CallState.ended;
    _stopDurationTimer();
    _cleanup();
    notifyListeners();
  }

  // ─── Reject Call ──────────────────────────────────────────────────

  Future<void> rejectCall() async {
    if (_callId != null) {
      await _callService.rejectCall(_callId!);
    }
    _callState = CallState.ended;
    _cleanup();
    notifyListeners();
  }

  // ─── Random Match ────────────────────────────────────────────────

  Future<Map<String, dynamic>?> findRandomMatch({
    String? genderFilter,
  }) async {
    try {
      return await _callService.findAndConnect(genderFilter: genderFilter);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> leaveQueue() async {
    await _callService.leaveMatchingQueue();
  }

  // ─── Duration Timer ──────────────────────────────────────────────

  void _startDurationTimer() {
    _callDuration = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration++;
      notifyListeners();
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  String get formattedDuration {
    final m = (_callDuration ~/ 60).toString().padLeft(2, '0');
    final s = (_callDuration % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Cleanup ─────────────────────────────────────────────────────

  void _cleanup() {
    _callSubscription?.cancel();
    _callSubscription = null;
    _callId = null;
    _channelName = null;
  }

  void reset() {
    _callState = CallState.idle;
    _callDuration = 0;
    _remoteUser = null;
    _errorMessage = null;
    _cleanup();
    _stopDurationTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _incomingSubscription?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }
}
