import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ⚠️ Configura esto con tu backend real
  // Para emulador Android: http://10.0.2.2:8000
  // Para dispositivo físico: usa IP de tu máquina (ej. http://192.168.x.x:8000)
  static const String baseUrl = "http://10.0.2.2:8000/api/v1";

  // Cliente inyectable para facilitar tests
  static http.Client _httpClient = http.Client();

  static void setHttpClient(http.Client client) {
    _httpClient = client;
  }

  // Resetear cliente (para tests)
  static void resetHttpClient() {
    _httpClient = http.Client();
  }

  // ============ LOGIN ============
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/auth/login");

      print('[AUTH] POST $url');
      print('[AUTH] Headers: Content-Type=application/json');
      print('[AUTH] Body: email=$email (password omitida)');

      final response = await _httpClient.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Timeout: la solicitud tardó demasiado"),
      );

      print('[AUTH] Response Status: ${response.statusCode}');
      print('[AUTH] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return {
            "success": true,
            "token": data["access_token"],
            "role": data["role"],
          };
        } catch (e) {
          print('[AUTH] Error decodificando JSON: $e');
          return {
            "success": false,
            "message": "Error al procesar respuesta del servidor: $e"
          };
        }
      } else if (response.statusCode == 401) {
        return {
          "success": false,
          "message": "Email o contraseña incorrectos"
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "message": errorData["detail"] ?? "Error de login (${response.statusCode})"
          };
        } catch (e) {
          return {
            "success": false,
            "message": "Error: ${response.statusCode} - ${response.body}"
          };
        }
      }
    } catch (e) {
      print('[AUTH] Exception en login: $e');
      return {
        "success": false,
        "message": "Error de conexión: $e"
      };
    }
  }

  // ============ REGISTER ============
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required int favouriteTeamId,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/auth/register");

      print('[AUTH] POST $url');
      print('[AUTH] Headers: Content-Type=application/json');
      print('[AUTH] Body: username=$username, email=$email (password omitida)');

      final response = await _httpClient.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
          "role": "user",
          "favourite_team_id": favouriteTeamId,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Timeout: la solicitud tardó demasiado"),
      );

      print('[AUTH] Response Status: ${response.statusCode}');
      print('[AUTH] Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return {
          "success": true,
        };
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "message": errorData["detail"] ?? "Datos inválidos"
          };
        } catch (e) {
          return {
            "success": false,
            "message": "Error de validación: ${response.body}"
          };
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            "success": false,
            "message": errorData["detail"] ?? "Error en registro (${response.statusCode})"
          };
        } catch (e) {
          return {
            "success": false,
            "message": "Error: ${response.statusCode} - ${response.body}"
          };
        }
      }
    } catch (e) {
      print('[AUTH] Exception en register: $e');
      return {
        "success": false,
        "message": "Error de conexión: $e"
      };
    }
  }

  // ============ SAVE SESSION ============
  static Future<void> saveSession({
    required String token,
    required String role,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token);
      await prefs.setString("role", role);
      print('[AUTH] Sesión guardada exitosamente');
    } catch (e) {
      print('[AUTH] Error guardando sesión: $e');
    }
  }

  // ============ GET ROLE ============
  static Future<String?> getSavedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString("role");
    } catch (e) {
      print('[AUTH] Error obteniendo rol: $e');
      return null;
    }
  }

  // ============ LOGOUT ============
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('[AUTH] Sesión cerrada exitosamente');
    } catch (e) {
      print('[AUTH] Error cerrando sesión: $e');
    }
  }
}