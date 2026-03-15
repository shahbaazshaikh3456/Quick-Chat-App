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

  Stream<User?> get authStateChange => auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password, String name) async {
    UserCredential creds = await auth.createUserWithEmailAndPassword(email: email, password: password);
    if (creds.user != null) {
      UserModel userModel = UserModel(
        uid: creds.user!.uid,
        name: name,
        email: email,
        profilePhoto: 'https://i.pravatar.cc/150?u=${creds.user!.uid}',
        isOnline: true,
        lastSeen: DateTime.now().millisecondsSinceEpoch,
      );
      await firestore.collection('users').doc(creds.user!.uid).set(userModel.toMap());
    }
    return creds;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential creds = await auth.signInWithCredential(credential);
      
      if (creds.user != null && creds.additionalUserInfo?.isNewUser == true) {
        UserModel userModel = UserModel(
          uid: creds.user!.uid,
          name: googleUser.displayName ?? 'User',
          email: googleUser.email,
          profilePhoto: googleUser.photoUrl ?? 'https://i.pravatar.cc/150?u=${creds.user!.uid}',
          isOnline: true,
          lastSeen: DateTime.now().millisecondsSinceEpoch,
        );
        await firestore.collection('users').doc(creds.user!.uid).set(userModel.toMap());
      }
      return creds;
    }
    return null;
  }

  Future<void> signOut() async {
    if (auth.currentUser != null) {
      await updateOnlineStatus(auth.currentUser!.uid, false);
    }
    await googleSignIn.signOut();
    await auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    await firestore.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
