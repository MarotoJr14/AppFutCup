import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/event_model.dart';
import '../models/top_scorer_model.dart';

class EventRepository {
  final _dio = DioClient.instance;

  Future<List<EventModel>> getByMatch(int matchId) async {
    try {
      final res = await _dio.get('/events/', queryParameters: {'match_id': matchId});
      return (res.data as List).map((e) => EventModel.fromJson(e)).toList();
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<EventModel> create(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/events/', data: data);
      return EventModel.fromJson(res.data);
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }

  Future<List<TopScorerModel>> getTopScorers(int tournamentId) async {
    try {
      final res = await _dio.get('/events/top-scorers', queryParameters: {'tournament_id': tournamentId});
      return (res.data as List).map((e) => TopScorerModel.fromJson(e)).toList();
    } on DioException catch (e) { throw ApiException.fromDioError(e); }
  }
}
