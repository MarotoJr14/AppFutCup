import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team_model.dart';
import '../models/player_team_model.dart';
import '../repositories/team_repository.dart';
import '../repositories/player_repository.dart';

final teamRepositoryProvider = Provider((_) => TeamRepository());
final playerRepositoryProvider = Provider((_) => PlayerRepository());

final teamsProvider = FutureProvider.family<List<TeamModel>, int>((ref, tournamentId) {
  return ref.read(teamRepositoryProvider).getByTournament(tournamentId);
});

final teamDetailProvider = FutureProvider.family<TeamModel, int>((ref, teamId) {
  return ref.read(teamRepositoryProvider).getById(teamId);
});

final teamPlayersProvider = FutureProvider.family<List<PlayerTeamModel>, int>((ref, teamId) {
  return ref.read(playerRepositoryProvider).getByTeam(teamId);
});
