import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final userRepositoryProvider = Provider((ref) => UserRepository(
      firestore: FirebaseFirestore.instance,
    ));

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
}
