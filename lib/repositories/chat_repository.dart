import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

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

  Future<void> sendMessage({
    required String currentUserId,
    required String receiverId,
    required String text,
    String type = 'text',
    String? imageUrl,
    String? videoUrl,
    String? fileUrl,
    String? fileName,
  }) async {
    String chatId = getChatId(currentUserId, receiverId);

    MessageModel message = MessageModel(
      senderId: currentUserId,
      receiverId: receiverId,
      message: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: 'sent',
      type: type,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      fileUrl: fileUrl,
      fileName: fileName,
    );

    await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    await firestore.collection('chats').doc(chatId).set({
      'lastMessage': type == 'text' ? text : 'Shared a $type',
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
        .where('status', isEqualTo: 'sent')
        .get();

    WriteBatch batch = firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'status': 'seen'});
    }
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getRecentChats(String currentUserId) {
    return firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['chatId'] = doc.id;
        return data;
      }).toList();
    });
  }
}
