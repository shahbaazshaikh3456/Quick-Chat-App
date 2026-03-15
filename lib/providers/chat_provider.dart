import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';
import 'auth_provider.dart';

final chatControllerProvider = Provider((ref) {
  return ChatController(
    chatRepository: ref.watch(chatRepositoryProvider),
    ref: ref,
  );
});

final messagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, receiverId) {
  final chatController = ref.watch(chatControllerProvider);
  return chatController.getMessages(receiverId);
});

class ChatController {
  final ChatRepository _chatRepository;
  final Ref _ref;

  ChatController({required ChatRepository chatRepository, required Ref ref})
      : _chatRepository = chatRepository,
        _ref = ref;

  Stream<List<MessageModel>> getMessages(String receiverId) {
    final currentUserId = _ref.watch(authStateProvider).value?.uid;
    if (currentUserId == null) return const Stream.empty();
    return _chatRepository.getMessages(currentUserId, receiverId);
  }

  Future<void> sendMessage(String receiverId, String text) async {
    final currentUserId = _ref.read(authStateProvider).value?.uid;
    if (currentUserId != null) {
      await _chatRepository.sendMessage(currentUserId, receiverId, text);
    }
  }

  Future<void> markMessagesAsSeen(String receiverId) async {
    final currentUserId = _ref.read(authStateProvider).value?.uid;
    if (currentUserId != null) {
      await _chatRepository.markMessagesAsSeen(currentUserId, receiverId);
    }
  }
}
