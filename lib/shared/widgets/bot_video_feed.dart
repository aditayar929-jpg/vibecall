import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays real video during bot video call to simulate a live call.
/// Falls back to animated photo if video fails to load.
class BotVideoFeed extends StatefulWidget {
  final String avatarUrl;
  final String videoUrl;
  final String botName;

  const BotVideoFeed({
    super.key,
    required this.avatarUrl,
    required this.videoUrl,
    required this.botName,
  });

  @override
  State<BotVideoFeed> createState() => _BotVideoFeedState();
}

class _BotVideoFeedState extends State<BotVideoFeed> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0.0); // silent — simulates muted call
      await _videoController!.play();
      if (mounted) {
        setState(() {
          _videoReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show real video if loaded
    if (_videoReady && _videoController != null) {
      return Stack(fit: StackFit.expand, children: [
        // Video fills the screen
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),

        // Vignette effect (camera feel)
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [Colors.transparent, Colors.transparent, Color(0x40000000)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Top gradient
        Positioned(
          top: 0, left: 0, right: 0, height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
              ),
            ),
          ),
        ),

        // Bottom gradient
        Positioned(
          bottom: 0, left: 0, right: 0, height: 180,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
              ),
            ),
          ),
        ),

        // HD badge
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('HD', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),

        // Live indicator
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.white, size: 6),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ]);
    }

    // Fallback: animated photo while video loads or if it failed
    return Stack(fit: StackFit.expand, children: [
      Image.network(
        widget.avatarUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF1A1A2E),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_rounded, size: 100, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 8),
                Text(widget.botName, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
              ],
            ),
          ),
        ),
      ),

      // Loading indicator while video loads
      if (!_videoFailed)
        const Center(
          child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2),
        ),

      // Gradients
      Positioned(
        top: 0, left: 0, right: 0, height: 100,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0, left: 0, right: 0, height: 180,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
            ),
          ),
        ),
      ),
    ]);
  }
}
