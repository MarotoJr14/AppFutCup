import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../repositories/match_repository.dart';

final matchRepositoryProvider = Provider((_) => MatchRepository());

final matchesProvider = FutureProvider.family<List<MatchModel>, Map<String, dynamic>>((ref, params) {
  final repo = ref.read(matchRepositoryProvider);
  final tournamentId = params['tournament_id'] as int;
  final round = params['round'] as String?;
  if (round != null) {
    return repo.getByTournamentAndRound(tournamentId, round);
  }
  return repo.getByTournament(tournamentId);
});

final matchDetailProvider = FutureProvider.family<MatchModel, int>((ref, matchId) {
  return ref.read(matchRepositoryProvider).getById(matchId);
});

final selectedRoundProvider = StateProvider<String>((ref) => 'Quarterfinal');
