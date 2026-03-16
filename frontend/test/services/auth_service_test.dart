import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/features/auth/auth_service.dart';

void main() {
  group('AuthService', () {

    setUp(() {
      // Resetear cliente antes de cada test
      AuthService.resetHttpClient();
    });

    test('login() retorna token cuando statusCode es 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('/auth/login'));
        expect(request.method, 'POST');
        expect(request.headers['Content-Type'], 'application/json');

        return http.Response(
          '{"access_token": "test_token_123", "role": "user"}',
          200,
        );
      });

      AuthService.setHttpClient(mockClient);

      final result = await AuthService.login(
        email: 'test@pro2fp.es',
        password: 'password123',
      );

      expect(result['success'], true);
      expect(result['token'], 'test_token_123');
      expect(result['role'], 'user');
    });

    test('login() retorna error cuando statusCode es 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"detail": "Email o contraseña incorrectos"}',
          401,
        );
      });

      AuthService.setHttpClient(mockClient);

      final result = await AuthService.login(
        email: 'test@pro2fp.es',
        password: 'wrongpassword',
      );

      expect(result['success'], false);
      expect(result['message'], 'Email o contraseña incorrectos');
    });

    test('login() maneja JSON inválido gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          'Respuesta inválida no JSON',
          500,
        );
      });

      AuthService.setHttpClient(mockClient);

      final result = await AuthService.login(
        email: 'test@pro2fp.es',
        password: 'password123',
      );

      expect(result['success'], false);
      expect(result['message'], contains('500'));
    });

    test('register() retorna success cuando statusCode es 201', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('/auth/register'));
        expect(request.method, 'POST');
        expect(request.headers['Content-Type'], 'application/json');

        return http.Response(
          '{"message": "Usuario creado exitosamente"}',
          201,
        );
      });

      AuthService.setHttpClient(mockClient);

      final result = await AuthService.register(
        username: 'testuser',
        email: 'test@pro2fp.es',
        password: 'password123',
        favouriteTeamId: 1,
      );

      expect(result['success'], true);
    });

    test('register() retorna error cuando statusCode es 400', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"detail": "El email ya está registrado"}',
          400,
        );
      });

      AuthService.setHttpClient(mockClient);

      final result = await AuthService.register(
        username: 'testuser',
        email: 'existing@pro2fp.es',
        password: 'password123',
        favouriteTeamId: 1,
      );

      expect(result['success'], false);
      expect(result['message'], 'El email ya está registrado');
    });

    test('login() maneja timeout correctamente', () async {
      final mockClient = MockClient((request) async {
        // Simular timeout
        await Future.delayed(const Duration(seconds: 20));
        return http.Response('', 200);
      });

      AuthService.setHttpClient(mockClient);

      final result = await AuthService.login(
        email: 'test@pro2fp.es',
        password: 'password123',
      );

      expect(result['success'], false);
      expect(
        result['message'].toString().toLowerCase().contains('timeout'),
        true,
      );
    });
  });
}

