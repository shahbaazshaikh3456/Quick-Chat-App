import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).requestPermission();
    });
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
                  hintText: 'Search by name or email...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(user.profilePhoto),
                      backgroundColor: Colors.grey.shade300,
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
                subtitle: const Text('Tap to chat...'), // Placeholder for last message
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(receiver: user),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Future: Open list of users or a search dialog to start a new chat
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a user from the list to start chatting.')));
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}
