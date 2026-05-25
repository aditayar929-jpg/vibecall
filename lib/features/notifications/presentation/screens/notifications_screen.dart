import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      _NotificationData(Icons.favorite_rounded, 'New Match!', 'You and Sophia Rose matched', '2m ago', AppColors.neonPink, true),
      _NotificationData(Icons.videocam_rounded, 'Missed Call', 'Emma Watson tried to video call you', '15m ago', AppColors.primaryPurple, true),
      _NotificationData(Icons.monetization_on_rounded, 'Coins Received', 'You earned 10 coins from daily reward', '1h ago', AppColors.coinGold, false),
      _NotificationData(Icons.chat_rounded, 'New Message', 'Olivia Chen sent you a message', '2h ago', AppColors.diamondBlue, false),
      _NotificationData(Icons.person_add_rounded, 'New Follower', 'Ava Mitchell started following you', '3h ago', AppColors.successGreen, false),
      _NotificationData(Icons.diamond_rounded, 'Premium Activated', 'Your VIP membership is now active', '5h ago', AppColors.coinGold, false),
      _NotificationData(Icons.star_rounded, 'Profile Featured', 'Your profile was featured in Trending', '1d ago', AppColors.neonPink, false),
      _NotificationData(Icons.card_giftcard_rounded, 'Gift Received', 'Isabella Lee sent you a Diamond gift', '1d ago', AppColors.diamondBlue, false),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read', style: TextStyle(color: AppColors.neonPink, fontSize: 13)),
          ),
        ],
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: notif.isUnread
                      ? AppColors.primaryPurple.withOpacity(0.06)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: notif.isUnread
                        ? AppColors.primaryPurple.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: notif.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(notif.icon, color: notif.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: notif.isUnread ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (notif.isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.neonPink,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notif.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notif.time,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 100 + index * 60)).slideX(begin: -0.03, delay: Duration(milliseconds: 100 + index * 60));
          },
        ),
      ),
    );
  }
}

class _NotificationData {
  final IconData icon;
  final String title;
  final String description;
  final String time;
  final Color color;
  final bool isUnread;

  _NotificationData(this.icon, this.title, this.description, this.time, this.color, this.isUnread);
}
