import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/team_model.dart';

class TeamRepository {
  final _dio = DioClient.instance;

  Future<List<TeamModel>> getByTournament(int tournamentId) async {
    try {
      final res = await _dio.get('/teams', queryParameters: {'tournament_id': tournamentId});
      return (res.data as List).map((e) => TeamModel.fromJson(e)).toList();
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<TeamModel> getById(int teamId) async {
    try {
      final res = await _dio.get('/teams/$teamId');
      return TeamModel.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<TeamModel> create({required String name, required String group, required String kitColor, required int tournamentId}) async {
    try {
      final res = await _dio.post('/teams', data: {
        'name': name, 'group': group, 'kit_color': kitColor, 'tournament_id': tournamentId,
      });
      return TeamModel.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }
}
