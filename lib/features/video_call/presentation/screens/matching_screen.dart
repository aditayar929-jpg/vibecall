import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/random_match_service.dart';
import '../../../../shared/services/bot_service.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _waveController;
  final RandomMatchService _matchService = RandomMatchService();
  final Random _random = Random();

  // ─── Matching state ──────────────────────────────────────────
  bool _isSearching = true;
  bool _matchFound = false;
  Map<String, dynamic>? _matchedUser;
  bool _isBotMatch = false;
  String _selectedGender = 'All';
  RangeValues _ageRange = const RangeValues(18, 35);
  Timer? _pollTimer;
  int _searchSeconds = 0;
  Timer? _searchTimer;
  int _onlineCount = 0;
  int _queueCount = 0;
  StreamSubscription? _onlineSub;
  StreamSubscription? _queueSub;
  StreamSubscription? _myQueueSub;

  // ─── Bot call state ──────────────────────────────────────────
  bool _inBotCall = false;
  bool _botConnected = false;
  int _callDuration = 0;
  Timer? _durationTimer;
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  Timer? _messageTimer;
  late List<String> _chatScript;
  int _messageIndex = 0;
  bool _showChat = false;
  bool _isTyping = false;
  bool _isMuted = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  String? _currentReaction;
  Timer? _reactionTimer;
  bool _callEnded = false;

  static const int _botMatchDelay = 8;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _matchService.setOnline();
    _watchOnlineCount();
    _watchQueueCount();
    _startMatching();
  }

  // ─── Online / Queue watchers ────────────────────────────────
  void _watchOnlineCount() {
    _onlineSub = FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final real = snapshot.docs.length;
        setState(() => _onlineCount = real < 10
            ? real + BotService.getSimulatedOnlineCount()
            : real);
      }
    });
  }

  void _watchQueueCount() {
    _queueSub = FirebaseFirestore.instance
        .collection('random_queue')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final real = snapshot.docs.length;
        setState(() => _queueCount = real < 3
            ? real + (5 + DateTime.now().millisecond % 10)
            : real);
      }
    });
  }

  // ─── Matching logic ─────────────────────────────────────────
  Future<void> _startMatching() async {
    setState(() {
      _isSearching = true;
      _matchFound = false;
      _matchedUser = null;
      _isBotMatch = false;
      _searchSeconds = 0;
      _inBotCall = false;
      _callEnded = false;
    });

    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _searchSeconds++);
    });

    await _matchService.joinQueue(
      genderFilter: _selectedGender,
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
    );

    _myQueueSub?.cancel();
    _myQueueSub = _matchService.watchMyQueue().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;
      if (data['status'] == 'matched' && mounted && _isSearching) {
        _myQueueSub?.cancel();
        _pollTimer?.cancel();
        _searchTimer?.cancel();
        final roomName = data['roomName'] as String;
        FirebaseFirestore.instance
            .collection('users')
            .doc(data['partnerUid'])
            .get()
            .then((partnerDoc) {
          final pd = partnerDoc.data();
          if (mounted) {
            setState(() {
              _matchFound = true;
              _isSearching = false;
              _isBotMatch = false;
              _matchedUser = pd ?? {'name': 'Stranger'};
            });
          }
        });
      }
    });

    final result = await _matchService.findMatch(
      genderFilter: _selectedGender,
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
    );

    if (result != null && result['matched'] == true) {
      _myQueueSub?.cancel();
      _pollTimer?.cancel();
      _searchTimer?.cancel();
      final partner = result['partner'] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _matchFound = true;
          _isSearching = false;
          _isBotMatch = false;
          _matchedUser = partner;
        });
      }
    } else {
      _startPolling();
      _scheduleBotFallback();
    }
  }

  void _scheduleBotFallback() {
    Future.delayed(const Duration(seconds: _botMatchDelay), () {
      if (!mounted || !_isSearching) return;

      final bot = BotService.getRandomBot(genderFilter: _selectedGender);
      _pollTimer?.cancel();
      _searchTimer?.cancel();
      _myQueueSub?.cancel();
      _matchService.leaveQueue();

      setState(() {
        _matchFound = true;
        _isSearching = false;
        _isBotMatch = true;
        _matchedUser = bot;
      });

      // Auto-start bot call after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _startBotCall(bot);
      });
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || !_isSearching) { timer.cancel(); return; }
      final result = await _matchService.findMatch(
        genderFilter: _selectedGender,
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
      );
      if (result != null && result['matched'] == true && mounted) {
        timer.cancel();
        _searchTimer?.cancel();
        _myQueueSub?.cancel();
        final partner = result['partner'] as Map<String, dynamic>;
        setState(() {
          _matchFound = true;
          _isSearching = false;
          _isBotMatch = false;
          _matchedUser = partner;
        });
      }
    });
  }

  // ─── Bot Call Logic ─────────────────────────────────────────
  void _startBotCall(Map<String, dynamic> bot) {
    setState(() {
      _inBotCall = true;
      _botConnected = false;
      _callDuration = 0;
      _messages.clear();
      _messageIndex = 0;
      _showChat = false;
      _isTyping = false;
      _isMuted = false;
      _showControls = true;
      _callEnded = false;
    });

    _chatScript = BotService.getRandomChatScript();

    // Simulate connecting (1-2 sec)
    Future.delayed(Duration(seconds: 1 + _random.nextInt(2)), () {
      if (!mounted) return;
      setState(() => _botConnected = true);

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => _callDuration++);
      });

      _startHideControlsTimer();
      _startBotChat();
      _startRandomReactions();
      _scheduleBotDisconnect(bot);
    });
  }

  void _startBotChat() {
    Future.delayed(Duration(seconds: 2 + _random.nextInt(3)), () {
      if (mounted && !_callEnded) _sendBotMessage();
    });
  }

  void _sendBotMessage() {
    if (_callEnded || _messageIndex >= _chatScript.length) return;
    setState(() => _isTyping = true);
    Future.delayed(Duration(seconds: 1 + _random.nextInt(3)), () {
      if (!mounted || _callEnded) return;
      setState(() {
        _isTyping = false;
        _messages.add({'text': _chatScript[_messageIndex], 'isMe': false, 'time': DateTime.now()});
        _messageIndex++;
      });
      _scrollToBottom();
      if (_messageIndex < _chatScript.length) {
        _messageTimer = Timer(Duration(seconds: 4 + _random.nextInt(5)), () => _sendBotMessage());
      }
    });
  }

  void _sendUserMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() => _messages.add({'text': text, 'isMe': true, 'time': DateTime.now()}));
    _chatController.clear();
    _scrollToBottom();
    if (_messageIndex < _chatScript.length) {
      Future.delayed(Duration(seconds: 2 + _random.nextInt(3)), () {
        if (mounted && !_callEnded) _sendBotMessage();
      });
    }
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

  void _startRandomReactions() {
    _reactionTimer = Timer.periodic(Duration(seconds: 8 + _random.nextInt(12)), (timer) {
      if (!mounted || _callEnded) { timer.cancel(); return; }
      setState(() => _currentReaction = BotService.getRandomReaction());
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _currentReaction = null);
      });
    });
  }

  void _scheduleBotDisconnect(Map<String, dynamic> bot) {
    final duration = BotService.getCallDuration();
    Future.delayed(duration, () {
      if (mounted && !_callEnded) _endBotCall(fromBot: true);
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _endBotCall({bool fromBot = false}) {
    if (_callEnded) return;
    _callEnded = true;
    _durationTimer?.cancel();
    _messageTimer?.cancel();
    _reactionTimer?.cancel();
    _hideControlsTimer?.cancel();
    HapticFeedback.heavyImpact();

    if (fromBot && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${_matchedUser?['name'] ?? 'User'} ended the call'),
        backgroundColor: AppColors.primaryPurple,
      ));
    }

    Future.delayed(Duration(seconds: fromBot ? 2 : 0), () {
      if (mounted) _goBackToMatching();
    });
  }

  void _goBackToMatching() {
    setState(() {
      _inBotCall = false;
      _botConnected = false;
      _callEnded = false;
      _matchFound = false;
      _isBotMatch = false;
      _matchedUser = null;
      _messages.clear();
    });
    _durationTimer?.cancel();
    _messageTimer?.cancel();
    _reactionTimer?.cancel();
    _hideControlsTimer?.cancel();
    _startMatching();
  }

  void _skipToNextBot() {
    HapticFeedback.lightImpact();
    _durationTimer?.cancel();
    _messageTimer?.cancel();
    _reactionTimer?.cancel();
    _hideControlsTimer?.cancel();
    _matchService.leaveQueue();
    _pollTimer?.cancel();
    _searchTimer?.cancel();
    _myQueueSub?.cancel();

    final bot = BotService.getNextBot(
      excludeName: _matchedUser?['name'] ?? '',
      genderFilter: _selectedGender,
    );
    setState(() {
      _matchFound = true;
      _isBotMatch = true;
      _matchedUser = bot;
      _inBotCall = false;
      _botConnected = false;
      _callEnded = false;
      _messages.clear();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _startBotCall(bot);
    });
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ─── Matching cancel / skip ─────────────────────────────────
  Future<void> _skipAndFindNext() async {
    HapticFeedback.lightImpact();
    await _matchService.leaveQueue();
    _pollTimer?.cancel();
    _searchTimer?.cancel();
    _myQueueSub?.cancel();
    _startMatching();
  }

  Future<void> _cancelMatching() async {
    HapticFeedback.lightImpact();
    _pollTimer?.cancel();
    _searchTimer?.cancel();
    _myQueueSub?.cancel();
    await _matchService.leaveQueue();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _waveController.dispose();
    _pollTimer?.cancel();
    _searchTimer?.cancel();
    _durationTimer?.cancel();
    _messageTimer?.cancel();
    _reactionTimer?.cancel();
    _hideControlsTimer?.cancel();
    _onlineSub?.cancel();
    _queueSub?.cancel();
    _myQueueSub?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    _matchService.leaveQueue();
    _matchService.setOffline();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // If in bot call, show call UI
    if (_inBotCall && _matchedUser != null) {
      return _buildBotCallScreen(_matchedUser!);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF12122A), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              if (_isSearching) _buildStatusText(),
              Expanded(child: Center(child: _buildCenterContent())),
              if (_isSearching) _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Matching screen widgets ─────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: _cancelMatching, icon: const Icon(Icons.arrow_back_ios_rounded, size: 22)),
          const Text('Random Video Call', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text('Searching... ${_searchSeconds}s',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.onlineGreen)),
              const SizedBox(width: 6),
              Text('$_onlineCount online',
                  style: TextStyle(color: AppColors.onlineGreen.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(width: 16),
              const Icon(Icons.queue_rounded, size: 14, color: AppColors.neonPink),
              const SizedBox(width: 4),
              Text('$_queueCount waiting',
                  style: TextStyle(color: AppColors.neonPink.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 220 + _pulseController.value * 30,
              height: 220 + _pulseController.value * 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primaryPurple.withOpacity(0.4 - _pulseController.value * 0.2),
                  AppColors.primaryPurple.withOpacity(0.1 - _pulseController.value * 0.05),
                  Colors.transparent,
                ]),
              ),
              child: Center(
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _matchFound
                          ? [AppColors.successGreen, AppColors.diamondBlue]
                          : AppColors.primaryGradient,
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(
                      color: (_matchFound ? AppColors.successGreen : AppColors.primaryPurple).withOpacity(0.5),
                      blurRadius: 40, spreadRadius: 5,
                    )],
                  ),
                  child: _matchFound
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 60)
                      : RotationTransition(
                          turns: _rotateController,
                          child: const Icon(Icons.sync_rounded, color: Colors.white, size: 60),
                        ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        Text(
          _matchFound ? 'Match Found!' : 'Looking for someone...',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
              color: _matchFound ? AppColors.successGreen : Colors.white),
        ),
        if (_matchFound && _matchedUser != null) ...[
          const SizedBox(height: 12),
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.successGreen, width: 3),
              boxShadow: [BoxShadow(color: AppColors.successGreen.withOpacity(0.4), blurRadius: 20, spreadRadius: 3)],
            ),
            child: ClipOval(
              child: _matchedUser!['avatar'] != null && (_matchedUser!['avatar'] as String).isNotEmpty
                  ? Image.network(_matchedUser!['avatar'], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white, size: 35))
                  : const Icon(Icons.person_rounded, color: Colors.white, size: 35),
            ),
          ),
          const SizedBox(height: 10),
          Text(_matchedUser!['name'] ?? 'Stranger',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
          if (_matchedUser!['age'] != null) ...[
            const SizedBox(height: 4),
            Text('${_matchedUser!['age']} years',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
          ],
        ],
        if (_isSearching) ...[
          const SizedBox(height: 8),
          Text('This may take a few seconds',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
        ],
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(height: 56,
              child: ElevatedButton(
                onPressed: _cancelMatching,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(height: 56,
              child: ElevatedButton.icon(
                onPressed: _skipAndFindNext,
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                label: const Text('Skip', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: AppColors.primaryPurple.withOpacity(0.5)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  //  BOT CALL SCREEN (inline)
  // ═════════════════════════════════════════════════════════════
  Widget _buildBotCallScreen(Map<String, dynamic> bot) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
          if (_showControls) _startHideControlsTimer();
        },
        child: Stack(
          children: [
            // Background video feed
            Positioned.fill(child: _botConnected ? _buildBotVideoFeed(bot) : _buildBotConnecting(bot)),

            // Reaction overlay
            if (_currentReaction != null)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.25, right: 30,
                child: Text(_currentReaction!, style: const TextStyle(fontSize: 48)),
              ),

            // Top bar
            if (_showControls)
              Positioned(top: 0, left: 0, right: 0,
                child: Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.7), Colors.transparent]),
                  ),
                  child: Row(
                    children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            border: Border.all(color: AppColors.neonPink, width: 2)),
                        child: ClipOval(
                          child: Image.network(bot['avatar'] ?? '', fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white, size: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${bot['name'] ?? 'User'}, ${bot['age'] ?? ''}',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(bot['city'] ?? '',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
                        child: Text(_fmt(_callDuration),
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'monospace')),
                      ),
                    ],
                  ),
                ),
              ),

            // Chat overlay
            if (_showChat) _buildChatOverlay(),

            // Bottom controls
            if (_showControls)
              Positioned(bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20, top: 20, left: 30, right: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent]),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCallBtn(icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          label: _isMuted ? 'Unmute' : 'Mute',
                          onTap: () { HapticFeedback.lightImpact(); setState(() => _isMuted = !_isMuted); }),
                      _buildCallBtn(icon: Icons.cameraswitch_rounded, label: 'Flip',
                          onTap: () => HapticFeedback.lightImpact()),
                      GestureDetector(
                        onTap: () => _endBotCall(),
                        child: Container(width: 64, height: 64,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red,
                              boxShadow: [BoxShadow(color: Colors.red, blurRadius: 20, spreadRadius: 2)]),
                          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                      _buildCallBtn(
                          icon: _showChat ? Icons.chat_bubble : Icons.chat_bubble_outline_rounded,
                          label: 'Chat',
                          onTap: () { HapticFeedback.lightImpact(); setState(() => _showChat = !_showChat); }),
                      _buildCallBtn(icon: Icons.skip_next_rounded, label: 'Next',
                          onTap: () { HapticFeedback.lightImpact(); _skipToNextBot(); }),
                    ],
                  ),
                ),
              ),

            // Chat preview bubble
            if (!_showChat && _messages.isNotEmpty)
              Positioned(bottom: 130, left: 20,
                child: GestureDetector(
                  onTap: () => setState(() => _showChat = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.neonPink.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(bot['name'] ?? '', style: const TextStyle(color: AppColors.neonPink, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(
                        _messages.last['text'].toString().length > 25
                            ? '${_messages.last['text'].toString().substring(0, 25)}...'
                            : _messages.last['text'],
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                      ),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotVideoFeed(Map<String, dynamic> bot) {
    return Stack(fit: StackFit.expand, children: [
      AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
              Color.lerp(const Color(0xFF1A1A2E), const Color(0xFF2D1B3D), _pulseController.value)!,
              Color.lerp(const Color(0xFF16213E), const Color(0xFF1A1A2E), _pulseController.value)!,
            ]),
          ),
        ),
      ),
      Center(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) => Transform.scale(
            scale: 1.0 + _pulseController.value * 0.03,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                BoxShadow(color: AppColors.primaryPurple.withOpacity(0.3 + _pulseController.value * 0.2),
                    blurRadius: 40, spreadRadius: 10),
              ]),
              child: ClipOval(
                child: Image.network(bot['avatar'] ?? '', fit: BoxFit.cover, width: 200, height: 200,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.primaryPurple.withOpacity(0.3),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 80))),
              ),
            ),
          ),
        ),
      ),
      Positioned(bottom: 140, left: 0, right: 0,
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) {
              final height = 4.0 + (12.0 * (0.5 + 0.5 * sin((_waveController.value * 2 * pi) + i * 0.1)));
              return Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 4, height: height,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: AppColors.neonPink.withOpacity(0.6)));
            }),
          ),
        ),
      ),
    ]);
  }

  Widget _buildBotConnecting(Map<String, dynamic> bot) {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryPurple, width: 3)),
          child: ClipOval(
            child: Image.network(bot['avatar'] ?? '', fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white, size: 40)),
          ),
        ),
        const SizedBox(height: 24),
        Text('Connecting with ${bot['name'] ?? 'User'}...',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPurple.withOpacity(0.7))),
      ])),
    );
  }

  Widget _buildChatOverlay() {
    return Positioned(bottom: 120, left: 16, right: 16,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: ListView.builder(
              controller: _chatScrollController, padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) return _buildTypingBubble();
                return _buildChatBubble(_messages[index]);
              },
            ),
          ),
          Container(padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
            child: Row(children: [
              Expanded(child: TextField(controller: _chatController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a message...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true, fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendUserMessage(),
              )),
              const SizedBox(width: 8),
              GestureDetector(onTap: _sendUserMessage,
                child: Container(width: 40, height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                      gradient: LinearGradient(colors: AppColors.primaryGradient)),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
              ),
            ]),
          ),
        ]),
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryPurple.withOpacity(0.8) : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Text(msg['text'], style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) {
              final opacity = 0.3 + 0.7 * (0.5 + 0.5 * sin(_waveController.value * 2 * pi + i * 0.3));
              return Container(margin: const EdgeInsets.symmetric(horizontal: 2), width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)));
            },
          )),
        ),
      ),
    );
  }

  Widget _buildCallBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 50, height: 50,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
          child: Icon(icon, color: Colors.white, size: 24)),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
      ]),
    );
  }
}
