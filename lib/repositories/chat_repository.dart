import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository(
      firestore: FirebaseFirestore.instance,
    ));

class ChatRepository {
  final FirebaseFirestore firestore;

  ChatRepository({required this.firestore});

  String getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }

  Stream<List<MessageModel>> getMessages(String currentUserId, String receiverId) {
    String chatId = getChatId(currentUserId, receiverId);
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> sendMessage(String currentUserId, String receiverId, String text) async {
    String chatId = getChatId(currentUserId, receiverId);
    
    MessageModel message = MessageModel(
      senderId: currentUserId,
      receiverId: receiverId,
      message: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: 'sent',
    );

    await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());
        
    await firestore.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'timestamp': message.timestamp,
      'participants': [currentUserId, receiverId],
    }, SetOptions(merge: true));
  }

  Future<void> markMessagesAsSeen(String currentUserId, String receiverId) async {
    String chatId = getChatId(currentUserId, receiverId);
    final querySnapshot = await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isNotEqualTo: 'seen')
        .get();

    WriteBatch batch = firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'status': 'seen'});
    }
    await batch.commit();
  }
}
