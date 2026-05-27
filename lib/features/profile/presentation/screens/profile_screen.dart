import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF12122A), AppColors.background],
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final name = data['name'] ?? 'User';
            final avatar = data['avatar'] ?? '';
            final bio = data['bio'] ?? '';
            final age = data['age'] ?? '';
            final isVerified = data['isVerified'] ?? false;
            final isPremium = data['isPremium'] ?? false;
            final coins = data['coins'] ?? 0;
            final interests = List<String>.from(data['interests'] ?? []);
            final followers = data['followers'] ?? 0;
            final following = data['following'] ?? 0;
            final profileCompletion = data['profileCompletion'] ?? 50;

            return CustomScrollView(
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
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings coming soon!'), backgroundColor: AppColors.primaryPurple),
                        );
                      },
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
                              child: avatar.isNotEmpty
                                  ? ClipOval(child: Image.network(avatar, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.person_rounded, size: 50, color: Colors.white38))))
                                  : const Center(child: Icon(Icons.person_rounded, size: 50, color: Colors.white38)),
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
                          Text(
                            name,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.verifiedBlue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.verified_rounded, color: AppColors.verifiedBlue, size: 18),
                            ),
                          ],
                          if (isPremium) ...[
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
                        ],
                      ),
                      if (age.toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '$age years',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                        ),
                      ],
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            bio,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Stats
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Row(
                      children: [
                        _buildStat('$followers', 'Followers'),
                        Container(width: 1, height: 40, color: Colors.white12),
                        _buildStat('$following', 'Following'),
                        Container(width: 1, height: 40, color: Colors.white12),
                        _buildStat('$coins', 'Coins'),
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
                              Text('$profileCompletion%', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: profileCompletion / 100,
                              backgroundColor: AppColors.surfaceColor,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.successGreen),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profileCompletion < 100 ? 'Complete your profile to get more matches!' : 'Your profile is complete!',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ),
                ),

                // Interests
                if (interests.isNotEmpty)
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
                            children: interests
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
                        _buildMenuItem(Icons.account_balance_wallet_rounded, 'Wallet', '$coins coins remaining', AppColors.diamondBlue, () => context.push('/wallet')),
                        _buildMenuItem(Icons.notifications_rounded, 'Notifications', 'View notifications', AppColors.neonPink, () => context.push('/notifications')),
                        _buildMenuItem(Icons.shield_rounded, 'Safety Center', 'Manage your safety', AppColors.successGreen, () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Safety Center coming soon!'), backgroundColor: AppColors.successGreen),
                          );
                        }),
                        _buildMenuItem(Icons.help_rounded, 'Help & Support', 'Get help', AppColors.primaryPurple, () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Help & Support coming soon!'), backgroundColor: AppColors.primaryPurple),
                          );
                        }),
                        _buildMenuItem(Icons.info_outline_rounded, 'About', 'Version 1.0.0', Colors.white38, () {
                          HapticFeedback.lightImpact();
                          showAboutDialog(
                            context: context,
                            applicationName: 'VibeCall',
                            applicationVersion: '1.0.0',
                            applicationIcon: Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 28),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        _buildMenuItem(Icons.logout_rounded, 'Logout', '', AppColors.errorRed, () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) context.go('/login');
                        }),
                      ],
                    ).animate().fadeIn(delay: 500.ms),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
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
    return Builder(
      builder: (context) => GestureDetector(
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
      ),
    );
  }
}
