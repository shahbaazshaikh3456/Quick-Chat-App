/// Repository for managing real-time chat messages and conversation history.
/// Handles Firestore operations for sending and receiving messages.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatRepository {
  final FirebaseFirestore firestore; // Connection to the database / used to talk to Firestore

  ChatRepository({required this.firestore}); // Constructor / sets up the database tool

  // Creates a unique room ID for two people
  String getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2]; // Put both user IDs in a list / gathers the two people
    ids.sort(); // Sort them alphabetically / ensures the ID is the same no matter who starts the chat
    return ids.join('_'); // Join with underscore / e.g., "ID123_ID456"
  }

  // Listens to messages between two users in real-time
  Stream<List<MessageModel>> getMessages(String currentUserId, String receiverId) {
    String chatId = getChatId(currentUserId, receiverId); // Get the unique room ID / finds the right chat room
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages') // Go to the messages sub-collection / looks at the list of chats
        .orderBy('timestamp', descending: true) // Sort by time / shows newest messages at the bottom
        .snapshots() // Start listening / keeps the connection open for new messages
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList(); // Convert to Dart / turns database data into message objects
    });
  }

  // Saves a new message to the database
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
    String chatId = getChatId(currentUserId, receiverId); // Get room ID / finds where to save the message

    // Create the message object / prepares the data with a timestamp and 'sent' status
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

    // Add message to the 'messages' folder in Firestore
    await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap()); // Save to database / physically writes the message to the cloud

    // Update the main chat document / used to show the "Last Message" on the home screen
    await firestore.collection('chats').doc(chatId).set({
      'lastMessage': type == 'text' ? text : 'Shared a $type', // Show preview / e.g., "Hello" or "Shared a image"
      'timestamp': message.timestamp, // Update time / moves the chat to the top of the list
      'participants': [currentUserId, receiverId], // Store IDs / keeps track of who is in this chat
    }, SetOptions(merge: true)); // Merge / updates only these fields without deleting others
  }

  // Updates "sent" status to "seen" (the blue ticks logic)
  Future<void> markMessagesAsSeen(String currentUserId, String receiverId) async {
    String chatId = getChatId(currentUserId, receiverId); // Get room ID
    final querySnapshot = await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId) // Find messages meant for ME / only updates what I received
        .where('status', isEqualTo: 'sent') // Find unread messages / only updates what hasn't been seen
        .get();

    WriteBatch batch = firestore.batch(); // Create a batch / allows updating many messages at once for speed
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'status': 'seen'}); // Mark each as 'seen' / updates the database status
    }
    await batch.commit(); // Save all changes / sends the batch update to the cloud
  }

  // Gets the list of people you have chatted with recently
  Stream<List<Map<String, dynamic>>> getRecentChats(String currentUserId) {
    return firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId) // Find my chats / looks for any room where I am a participant
        .orderBy('timestamp', descending: true) // Order by latest / shows recent chats first
        .snapshots() // Listen for changes / updates if someone sends you a new message
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data(); // Get chat data / e.g., last message and time
        data['chatId'] = doc.id; // Include the ID / helps the app know which room to open
        return data;
      }).toList();
    });
  }
}
