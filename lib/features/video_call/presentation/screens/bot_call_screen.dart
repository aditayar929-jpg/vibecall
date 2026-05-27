import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/bot_service.dart';

class BotCallScreen extends StatefulWidget {
  final Map<String, dynamic> botProfile;
  final String callType;

  const BotCallScreen({
    super.key,
    required this.botProfile,
    this.callType = 'video',
  });

  @override
  State<BotCallScreen> createState() => _BotCallScreenState();
}

class _BotCallScreenState extends State<BotCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _avatarAnimController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  // Call state
  bool _isConnected = false;
  bool _isMuted = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  int _callDuration = 0;
  Timer? _durationTimer;
  bool _callEnded = false;

  // Chat
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  Timer? _messageTimer;
  late List<String> _chatScript;
  int _messageIndex = 0;
  bool _showChat = false;
  bool _isTyping = false;

  // Reactions
  String? _currentReaction;
  Timer? _reactionTimer;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _avatarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _chatScript = BotService.getRandomChatScript();

    _startCall();
  }

  Future<void> _startCall() async {
    // Simulate connecting animation (1-2 seconds)
    await Future.delayed(Duration(seconds: 1 + _random.nextInt(2)));

    if (!mounted) return;

    setState(() => _isConnected = true);

    // Start call timer
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _callDuration++);
    });

    // Start sending chat messages
    _startBotChat();

    // Auto-hide controls
    _startHideControlsTimer();

    // Random reactions
    _startRandomReactions();

    // Bot disconnects after random duration (30-90 seconds)
    _scheduleBotDisconnect();
  }

  void _startBotChat() {
    // First message after 2-4 seconds
    Future.delayed(Duration(seconds: 2 + _random.nextInt(3)), () {
      if (mounted && !_callEnded) _sendBotMessage();
    });
  }

  void _sendBotMessage() {
    if (_callEnded || _messageIndex >= _chatScript.length) return;

    setState(() => _isTyping = true);

    // Typing animation for 1-3 seconds
    Future.delayed(Duration(seconds: 1 + _random.nextInt(3)), () {
      if (!mounted || _callEnded) return;

      setState(() {
        _isTyping = false;
        _messages.add({
          'text': _chatScript[_messageIndex],
          'isMe': false,
          'time': DateTime.now(),
        });
        _messageIndex++;
      });

      _scrollToBottom();

      // Schedule next message (4-8 seconds later)
      if (_messageIndex < _chatScript.length) {
        _messageTimer = Timer(
          Duration(seconds: 4 + _random.nextInt(5)),
          () => _sendBotMessage(),
        );
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendUserMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': DateTime.now(),
      });
    });

    _chatController.clear();
    _scrollToBottom();

    // Bot replies after delay
    if (_messageIndex < _chatScript.length) {
      Future.delayed(Duration(seconds: 2 + _random.nextInt(3)), () {
        if (mounted && !_callEnded) _sendBotMessage();
      });
    }
  }

  void _startRandomReactions() {
    _reactionTimer = Timer.periodic(
      Duration(seconds: 8 + _random.nextInt(12)),
      (timer) {
        if (!mounted || _callEnded) {
          timer.cancel();
          return;
        }
        setState(() => _currentReaction = BotService.getRandomReaction());
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _currentReaction = null);
        });
      },
    );
  }

  void _scheduleBotDisconnect() {
    final duration = BotService.getCallDuration();
    Future.delayed(duration, () {
      if (mounted && !_callEnded) _endCall(fromBot: true);
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideControlsTimer();
  }

  void _endCall({bool fromBot = false}) {
    if (_callEnded) return;
    _callEnded = true;

    _durationTimer?.cancel();
    _messageTimer?.cancel();
    _reactionTimer?.cancel();
    _hideControlsTimer?.cancel();

    HapticFeedback.heavyImpact();

    if (fromBot) {
      // Bot ended the call — show message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.botProfile['name']} ended the call',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryPurple,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // Navigate back after short delay
    Future.delayed(Duration(seconds: fromBot ? 2 : 0), () {
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _avatarAnimController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _durationTimer?.cancel();
    _messageTimer?.cancel();
    _reactionTimer?.cancel();
    _hideControlsTimer?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bot = widget.botProfile;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // ─── Full screen "video" (animated avatar) ─────────
            Positioned.fill(
              child: _isConnected
                  ? _buildVideoFeed(bot)
                  : _buildConnectingScreen(),
            ),

            // ─── Bot reaction overlay ──────────────────────────
            if (_currentReaction != null)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.25,
                right: 30,
                child: Text(
                  _currentReaction!,
                  style: const TextStyle(fontSize: 48),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.2, 1.2),
                      duration: const Duration(milliseconds: 300),
                    )
                    .then()
                    .fade(duration: const Duration(seconds: 1)),
              ),

            // ─── Top info bar ──────────────────────────────────
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
                    bottom: 16,
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
                      // Bot avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.neonPink, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            bot['avatar'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name + city
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${bot['name'] ?? 'User'}, ${bot['age'] ?? ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              bot['city'] ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Timer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatDuration(_callDuration),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ─── Chat overlay ──────────────────────────────────
            if (_showChat)
              Positioned(
                bottom: 120,
                left: 16,
                right: 16,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Messages
                      Flexible(
                        child: ListView.builder(
                          controller: _chatScrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length && _isTyping) {
                              return _buildTypingIndicator();
                            }
                            final msg = _messages[index];
                            return _buildChatBubble(msg);
                          },
                        ),
                      ),
                      // Input
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                onSubmitted: (_) => _sendUserMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _sendUserMessage,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: AppColors.primaryGradient,
                                  ),
                                ),
                                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ─── Bottom controls ───────────────────────────────
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    top: 20,
                    left: 30,
                    right: 30,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isMuted = !_isMuted);
                        },
                      ),
                      // Camera flip
                      _buildControlButton(
                        icon: Icons.cameraswitch_rounded,
                        label: 'Flip',
                        onTap: () => HapticFeedback.lightImpact(),
                      ),
                      // End call
                      GestureDetector(
                        onTap: _endCall,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red,
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                      // Chat toggle
                      _buildControlButton(
                        icon: _showChat ? Icons.chat_bubble : Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _showChat = !_showChat);
                        },
                      ),
                      // Gift
                      _buildControlButton(
                        icon: Icons.card_giftcard_rounded,
                        label: 'Gift',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showGiftSheet();
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // ─── Incoming message indicator (when chat is hidden) ─
            if (!_showChat && _messages.isNotEmpty)
              Positioned(
                bottom: 130,
                left: 20,
                child: GestureDetector(
                  onTap: () => setState(() => _showChat = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.neonPink.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bot['name'] ?? '',
                          style: const TextStyle(
                            color: AppColors.neonPink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _messages.last['text'].toString().length > 25
                              ? '${_messages.last['text'].toString().substring(0, 25)}...'
                              : _messages.last['text'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 300))
                      .slideX(begin: -0.2, end: 0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoFeed(Map<String, dynamic> bot) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Animated gradient background (simulating video)
        AnimatedBuilder(
          animation: _avatarAnimController,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      const Color(0xFF1A1A2E),
                      const Color(0xFF2D1B3D),
                      _avatarAnimController.value,
                    )!,
                    Color.lerp(
                      const Color(0xFF16213E),
                      const Color(0xFF1A1A2E),
                      _avatarAnimController.value,
                    )!,
                  ],
                ),
              ),
            );
          },
        ),
        // Bot avatar (large, centered)
        Center(
          child: AnimatedBuilder(
            animation: _avatarAnimController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + _avatarAnimController.value * 0.03,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.3 + _avatarAnimController.value * 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      bot['avatar'] ?? '',
                      fit: BoxFit.cover,
                      width: 200,
                      height: 200,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryPurple.withOpacity(0.3),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 80),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Audio wave effect at bottom (simulating voice)
        Positioned(
          bottom: 140,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (i) {
                  final delay = i * 0.1;
                  final height = 4.0 +
                      (12.0 * (0.5 + 0.5 * sin((_waveController.value * 2 * pi) + delay)));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 4,
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: AppColors.neonPink.withOpacity(0.6),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConnectingScreen() {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 120 + _pulseController.value * 20,
                  height: 120 + _pulseController.value * 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryPurple.withOpacity(0.3 - _pulseController.value * 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryPurple, width: 3),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          widget.botProfile['avatar'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Connecting with ${widget.botProfile['name'] ?? 'User'}...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryPurple.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primaryPurple.withOpacity(0.8)
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Text(
          msg['text'],
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 200));
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                final offset = i * 0.3;
                final opacity = 0.3 + 0.7 * (0.5 + 0.5 * sin(_waveController.value * 2 * pi + offset));
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(opacity),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showGiftSheet() {
    final gifts = [
      {'icon': Icons.favorite_rounded, 'name': 'Heart', 'cost': 10, 'color': AppColors.neonPink},
      {'icon': Icons.star_rounded, 'name': 'Star', 'cost': 20, 'color': AppColors.coinGold},
      {'icon': Icons.diamond_rounded, 'name': 'Diamond', 'cost': 50, 'color': AppColors.diamondBlue},
      {'icon': Icons.local_fire_department_rounded, 'name': 'Fire', 'cost': 30, 'color': Colors.orange},
      {'icon': Icons.auto_awesome_rounded, 'name': 'Magic', 'cost': 40, 'color': Colors.purple},
      {'icon': Icons.cake_rounded, 'name': 'Cake', 'cost': 15, 'color': Colors.pink},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send a Gift', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: gifts.length,
              itemBuilder: (context, index) {
                final gift = gifts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    // Show sent animation
                    setState(() => _currentReaction = '🎁');
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _currentReaction = null);
                    });
                    // Bot thanks
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted && !_callEnded) {
                        setState(() {
                          _messages.add({
                            'text': 'Thank you for the ${gift['name']}! ${gift['icon'] == Icons.favorite_rounded ? '❤️' : '😊'}',
                            'isMe': false,
                            'time': DateTime.now(),
                          });
                        });
                        _scrollToBottom();
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: (gift['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: (gift['color'] as Color).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(gift['icon'] as IconData, color: gift['color'] as Color, size: 36),
                        const SizedBox(height: 8),
                        Text(gift['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on_rounded, color: AppColors.coinGold, size: 14),
                            const SizedBox(width: 2),
                            Text('${gift['cost']}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
