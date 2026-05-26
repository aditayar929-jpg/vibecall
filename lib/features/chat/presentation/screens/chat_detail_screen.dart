import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../../../shared/services/call_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String userAvatar;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  final CallService _callService = CallService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isTyping = false;

  String get _otherUid => widget.chatId.split('_').where((s) => s != _currentUid).join('_');

  @override
  void initState() {
    super.initState();
    _firestoreService.markMessagesAsRead(widget.chatId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    _firestoreService.sendMessage(chatId: widget.chatId, text: text);
    _messageController.clear();

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    final file = File(picked.path);
    final url = await _firestoreService.uploadPhoto(file, 'chat_images');
    await _firestoreService.sendMessage(
      chatId: widget.chatId,
      text: '📷 Photo',
      type: 'image',
      mediaUrl: url,
    );
  }

  Future<void> _sendGif(String gifUrl) async {
    HapticFeedback.lightImpact();
    await _firestoreService.sendMessage(
      chatId: widget.chatId,
      text: '🎞️ GIF',
      type: 'gif',
      mediaUrl: gifUrl,
    );
  }

  void _showReactionPicker(String messageId) {
    final reactions = ['❤️', '😂', '😮', '😢', '😡', '👍'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: reactions.map((emoji) => GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _firestoreService.addMessageReaction(widget.chatId, messageId, emoji);
            },
            child: Text(emoji, style: const TextStyle(fontSize: 32)),
          )).toList(),
        ),
      ),
    );
  }

  void _showGifPicker() {
    final popularGifs = [
      'https://media.giphy.com/media/l0MYt5jPR6QX5pnqM/giphy.gif',
      'https://media.giphy.com/media/3o7abKhOpu0NwenH3O/giphy.gif',
      'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif',
      'https://media.giphy.com/media/5GoVLqeAOo6PK/giphy.gif',
      'https://media.giphy.com/media/26BRBKqUiq586bRVm/giphy.gif',
      'https://media.giphy.com/media/l0MYGb1LuZ3n7dRnO/giphy.gif',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Send a GIF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: popularGifs.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _sendGif(popularGifs[index]);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        popularGifs[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surfaceColor,
                          child: const Center(child: Icon(Icons.gif_box_rounded, color: Colors.white38, size: 40)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startCall(String callType) async {
    HapticFeedback.heavyImpact();
    try {
      final otherUserData = await _firestoreService.getUserData(_otherUid);
      final otherName = otherUserData?['name'] ?? 'User';
      final otherAvatar = otherUserData?['avatar'] ?? '';

      final result = await _callService.initiateCall(
        calleeId: _otherUid,
        calleeName: otherName,
        calleeAvatar: otherAvatar,
        callType: callType,
      );

      if (mounted) {
        context.push('/video-call', extra: {
          'callId': result['callId'],
          'remoteUserId': _otherUid,
          'isCaller': true,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start call: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
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
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                right: 12,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground.withOpacity(0.8),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 22),
                  ),
                  // Avatar with online indicator
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_otherUid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final isOnline = snapshot.data?.data() != null
                          ? (snapshot.data!.data() as Map<String, dynamic>)['isOnline'] ?? false
                          : false;
                      return Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
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
                                widget.userName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.onlineGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.cardBackground, width: 2),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('chats')
                              .doc(widget.chatId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final data = snapshot.data?.data() as Map<String, dynamic>?;
                            final isOtherTyping = data?['typing_$_otherUid'] ?? false;
                            return Text(
                              isOtherTyping ? 'Typing...' : 'Online',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOtherTyping ? AppColors.neonPink : AppColors.onlineGreen.withOpacity(0.8),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Audio call button
                  IconButton(
                    onPressed: () => _startCall('audio'),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.call_rounded, color: AppColors.successGreen, size: 20),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Video call button
                  IconButton(
                    onPressed: () => _startCall('video'),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.primaryGradient),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert_rounded, size: 22),
                  ),
                ],
              ),
            ),

            // Messages from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryPurple),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.white.withOpacity(0.15)),
                          const SizedBox(height: 12),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs;

                  // Mark messages as read
                  _firestoreService.markMessagesAsRead(widget.chatId);

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index].data() as Map<String, dynamic>;
                      final isMe = msg['senderId'] == _currentUid;
                      final timestamp = msg['timestamp'] as Timestamp?;
                      final time = timestamp != null
                          ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                          : '';
                      final type = msg['type'] ?? 'text';

                      return _buildMessageBubble(
                        msg['text'] ?? '',
                        isMe,
                        time,
                        msg['isRead'] ?? false,
                        type,
                        msg['mediaUrl'] ?? '',
                        messageId: messages[index].id,
                        reactions: msg['reactions'] != null
                            ? Map<String, dynamic>.from(msg['reactions'])
                            : null,
                      );
                    },
                  );
                },
              ),
            ),

            // Input bar
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 8,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _showAttachmentOptions(),
                    icon: Icon(Icons.add_circle_rounded, color: AppColors.primaryPurple, size: 28),
                  ),
                  IconButton(
                    onPressed: () => _showGifPicker(),
                    icon: Icon(Icons.gif_box_rounded, color: AppColors.neonPink, size: 26),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (v) {
                                if (v.isNotEmpty && !_isTyping) {
                                  setState(() => _isTyping = true);
                                  _firestoreService.setTypingStatus(widget.chatId, true);
                                } else if (v.isEmpty && _isTyping) {
                                  setState(() => _isTyping = false);
                                  _firestoreService.setTypingStatus(widget.chatId, false);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.primaryGradient),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time, bool isRead, String type, String mediaUrl, {String messageId = '', Map<String, dynamic>? reactions}) {
    return GestureDetector(
      onLongPress: messageId.isNotEmpty ? () => _showReactionPicker(messageId) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isMe ? const LinearGradient(colors: AppColors.primaryGradient) : null,
                  color: isMe ? null : AppColors.cardBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if ((type == 'image' || type == 'gif') && mediaUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          mediaUrl,
                          width: 200,
                          height: type == 'gif' ? 120 : 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 200,
                            height: type == 'gif' ? 120 : 150,
                            color: AppColors.surfaceColor,
                            child: Icon(
                              type == 'gif' ? Icons.gif_box_rounded : Icons.image_rounded,
                              color: Colors.white38,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    if (type == 'text')
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(isMe ? 1.0 : 0.9),
                        ),
                      ),
                    // Reactions
                    if (reactions != null && reactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reactions.values.join(' '),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(isMe ? 0.7 : 0.3)),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isRead ? Icons.done_all_rounded : Icons.done_rounded,
                            size: 14,
                            color: isRead ? Colors.white70 : Colors.white38,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachOption(Icons.camera_alt_rounded, 'Camera', AppColors.neonPink, () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                  if (picked != null) {
                    final url = await _firestoreService.uploadPhoto(File(picked.path), 'chat_images');
                    _firestoreService.sendMessage(chatId: widget.chatId, text: '📷 Photo', type: 'image', mediaUrl: url);
                  }
                }),
                _buildAttachOption(Icons.photo_rounded, 'Gallery', AppColors.primaryPurple, () async {
                  Navigator.pop(context);
                  await _sendImage();
                }),
                _buildAttachOption(Icons.location_on_rounded, 'Location', AppColors.coinGold, () {
                  Navigator.pop(context);
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }
}
