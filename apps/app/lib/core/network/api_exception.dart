import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException e) {
    final data = e.response?.data;
    String msg = 'Error de conexión';
    if (data is Map && data.containsKey('detail')) {
      msg = data['detail'].toString();
    } else if (e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.receiveTimeout) {
      msg = 'Tiempo de espera agotado';
    } else if (e.type == DioExceptionType.connectionError) {
      msg = 'Sin conexión con el servidor';
    }
    return ApiException(msg, statusCode: e.response?.statusCode);
  }

  @override
  String toString() => message;
}
