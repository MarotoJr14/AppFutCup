import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/player_provider.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class PlayerDetailScreen extends ConsumerWidget {
  final int playerId;
  final int tournamentId;
  const PlayerDetailScreen({super.key, required this.playerId, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerStatsProvider(PlayerStatsParams(playerId, tournamentId)));

    return statsAsync.when(
      loading: () => const ScaffoldWithMenu(title: 'Jugador', body: LoadingWidget()),
      error: (e, _) => ScaffoldWithMenu(title: 'Jugador', body: AppErrorWidget(message: e.toString())),
      data: (s) => ScaffoldWithMenu(
        title: s.playerName,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.primary)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header('#${s.number} – ${s.playerName}', s.teamName),
                  const Divider(color: AppColors.divider, height: 28),
                  _section('Partidos jugados'),
                  _row('De titular', '${s.matchesStarter}'),
                  _row('De suplente', '${s.matchesBench}'),
                  const Divider(color: AppColors.divider, height: 28),
                  _section('Sanciones'),
                  _row('Tarjetas amarillas', '${s.yellowCards}', color: AppColors.yellowCard),
                  _row('Dobles amarillas', '${s.doubleYellows}', color: AppColors.warning),
                  _row('Tarjetas rojas', '${s.redCards}', color: AppColors.redCard),
                  const Divider(color: AppColors.divider, height: 28),
                  _section('Goles'),
                  _row('Total', '${s.goals}', color: AppColors.goalColor),
                  _row('Goles por partido', s.goalsPerMatch.toStringAsFixed(2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String name, String team) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(name, style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(team, style: const TextStyle(color: AppColors.hint)),
    ],
  );

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
  );

  Widget _row(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.hint)),
        Text(value, style: TextStyle(color: color ?? AppColors.onSurface, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
