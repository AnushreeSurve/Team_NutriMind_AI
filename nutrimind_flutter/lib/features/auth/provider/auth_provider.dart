/// Auth state management using Riverpod.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/auth_models.dart';
import '../repository/auth_repository.dart';

// ── Auth state ────────────────────────────────────────────────
class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final SignupResponse? signupResponse;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.signupResponse,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
    SignupResponse? signupResponse,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        user: user ?? this.user,
        signupResponse: signupResponse ?? this.signupResponse,
      );
}

// ── Auth notifier ─────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  /// Perform signup via backend.
  Future<bool> signup(SignupRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.signup(request);
      state = state.copyWith(
        isLoading: false,
        signupResponse: response,
        user: UserModel(
          name: request.name,
          email: request.email,
          userId: response.userId,
          dailyCalorieTarget: response.dailyCalorieTarget,
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Mock login — preserves local onboarding state
  void loginMock(String email, String name) {
    state = state.copyWith(
      user: UserModel(name: name, email: email),
    );
  }

  /// Real Supabase Login
  Future<bool> login(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.login(email);
      state = state.copyWith(
        isLoading: false,
        signupResponse: response,
        user: UserModel(
          name: response.message != 'Success' ? response.message : 'User',
          email: email,
          userId: response.userId,
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void logout() {
    state = const AuthState();
  }
}

// ── Providers ─────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);
