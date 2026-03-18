import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';


class UserRepository {
  final FirebaseFirestore firestore;

  UserRepository({required this.firestore});

  Stream<List<UserModel>> getUsers() {
    return firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<UserModel> getUserStream(String uid) {
    return firestore.collection('users').doc(uid).snapshots().map((doc) {
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }
  Future<void> updateUserProfile(UserModel user) async {
    await firestore.collection('users').doc(user.uid).set(
          user.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> updateProfileImage(String uid, String imageUrl) async {
    await firestore.collection('users').doc(uid).set({
      'profilePhoto': imageUrl,
    }, SetOptions(merge: true));
  }
}
