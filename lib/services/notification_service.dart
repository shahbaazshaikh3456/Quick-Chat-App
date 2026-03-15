import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

final notificationServiceProvider = Provider((ref) {
  return NotificationService(ref: ref);
});

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref ref;

  NotificationService({required this.ref});

  Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    }

    _messaging.onTokenRefresh.listen((token) {
      _saveTokenToFirestore(token);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages here if needed
    });
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final currentUserId = ref.read(authStateProvider).value?.uid;
    if (currentUserId != null) {
      await _firestore.collection('users').doc(currentUserId).update({
        'fcmToken': token,
      });
    }
  }
}
