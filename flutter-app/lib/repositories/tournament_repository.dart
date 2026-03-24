import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/tournament_model.dart';

class TournamentRepository {
  final _dio = DioClient.instance;

  Future<List<TournamentModel>> getAll() async {
    try {
      final res = await _dio.get('/tournaments');
      return (res.data as List).map((e) => TournamentModel.fromJson(e)).toList();
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<TournamentModel?> getActive() async {
    try {
      final res = await _dio.get('/tournaments/active');
      return TournamentModel.fromJson(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<int>> getFollowedIds() async {
    try {
      final res = await _dio.get('/user-tournaments/me');
      return (res.data as List).map<int>((e) => e['tournament_id'] as int).toList();
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<void> follow(int tournamentId) async {
    try {
      await _dio.post('/user-tournaments/follow', data: {'tournament_id': tournamentId});
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<void> unfollow(int tournamentId) async {
    try {
      await _dio.delete('/user-tournaments/unfollow/$tournamentId');
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }
}
