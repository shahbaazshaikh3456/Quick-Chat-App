/// User Listing and Search Providers.
/// Streams the list of all users and applies filters for local search.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'auth_provider.dart';

// Providers to manage user data and search state
final userRepositoryProvider = Provider((ref) {
  return UserRepository(
    firestore: FirebaseFirestore.instance, // Connects to the user database / tells the app where the user profiles are stored
  );
});

// A provider to hold whatever the user types in the search bar
final searchQueryProvider = StateProvider<String>((ref) => ''); // Stores the search text / starts as an empty box

// The main provider that gives the UI a filtered list of users
final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider); // Gets the database helper / links to the user data logic
  final currentUserResponse = ref.watch(authStateProvider); // Gets the currently logged-in user / used to identify "Me"
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase(); // Gets the search text / converts it to small letters for easy matching
  
  // Starts listening to the database for all users
  return userRepository.getUsers().map((users) {
    List<UserModel> filtered = users; // Starts with the full list / creates a temporary list of everyone
    
    // Logic to hide your own profile from the list
    if (currentUserResponse.value != null) {
      filtered = filtered.where((u) => u.uid != currentUserResponse.value!.uid).toList(); // Remove "Me" / ensures you don't chat with yourself
    }
    
    // Logic to filter the list based on what you typed
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((u) => 
        u.name.toLowerCase().contains(searchQuery) || // Check if name matches / looks for the search text in user names
        u.email.toLowerCase().contains(searchQuery)    // Check if email matches / looks for the search text in emails
      ).toList(); // Keeps only the people who match / updates the list on the screen
    }
    
    return filtered; // Returns the final list / shows only the relevant users on the UI
  });
});
