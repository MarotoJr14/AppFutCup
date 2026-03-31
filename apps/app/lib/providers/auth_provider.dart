import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../core/constants/app_strings.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage.dart';
import '../core/network/dio_client.dart';
import '../core/ui/app_messenger.dart';

final authRepositoryProvider = Provider((_) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;
  static const Duration sessionTimeout = Duration(minutes: 30);

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
    // Register the global 401 handler so expired tokens log the user out
    DioClient.setOnUnauthorized((message) {
      SecureStorageService.clearAuth();
      state = const AsyncValue.data(null);
      showAuthErrorSnack(message ?? 'Token inválido o expirado. Vuelve a iniciar sesión.');
    });
  }

  Future<void> _init() async {
    // If the app was in background for too long (or the OS killed it), expire the session on startup
    await _enforceSessionTimeoutOnStartup();

    // Restore session from secure storage on startup (if available)
    final userJson = await SecureStorageService.getUser();
    if (userJson != null) {
      try {
        final user = UserModel.fromJsonString(userJson);
        if (user.isAdmin) {
          await logout();
          showAuthErrorSnack('Acceso denegado: los administradores no pueden acceder a la app.');
          return;
        }
        state = AsyncValue.data(user);
        return;
      } catch (_) {
        // fallthrough to refetch below
      }
    }

    final token = await SecureStorageService.getToken();
    if (token != null) {
      try {
        final user = await _repo.getMe();
        if (user.isAdmin) {
          await logout();
          showAuthErrorSnack('Acceso denegado: los administradores no pueden acceder a la app.');
          return;
        }
        await SecureStorageService.saveUser(user.toJsonString());
        state = AsyncValue.data(user);
        return;
      } catch (_) {
        // token invalid/expired or network error -> keep as logged out
      }
    }

    state = const AsyncValue.data(null);
  }

  Future<void> _enforceSessionTimeoutOnStartup() async {
    final lastBg = await SecureStorageService.getLastBackgroundAt();
    if (lastBg == null) return;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastBg;
    await SecureStorageService.clearLastBackgroundAt();
    if (elapsed > sessionTimeout.inMilliseconds) {
      await SecureStorageService.clearAuth();
      DioClient.reset();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> handleLifecycleChange(AppLifecycleState state) async {
    if (this.state is AsyncLoading) return;
    final isLoggedIn = this.state.valueOrNull != null;
    if (!isLoggedIn) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        await logout();
        break;
      case AppLifecycleState.resumed:
        // No need to check timeout since we logout on pause
        break;
      case AppLifecycleState.detached:
        // Already logged out on pause, but ensure
        await logout();
        break;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.login(email, password);
      final user = await _repo.getMe();
      if (user.role == AppStrings.roleAdmin) {
        await logout();
        throw ApiException('Acceso denegado.');
      }
      await SecureStorageService.saveUser(user.toJsonString());
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String username, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.register(username, email, password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({String? username, String? password, String? currentPassword}) async {
    try {
      final updated = await _repo.updateMe(username: username, password: password, currentPassword: currentPassword);
      await SecureStorageService.saveUser(updated.toJsonString());
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await SecureStorageService.clearAuth();
    DioClient.reset();
    state = const AsyncValue.data(null);
  }
}
