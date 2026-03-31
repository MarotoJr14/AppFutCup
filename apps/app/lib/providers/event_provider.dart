import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../models/top_scorer_model.dart';
import '../repositories/event_repository.dart';

final eventRepositoryProvider = Provider((_) => EventRepository());

final matchEventsProvider = FutureProvider.family<List<EventModel>, int>((ref, matchId) {
  return ref.read(eventRepositoryProvider).getByMatch(matchId);
});

final topScorersProvider = FutureProvider.family<List<TopScorerModel>, int>((ref, tournamentId) {
  return ref.read(eventRepositoryProvider).getTopScorers(tournamentId);
});
