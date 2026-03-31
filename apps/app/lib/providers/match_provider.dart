import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/match_model.dart';
import '../repositories/match_repository.dart';

final matchRepositoryProvider = Provider((_) => MatchRepository());

@immutable
class MatchesQuery {
  final int tournamentId;
  final String? round;

  const MatchesQuery({required this.tournamentId, this.round});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchesQuery &&
          runtimeType == other.runtimeType &&
          tournamentId == other.tournamentId &&
          round == other.round;

  @override
  int get hashCode => Object.hash(tournamentId, round);
}

final matchesProvider = FutureProvider.family<List<MatchModel>, MatchesQuery>((ref, query) {
  final repo = ref.read(matchRepositoryProvider);
  if (query.round != null) {
    return repo.getByTournamentAndRound(query.tournamentId, query.round!);
  }
  return repo.getByTournament(query.tournamentId);
});

final matchDetailProvider = FutureProvider.family<MatchModel, int>((ref, matchId) {
  return ref.read(matchRepositoryProvider).getById(matchId);
});

final selectedRoundProvider = StateProvider<String>((ref) => 'Quarterfinal');
