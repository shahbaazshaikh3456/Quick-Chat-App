import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/auth_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    const ProviderScope(
      child: QuickChatApp(),
    ),
  );
}

class QuickChatApp extends ConsumerWidget {
  const QuickChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Quick Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Uses system setting by default
      home: const AuthChecker(),
    );
  }
}
