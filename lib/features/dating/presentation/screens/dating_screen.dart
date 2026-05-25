import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';

class DatingScreen extends StatefulWidget {
  const DatingScreen({super.key});

  @override
  State<DatingScreen> createState() => _DatingScreenState();
}

class _DatingScreenState extends State<DatingScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _swipeController;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  final List<_ProfileData> _profiles = [
    _ProfileData(
      name: 'Sophia Rose',
      age: 23,
      distance: '2 km away',
      bio: 'Adventure seeker & coffee lover ☕',
      interests: ['Travel', 'Photography', 'Music', 'Yoga'],
      photos: 5,
      matchPercent: 92,
    ),
    _ProfileData(
      name: 'Emma Watson',
      age: 25,
      distance: '5 km away',
      bio: 'Book nerd who loves sunsets 📚🌅',
      interests: ['Reading', 'Art', 'Movies', 'Cooking'],
      photos: 4,
      matchPercent: 87,
    ),
    _ProfileData(
      name: 'Olivia Chen',
      age: 22,
      distance: '1 km away',
      bio: 'Dance like nobody is watching 💃',
      interests: ['Dance', 'Fitness', 'Music', 'Beach'],
      photos: 6,
      matchPercent: 95,
    ),
    _ProfileData(
      name: 'Ava Mitchell',
      age: 24,
      distance: '3 km away',
      bio: 'Tech geek & foodie 🍕💻',
      interests: ['Tech', 'Foodie', 'Gaming', 'Coffee'],
      photos: 3,
      matchPercent: 78,
    ),
    _ProfileData(
      name: 'Isabella Lee',
      age: 21,
      distance: '4 km away',
      bio: 'Nature lover & photographer 📸🌿',
      interests: ['Nature', 'Photography', 'Travel', 'Pets'],
      photos: 7,
      matchPercent: 84,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _onSwipeComplete(bool isLike) {
    HapticFeedback.mediumImpact();
    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = false;
      if (_currentIndex < _profiles.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
    });
    if (isLike) {
      _showMatchPopup();
    }
  }

  void _showMatchPopup() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cardBackground,
                AppColors.surfaceColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.neonPink.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonPink.withOpacity(0.2),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: AppColors.neonPink,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'It\'s a Match!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neonPink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You and ${_profiles[_currentIndex].name} liked each other',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Center(
                          child: Text(
                            'Keep Swiping',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.primaryGradient),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Send Message',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.0, 1.0),
            duration: 500.ms,
            curve: Curves.elasticOut,
          ),
    );
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
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discover',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 22),
                    ),
                  ],
                ),
              ),

              // Card Stack
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background cards
                    if (_currentIndex + 2 < _profiles.length)
                      Positioned(
                        top: 20,
                        child: _buildCard(_profiles[_currentIndex + 2], scale: 0.9, opacity: 0.3),
                      ),
                    if (_currentIndex + 1 < _profiles.length)
                      Positioned(
                        top: 10,
                        child: _buildCard(_profiles[_currentIndex + 1], scale: 0.95, opacity: 0.6),
                      ),
                    // Current card
                    GestureDetector(
                      onPanStart: (details) => setState(() => _isDragging = true),
                      onPanUpdate: (details) {
                        setState(() {
                          _dragOffset += details.delta;
                        });
                      },
                      onPanEnd: (details) {
                        if (_dragOffset.dx > 150) {
                          _onSwipeComplete(true);
                        } else if (_dragOffset.dx < -150) {
                          _onSwipeComplete(false);
                        } else {
                          setState(() {
                            _dragOffset = Offset.zero;
                            _isDragging = false;
                          });
                        }
                      },
                      child: Transform.translate(
                        offset: _dragOffset,
                        child: Transform.rotate(
                          angle: _dragOffset.dx * 0.001,
                          child: _buildCard(_profiles[_currentIndex]),
                        ),
                      ),
                    ),

                    // Swipe indicators
                    if (_isDragging) ...[
                      if (_dragOffset.dx > 50)
                        Positioned(
                          top: 50,
                          left: 30,
                          child: Transform.rotate(
                            angle: -0.3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.successGreen, width: 3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'LIKE',
                                style: TextStyle(
                                  color: AppColors.successGreen,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_dragOffset.dx < -50)
                        Positioned(
                          top: 50,
                          right: 30,
                          child: Transform.rotate(
                            angle: 0.3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.errorRed, width: 3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'NOPE',
                                style: TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.close_rounded,
                      color: AppColors.errorRed,
                      size: 56,
                      onTap: () => _onSwipeComplete(false),
                    ),
                    _buildActionButton(
                      icon: Icons.star_rounded,
                      color: AppColors.superLikeBlue,
                      size: 48,
                      onTap: () => _onSwipeComplete(true),
                    ),
                    _buildActionButton(
                      icon: Icons.favorite_rounded,
                      color: AppColors.successGreen,
                      size: 64,
                      isLarge: true,
                      onTap: () => _onSwipeComplete(true),
                    ),
                    _buildActionButton(
                      icon: Icons.flash_on_rounded,
                      color: AppColors.coinGold,
                      size: 48,
                      onTap: () {},
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

  Widget _buildCard(_ProfileData profile, {double scale = 1.0, double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: MediaQuery.of(context).size.width - 40,
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [
                AppColors.cardBackground,
                AppColors.surfaceColor.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                // Photo placeholder
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryPurple.withOpacity(0.3),
                        AppColors.neonPink.withOpacity(0.2),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 120,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),

                // Match percentage
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.matchPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Photo count
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        profile.photos,
                        (i) => Container(
                          width: 16,
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: i == 0 ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),

                // Profile info
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${profile.name}, ${profile.age}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.verifiedBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: AppColors.verifiedBlue,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.neonPink, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            profile.distance,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile.bio,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.interests
                            .map((interest) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primaryPurple.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    interest,
                                    style: TextStyle(
                                      color: AppColors.lightPurple,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    bool isLarge = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isLarge ? null : AppColors.cardBackground,
          gradient: isLarge
              ? const LinearGradient(colors: AppColors.primaryGradient)
              : null,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            if (isLarge)
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Icon(icon, color: color, size: isLarge ? 32 : 26),
      ),
    );
  }
}

class _ProfileData {
  final String name;
  final int age;
  final String distance;
  final String bio;
  final List<String> interests;
  final int photos;
  final int matchPercent;

  _ProfileData({
    required this.name,
    required this.age,
    required this.distance,
    required this.bio,
    required this.interests,
    required this.photos,
    required this.matchPercent,
  });
}
