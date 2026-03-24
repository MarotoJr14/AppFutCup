import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tournament_model.dart';
import '../repositories/tournament_repository.dart';

final tournamentRepositoryProvider = Provider((_) => TournamentRepository());

final allTournamentsProvider = FutureProvider<List<TournamentModel>>((ref) {
  return ref.read(tournamentRepositoryProvider).getAll();
});

final activeTournamentProvider = FutureProvider<TournamentModel?>((ref) {
  return ref.read(tournamentRepositoryProvider).getActive();
});

final followedTournamentIdsProvider = FutureProvider<List<int>>((ref) {
  return ref.read(tournamentRepositoryProvider).getFollowedIds();
});

final selectedTournamentProvider = StateProvider<TournamentModel?>((ref) => null);
