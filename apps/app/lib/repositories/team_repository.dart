import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/team_model.dart';

class TeamRepository {
  final _dio = DioClient.instance;

  Future<List<TeamModel>> getByTournament(int tournamentId) async {
    try {
      final res = await _dio.get('/teams/', queryParameters: {'tournament_id': tournamentId});
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
      final res = await _dio.post('/teams/', data: {
        'name': name, 'group': group, 'kit_color': kitColor, 'tournament_id': tournamentId,
      });
      return TeamModel.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<TeamModel> update(int teamId, {String? name, String? group, String? kitColor}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (group != null) data['group'] = group;
      if (kitColor != null) data['kit_color'] = kitColor;
      final res = await _dio.patch('/teams/$teamId', data: data);
      return TeamModel.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }
}
