import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../post/post_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Notification initialization is handled in main.dart
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsyncValue = ref.watch(usersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search people...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
              )
            : const Text('Quick Chat', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.dynamic_feed),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostScreen())),
            tooltip: 'Feed',
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'Profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              } else if (val == 'Logout') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Profile', child: Text('Profile')),
              const PopupMenuItem(value: 'Logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: usersAsyncValue.when(
        data: (users) => _buildUserList(users),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => _isSearching = true);
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildUserList(List<UserModel> users) {
    if (users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    final currentUserId = ref.read(authStateProvider).value?.uid;

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];

        return Consumer(builder: (context, ref, child) {
          final chatId = ref.read(chatRepositoryProvider).getChatId(currentUserId ?? '', user.uid);
          final chatStream = FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots();

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: chatStream,
            builder: (context, chatSnapshot) {
              String lastMessage = '';
              int timestamp = 0;

              int unreadCount = 0;

              if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
                final data = chatSnapshot.data!.data()!;
                lastMessage = data['lastMessage'] ?? '';
                timestamp = data['timestamp'] ?? 0;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .where('receiverId', isEqualTo: currentUserId)
                    .where('status', isEqualTo: 'sent')
                    .snapshots(),
                builder: (context, unreadSnapshot) {
                  if (unreadSnapshot.hasData) {
                    unreadCount = unreadSnapshot.data!.docs.length;
                  }

                  return ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: user.profilePhoto.isNotEmpty ? NetworkImage(user.profilePhoto) : null,
                          child: user.profilePhoto.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        if (user.isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      lastMessage.isNotEmpty ? lastMessage : 'Start a conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        fontStyle: lastMessage.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (timestamp != 0)
                          Text(
                            DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(timestamp)),
                            style: TextStyle(
                              fontSize: 12,
                              color: unreadCount > 0 ? Colors.green : Colors.grey,
                            ),
                          ),
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatScreen(receiver: user)),
                      );
                    },
                  );
                },
              );
            },
          );
        });
      },
    );
  }
}
