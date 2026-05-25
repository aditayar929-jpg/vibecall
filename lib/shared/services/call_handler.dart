import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'call_service.dart';

class CallHandler {
  final CallService _callService = CallService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _incomingCallSub;
  BuildContext? _context;
  bool _isShowingDialog = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ─── Start Listening for Incoming Calls ───────────────────────────

  void startListening(BuildContext context) {
    _context = context;
    _incomingCallSub?.cancel();

    _incomingCallSub = _callService.getIncomingCalls().listen((snapshot) {
      if (snapshot.docs.isEmpty) return;
      if (_isShowingDialog) return;

      final callDoc = snapshot.docs.first;
      final callData = callDoc.data() as Map<String, dynamic>;

      // Don't show dialog for own calls
      if (callData['callerId'] == _uid) return;

      _showIncomingCallDialog(
        callId: callData['callId'],
        callerName: callData['callerName'] ?? 'Someone',
        callerAvatar: callData['callerAvatar'] ?? '',
        callerId: callData['callerId'],
        callType: callData['type'] ?? 'video',
      );
    });
  }

  // ─── Stop Listening ───────────────────────────────────────────────

  void stopListening() {
    _incomingCallSub?.cancel();
    _incomingCallSub = null;
    _context = null;
  }

  // ─── Show Incoming Call Dialog ────────────────────────────────────

  void _showIncomingCallDialog({
    required String callId,
    required String callerName,
    required String callerAvatar,
    required String callerId,
    required String callType,
  }) {
    if (_context == null || !_context!.mounted) return;

    _isShowingDialog = true;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (dialogContext) => _IncomingCallDialog(
        callerName: callerName,
        callerAvatar: callerAvatar,
        callType: callType,
        onAccept: () async {
          Navigator.of(dialogContext).pop();
          _isShowingDialog = false;

          // Answer call in Firestore
          await _callService.answerCall(callId);

          // Navigate to video call screen as callee
          if (_context != null && _context!.mounted) {
            _context!.push(
              '/video-call?callId=$callId&remoteUserId=$callerId&isCaller=false',
            );
          }
        },
        onReject: () async {
          Navigator.of(dialogContext).pop();
          _isShowingDialog = false;
          await _callService.rejectCall(callId);
        },
      ),
    ).then((_) {
      _isShowingDialog = false;
    });
  }
}

// ─── Incoming Call Dialog Widget ──────────────────────────────────────

class _IncomingCallDialog extends StatefulWidget {
  final String callerName;
  final String callerAvatar;
  final String callType;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _IncomingCallDialog({
    required this.callerName,
    required this.callerAvatar,
    required this.callType,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<_IncomingCallDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Caller avatar with pulse
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 100 + _pulseController.value * 15,
                  height: 100 + _pulseController.value * 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryPurple.withOpacity(0.4 - _pulseController.value * 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: AppColors.primaryGradient),
                      ),
                      child: Center(
                        child: Text(
                          widget.callerName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            Text(
              widget.callerName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Incoming ${widget.callType == 'video' ? 'Video' : 'Audio'} Call',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),

            const SizedBox(height: 30),

            // Accept & Reject buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reject
                GestureDetector(
                  onTap: widget.onReject,
                  child: Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.errorRed),
                    ),
                    child: const Icon(Icons.call_end_rounded, color: AppColors.errorRed, size: 30),
                  ),
                ),

                // Accept
                GestureDetector(
                  onTap: widget.onAccept,
                  child: Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.successGreen, Color(0xFF00C853)]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.successGreen.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Reject', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                Text('Accept', style: TextStyle(color: AppColors.successGreen, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
