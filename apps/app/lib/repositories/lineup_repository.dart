import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/lineup_model.dart';

class LineupRepository {
  final _dio = DioClient.instance;

  Future<List<LineupModel>> getByMatch(int matchId) async {
    try {
      final res = await _dio.get('/lineups', queryParameters: {'match_id': matchId});
      return (res.data as List).map((e) => LineupModel.fromJson(e)).toList();
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<List<LineupModel>> bulkCreate(List<Map<String, dynamic>> lineups) async {
    try {
      final res = await _dio.post('/lineups/bulk', data: {'lineups': lineups});
      return (res.data as List).map((e) => LineupModel.fromJson(e)).toList();
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }
}
