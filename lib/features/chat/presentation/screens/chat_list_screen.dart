import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chats = [
      _ChatData('Sophia Rose', 'Hey! How are you doing? 💕', '2m ago', true, true, 92),
      _ChatData('Emma Watson', 'That sounds amazing!', '15m ago', true, false, 87),
      _ChatData('Olivia Chen', 'Let\'s meet up soon 🎉', '1h ago', false, true, 95),
      _ChatData('Ava Mitchell', 'Thanks for the call!', '2h ago', false, false, 78),
      _ChatData('Isabella Lee', 'You: See you tomorrow!', '3h ago', false, false, 84),
      _ChatData('Mia Garcia', 'That was so fun 😂', '5h ago', true, false, 76),
      _ChatData('Luna Park', 'You: Good night! 🌙', '1d ago', false, false, 69),
      _ChatData('Chloe Kim', 'What are you up to?', '2d ago', false, false, 71),
    ];

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
              snap: true,
              backgroundColor: Colors.transparent,
              title: const Text('Messages', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_square, size: 24),
                ),
              ],
            ),

            // Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3)),
                      const SizedBox(width: 12),
                      Text('Search conversations...', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                    ],
                  ),
                ),
              ).animate().fadeIn(),
            ),

            // New matches row
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: const Text(
                      'New Matches',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.neonPink),
                    ),
                  ),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final names = ['Sophia', 'Emma', 'Olivia', 'Ava', 'Isabella'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPurple.withOpacity(0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(2.5),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: AppColors.background,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      names[index][0],
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(names[index], style: const TextStyle(fontSize: 11, color: Colors.white60)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ).animate().fadeIn(delay: 100.ms),
            ),

            // Chat list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chat = chats[index];
                  return _buildChatTile(context, chat, index);
                },
                childCount: chats.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, _ChatData chat, int index) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/chat-detail?chatId=$index&name=${chat.name}&avatar=');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: chat.isUnread ? AppColors.primaryPurple.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryPurple.withOpacity(0.3),
                        AppColors.neonPink.withOpacity(0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      chat.name[0],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (chat.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.onlineGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: chat.isUnread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        chat.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: chat.isUnread ? AppColors.neonPink : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (chat.isMatch)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.primaryGradient),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Match', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: chat.isUnread ? Colors.white70 : Colors.white38,
                            fontWeight: chat.isUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.isUnread)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.neonPink,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('1', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 200 + index * 60)).slideX(begin: -0.05, delay: Duration(milliseconds: 200 + index * 60)),
    );
  }
}

class _ChatData {
  final String name;
  final String lastMessage;
  final String time;
  final bool isOnline;
  final bool isUnread;
  final int matchPercent;
  final bool isMatch;

  _ChatData(this.name, this.lastMessage, this.time, this.isOnline, this.isUnread, this.matchPercent, {this.isMatch = false});
}
