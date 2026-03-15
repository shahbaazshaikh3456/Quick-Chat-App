import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authControllerProvider.notifier)
            .signInWithEmail(_emailController.text.trim(), _passwordController.text.trim());
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _googleLogin() async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 32),
                  const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Sign in to continue', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val != null && val.contains('@') ? null : 'Enter a valid email',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (val) => val != null && val.length >= 6 ? null : 'Password must be 6+ chars',
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Login',
                    onPressed: _login,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Sign in with Google',
                    onPressed: _googleLogin,
                    backgroundColor: Colors.redAccent,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
