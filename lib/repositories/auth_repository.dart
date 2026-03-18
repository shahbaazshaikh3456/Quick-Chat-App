import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
  auth: FirebaseAuth.instance,
  firestore: FirebaseFirestore.instance,
  googleSignIn: GoogleSignIn(),
));

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  AuthRepository({
    required this.auth,
    required this.firestore,
    required this.googleSignIn,
  });

  /// AUTH STATE LISTENER
  Stream<User?> get authStateChange => auth.authStateChanges();

  /// GET USER DATA FROM FIRESTORE
  Future<UserModel?> getUserData(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  /// EMAIL LOGIN
  Future<UserCredential> signInWithEmail(String email, String password) async {
    UserCredential creds = await auth.signInWithEmailAndPassword(
        email: email, password: password);

    if (creds.user != null) {
      await _saveUserToFirestore(creds.user!, name: email.split('@')[0]);
    }

    return creds;
  }

  /// EMAIL REGISTER
  Future<UserCredential> registerWithEmail(
      String email, String password, String name) async {
    UserCredential creds =
    await auth.createUserWithEmailAndPassword(email: email, password: password);

    if (creds.user != null) {
      await _saveUserToFirestore(creds.user!, name: name);
    }

    return creds;
  }

  /// GOOGLE LOGIN
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential creds = await auth.signInWithCredential(credential);

    if (creds.user != null) {
      await _saveUserToFirestore(
        creds.user!,
        name: googleUser.displayName ?? "User",
        email: googleUser.email,
        photo: googleUser.photoUrl,
      );
    }

    return creds;
  }

  /// SAVE USER TO FIRESTORE
  Future<void> _saveUserToFirestore(User user,
      {String? name, String? email, String? photo}) async {
    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name ?? 'User',
      'email': email ?? user.email,
      'profilePhoto': photo ?? 'https://i.pravatar.cc/150?u=${user.uid}',
      'isOnline': true,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  /// SIGN OUT
  Future<void> signOut() async {
    if (auth.currentUser != null) {
      await updateOnlineStatus(auth.currentUser!.uid, false);
    }

    await googleSignIn.signOut();
    await auth.signOut();
  }

  /// PASSWORD RESET
  Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  /// UPDATE ONLINE STATUS
  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    await firestore.collection('users').doc(uid).set({
      'isOnline': isOnline,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }
}