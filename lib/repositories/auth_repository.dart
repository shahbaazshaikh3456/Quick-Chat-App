/// Repository handling Firebase Authentication and Google Sign-In.
/// Also manages user data persistence and online status in Firestore.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

// Provider to give the app access to this repository
final authRepositoryProvider = Provider((ref) => AuthRepository(
  auth: FirebaseAuth.instance, // Connects to Firebase Login system / handles passwords and accounts
  firestore: FirebaseFirestore.instance, // Connects to Database / handles saving user profiles
  googleSignIn: GoogleSignIn(), // Connects to Google / allows "One-Tap" login
));

class AuthRepository {
  final FirebaseAuth auth; // Variable to hold login tools / used for authentication tasks
  final FirebaseFirestore firestore; // Variable to hold database tools / used for profile storage
  final GoogleSignIn googleSignIn; // Variable for Google login / handles Google account access

  // Constructor / sets up the tools whenever the repository is created
  AuthRepository({
    required this.auth,
    required this.firestore,
    required this.googleSignIn,
  });

  /// AUTH STATE LISTENER
  Stream<User?> get authStateChange => auth.authStateChanges(); // Watches the user / tells the app if someone is currently logged in

  /// GET USER DATA FROM FIRESTORE
  Future<UserModel?> getUserData(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get(); // Look in database / finds the profile for a specific ID
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, uid); // Success / turns database data back into a User object
    }
    return null; // Not found / returns nothing if user profile doesn't exist yet
  }

  /// EMAIL LOGIN
  Future<UserCredential> signInWithEmail(String email, String password) async {
    UserCredential creds = await auth.signInWithEmailAndPassword(
        email: email, password: password); // Login check / verifies email and password with Firebase

    if (creds.user != null) {
      await _saveUserToFirestore(creds.user!, name: email.split('@')[0]); // Save profile / creates a database entry if it's the first time
    }
    return creds; // Success / user is logged in
  }

  /// EMAIL REGISTER
  Future<UserCredential> registerWithEmail(
      String email, String password, String name) async {
    UserCredential creds =
    await auth.createUserWithEmailAndPassword(email: email, password: password); // Create account / registers new user in Firebase

    if (creds.user != null) {
      await _saveUserToFirestore(creds.user!, name: name); // Save info / stores the new user's name in the database
    }
    return creds; // Success / account is ready
  }

  /// GOOGLE LOGIN
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn(); // Open Google Popup / user chooses their Google account
    if (googleUser == null) return null; // Cancelled / user closed the popup without signing in

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication; // Get Keys / gets security tokens from Google
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    ); // Create Credential / bundles Google tokens for Firebase to use

    UserCredential creds = await auth.signInWithCredential(credential); // Login / tells Firebase to trust the Google account

    if (creds.user != null) {
      await _saveUserToFirestore(
        creds.user!,
        name: googleUser.displayName ?? "User",
        email: googleUser.email,
        photo: googleUser.photoUrl,
      ); // Sync Profile / saves Google name and photo into our own database
    }
    return creds; // Success / logged in via Google
  }

  /// SAVE USER TO FIRESTORE
  Future<void> _saveUserToFirestore(User user,
      {String? name, String? email, String? photo}) async {
    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid, // Save ID / identifies the user in the database
      'name': name ?? 'User', // Save Name / uses provided name or defaults to "User"
      'email': email ?? user.email, // Save Email / stores contact info
      'profilePhoto': photo ?? 'https://i.pravatar.cc/150?u=${user.uid}', // Save Photo / uses Google photo or a generated avatar
      'isOnline': true, // Set Online / marks user as currently active
      'lastSeen': DateTime.now().millisecondsSinceEpoch, // Save Time / records exactly when they joined or logged in
    }, SetOptions(merge: true)); // Merge / only updates new info without deleting old data
  }

  /// SIGN OUT
  Future<void> signOut() async {
    if (auth.currentUser != null) {
      await updateOnlineStatus(auth.currentUser!.uid, false); // Set Offline / removes the "active" status before leaving
    }
    await googleSignIn.signOut(); // Google Logout / disconnects the Google account
    await auth.signOut(); // Firebase Logout / ends the app session
  }

  /// PASSWORD RESET
  Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email); // Forgot Password / sends a reset link to the user's email
  }

  /// UPDATE ONLINE STATUS
  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    await firestore.collection('users').doc(uid).set({
      'isOnline': isOnline, // Update status / changes between green (online) and grey (offline) dots
      'lastSeen': DateTime.now().millisecondsSinceEpoch, // Update timer / records the last time they were active
    }, SetOptions(merge: true)); // Save changes / keeps the rest of the profile safe
  }
}
