import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authControllerProvider.notifier)
            .registerWithEmail(_emailController.text.trim(), _passwordController.text.trim(), _nameController.text.trim());
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
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
                  const Icon(Icons.person_add_alt_1_rounded, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 32),
                  const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Sign up to get started', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Full Name',
                    prefixIcon: Icons.person_outline,
                    validator: (val) => val != null && val.isNotEmpty ? null : 'Enter your name',
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Register',
                    onPressed: _register,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                        child: const Text('Login'),
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
