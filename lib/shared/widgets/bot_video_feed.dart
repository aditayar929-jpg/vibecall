import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Simulates a live video feed from a bot using animated photo.
/// Uses Ken Burns effect (zoom + pan), color temperature shifts,
/// and subtle movements to look like a real camera feed.
class BotVideoFeed extends StatefulWidget {
  final String avatarUrl;
  final String botName;

  const BotVideoFeed({
    super.key,
    required this.avatarUrl,
    required this.botName,
  });

  @override
  State<BotVideoFeed> createState() => _BotVideoFeedState();
}

class _BotVideoFeedState extends State<BotVideoFeed>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _colorController;
  late AnimationController _breatheController;
  late AnimationController _blinkController;
  final Random _random = Random();

  // Ken Burns movement values
  double _startX = 0;
  double _startY = 0;
  double _endX = 0;
  double _endY = 0;
  double _startScale = 1.0;
  double _endScale = 1.1;

  // Color temperature
  double _warmth = 0;
  double _brightness = 0;

  Timer? _movementTimer;
  Timer? _blinkTimer;
  bool _showBlink = false;

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _randomizeMovement();
    _startMovementLoop();
    _startBlinkLoop();
  }

  void _randomizeMovement() {
    _startX = (_random.nextDouble() - 0.5) * 0.15;
    _startY = (_random.nextDouble() - 0.5) * 0.15;
    _endX = (_random.nextDouble() - 0.5) * 0.15;
    _endY = (_random.nextDouble() - 0.5) * 0.15;
    _startScale = 1.0 + _random.nextDouble() * 0.05;
    _endScale = 1.1 + _random.nextDouble() * 0.1;
    _warmth = _random.nextDouble() * 0.06;
    _brightness = (_random.nextDouble() - 0.5) * 0.04;
  }

  void _startMovementLoop() {
    _moveController.forward().then((_) {
      if (mounted) {
        _randomizeMovement();
        _moveController.reset();
        _movementTimer = Timer(
          Duration(milliseconds: 500 + _random.nextInt(1500)),
          () => _startMovementLoop(),
        );
      }
    });
  }

  void _startBlinkLoop() {
    _blinkTimer = Timer.periodic(
      Duration(seconds: 3 + _random.nextInt(5)),
      (timer) {
        if (!mounted) { timer.cancel(); return; }
        setState(() => _showBlink = true);
        _blinkController.forward().then((_) {
          if (mounted) {
            _blinkController.reverse().then((_) {
              if (mounted) setState(() => _showBlink = false);
            });
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _colorController.dispose();
    _breatheController.dispose();
    _blinkController.dispose();
    _movementTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_moveController, _colorController, _breatheController]),
      builder: (context, child) {
        // Ken Burns: smooth pan + zoom
        final t = Curves.easeInOut.transform(_moveController.value);
        final dx = _startX + (_endX - _startX) * t;
        final dy = _startY + (_endY - _startY) * t;
        final scale = _startScale + (_endScale - _startScale) * t;

        // Subtle breathe (simulates chest movement)
        final breathe = _breatheController.value * 0.003;

        // Color warmth flicker (simulates auto-exposure)
        final warmth = _colorController.value * _warmth;
        final bright = _colorController.value * _brightness;

        return Stack(fit: StackFit.expand, children: [
          // Main "video" — photo with Ken Burns movement
          Transform.translate(
            offset: Offset(dx * MediaQuery.of(context).size.width, dy * MediaQuery.of(context).size.height),
            child: Transform.scale(
              scale: scale + breathe,
              child: Image.network(
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
            ),
          ),

          // Color temperature overlay (auto-exposure simulation)
          Container(
            color: Color.fromRGBO(
              (255 * warmth).clamp(0, 255).toInt(),
              (140 * warmth).clamp(0, 255).toInt(),
              0,
              warmth.clamp(0, 0.08),
            ),
          ),

          // Brightness flicker
          Container(
            color: Colors.white.withOpacity(bright.clamp(-0.03, 0.03).abs()),
          ),

          // Vignette effect (like real camera)
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

          // Bottom gradient for controls visibility
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: 180,
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

          // Top gradient for status bar
          Positioned(
            top: 0, left: 0, right: 0,
            height: 100,
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

          // "HD" quality badge (realism)
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

          // Simulated "blink" dark overlay
          if (_showBlink)
            AnimatedBuilder(
              animation: _blinkController,
              builder: (_, __) => Container(
                color: Colors.black.withOpacity(_blinkController.value * 0.15),
              ),
            ),
        ]);
      },
    );
  }
}
