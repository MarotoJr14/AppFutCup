import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _dio = DioClient.instance;

  Future<String> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      final token = res.data['access_token'] as String;
      await SecureStorageService.saveToken(token);
      return token;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> register(String username, String email, String password) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'username': username, 'email': email, 'password': password, 'role': 'user',
      });
      return UserModel.fromJson(res.data['user']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final res = await _dio.get('/users/me');
      return UserModel.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    await SecureStorageService.clear();
  }
}
