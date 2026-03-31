import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tournament_model.dart';
import '../repositories/tournament_repository.dart';

final tournamentRepositoryProvider = Provider((_) => TournamentRepository());

final allTournamentsProvider = FutureProvider<List<TournamentModel>>((ref) {
  return ref.read(tournamentRepositoryProvider).getAll().then((list) {
    final sorted = [...list]..sort((a, b) => b.dateIni.compareTo(a.dateIni));
    return sorted;
  });
});

final activeTournamentProvider = FutureProvider<TournamentModel?>((ref) {
  return ref.read(tournamentRepositoryProvider).getActive();
});

final followedTournamentIdsProvider = FutureProvider<List<int>>((ref) {
  return ref.read(tournamentRepositoryProvider).getFollowedIds();
});

final selectedTournamentIdProvider = StateProvider<int?>((ref) => null);

final followedTournamentsProvider = FutureProvider<List<TournamentModel>>((ref) async {
  final all = await ref.watch(allTournamentsProvider.future);
  final ids = await ref.watch(followedTournamentIdsProvider.future);
  return all.where((t) => ids.contains(t.id)).toList();
});
