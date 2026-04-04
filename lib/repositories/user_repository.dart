/// Repository for managing user profiles and broad user listings.
/// Provides streams for real-time user data and handles profile updates.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';


class UserRepository {
  final FirebaseFirestore firestore; // Connection to the database / used to talk to Firestore

  UserRepository({required this.firestore}); // Constructor / sets up the database tool

  // Gets a live list of every user registered in the app
  Stream<List<UserModel>> getUsers() {
    return firestore.collection('users').snapshots().map((snapshot) { // Listen to the 'users' folder / watches for any new sign-ups
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList(); // Convert to list / turns database rows into User objects
    });
  }

  // Listens to a single user's data (like their online status or bio)
  Stream<UserModel> getUserStream(String uid) {
    return firestore.collection('users').doc(uid).snapshots().map((doc) { // Watch one specific user / stays updated if their profile changes
      return UserModel.fromMap(doc.data()!, doc.id); // Convert to User object / turns raw data into a usable profile
    });
  }

  // Updates the entire user profile (name, bio, etc.)
  Future<void> updateUserProfile(UserModel user) async {
    await firestore.collection('users').doc(user.uid).set( // Go to the user's document / finds their specific "folder"
          user.toMap(), // Convert to database format / prepares the data to be saved
          SetOptions(merge: true), // Merge changes / only updates what changed without deleting other info
        );
  }

  // Specifically updates only the profile picture
  Future<void> updateProfileImage(String uid, String imageUrl) async {
    await firestore.collection('users').doc(uid).set({ // Find the user / targets the correct profile
      'profilePhoto': imageUrl, // Set new photo link / replaces the old image URL with the new one
    }, SetOptions(merge: true)); // Keep other info safe / ensures name and email aren't deleted
  }
}
