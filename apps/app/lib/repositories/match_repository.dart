import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/match_model.dart';

class MatchRepository {
  final _dio = DioClient.instance;

  Future<List<MatchModel>> getByTournamentAndRound(int tournamentId, String round) async {
    try {
      final res = await _dio.get('/matches/', queryParameters: {'tournament_id': tournamentId, 'round': round});
      return (res.data as List).map((e) => MatchModel.fromJson(e)).toList();
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<List<MatchModel>> getByTournament(int tournamentId) async {
    try {
      final res = await _dio.get('/matches/', queryParameters: {'tournament_id': tournamentId});
      return (res.data as List).map((e) => MatchModel.fromJson(e)).toList();
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<MatchModel> getById(int matchId) async {
    try {
      final res = await _dio.get('/matches/$matchId');
      return MatchModel.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<MatchModel> create({required int tournamentId, required String round}) async {
    try {
      final res = await _dio.post('/matches/', data: {'tournament_id': tournamentId, 'round': round, 'status': 'Pending'});
      return MatchModel.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<MatchModel> update(int matchId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch('/matches/$matchId', data: data);
      return MatchModel.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }
}
