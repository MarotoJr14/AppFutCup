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

  static Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: AppStrings.themeKey, value: mode);
  }

  static Future<String?> getThemeMode() async {
    return await _storage.read(key: AppStrings.themeKey);
  }

  static Future<void> saveLastBackgroundAt(int epochMillis) async {
    await _storage.write(key: AppStrings.lastBackgroundAtKey, value: epochMillis.toString());
  }

  static Future<int?> getLastBackgroundAt() async {
    final v = await _storage.read(key: AppStrings.lastBackgroundAtKey);
    if (v == null) return null;
    return int.tryParse(v);
  }

  static Future<void> clearLastBackgroundAt() async {
    await _storage.delete(key: AppStrings.lastBackgroundAtKey);
  }

  static Future<void> clearAuth() async {
    await _storage.delete(key: AppStrings.tokenKey);
    await _storage.delete(key: AppStrings.userKey);
    await _storage.delete(key: AppStrings.lastBackgroundAtKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
