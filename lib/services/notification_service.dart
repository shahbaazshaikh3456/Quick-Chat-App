import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Global navigator key – allows navigation outside the widget tree
// ─────────────────────────────────────────────────────────────────────────────
final navigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────────────────────
// Background message handler – MUST be a top-level function
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM automatically shows notification when app is background/terminated
}

// ─────────────────────────────────────────────────────────────────────────────
// Local notifications (used for foreground display)
// ─────────────────────────────────────────────────────────────────────────────
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'quick_chat_channel',
  'Quick Chat Messages',
  description: 'New message notifications',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final notificationServiceProvider =
    Provider((ref) => NotificationService(ref: ref));

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref ref;

  NotificationService({required this.ref});

  // ── Full initialization ────────────────────────────────────────────────────
  Future<void> initialize() async {
    // 1. Create Android channel (must match AndroidManifest meta-data)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 2. Init local notifications plugin
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // 3. Request permission & save token
    await requestPermission();

    // 4. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Foreground: show local notification banner
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Background → foreground (app resumed via notification tap)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // 7. Terminated app (opened via notification tap)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationOpen(initialMessage);

    // 8. iOS foreground options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ── Permission + token ─────────────────────────────────────────────────────
  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _refreshAndSaveToken();
    }

    // Keep token fresh
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  Future<void> _refreshAndSaveToken() async {
    final token = await _messaging.getToken();
    if (token != null) await _saveTokenToFirestore(token);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    }
  }

  // ── Foreground: show local notification ───────────────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ??
        message.data['senderName'] ??
        'New Message';
    final body = message.notification?.body ??
        message.data['messagePreview'] ??
        '';

    // Show system-style local notification banner
    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );

    // Also show in-app SnackBar banner
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.message, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(body,
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.blueAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => _navigateToChat(message.data),
          ),
        ),
      );
    }
  }

  // ── Notification tap ───────────────────────────────────────────────────────
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      _navigateToChat(
          jsonDecode(response.payload!) as Map<String, dynamic>);
    } catch (_) {}
  }

  void _handleNotificationOpen(RemoteMessage message) {
    _navigateToChat(message.data);
  }

  void _navigateToChat(Map<String, dynamic> data) {
    final senderId = data['senderId'] as String?;
    if (senderId == null) return;
    _firestore.collection('users').doc(senderId).get().then((doc) {
      if (!doc.exists) return;
      navigatorKey.currentState?.pushNamed(
        '/chat',
        arguments: {'senderId': senderId, 'senderData': doc.data()},
      );
    });
  }

  // ── FCM v1 HTTP API ────────────────────────────────────────────────────────
  /// Returns an OAuth2 Bearer token using the service account credentials
  /// stored in [assets/service-account.json].
  Future<String?> _getAccessToken() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/service-account.json');
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Detect placeholder file
      if (jsonMap.containsKey('SETUP_REQUIRED')) {
        debugPrint(
            '[NotificationService] service-account.json is a placeholder. '
            'Replace it with the real Firebase service account key to enable notifications.');
        return null;
      }

      final credentials = ServiceAccountCredentials.fromJson(jsonMap);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(credentials, scopes);
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      debugPrint('[NotificationService] Failed to get access token: $e');
      return null;
    }
  }

  /// Sends an FCM push notification using the FCM v1 HTTP API.
  /// Requires [assets/service-account.json] to contain a valid Firebase
  /// service account key (downloaded from Firebase Console → Project Settings
  /// → Service Accounts → Generate new private key).
  Future<void> sendPushNotification({
    required String receiverUserId,
    required String senderName,
    required String messagePreview,
    required String senderUserId,
  }) async {
    try {
      // 1. Get receiver's FCM token
      final doc =
          await _firestore.collection('users').doc(receiverUserId).get();
      if (!doc.exists) return;
      final token = doc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) return;

      // 2. Skip self-notifications
      final senderDoc =
          await _firestore.collection('users').doc(senderUserId).get();
      final senderToken = senderDoc.data()?['fcmToken'] as String?;
      if (token == senderToken) return;

      // 3. Get OAuth2 access token from service account
      final accessToken = await _getAccessToken();
      if (accessToken == null) return; // service-account.json not configured

      // 4. Extract Firebase project ID from service account JSON
      final jsonStr =
          await rootBundle.loadString('assets/service-account.json');
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final projectId = jsonMap['project_id'] as String?;
      if (projectId == null) {
        debugPrint('[NotificationService] project_id missing in service-account.json');
        return;
      }

      final preview = messagePreview.length > 100
          ? '${messagePreview.substring(0, 97)}...'
          : messagePreview;

      // 5. Send via FCM v1 HTTP API
      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {
              'title': senderName,
              'body': preview,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'quick_chat_channel',
                'sound': 'default',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                  'badge': 1,
                },
              },
            },
            'data': {
              'senderId': senderUserId,
              'senderName': senderName,
              'messagePreview': preview,
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[NotificationService] FCM v1 notification sent successfully.');
      } else {
        debugPrint(
            '[NotificationService] FCM v1 send failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[NotificationService] FCM error: $e');
    }
  }
}
