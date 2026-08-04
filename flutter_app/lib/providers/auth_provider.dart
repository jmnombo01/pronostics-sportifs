import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../core/network/dio_client.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.read(dioClientProvider));
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
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
    UserModel? user,
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

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      state = AuthState(isLoading: false, isAuthenticated: false);
      return;
    }

    try {
      final user = await _apiService.getProfile();
      state = AuthState(isLoading: false, isAuthenticated: true, user: user);
    } catch (_) {
      await prefs.remove('auth_token');
      state = AuthState(isLoading: false, isAuthenticated: false);
    }
  }

  Future<bool> register({
    required String lastName,
    required String firstName,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiService.register(
        lastName: lastName,
        firstName: firstName,
        phone: phone,
        email: email,
        password: password,
        referralCode: referralCode,
      );
      final token = res['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      final user = UserModel.fromJson(res['user']);
      state = AuthState(isLoading: false, isAuthenticated: true, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur lors de l\'inscription. Vérifiez vos informations.',
      );
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiService.login(email: email, password: password);
      final token = res['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      final user = UserModel.fromJson(res['user']);
      state = AuthState(isLoading: false, isAuthenticated: true, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email ou mot de passe incorrect.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = AuthState(isLoading: false, isAuthenticated: false);
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _apiService.getProfile();
      state = state.copyWith(user: user);
    } catch (_) {}
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});
