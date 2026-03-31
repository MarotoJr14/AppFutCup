import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_model.dart';
import '../models/player_stats_model.dart';
import '../models/player_team_model.dart';
import '../repositories/player_repository.dart';

class PlayerStatsParams {
  final int playerId;
  final int tournamentId;
  PlayerStatsParams(this.playerId, this.tournamentId);
  @override bool operator ==(Object o) => o is PlayerStatsParams && o.playerId == playerId && o.tournamentId == tournamentId;
  @override int get hashCode => Object.hash(playerId, tournamentId);
}

class PlayerTeamParams {
  final int teamId;
  final int playerId;
  PlayerTeamParams(this.teamId, this.playerId);
  @override
  bool operator ==(Object o) => o is PlayerTeamParams && o.teamId == teamId && o.playerId == playerId;
  @override
  int get hashCode => Object.hash(teamId, playerId);
}

final playerStatsProvider = FutureProvider.family<PlayerStatsModel, PlayerStatsParams>((ref, params) {
  return ref.read(playerRepositoryProvider).getStats(params.playerId, params.tournamentId);
});

final playerRepositoryProvider = Provider((_) => PlayerRepository());

final playerDetailProvider = FutureProvider.family<PlayerModel, int>((ref, playerId) {
  return ref.read(playerRepositoryProvider).getById(playerId);
});

final playerTeamProvider = FutureProvider.family<PlayerTeamModel?, PlayerTeamParams>((ref, params) {
  return ref.read(playerRepositoryProvider).getByTeamAndPlayer(teamId: params.teamId, playerId: params.playerId);
});
