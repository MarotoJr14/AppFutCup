import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_stats_model.dart';
import '../repositories/player_repository.dart';

class PlayerStatsParams {
  final int playerId;
  final int tournamentId;
  PlayerStatsParams(this.playerId, this.tournamentId);
  @override bool operator ==(Object o) => o is PlayerStatsParams && o.playerId == playerId && o.tournamentId == tournamentId;
  @override int get hashCode => Object.hash(playerId, tournamentId);
}

final playerStatsProvider = FutureProvider.family<PlayerStatsModel, PlayerStatsParams>((ref, params) {
  return ref.read(playerRepositoryProvider).getStats(params.playerId, params.tournamentId);
});

final playerRepositoryProvider = Provider((_) => PlayerRepository());
