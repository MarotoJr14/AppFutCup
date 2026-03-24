import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class TeamDetailScreen extends ConsumerWidget {
  final int teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final playersAsync = ref.watch(teamPlayersProvider(teamId));
    final user = ref.watch(authProvider).valueOrNull;
    final isOrg = user?.isOrg ?? false;

    return teamAsync.when(
      loading: () => const ScaffoldWithMenu(title: 'Equipo', body: LoadingWidget()),
      error: (e, _) => ScaffoldWithMenu(title: 'Equipo', body: AppErrorWidget(message: e.toString())),
      data: (team) {
        final allTournaments = ref.watch(allTournamentsProvider).valueOrNull ?? [];
        final tournament = allTournaments.firstWhere((t) => t.id == team.tournamentId, orElse: () => allTournaments.first);
        final isActive = tournament.isActive;

        return ScaffoldWithMenu(
          title: team.name,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.primary)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Nombre', team.name),
                        _row('Grupo', team.group),
                        _row('Color equipación', team.kitColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jugadores', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isOrg && isActive)
                      TextButton.icon(
                        onPressed: () => context.push('/team/$teamId/add-player'),
                        icon: const Icon(Icons.person_add, color: AppColors.primary),
                        label: const Text('Añadir jugador', style: TextStyle(color: AppColors.primary)),
                      ),
                  ],
                ),
                playersAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (players) => players.isEmpty
                      ? const Text('Sin jugadores', style: TextStyle(color: AppColors.hint))
                      : Column(
                          children: players.map((p) => ListTile(
                            leading: CircleAvatar(backgroundColor: AppColors.primary, child: Text('${p.number}', style: const TextStyle(color: AppColors.onPrimary, fontSize: 12))),
                            title: Text('Jugador ${p.playerId}', style: const TextStyle(color: AppColors.onSurface)),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
                            onTap: () => context.push('/player/${p.playerId}', extra: team.tournamentId),
                          )).toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text('$label: ', style: const TextStyle(color: AppColors.hint, fontSize: 13)),
      Expanded(child: Text(value, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w500))),
    ]),
  );
}
