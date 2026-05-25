import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/call_service.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../../../shared/services/signaling_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String remoteUserId;
  final bool isCaller;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.remoteUserId,
    this.isCaller = true,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with TickerProviderStateMixin {
  final CallService _callService = CallService();
  final FirestoreService _firestoreService = FirestoreService();
  final SignalingService _signalingService = SignalingService();

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // Subscriptions
  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _iceSub;
  StreamSubscription? _callStatusSub;

  // UI State
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  bool _showControls = true;
  bool _isBeautyOn = false;
  bool _isConnected = false;
  int _callDuration = 0;
  Timer? _timer;
  late AnimationController _giftController;
  String? _callId;

  Map<String, dynamic> _remoteUser = {};

  final List<Map<String, dynamic>> _gifts = [
    {'icon': Icons.favorite_rounded, 'name': 'Heart', 'cost': 10, 'color': AppColors.neonPink},
    {'icon': Icons.star_rounded, 'name': 'Star', 'cost': 20, 'color': AppColors.coinGold},
    {'icon': Icons.diamond_rounded, 'name': 'Diamond', 'cost': 50, 'color': AppColors.diamondBlue},
    {'icon': Icons.local_fire_department_rounded, 'name': 'Fire', 'cost': 30, 'color': Colors.orange},
    {'icon': Icons.auto_awesome_rounded, 'name': 'Magic', 'cost': 100, 'color': AppColors.primaryPurple},
  ];

  // STUN servers for NAT traversal
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _giftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _callId = widget.callId;
    _initRenderers();
    _loadRemoteUser();
    _startTimer();
    _initWebRTC();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _initWebRTC() async {
    // Get local media stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': _isFrontCamera ? 'user' : 'environment',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      },
    });
    _localRenderer.srcObject = _localStream;

    // Create peer connection
    _peerConnection = await createPeerConnection(_iceServers);

    // Add local tracks to peer connection
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // Handle remote stream
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteStream = event.streams[0];
          _remoteRenderer.srcObject = _remoteStream;
          _isConnected = true;
        });
      }
    };

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      _signalingService.sendIceCandidate(_callId!, uid, {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    // Handle connection state
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _endCall();
      }
    };

    // Initialize candidates doc
    await _signalingService.initCandidatesDoc(_callId!);

    if (widget.isCaller) {
      await _callerFlow();
    } else {
      await _calleeFlow();
    }

    // Listen for ICE candidates from remote peer
    _iceSub = _signalingService.listenForIceCandidates(_callId!).listen((doc) {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final remoteUid = widget.remoteUserId;
      final candidatesKey = 'candidates_$remoteUid';
      final candidates = data[candidatesKey] as List<dynamic>?;

      if (candidates != null) {
        for (final c in candidates) {
          final candidate = RTCIceCandidate(
            c['candidate'],
            c['sdpMid'],
            c['sdpMLineIndex'],
          );
          _peerConnection?.addCandidate(candidate);
        }
      }
    });

    // Listen for call status changes
    _callStatusSub = _callService.getCallStream(_callId!).listen((doc) {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;
      if (data['status'] == 'ended' || data['status'] == 'rejected') {
        if (mounted) context.pop();
      }
    });
  }

  // ─── Caller Flow: Create Offer ────────────────────────────────────

  Future<void> _callerFlow() async {
    // Create offer
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Send offer via Firestore
    await _signalingService.sendOffer(_callId!, {
      'sdp': offer.sdp,
      'type': offer.type,
    });

    // Listen for answer
    _answerSub = _signalingService.listenForAnswer(_callId!).listen((doc) async {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data['sdp'] == null) return;

      final answer = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection!.setRemoteDescription(answer);
    });
  }

  // ─── Callee Flow: Listen for Offer, Create Answer ─────────────────

  Future<void> _calleeFlow() async {
    _offerSub = _signalingService.listenForOffer(_callId!).listen((doc) async {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data['sdp'] == null) return;

      // Set remote description (offer)
      final offer = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection!.setRemoteDescription(offer);

      // Create answer
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Send answer via Firestore
      await _signalingService.sendAnswer(_callId!, {
        'sdp': answer.sdp,
        'type': answer.type,
      });
    });
  }

  Future<void> _loadRemoteUser() async {
    final userData = await _firestoreService.getUserData(widget.remoteUserId);
    if (userData != null && mounted) {
      setState(() => _remoteUser = userData);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _callDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
  }

  void _toggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !_isCameraOff;
    });
  }

  void _flipCamera() async {
    setState(() => _isFrontCamera = !_isFrontCamera);

    // Stop current video tracks
    _localStream?.getVideoTracks().forEach((track) {
      track.stop();
    });

    // Get new stream with flipped camera
    final newStream = await navigator.mediaDevices.getUserMedia({
      'audio': false,
      'video': {
        'facingMode': _isFrontCamera ? 'user' : 'environment',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      },
    });

    // Replace video track in peer connection
    final newVideoTrack = newStream.getVideoTracks().first;
    final senders = await _peerConnection!.getSenders();
    for (final sender in senders) {
      if (sender.track?.kind == 'video') {
        await sender.replaceTrack(newVideoTrack);
      }
    }

    // Update local stream
    final oldVideoTracks = _localStream!.getVideoTracks();
    for (final track in oldVideoTracks) {
      _localStream!.removeTrack(track);
    }
    _localStream!.addTrack(newVideoTrack);
    _localRenderer.srcObject = _localStream;
  }

  void _endCall() async {
    _timer?.cancel();
    _offerSub?.cancel();
    _answerSub?.cancel();
    _iceSub?.cancel();
    _callStatusSub?.cancel();

    // Stop local stream
    _localStream?.getTracks().forEach((track) => track.stop());

    // Close peer connection
    await _peerConnection?.close();

    // End call in Firestore
    if (_callId != null) {
      await _callService.endCall(_callId!);
      await _signalingService.cleanup(_callId!);
    }

    if (mounted) context.pop();
  }

  void _skipUser() async {
    _timer?.cancel();
    _offerSub?.cancel();
    _answerSub?.cancel();
    _iceSub?.cancel();
    _callStatusSub?.cancel();

    _localStream?.getTracks().forEach((track) => track.stop());
    await _peerConnection?.close();

    if (_callId != null) {
      await _callService.endCall(_callId!);
      await _signalingService.cleanup(_callId!);
    }

    if (mounted) context.push('/matching');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _offerSub?.cancel();
    _answerSub?.cancel();
    _iceSub?.cancel();
    _callStatusSub?.cancel();
    _localStream?.getTracks().forEach((track) => track.stop());
    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _giftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Remote video (full screen)
            _isConnected
                ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurple.withOpacity(0.2),
                          AppColors.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: AppColors.primaryGradient),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryPurple.withOpacity(0.5),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                (_remoteUser['name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _remoteUser['name'] ?? 'User',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isConnected ? _formatDuration(_callDuration) : 'Connecting...',
                            style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.6), letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                  ),

            // Local video (small preview)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _isCameraOff
                      ? Container(
                          color: AppColors.cardBackground,
                          child: const Center(
                            child: Icon(Icons.videocam_off_rounded, size: 40, color: Colors.white38),
                          ),
                        )
                      : RTCVideoView(
                          _localRenderer,
                          mirror: _isFrontCamera,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            // Match badge
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _isConnected ? 'Live Call' : 'Connecting...',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, delay: 200.ms),

            // Call duration (top center)
            if (_isConnected)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: MediaQuery.of(context).size.width / 2 - 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

            // Controls
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Column(
                children: [
                  const Spacer(),

                  // Gift strip
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _gifts.length,
                      itemBuilder: (context, index) {
                        final gift = _gifts[index];
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _sendGift(gift);
                          },
                          child: Container(
                            width: 65,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(gift['icon'] as IconData, color: gift['color'] as Color, size: 28),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.monetization_on_rounded, color: AppColors.coinGold, size: 12),
                                    const SizedBox(width: 2),
                                    Text('${gift['cost']}', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Main controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          label: _isMuted ? 'Unmute' : 'Mute',
                          onTap: _toggleMute,
                          isActive: _isMuted,
                        ),
                        _buildControlButton(
                          icon: _isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                          label: _isCameraOff ? 'Camera On' : 'Camera Off',
                          onTap: _toggleCamera,
                          isActive: _isCameraOff,
                        ),
                        _buildControlButton(
                          icon: Icons.flip_camera_ios_rounded,
                          label: 'Flip',
                          onTap: _flipCamera,
                        ),
                        _buildControlButton(
                          icon: Icons.auto_fix_high_rounded,
                          label: 'Beauty',
                          onTap: () => setState(() => _isBeautyOn = !_isBeautyOn),
                          isActive: _isBeautyOn,
                          activeColor: AppColors.neonPink,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Skip and End
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _skipUser,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.skip_next_rounded, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Skip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _endCall,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.errorRed, Color(0xFFFF6B6B)]),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(color: AppColors.errorRed.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5)),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.call_end_rounded, color: Colors.white, size: 26),
                                  SizedBox(width: 8),
                                  Text('End Call', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // More options
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: MediaQuery.of(context).size.width / 2 - 20,
              child: GestureDetector(
                onTap: () => _showReportSheet(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                  child: const Icon(Icons.more_horiz_rounded, color: Colors.white54, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendGift(Map<String, dynamic> gift) async {
    final hasCoins = await _firestoreService.hasEnoughCoins(gift['cost']);
    if (!hasCoins) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Not enough coins!'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    await _firestoreService.deductCoins(gift['cost'], 'Gift: ${gift['name']}');

    _giftController.reset();
    _giftController.forward();

    if (mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => Center(
          child: AnimatedBuilder(
            animation: _giftController,
            builder: (context, child) {
              return Transform.scale(
                scale: _giftController.value,
                child: Opacity(
                  opacity: 1 - _giftController.value * 0.5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(gift['icon'] as IconData, size: 80, color: gift['color'] as Color),
                      const SizedBox(height: 8),
                      Text(
                        'Sent ${gift['name']}!',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color activeColor = AppColors.errorRed,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.2) : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? activeColor : Colors.white.withOpacity(0.15)),
            ),
            child: Icon(icon, color: isActive ? activeColor : Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, color: isActive ? activeColor : Colors.white54)),
        ],
      ),
    );
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            _buildReportOption(Icons.flag_rounded, 'Report User', AppColors.errorRed, () async {
              await _firestoreService.reportUser(widget.remoteUserId, 'Inappropriate behavior');
              if (mounted) Navigator.pop(context);
            }),
            _buildReportOption(Icons.block_rounded, 'Block User', AppColors.warningYellow, () async {
              await _firestoreService.blockUser(widget.remoteUserId);
              if (mounted) Navigator.pop(context);
              _endCall();
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white38),
      onTap: onTap,
    );
  }
}
