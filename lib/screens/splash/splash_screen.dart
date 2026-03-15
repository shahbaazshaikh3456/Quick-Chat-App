import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay for splash screen animation
    await Future.delayed(const Duration(seconds: 2));
    
    // We will check Firebase Auth state here later.
    // For now, redirect to a mocked Login screen or Auth gate.
    if (mounted) {
       // Placeholder: wait for auth implementation
       // Navigator.pushReplacement(...) 
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: Colors.blueAccent,
            ),
            SizedBox(height: 20),
            Text(
              'Quick Chat',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
