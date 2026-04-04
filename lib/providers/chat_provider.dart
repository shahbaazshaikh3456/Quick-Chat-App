/// Chat Logic and Messaging Providers.
/// Connects the UI to ChatRepository and handles media uploads and push notifications.
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';
import '../services/cloudinary_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

// Providers to set up the chat services and keep the UI updated
final cloudinaryServiceProvider = Provider((_) => CloudinaryService()); // Helper for cloud storage / used to upload images and videos
final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(firestore: FirebaseFirestore.instance); // Connection to database / tells the app where to save messages
});

final chatControllerProvider = Provider((ref) {
  return ChatController(
    chatRepository: ref.watch(chatRepositoryProvider), // Gets the database helper / links the logic to the data storage
    cloudinary: ref.watch(cloudinaryServiceProvider), // Gets the cloud helper / links the logic to the media uploader
    notificationService: ref.watch(notificationServiceProvider), // Gets notification helper / links to the alert system
    ref: ref, // Gives the controller access to other providers / allows it to check things like current user ID
  );
});

// A "Listener" that stays open to show new messages instantly
final messagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, receiverId) {
  final chatController = ref.watch(chatControllerProvider); // Access the chat controller / gets the message logic
  return chatController.getMessages(receiverId); // Starts the real-time stream / keeps the chat screen updated automatically
});

// The main class that handles the "work" of chatting
class ChatController {
  final ChatRepository _chatRepository; // Private database connection / used to save chat data
  final CloudinaryService _cloudinary; // Private cloud connection / used for media uploads
  final NotificationService _notificationService; // Private notification system / used to send alerts
  final Ref _ref; // Internal tool / used to read user data from other parts of the app

  // Constructor / sets up all the connections mentioned above
  ChatController({
    required ChatRepository chatRepository,
    required CloudinaryService cloudinary,
    required NotificationService notificationService,
    required Ref ref,
  })  : _chatRepository = chatRepository,
        _cloudinary = cloudinary,
        _notificationService = notificationService,
        _ref = ref;

  // Function to pull messages for a specific person
  Stream<List<MessageModel>> getMessages(String receiverId) {
    final currentUserId = _ref.watch(authStateProvider).value?.uid; // Get my ID / checks who is currently logged in
    if (currentUserId == null) return const Stream.empty(); // If not logged in, return nothing / prevents crashes
    return _chatRepository.getMessages(currentUserId, receiverId); // Get chat history / pulls the messages between two people
  }

  // The main function to send any kind of message
  Future<void> sendMessage({
    required String receiverId, // Who gets it / the person you are chatting with
    required String text, // What it says / the message text
    String type = 'text', // What it is / defaults to "text" but can be "image" or "video"
    File? file, // The actual media file / the photo or video being sent
  }) async {
    final currentUser = _ref.read(authStateProvider).value; // Get my user info / used for notifications and database
    final currentUserId = currentUser?.uid; // Get my ID / used as the "sender"
    if (currentUserId == null) return; // Exit if no user / stops the message if not logged in

    // Variables to hold cloud links
    String? imageUrl;
    String? videoUrl;
    String? fileUrl;
    String? fileName;

    // Logic to upload files if they exist
    if (file != null) {
      if (type == 'image') {
        imageUrl = await _cloudinary.uploadImage(file); // Upload photo / gets a link from the cloud
      } else if (type == 'video') {
        videoUrl = await _cloudinary.uploadVideo(file); // Upload video / gets a link from the cloud
      } else if (type == 'file') {
        fileUrl = await _cloudinary.uploadFile(file); // Upload document / gets a link from the cloud
        fileName = file.path.split('/').last; // Get file name / identifies the document name (e.g., "report.pdf")
      }
    }

    // Save everything to the database
    await _chatRepository.sendMessage(
      currentUserId: currentUserId,
      receiverId: receiverId,
      text: text,
      type: type,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      fileUrl: fileUrl,
      fileName: fileName,
    );

    // Prepare and send a push notification alert
    final senderName = await _getSenderName(currentUserId); // Look up my name / so the receiver knows who sent the message
    final preview = type == 'text' ? text : '📎 Shared a $type'; // Create a short alert text / e.g., "Shared a image"

    await _notificationService.sendPushNotification(
      receiverUserId: receiverId, // Who gets the alert / the receiver's phone
      senderName: senderName, // Name shown in alert / e.g., "Krish"
      messagePreview: preview, // Text shown in alert / e.g., "Hello!"
      senderUserId: currentUserId, // ID of the sender / used for routing
    );
  }

  // Helper function to find a name from an ID
  Future<String> _getSenderName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get(); // Look in database / finds user profile
      return (doc.data()?['name'] as String?) ?? 'Someone'; // Get name / defaults to "Someone" if name is missing
    } catch (_) {
      return 'Someone'; // Safety net / returns "Someone" if there is a database error
    }
  }

  // Function to mark messages as read
  Future<void> markMessagesAsSeen(String receiverId) async {
    final currentUserId = _ref.read(authStateProvider).value?.uid; // Get my ID / current logged in user
    if (currentUserId != null) {
      await _chatRepository.markMessagesAsSeen(currentUserId, receiverId); // Update status in database / changes ticks to 'seen'
    }
  }
}
