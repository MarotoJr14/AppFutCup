import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_strings.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppStrings.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: AppStrings.tokenKey);
  }

  static Future<void> saveUser(String userJson) async {
    await _storage.write(key: AppStrings.userKey, value: userJson);
  }

  static Future<String?> getUser() async {
    return await _storage.read(key: AppStrings.userKey);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
