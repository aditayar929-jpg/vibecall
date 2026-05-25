import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              title: const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  onPressed: () => context.push('/edit-profile'),
                  icon: const Icon(Icons.edit_rounded, size: 24),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.settings_rounded, size: 24),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.primaryGradient),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.person_rounded, size: 50, color: Colors.white38),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.primaryGradient),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Alex Johnson',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.verifiedBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.verified_rounded, color: AppColors.verifiedBlue, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.premiumGradient),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.diamond_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('VIP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '@alexjohnson • 24 years',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adventure seeker & coffee lover ☕\nExploring the world one vibe at a time 🌍',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),

            // Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    _buildStat('1,247', 'Followers'),
                    Container(width: 1, height: 40, color: Colors.white12),
                    _buildStat('432', 'Following'),
                    Container(width: 1, height: 40, color: Colors.white12),
                    _buildStat('89', 'Matches'),
                  ],
                ).animate().fadeIn(delay: 200.ms),
              ),
            ),

            // Profile completion
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Profile Completion', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('75%', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: 0.75,
                          backgroundColor: AppColors.surfaceColor,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.successGreen),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add 2 more photos to reach 100%',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ),
            ),

            // Interests
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Interests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Travel', 'Music', 'Photography', 'Coffee', 'Yoga', 'Art']
                          .map((interest) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
                                ),
                                child: Text(
                                  interest,
                                  style: TextStyle(color: AppColors.lightPurple, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
              ),
            ),

            // Menu items
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  children: [
                    _buildMenuItem(Icons.diamond_rounded, 'Go Premium', 'Unlock all features', AppColors.coinGold, () => context.push('/premium')),
                    _buildMenuItem(Icons.account_balance_wallet_rounded, 'Wallet', '520 coins remaining', AppColors.diamondBlue, () => context.push('/wallet')),
                    _buildMenuItem(Icons.notifications_rounded, 'Notifications', '3 new notifications', AppColors.neonPink, () => context.push('/notifications')),
                    _buildMenuItem(Icons.shield_rounded, 'Safety Center', 'Manage your safety', AppColors.successGreen, () {}),
                    _buildMenuItem(Icons.help_rounded, 'Help & Support', 'Get help', AppColors.primaryPurple, () {}),
                    _buildMenuItem(Icons.info_outline_rounded, 'About', 'Version 1.0.0', Colors.white38, () {}),
                    const SizedBox(height: 12),
                    _buildMenuItem(Icons.logout_rounded, 'Logout', '', AppColors.errorRed, () => context.go('/login')),
                  ],
                ).animate().fadeIn(delay: 500.ms),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}
