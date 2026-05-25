import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Wallet'),
      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Balance',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('VIP Member', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.monetization_on_rounded, color: AppColors.coinGold, size: 36),
                        SizedBox(width: 12),
                        Text(
                          '520',
                          style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildBalanceAction(Icons.add_rounded, 'Buy'),
                        const SizedBox(width: 12),
                        _buildBalanceAction(Icons.send_rounded, 'Send'),
                        const SizedBox(width: 12),
                        _buildBalanceAction(Icons.history_rounded, 'History'),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 24),

              // Daily reward
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.successGreen.withOpacity(0.1),
                      AppColors.diamondBlue.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.successGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: AppColors.successGreen, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daily Reward', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Claim your free coins!', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.successGreen, AppColors.successGreen.withOpacity(0.7)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('Claim +10', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // Earn more
              const Text('Earn More Coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              _buildEarnOption(
                Icons.play_circle_rounded,
                'Watch Ad',
                '+5 coins',
                AppColors.diamondBlue,
                () {},
              ).animate().fadeIn(delay: 200.ms),

              _buildEarnOption(
                Icons.person_add_rounded,
                'Invite Friends',
                '+50 coins per referral',
                AppColors.successGreen,
                () {},
              ).animate().fadeIn(delay: 300.ms),

              _buildEarnOption(
                Icons.share_rounded,
                'Share App',
                '+20 coins',
                AppColors.neonPink,
                () {},
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

              // Buy coins
              const Text('Buy Coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildCoinPackage('100', '\$0.99', false),
                  _buildCoinPackage('500', '\$3.99', true),
                  _buildCoinPackage('1000', '\$6.99', false),
                  _buildCoinPackage('5000', '\$24.99', false),
                ],
              ),

              const SizedBox(height: 24),

              // Recent transactions
              const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              _buildTransaction('Video Call - Sophia', '-15', '2 hours ago', Icons.videocam_rounded, AppColors.errorRed),
              _buildTransaction('Gift Sent - Emma', '-30', '5 hours ago', Icons.favorite_rounded, AppColors.neonPink),
              _buildTransaction('Daily Reward', '+10', 'Yesterday', Icons.card_giftcard_rounded, AppColors.successGreen),
              _buildTransaction('Referral Bonus', '+50', '2 days ago', Icons.person_add_rounded, AppColors.diamondBlue),
              _buildTransaction('Coin Purchase', '+500', '3 days ago', Icons.shopping_bag_rounded, AppColors.coinGold),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceAction(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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

  Widget _buildCoinPackage(String coins, String price, bool isPopular) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? AppColors.coinGold.withOpacity(0.5) : Colors.white.withOpacity(0.05),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, color: AppColors.coinGold, size: 22),
                  const SizedBox(width: 6),
                  Text(coins, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(price, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.6))),
            ],
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.premiumGradient),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Best', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransaction(String title, String amount, String time, IconData icon, Color color) {
    final isPositive = amount.startsWith('+');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                Text(time, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3))),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.monetization_on_rounded, color: isPositive ? AppColors.successGreen : AppColors.errorRed, size: 16),
              const SizedBox(width: 4),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? AppColors.successGreen : AppColors.errorRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
