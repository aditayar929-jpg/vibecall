import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/call_service.dart';
import '../../../../shared/services/firestore_service.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  final CallService _callService = CallService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isSearching = true;
  bool _matchFound = false;
  Map<String, dynamic>? _matchedUser;
  String _selectedGender = 'All';
  double _maxDistance = 50;
  RangeValues _ageRange = const RangeValues(18, 35);
  Stream<QuerySnapshot>? _queueStream;

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

    _startMatching();
  }

  Future<void> _startMatching() async {
    setState(() {
      _isSearching = true;
      _matchFound = false;
      _matchedUser = null;
    });

    // Add self to matching queue with profile data
    await _firestoreService.addToMatchingQueue(
      genderFilter: _selectedGender,
      minAge: _ageRange.start.toInt(),
      maxAge: _ageRange.end.toInt(),
    );

    // Try compatible matching first
    final match = await _firestoreService.findCompatibleMatch(
      genderFilter: _selectedGender,
      minAge: _ageRange.start.toInt(),
      maxAge: _ageRange.end.toInt(),
    );

    if (match != null && mounted) {
      setState(() {
        _matchedUser = match;
        _matchFound = true;
        _isSearching = false;
      });

      await _firestoreService.removeFromMatchingQueue();

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _startVideoCall();
      });
      return;
    }

    // Fall back to queue watching
    _queueStream = _firestoreService.watchMatchingQueue(genderFilter: _selectedGender);
    _queueStream?.listen((snapshot) async {
      if (!_isSearching || !mounted) return;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['uid'] != FirebaseAuth.instance.currentUser?.uid) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(data['uid'])
              .get();

          if (userDoc.exists && mounted) {
            final userData = userDoc.data()!;
            setState(() {
              _matchedUser = {'uid': data['uid'], ...userData};
              _matchFound = true;
              _isSearching = false;
            });

            await _firestoreService.removeFromMatchingQueue();

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _startVideoCall();
            });
            return;
          }
        }
      }
    });
  }

  void _skipAndFindNext() async {
    await _firestoreService.removeFromMatchingQueue();
    _startMatching();
  }

  Future<void> _startVideoCall() async {
    if (_matchedUser == null) return;

    final result = await _callService.initiateCall(
      calleeId: _matchedUser!['uid'],
      calleeName: _matchedUser!['name'] ?? 'User',
      calleeAvatar: _matchedUser!['avatar'] ?? '',
      callType: 'video',
    );

    if (mounted) {
      context.push(
        '/video-call?callId=${result['callId']}&remoteUserId=${_matchedUser!['uid']}&isCaller=true',
      );
    }
  }

  void _cancelMatching() async {
    await _firestoreService.removeFromMatchingQueue();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _firestoreService.removeFromMatchingQueue();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
                      icon: const Icon(Icons.close_rounded, size: 28),
                    ),
                    const Text(
                      'Random Match',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => _showFilterSheet(),
                      icon: const Icon(Icons.tune_rounded, size: 24),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Matching animation
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

              const SizedBox(height: 40),

              Text(
                _matchFound ? 'Match Found!' : 'Finding someone for you...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _matchFound ? AppColors.successGreen : Colors.white,
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 12),

              if (_matchFound && _matchedUser != null)
                Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.primaryGradient),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (_matchedUser!['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _matchedUser!['name'] ?? 'User',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_matchedUser!['age'] ?? ''} • ${_matchedUser!['location'] ?? ''}',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

              if (_isSearching)
                Text(
                  'Looking for the perfect match',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
                ).animate().fadeIn(delay: 200.ms),

              const Spacer(),

              // Online users count
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('isOnline', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.onlineGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$count users online',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Cancel + Skip buttons
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: ['All', 'Male', 'Female', 'Other'].map((g) {
                  final isSelected = _selectedGender == g;
                  return GestureDetector(
                    onTap: () => setSheetState(() => _selectedGender = g),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryPurple.withOpacity(0.2) : AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryPurple : Colors.white12,
                        ),
                      ),
                      child: Text(
                        g,
                        style: TextStyle(
                          color: isSelected ? AppColors.lightPurple : Colors.white54,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                    style: const TextStyle(color: AppColors.neonPink),
                  ),
                ],
              ),
              RangeSlider(
                values: _ageRange,
                min: 18,
                max: 60,
                activeColor: AppColors.primaryPurple,
                inactiveColor: AppColors.surfaceColor,
                onChanged: (v) => setSheetState(() => _ageRange = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
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
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text('Apply & Search', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
