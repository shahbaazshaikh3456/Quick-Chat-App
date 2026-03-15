import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userDataAsync = ref.watch(userDataProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (userModel) {
          if (userModel == null) return const Center(child: Text('User not found'));
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(userModel.profilePhoto),
                ),
                const SizedBox(height: 24),
                Text(userModel.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(userModel.email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signOut();
                    Navigator.pop(context); // Pop back to close the Profile Screen, AuthChecker resets.
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
