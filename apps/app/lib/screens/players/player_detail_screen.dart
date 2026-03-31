import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class PlayerDetailScreen extends ConsumerWidget {
  final int playerId;
  final int tournamentId;
  final int? teamId;
  const PlayerDetailScreen({super.key, required this.playerId, required this.tournamentId, this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerStatsProvider(PlayerStatsParams(playerId, tournamentId)));
    final user = ref.watch(authProvider).valueOrNull;
    final isOrg = user?.isOrg ?? false;
    final allTournaments = ref.watch(allTournamentsProvider).valueOrNull ?? [];
    final isActive = allTournaments.any((t) => t.id == tournamentId && t.isActive);

    return statsAsync.when(
      loading: () => ScaffoldWithMenu(title: 'Jugador', body: LoadingWidget()),
      error: (e, _) => ScaffoldWithMenu(title: 'Jugador', body: AppErrorWidget(message: e.toString())),
      data: (s) => ScaffoldWithMenu(
        title: s.playerName,
        body: RefreshIndicator(
          onRefresh: () async {
            final p = PlayerStatsParams(playerId, tournamentId);
            ref.invalidate(playerStatsProvider(p));
            await ref.read(playerStatsProvider(p).future);
          },
          child: SingleChildScrollView(
            physics : AlwaysScrollableScrollPhysics(),
            padding : EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isOrg && isActive && teamId != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.push(
                        '/player/$playerId/edit',
                        extra: {'tournamentId': tournamentId, 'teamId': teamId},
                      ),
                      icon: Icon(Icons.edit, color: AppColors.primary),
                      label: Text('Editar información', style: TextStyle(color: AppColors.primary)),
                    ),
                  ),
                Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.primary)),
                  child: Padding(
                    padding : EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header('#${s.number} – ${s.playerName}', s.teamName),
                        Divider(color: AppColors.divider, height: 28),
                        _section('Partidos jugados'),
                        _row('Total', '${s.matchesStarter + s.matchesBench}'),
                        _row('De titular', '${s.matchesStarter}'),
                        _row('De suplente', '${s.matchesBench}'),
                        Divider(color: AppColors.divider, height: 28),
                        _section('Sanciones'),
                        _row('Tarjetas amarillas', '${s.yellowCards}', color: AppColors.yellowCard),
                        _row('Dobles amarillas', '${s.doubleYellows}', color: AppColors.warning),
                        _row('Tarjetas rojas', '${s.redCards}', color: AppColors.redCard),
                        Divider(color: AppColors.divider, height: 28),
                        _section('Goles'),
                        _row('Total', '${s.goals}', color: AppColors.goalColor),
                        _row('Goles por partido', s.goalsPerMatch.toStringAsFixed(2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String name, String team) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(name, style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
      SizedBox(height: 4),
      Text(team, style: TextStyle(color: AppColors.hint)),
    ],
  );

  Widget _section(String t) => Padding(
    padding : EdgeInsets.only(bottom: 8),
    child: Text(t, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
  );

  Widget _row(String label, String value, {Color? color}) => Padding(
    padding : EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.hint)),
        Text(value, style: TextStyle(color: color ?? AppColors.onSurface, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
