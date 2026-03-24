import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/player_model.dart';
import '../models/player_team_model.dart';
import '../models/player_stats_model.dart';

class PlayerRepository {
  final _dio = DioClient.instance;

  Future<List<PlayerTeamModel>> getByTeam(int teamId) async {
    try {
      final res = await _dio.get('/player-teams', queryParameters: {'team_id': teamId});
      return (res.data as List).map((e) => PlayerTeamModel.fromJson(e)).toList();
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<PlayerModel?> searchByDni(String dni) async {
    try {
      final res = await _dio.get('/players/search-dni/$dni');
      if (res.data == null) return null;
      return PlayerModel.fromJson(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioError(e);
    }
  }

  Future<PlayerModel> getById(int playerId) async {
    try {
      final res = await _dio.get('/players/$playerId');
      return PlayerModel.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<PlayerStatsModel> getStats(int playerId, int tournamentId) async {
    try {
      final res = await _dio.get('/player-stats/$playerId', queryParameters: {'tournament_id': tournamentId});
      return PlayerStatsModel.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<PlayerTeamModel> register({required String dni, String? name, required int teamId, required int number}) async {
    try {
      final res = await _dio.post('/player-teams/register', data: {
        'dni': dni, if (name != null) 'name': name, 'team_id': teamId, 'number': number,
      });
      return PlayerTeamModel.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }
}
