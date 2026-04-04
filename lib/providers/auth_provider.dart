/// Authentication Providers and Controllers.
/// Manages user login, registration, and session state using Riverpod and Firebase Auth.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

// Providers to watch the login state and handle user actions
final authStateProvider = StreamProvider<User?>((ref) { 
  final authRepository = ref.watch(authRepositoryProvider); // Access the Auth logic / gets the database helper
  return authRepository.authStateChange; // Watches if user logs in or out / updates the app instantly
});

// Provider to fetch specific user details from the database
final userDataProvider = FutureProvider.family<UserModel?, String>((ref, uid) {
  final authRepository = ref.watch(authRepositoryProvider); // Access the Auth logic / gets the database helper
  return authRepository.getUserData(uid); // Gets name and photo for a specific ID / fetches profile info
});

// The main controller that the UI talks to for buttons and logic
final authControllerProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(authRepository: ref.watch(authRepositoryProvider)); // Links the controller to the logic
});

// This class manages the "Loading" state and the login functions
class AuthController extends StateNotifier<bool> {
  final AuthRepository _authRepository; // Private variable for auth logic / the connection to Firebase

  AuthController({required AuthRepository authRepository}) 
    : _authRepository = authRepository, super(false); // Starts with 'false' / app is not loading at startup

  // Function to log in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    state = true; // Set state to true / shows the loading spinner in UI
    try {
      final creds = await _authRepository.signInWithEmail(email, password); // Tries to log in via Firebase
      if (creds.user != null) {
        await _authRepository.updateOnlineStatus(creds.user!.uid, true); // Set status to 'Online' / shows green dot
      }
      state = false; // Set state to false / hides the loading spinner
      return creds; // Success / user is now logged in
    } catch (e) {
      state = false; // Error happened / hide spinner so user can try again
      rethrow; // Send error to UI / show an alert message to the user
    }
  }

  // Function to create a new user account
  Future<UserCredential?> registerWithEmail(String email, String password, String name) async {
    state = true; // Show loading spinner / user is waiting for registration
    try {
      final creds = await _authRepository.registerWithEmail(email, password, name); // Create account in Firebase
      state = false; // Hide spinner / registration finished
      return creds; // Success / new user account created
    } catch (e) {
      state = false; // Error happened / stop loading
      rethrow; // Send error message / e.g. "Email already exists"
    }
  }

  // Function for Google Login
  Future<UserCredential?> signInWithGoogle() async {
    state = true; // Show loading spinner / Google popup is opening
    try {
      final creds = await _authRepository.signInWithGoogle(); // Tries Google authentication
      if (creds?.user != null) {
         await _authRepository.updateOnlineStatus(creds!.user!.uid, true); // Sets user to 'Online'
      }
      state = false; // Hide spinner
      return creds; // Success / logged in with Google account
    } catch (e) {
      state = false; // Error or user cancelled / stop loading
      rethrow; // Show what went wrong
    }
  }

  // Function to log out
  Future<void> signOut() async {
    state = true; // Show loading spinner / cleaning up session
    try {
      await _authRepository.signOut(); // Ends the session in Firebase
      state = false; // Hide spinner
    } catch (e) {
      state = false; // Error / stop loading
      rethrow; // Send error to UI
    }
  }

  // Function to send a reset link to email
  Future<void> sendPasswordResetEmail(String email) async {
    state = true; // Show loading spinner / sending the email
    try {
      await _authRepository.sendPasswordResetEmail(email); // Firebase sends the link
      state = false; // Hide spinner
    } catch (e) {
      state = false; // Error / stop loading
      rethrow; // Send error message / e.g. "Invalid Email"
    }
  }
}
