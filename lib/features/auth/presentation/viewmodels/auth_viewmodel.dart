import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_providers.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserEntity? user;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    final user = ref.read(getCurrentUserUseCaseProvider).call();
    if (user != null) {
      return AuthState(isAuthenticated: true, user: user);
    }
    return AuthState();
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await ref.read(loginWithGoogleUseCaseProvider).call();
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loginWithApple() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await ref.read(loginWithAppleUseCaseProvider).call();
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(logoutUseCaseProvider).call();
      state = AuthState(); 
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
