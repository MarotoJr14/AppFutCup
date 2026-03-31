import 'package:dio/dio.dart';
import '../constants/app_strings.dart';
import '../storage/secure_storage.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  /// Reset singleton - call on logout or session expiry
  static void reset() => _instance = null;

  /// Global 401 callback - set once at app startup
  static void Function(String? message)? _onUnauthorized;
  static void setOnUnauthorized(void Function(String? message) callback) {
    _onUnauthorized = callback;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppStrings.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final data = error.response?.data;
            String? detail;
            if (data is Map && data['detail'] != null) {
              detail = data['detail'].toString();
            }
            await SecureStorageService.clearAuth();
            DioClient.reset();
            _onUnauthorized?.call(detail);
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}

