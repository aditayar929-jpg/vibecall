import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/livekit_service.dart';
import '../../../../shared/services/firestore_service.dart';

class LiveCallScreen extends StatefulWidget {
  final String roomName;
  final String? partnerName;
  final bool enableVideo;

  const LiveCallScreen({
    super.key,
    required this.roomName,
    this.partnerName,
    this.enableVideo = true,
  });

  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen>
    with TickerProviderStateMixin {
  final LiveKitService _liveKitService = LiveKitService();
  final FirestoreService _firestoreService = FirestoreService();

  Room? _room;
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  bool _showControls = true;
  bool _remoteConnected = false;
  int _callDuration = 0;
  Timer? _durationTimer;
  Timer? _hideControlsTimer;
  String _partnerName = '';
  RemoteVideoTrack? _remoteVideoTrack;
  late AnimationController _giftController;

  final List<Map<String, dynamic>> _gifts = [
    {'icon': Icons.favorite_rounded, 'name': 'Heart', 'cost': 10, 'color': AppColors.neonPink},
    {'icon': Icons.star_rounded, 'name': 'Star', 'cost': 20, 'color': AppColors.coinGold},
    {'icon': Icons.diamond_rounded, 'name': 'Diamond', 'cost': 50, 'color': AppColors.diamondBlue},
    {'icon': Icons.local_fire_department_rounded, 'name': 'Fire', 'cost': 30, 'color': Colors.orange},
    {'icon': Icons.auto_awesome_rounded, 'name': 'Magic', 'cost': 100, 'color': AppColors.primaryPurple},
  ];

  @override
  void initState() {
    super.initState();
    _giftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _partnerName = widget.partnerName ?? 'Connecting...';
    _connectToRoom();
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isConnected) {
        setState(() => _showControls = false);
      }
    });
  }

  Future<void> _connectToRoom() async {
    try {
      final room = await _liveKitService.connectToRoom(
        roomName: widget.roomName,
        enableVideo: widget.enableVideo,
        enableAudio: true,
      );

      _room = room;
      _room!.addListener(_onRoomUpdate);

      // Listen for participant events
      _liveKitService.onParticipantConnected((participant) {
        _onRemoteParticipantJoined(participant);
      });

      _liveKitService.onParticipantDisconnected((participant) {
        _onRemoteParticipantLeft();
      });

      // Check if someone is already in the room
      final remotes = _liveKitService.remoteParticipants;
      if (remotes.isNotEmpty) {
        _onRemoteParticipantJoined(remotes.first);
      }

      if (mounted) {
        setState(() => _isConnected = true);
        _startDurationTimer();
      }
    } catch (e) {
      debugPrint('Failed to connect: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        context.pop();
      }
    }
  }

  void _onRoomUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _onRemoteParticipantJoined(RemoteParticipant participant) {
    setState(() {
      _remoteConnected = true;
      _partnerName = participant.name ?? widget.partnerName ?? 'Stranger';
    });

    // Find their video track
    for (final trackPub in participant.videoTrackPublications) {
      if (trackPub.track != null) {
        setState(() {
          _remoteVideoTrack = trackPub.track as RemoteVideoTrack?;
        });
        break;
      }
    }

    // Listen for future track publications
    participant.addListener(() {
      if (!mounted) return;
      for (final trackPub in participant.videoTrackPublications) {
        if (trackPub.track != null && _remoteVideoTrack != trackPub.track) {
          setState(() {
            _remoteVideoTrack = trackPub.track as RemoteVideoTrack?;
          });
          break;
        }
      }
    });
  }

  void _onRemoteParticipantLeft() {
    setState(() {
      _remoteConnected = false;
      _remoteVideoTrack = null;
    });

    // Show dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.8),
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Call Ended', style: TextStyle(color: Colors.white)),
          content: Text(
            'The other person left the call.',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              child: const Text('OK', style: TextStyle(color: AppColors.neonPink)),
            ),
          ],
        ),
      );
    }
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _callDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideControlsTimer();
  }

  Future<void> _toggleMute() async {
    HapticFeedback.lightImpact();
    await _liveKitService.toggleMic();
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _toggleCamera() async {
    HapticFeedback.lightImpact();
    await _liveKitService.toggleCamera();
    setState(() => _isCameraOff = !_isCameraOff);
  }

  Future<void> _switchCamera() async {
    HapticFeedback.lightImpact();
    await _liveKitService.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  Future<void> _endCall() async {
    HapticFeedback.heavyImpact();
    _durationTimer?.cancel();
    _hideControlsTimer?.cancel();
    await _liveKitService.disconnect();
    if (mounted) context.pop();
  }

  void _sendGift(Map<String, dynamic> gift) {
    HapticFeedback.mediumImpact();
    _giftController.forward(from: 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent ${gift['name']}! (-${gift['cost']} coins)'),
        backgroundColor: AppColors.primaryPurple,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _hideControlsTimer?.cancel();
    _giftController.dispose();
    _room?.removeListener(_onRoomUpdate);
    _liveKitService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Remote video (full screen)
            if (_remoteVideoTrack != null)
              VideoTrackRenderer(_remoteVideoTrack!, fit: VideoViewFit.cover)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: AppColors.primaryGradient),
                      ),
                      child: const Icon(Icons.person_rounded, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _partnerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _remoteConnected ? 'Camera off' : 'Waiting for partner...',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                    ),
                    if (!_remoteConnected) ...[
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          color: AppColors.neonPink,
                          strokeWidth: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Local video (pip)
            if (_isConnected && !_isCameraOff)
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                right: 16,
                child: GestureDetector(
                  onPanUpdate: (details) {},
                  child: Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _liveKitService.localVideo != null
                          ? VideoTrackRenderer(
                              _liveKitService.localVideo!,
                              fit: VideoViewFit.cover,
                              mirrorMode: VideoMirrorMode.mirror,
                            )
                          : Container(
                              color: AppColors.surfaceColor,
                              child: const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 40),
                            ),
                    ),
                  ),
                ),
              ),

            // Top bar
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _remoteConnected ? AppColors.onlineGreen : AppColors.coinGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(_callDuration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _partnerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Gift button
                      GestureDetector(
                        onTap: () => _showGiftPanel(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.coinGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.card_giftcard_rounded, color: AppColors.coinGold, size: 22),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              ),

            // Bottom controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    top: 30,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Report / Block
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flag_rounded, color: Colors.white.withOpacity(0.6), size: 16),
                                  const SizedBox(width: 6),
                                  Text('Report', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _endCall,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.errorRed.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.block_rounded, color: AppColors.errorRed, size: 16),
                                  SizedBox(width: 6),
                                  Text('Block', style: TextStyle(color: AppColors.errorRed, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Main controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            label: _isMuted ? 'Unmute' : 'Mute',
                            color: _isMuted ? AppColors.errorRed : Colors.white,
                            onTap: _toggleMute,
                          ),
                          _buildControlButton(
                            icon: _isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                            label: _isCameraOff ? 'Camera On' : 'Camera Off',
                            color: _isCameraOff ? AppColors.errorRed : Colors.white,
                            onTap: _toggleCamera,
                          ),
                          _buildControlButton(
                            icon: Icons.cameraswitch_rounded,
                            label: 'Flip',
                            color: Colors.white,
                            onTap: _switchCamera,
                          ),
                          // Next button
                          _buildControlButton(
                            icon: Icons.skip_next_rounded,
                            label: 'Next',
                            color: AppColors.coinGold,
                            onTap: () async {
                              await _liveKitService.disconnect();
                              if (mounted) context.pop();
                              // matching_screen will handle re-join
                            },
                          ),
                          // End call
                          _buildControlButton(
                            icon: Icons.call_end_rounded,
                            label: 'End',
                            color: Colors.white,
                            bgColor: AppColors.errorRed,
                            size: 64,
                            iconSize: 28,
                            onTap: _endCall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? bgColor,
    double size = 52,
    double iconSize = 24,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor ?? Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showGiftPanel() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Send a Gift',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Show your appreciation!',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _gifts.map((gift) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _sendGift(gift);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: (gift['color'] as Color).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: (gift['color'] as Color).withOpacity(0.3)),
                        ),
                        child: Icon(gift['icon'], color: gift['color'], size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(gift['name'], style: const TextStyle(fontSize: 12)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on_rounded, color: AppColors.coinGold, size: 12),
                          const SizedBox(width: 2),
                          Text('${gift['cost']}', style: const TextStyle(fontSize: 12, color: AppColors.coinGold)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
