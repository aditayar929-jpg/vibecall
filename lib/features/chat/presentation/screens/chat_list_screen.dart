import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/firestore_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = (timestamp as Timestamp).toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  Future<Map<String, dynamic>> _getOtherUserData(List<String> users) async {
    final otherUid = users.firstWhere((u) => u != _currentUid, orElse: () => '');
    if (otherUid.isEmpty) return {'name': 'User', 'avatar': '', 'isOnline': false};
    final doc = await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
    return doc.data() ?? {'name': 'User', 'avatar': '', 'isOnline': false};
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

            // Chat list from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getUserChats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primaryPurple),
                    )),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text('No conversations yet', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Start matching to begin chatting!', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chatDoc = docs[index];
                      final chatData = chatDoc.data() as Map<String, dynamic>;
                      final chatId = chatDoc.id;
                      final users = List<String>.from(chatData['users'] ?? []);
                      final lastMessage = chatData['lastMessage'] ?? '';
                      final lastMessageTime = _formatTime(chatData['lastMessageTime']);
                      final isUnread = (chatData['lastSenderId'] ?? '') != _currentUid &&
                          (chatData['lastMessage'] ?? '').isNotEmpty;

                      return FutureBuilder<Map<String, dynamic>>(
                        future: _getOtherUserData(users),
                        builder: (context, userSnapshot) {
                          final userData = userSnapshot.data ?? {};
                          final name = userData['name'] ?? 'User';
                          final avatar = userData['avatar'] ?? '';
                          final isOnline = userData['isOnline'] ?? false;

                          return _buildChatTile(
                            context,
                            chatId: chatId,
                            name: name,
                            avatar: avatar,
                            lastMessage: lastMessage,
                            time: lastMessageTime,
                            isOnline: isOnline,
                            isUnread: isUnread,
                            index: index,
                          );
                        },
                      );
                    },
                    childCount: docs.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context, {
    required String chatId,
    required String name,
    required String avatar,
    required String lastMessage,
    required String time,
    required bool isOnline,
    required bool isUnread,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/chat-detail?chatId=$chatId&name=$name&avatar=$avatar');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.primaryPurple.withOpacity(0.08) : Colors.transparent,
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
                  child: avatar.isNotEmpty
                      ? ClipOval(child: Image.network(avatar, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(child: Text(name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)))))
                      : Center(child: Text(name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                ),
                if (isOnline)
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
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread ? AppColors.neonPink : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage.isEmpty ? 'Start chatting!' : lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: isUnread ? Colors.white70 : Colors.white38,
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                            fontStyle: lastMessage.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
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
