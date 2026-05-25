import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlan = 1;

  final List<Map<String, dynamic>> _plans = [
    {'duration': '1 Month', 'price': '\$9.99', 'perMonth': '\$9.99/mo', 'badge': ''},
    {'duration': '6 Months', 'price': '\$39.99', 'perMonth': '\$6.66/mo', 'badge': 'Popular'},
    {'duration': '12 Months', 'price': '\$59.99', 'perMonth': '\$4.99/mo', 'badge': 'Best Value'},
  ];

  final List<Map<String, dynamic>> _features = [
    {'icon': Icons.videocam_rounded, 'title': 'Unlimited Video Calls', 'desc': 'Call anyone without limits', 'color': AppColors.primaryPurple},
    {'icon': Icons.favorite_rounded, 'title': 'Unlimited Swipes', 'desc': 'Swipe as much as you want', 'color': AppColors.neonPink},
    {'icon': Icons.tune_rounded, 'title': 'Advanced Filters', 'desc': 'Filter by interests, location & more', 'color': AppColors.diamondBlue},
    {'icon': Icons.block_rounded, 'title': 'Ad-Free Experience', 'desc': 'No more interruptions', 'color': AppColors.successGreen},
    {'icon': Icons.rocket_launch_rounded, 'title': 'Profile Boost', 'desc': 'Get 10x more visibility', 'color': AppColors.coinGold},
    {'icon': Icons.diamond_rounded, 'title': 'VIP Badge', 'desc': 'Stand out with a premium badge', 'color': AppColors.coralPink},
    {'icon': Icons.star_rounded, 'title': 'Priority Matching', 'desc': 'Get matched first', 'color': AppColors.lightPurple},
    {'icon': Icons.card_giftcard_rounded, 'title': '500 Bonus Coins', 'desc': 'Free coins every month', 'color': AppColors.coinGold},
  ];

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
            colors: [Color(0xFF1A0A2E), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close_rounded, size: 28),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Restore', style: TextStyle(color: Colors.white54)),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Diamond icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.premiumGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coinGold.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.diamond_rounded, size: 40, color: Colors.white),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 20),

                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: AppColors.premiumGradient,
                  ).createShader(bounds),
                  child: const Text(
                    'VibeCall Premium',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 8),

                Text(
                  'Unlock the full experience',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 30),

                // Plans
                ...List.generate(_plans.length, (index) {
                  final plan = _plans[index];
                  final isSelected = _selectedPlan == index;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedPlan = index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.cardBackground : AppColors.cardBackground.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.coinGold : Colors.white.withOpacity(0.05),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppColors.coinGold.withOpacity(0.15), blurRadius: 15)]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.coinGold : Colors.white24,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(colors: AppColors.premiumGradient),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      plan['duration'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : Colors.white70,
                                      ),
                                    ),
                                    if (plan['badge'].isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: AppColors.premiumGradient),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          plan['badge'],
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  plan['perMonth'],
                                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            plan['price'],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.coinGold : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 400 + index * 100)).slideX(begin: -0.05, delay: Duration(milliseconds: 400 + index * 100));
                }),

                const SizedBox(height: 24),

                // Features
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('What You Get', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),

                ...List.generate(_features.length, (index) {
                  final feature = _features[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: (feature['color'] as Color).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(feature['icon'] as IconData, color: feature['color'] as Color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(feature['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(feature['desc'], style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 20),
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 700 + index * 60));
                }),

                const SizedBox(height: 30),

                // Subscribe button
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.premiumGradient),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.diamond_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'Subscribe for ${_plans[_selectedPlan]['price']}',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1200.ms),

                const SizedBox(height: 12),

                Text(
                  'Auto-renewable. Cancel anytime.',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.3)),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
