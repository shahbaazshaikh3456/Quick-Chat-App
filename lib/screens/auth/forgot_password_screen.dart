import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authControllerProvider.notifier)
            .sendPasswordResetEmail(_emailController.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent')));
        Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.lock_reset_rounded, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 32),
                const Text('Reset your password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text('Enter your registered email below to receive password reset instructions.', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                const SizedBox(height: 40),
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val != null && val.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Send Reset Link',
                  onPressed: _resetPassword,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
