import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final UserModel receiver;

  const ChatScreen({super.key, required this.receiver});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatControllerProvider).sendMessage(widget.receiver.uid, text);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = ref.watch(messagesStreamProvider(widget.receiver.uid));
    final currentUserId = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.receiver.profilePhoto),
              radius: 18,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiver.name, style: const TextStyle(fontSize: 16)),
                Text(
                  widget.receiver.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.receiver.isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesStream.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(chatControllerProvider).markMessagesAsSeen(widget.receiver.uid);
                });

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                            bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              message.message,
                              style: TextStyle(color: isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87), fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(message.timestamp)),
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                                if (isMe) const SizedBox(width: 4),
                                if (isMe) Icon(
                                  message.status == 'seen' ? Icons.done_all : Icons.check,
                                  size: 14,
                                  color: message.status == 'seen' ? Colors.blue.shade100 : Colors.white70,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey.shade900 
                          : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
