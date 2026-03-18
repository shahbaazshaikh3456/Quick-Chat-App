import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';
import '../services/cloudinary_service.dart';
import 'auth_provider.dart';

final cloudinaryServiceProvider = Provider((_) => CloudinaryService());

final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(firestore: FirebaseFirestore.instance);
});

final chatControllerProvider = Provider((ref) {
  return ChatController(
    chatRepository: ref.watch(chatRepositoryProvider),
    cloudinary: ref.watch(cloudinaryServiceProvider),
    ref: ref,
  );
});

final messagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, receiverId) {
  final chatController = ref.watch(chatControllerProvider);
  return chatController.getMessages(receiverId);
});

class ChatController {
  final ChatRepository _chatRepository;
  final CloudinaryService _cloudinary;
  final Ref _ref;

  ChatController({
    required ChatRepository chatRepository,
    required CloudinaryService cloudinary,
    required Ref ref,
  })  : _chatRepository = chatRepository,
        _cloudinary = cloudinary,
        _ref = ref;

  Stream<List<MessageModel>> getMessages(String receiverId) {
    final currentUserId = _ref.watch(authStateProvider).value?.uid;
    if (currentUserId == null) return const Stream.empty();
    return _chatRepository.getMessages(currentUserId, receiverId);
  }

  Future<void> sendMessage({
    required String receiverId,
    required String text,
    String type = 'text',
    File? file,
  }) async {
    final currentUserId = _ref.read(authStateProvider).value?.uid;
    if (currentUserId == null) return;

    String? imageUrl;
    String? videoUrl;
    String? fileUrl;
    String? fileName;

    if (file != null) {
      if (type == 'image') {
        imageUrl = await _cloudinary.uploadImage(file);
      } else if (type == 'video') {
        videoUrl = await _cloudinary.uploadVideo(file);
      } else if (type == 'file') {
        fileUrl = await _cloudinary.uploadFile(file);
        fileName = file.path.split('/').last;
      }
    }

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
  }

  Future<void> markMessagesAsSeen(String receiverId) async {
    final currentUserId = _ref.read(authStateProvider).value?.uid;
    if (currentUserId != null) {
      await _chatRepository.markMessagesAsSeen(currentUserId, receiverId);
    }
  }
}
