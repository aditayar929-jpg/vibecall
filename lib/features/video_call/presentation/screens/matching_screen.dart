import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/random_match_service.dart';
import '../../../../shared/services/bot_service.dart';
import 'bot_call_screen.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  final RandomMatchService _matchService = RandomMatchService();

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

  // After 8 seconds with no real user, auto-match with bot
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

    _matchService.setOnline();
    _watchOnlineCount();
    _watchQueueCount();
    _startMatching();
  }

  void _watchOnlineCount() {
    _onlineSub = FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          // Show real count + simulated minimum for UX
          final real = snapshot.docs.length;
          _onlineCount = real < 10
              ? real + BotService.getSimulatedOnlineCount()
              : real;
        });
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
        setState(() {
          final real = snapshot.docs.length;
          _queueCount = real < 3
              ? real + (5 + DateTime.now().millisecond % 10)
              : real;
        });
      }
    });
  }

  Future<void> _startMatching() async {
    setState(() {
      _isSearching = true;
      _matchFound = false;
      _matchedUser = null;
      _isBotMatch = false;
      _searchSeconds = 0;
    });

    // Start search timer
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _searchSeconds++);
    });

    // Join the Firestore queue
    await _matchService.joinQueue(
      genderFilter: _selectedGender,
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
    );

    // Listen for someone matching with us (passive listener)
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
        final partnerUid = data['partnerUid'] as String;

        FirebaseFirestore.instance
            .collection('users')
            .doc(partnerUid)
            .get()
            .then((partnerDoc) {
          final partnerData = partnerDoc.data();
          if (mounted) {
            setState(() {
              _matchFound = true;
              _isSearching = false;
              _isBotMatch = false;
              _matchedUser = partnerData ?? {'name': 'Stranger'};
            });

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _navigateToLiveCall(roomName, partnerData?['name'] ?? 'Stranger');
            });
          }
        });
      }
    });

    // Try to find a real match immediately
    final result = await _matchService.findMatch(
      genderFilter: _selectedGender,
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
    );

    if (result != null && result['matched'] == true) {
      _myQueueSub?.cancel();
      _pollTimer?.cancel();
      _searchTimer?.cancel();

      final roomName = result['roomName'] as String;
      final partner = result['partner'] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _matchFound = true;
          _isSearching = false;
          _isBotMatch = false;
          _matchedUser = partner;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _navigateToLiveCall(roomName, partner['name'] ?? 'Stranger');
        });
      }
    } else {
      // No immediate match — start polling + schedule bot fallback
      _startPolling();
      _scheduleBotFallback();
    }
  }

  void _scheduleBotFallback() {
    // After _botMatchDelay seconds, if still searching, match with a bot
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

      // Navigate to bot call after animation
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _navigateToBotCall(bot);
      });
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || !_isSearching) {
        timer.cancel();
        return;
      }

      final result = await _matchService.findMatch(
        genderFilter: _selectedGender,
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
      );

      if (result != null && result['matched'] == true && mounted) {
        timer.cancel();
        _searchTimer?.cancel();
        _myQueueSub?.cancel();

        final roomName = result['roomName'] as String;
        final partner = result['partner'] as Map<String, dynamic>;

        setState(() {
          _matchFound = true;
          _isSearching = false;
          _isBotMatch = false;
          _matchedUser = partner;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _navigateToLiveCall(roomName, partner['name'] ?? 'Stranger');
        });
      }
    });
  }

  void _navigateToLiveCall(String roomName, String partnerName) {
    context.push('/live-call', extra: {
      'roomName': roomName,
      'partnerName': partnerName,
      'enableVideo': true,
    }).then((_) {
      if (mounted) {
        setState(() {
          _isSearching = true;
          _matchFound = false;
        });
        _startMatching();
      }
    });
  }

  void _navigateToBotCall(Map<String, dynamic> bot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BotCallScreen(
          botProfile: bot,
          callType: 'video',
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isSearching = true;
          _matchFound = false;
        });
        _startMatching();
      }
    });
  }

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
    if (mounted) context.pop();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
              const Text('Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Show me', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              Row(
                children: ['All', 'Female', 'Male'].map((g) {
                  final isSelected = _selectedGender == g;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setSheetState(() => _selectedGender = g),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(colors: AppColors.primaryGradient)
                              : null,
                          color: isSelected ? null : AppColors.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Center(
                          child: Text(
                            g,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Age Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(
                    '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                    style: const TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              RangeSlider(
                values: _ageRange,
                min: 18,
                max: 60,
                divisions: 42,
                activeColor: AppColors.primaryPurple,
                inactiveColor: AppColors.surfaceColor,
                onChanged: (values) => setSheetState(() => _ageRange = values),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _pollTimer?.cancel();
                    _searchTimer?.cancel();
                    _myQueueSub?.cancel();
                    _matchService.leaveQueue();
                    _startMatching();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _pollTimer?.cancel();
    _searchTimer?.cancel();
    _onlineSub?.cancel();
    _queueSub?.cancel();
    _myQueueSub?.cancel();
    _matchService.leaveQueue();
    _matchService.setOffline();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _cancelMatching,
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 22),
                    ),
                    const Text(
                      'Random Video Call',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: _showFilterSheet,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.tune_rounded, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              // Status text
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        'Searching... ${_searchSeconds}s',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.onlineGreen,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_onlineCount online',
                            style: TextStyle(
                              color: AppColors.onlineGreen.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.queue_rounded, size: 14, color: AppColors.neonPink),
                          const SizedBox(width: 4),
                          Text(
                            '$_queueCount waiting',
                            style: TextStyle(
                              color: AppColors.neonPink.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Center animation
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsing ring
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 220 + _pulseController.value * 30,
                            height: 220 + _pulseController.value * 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primaryPurple.withOpacity(0.4 - _pulseController.value * 0.2),
                                  AppColors.primaryPurple.withOpacity(0.1 - _pulseController.value * 0.05),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _matchFound
                                        ? [AppColors.successGreen, AppColors.diamondBlue]
                                        : AppColors.primaryGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_matchFound ? AppColors.successGreen : AppColors.primaryPurple)
                                          .withOpacity(0.5),
                                      blurRadius: 40,
                                      spreadRadius: 5,
                                    ),
                                  ],
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
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _matchFound ? AppColors.successGreen : Colors.white,
                        ),
                      ),
                      if (_matchFound && _matchedUser != null) ...[
                        const SizedBox(height: 12),
                        // Matched user avatar
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.successGreen, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.successGreen.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _matchedUser!['avatar'] != null &&
                                    (_matchedUser!['avatar'] as String).isNotEmpty
                                ? Image.network(
                                    _matchedUser!['avatar'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 35,
                                    ),
                                  )
                                : const Icon(Icons.person_rounded, color: Colors.white, size: 35),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _matchedUser!['name'] ?? 'Stranger',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (_matchedUser!['age'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_matchedUser!['age']} years',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                        if (_isBotMatch) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'New user',
                              style: TextStyle(
                                color: AppColors.primaryPurple.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                      if (_isSearching) ...[
                        const SizedBox(height: 8),
                        Text(
                          'This may take a few seconds',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom buttons
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _cancelMatching,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cardBackground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _skipAndFindNext,
                            icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                            label: const Text(
                              'Skip',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
