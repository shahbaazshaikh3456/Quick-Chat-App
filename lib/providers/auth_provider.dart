/// Authentication Providers and Controllers.
/// Manages user login, registration, and session state using Riverpod and Firebase Auth.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChange;
});

final userDataProvider = FutureProvider.family<UserModel?, String>((ref, uid) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getUserData(uid);
});

final authControllerProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(authRepository: ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<bool> {
  final AuthRepository _authRepository;

  AuthController({required AuthRepository authRepository}) 
    : _authRepository = authRepository, super(false);

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    state = true;
    try {
      final creds = await _authRepository.signInWithEmail(email, password);
      if (creds.user != null) {
        await _authRepository.updateOnlineStatus(creds.user!.uid, true);
      }
      state = false;
      return creds;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  Future<UserCredential?> registerWithEmail(String email, String password, String name) async {
    state = true;
    try {
      final creds = await _authRepository.registerWithEmail(email, password, name);
      state = false;
      return creds;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    state = true;
    try {
      final creds = await _authRepository.signInWithGoogle();
      if (creds?.user != null) {
         await _authRepository.updateOnlineStatus(creds!.user!.uid, true);
      }
      state = false;
      return creds;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = true;
    try {
      await _authRepository.signOut();
      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = true;
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }
}
