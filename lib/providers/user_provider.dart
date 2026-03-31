/// User Listing and Search Providers.
/// Streams the list of all users and applies filters for local search.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'auth_provider.dart';

final userRepositoryProvider = Provider((ref) {
  return UserRepository(
    firestore: FirebaseFirestore.instance,
  );
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final currentUserResponse = ref.watch(authStateProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  
  return userRepository.getUsers().map((users) {
    List<UserModel> filtered = users;
    // Remove current user from the list
    if (currentUserResponse.value != null) {
      filtered = filtered.where((u) => u.uid != currentUserResponse.value!.uid).toList();
    }
    // Apply search filter locally
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((u) => 
        u.name.toLowerCase().contains(searchQuery) ||
        u.email.toLowerCase().contains(searchQuery)
      ).toList();
    }
    return filtered;
  });
});
