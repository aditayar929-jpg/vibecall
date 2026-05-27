import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/online_avatar.dart';
import '../../../../shared/services/bot_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  int _onlineCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 80 && !_showTitle) {
        setState(() => _showTitle = true);
      } else if (_scrollController.offset <= 80 && _showTitle) {
        setState(() => _showTitle = false);
      }
    });
    _markUserOnline();
    _watchOnlineUsers();
    _autoStartCallForNewUser();
  }

  void _markUserOnline() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      }).catchError((_) {});
    }
  }

  void _watchOnlineUsers() {
    FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) setState(() => _onlineCount = snapshot.docs.length);
    });
  }

  void _autoStartCallForNewUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return;

    // If user has profile complete but hasn't done first call yet
    final hasProfile = (data['name']?.toString().isNotEmpty ?? false);
    final hasDoneFirstCall = data['hasDoneFirstCall'] ?? false;

    if (hasProfile && !hasDoneFirstCall && mounted) {
      // Show auto-match dialog after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _showAutoMatchDialog();
      });
    }
  }

  void _showAutoMatchDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.videocam_rounded, color: AppColors.neonPink, size: 28),
            SizedBox(width: 10),
            Text('Start Meeting!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '$_onlineCount users are online right now!\nStart a random video call and meet someone new.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Mark as done so we don't show again
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'hasDoneFirstCall': true,
                }).catchError((_) {});
              }
            },
            child: Text('Later', style: TextStyle(color: Colors.white.withOpacity(0.4))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'hasDoneFirstCall': true,
                }).catchError((_) {});
              }
              context.push('/matching');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Start Call', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: AnimatedOpacity(
                opacity: _showTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Text(
                  'VibeCall',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () => context.push('/edit-profile'),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_rounded, size: 28),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.neonPink,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/wallet'),
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: AppColors.coinGold, size: 22),
                      const SizedBox(width: 4),
                      Text(
                        '520',
                        style: TextStyle(
                          color: AppColors.coinGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(width: 12),
                        Text(
                          'Search people...',
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: -0.1),
              ),
            ),

            // Stories Section
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildAddStory();
                    }
                    return OnlineAvatar(
                      name: ['Ava', 'Liam', 'Mia', 'Noah', 'Zoe', 'Eli', 'Luna'][index - 1],
                      isOnline: index < 4,
                      index: index,
                    );
                  },
                ),
              ).animate().fadeIn(delay: 100.ms),
            ),

            // Start Matching Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/matching');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Random Video Call',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _onlineCount > 0
                                    ? '$_onlineCount people online - tap to connect!'
                                    : 'Match with someone new now!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95), delay: 200.ms),
              ),
            ),

            // Online Users (using bot profiles with real photos)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Online Now',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.push('/matching'),
                      child: const Text('See All', style: TextStyle(color: AppColors.neonPink)),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final bot = BotService.getBotByIndex(index);
                    return _buildOnlineUserCard(
                      bot['name'],
                      bot['age'],
                      bot['avatar'],
                      bot['city'],
                      index,
                    );
                  },
                ),
              ).animate().fadeIn(delay: 400.ms),
            ),

            // Trending Profiles (using bot profiles with real photos)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trending',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.push('/dating'),
                      child: const Text('See All', style: TextStyle(color: AppColors.neonPink)),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final bot = BotService.getBotByIndex(index + 10);
                    return _buildTrendingCard(bot['name'], bot['age'], bot['avatar'], bot['city'], index);
                  },
                  childCount: 6,
                ),
              ),
            ),

            // Premium Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: GestureDetector(
                  onTap: () => context.push('/premium'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.coinGold.withOpacity(0.2),
                          AppColors.neonPink.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.coinGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.premiumGradient),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Go Premium',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.coinGold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unlimited calls, swipes & more!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: AppColors.coinGold, size: 20),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ),
            ),

            // Dating Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: const Text(
                  'Find Your Match',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 700.ms),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => context.push('/dating'),
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.neonPink.withOpacity(0.3),
                          AppColors.primaryPurple.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite_rounded, color: AppColors.neonPink, size: 50),
                        const SizedBox(height: 12),
                        const Text(
                          'Swipe & Match',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover people near you',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.95, 0.95), delay: 800.ms),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryPurple, width: 2),
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.primaryPurple, size: 28),
          ),
          const SizedBox(height: 6),
          const Text('Your Story', style: TextStyle(fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildOnlineUserCard(String name, int age, String avatar, String city, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => context.push('/matching'),
        child: Container(
          width: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cardBackground,
                AppColors.surfaceColor.withOpacity(0.5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurple.withOpacity(0.3),
                                AppColors.neonPink.withOpacity(0.2),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.person_rounded, size: 50, color: Colors.white.withOpacity(0.3)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.onlineGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$name, $age',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        city,
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingCard(String name, int age, String avatar, String city, int index) {
    return GestureDetector(
      onTap: () => context.push('/matching'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.cardBackground, AppColors.surfaceColor.withOpacity(0.5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryPurple.withOpacity(0.2),
                              AppColors.neonPink.withOpacity(0.15),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.person_rounded, size: 60, color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite_rounded, color: AppColors.neonPink, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${(index + 1) * 120}',
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index < 2)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.premiumGradient),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('VIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$name, $age',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(city,
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
