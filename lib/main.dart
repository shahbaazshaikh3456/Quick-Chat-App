import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/auth_checker.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Register background message handler before runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: QuickChatApp(),
    ),
  );
}

class QuickChatApp extends ConsumerStatefulWidget {
  const QuickChatApp({super.key});

  @override
  ConsumerState<QuickChatApp> createState() => _QuickChatAppState();
}

class _QuickChatAppState extends ConsumerState<QuickChatApp> {
  @override
  void initState() {
    super.initState();
    // Initialise notifications after the first frame so Riverpod is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: navigatorKey, // Global key for out-of-context navigation
      home: const AuthChecker(),
      routes: {
        '/chat': (context) => const _ChatRouteHandler(),
      },
    );
  }
}

/// Handles navigation to ChatScreen from a notification tap.
/// Reads the arguments passed via navigatorKey.currentState?.pushNamed('/chat', arguments: {...})
class _ChatRouteHandler extends ConsumerWidget {
  const _ChatRouteHandler();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If for any reason this route is hit without args, fall back to home
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.of(context).pushReplacementNamed('/'),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // The actual routing to ChatScreen is done inside HomeScreen; this is a
    // placeholder that navigates back to home after the notification tap
    // so the app at minimum opens correctly.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => Navigator.of(context).pop());
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
