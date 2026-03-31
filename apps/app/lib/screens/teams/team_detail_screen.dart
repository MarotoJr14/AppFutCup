import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../repositories/player_repository.dart';
import '../../models/player_model.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class TeamDetailScreen extends ConsumerWidget {
  final int teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync    = ref.watch(teamDetailProvider(teamId));
    final playersAsync = ref.watch(teamPlayersProvider(teamId));
    final user         = ref.watch(authProvider).valueOrNull;
    final isOrg        = user?.isOrg ?? false;

    return teamAsync.when(
      loading: () => ScaffoldWithMenu(title: 'Equipo', body: LoadingWidget()),
      error: (e, _) => ScaffoldWithMenu(title: 'Equipo', body: AppErrorWidget(message: e.toString())),
      data: (team) {
        final allTournaments = ref.watch(allTournamentsProvider).valueOrNull ?? [];
        final isActive = allTournaments.any((t) => t.id == team.tournamentId && t.isActive);

        return ScaffoldWithMenu(
          title: team.name,
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allTournamentsProvider);
              ref.invalidate(teamDetailProvider(teamId));
              ref.invalidate(teamPlayersProvider(teamId));
              await ref.read(allTournamentsProvider.future);
              await ref.read(teamDetailProvider(teamId).future);
              await ref.read(teamPlayersProvider(teamId).future);
            },
            child: SingleChildScrollView(
              physics : AlwaysScrollableScrollPhysics(),
              padding : EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOrg && isActive)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => context.push('/team/$teamId/edit'),
                        icon: Icon(Icons.edit, color: AppColors.primary),
                        label: Text('Editar información', style: TextStyle(color: AppColors.primary)),
                      ),
                    ),
                  // Team info card
                  Card(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.primary),
                    ),
                    child: Padding(
                      padding : EdgeInsets.all(16),
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
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Jugadores', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                      if (isOrg && isActive)
                        TextButton.icon(
                          onPressed: () => context.push('/team/$teamId/add-player'),
                          icon: Icon(Icons.person_add, color: AppColors.primary),
                          label: Text('Añadir jugador', style: TextStyle(color: AppColors.primary)),
                        ),
                    ],
                  ),
                  playersAsync.when(
                    loading: () => const LoadingWidget(),
                    error: (e, _) => AppErrorWidget(message: e.toString()),
                    data: (playerTeams) => playerTeams.isEmpty
                        ? Text('Sin jugadores', style: TextStyle(color: AppColors.hint))
                        : _PlayersList(
                            playerTeams: playerTeams,
                            teamId: teamId,
                            tournamentId: team.tournamentId,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
    padding : EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text('$label: ', style: TextStyle(color: AppColors.hint, fontSize: 13)),
      Expanded(child: Text(value, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w500))),
    ]),
  );
}

/// Loads real player names by fetching each player by id
class _PlayersList extends StatefulWidget {
  final List playerTeams;
  final int teamId;
  final int tournamentId;

  const _PlayersList({
    required this.playerTeams,
    required this.teamId,
    required this.tournamentId,
  });

  @override
  State<_PlayersList> createState() => _PlayersListState();
}

class _PlayersListState extends State<_PlayersList> {
  final Map<int, PlayerModel> _players = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final repo = PlayerRepository();
    for (final pt in widget.playerTeams) {
      try {
        final player = await repo.getById(pt.playerId);
        if (mounted) setState(() => _players[pt.playerId] = player);
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _players.isEmpty) return LoadingWidget();

    return Column(
      children: widget.playerTeams.map<Widget>((pt) {
        final player = _players[pt.playerId];
        final name   = player?.name ?? '...';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text('${pt.number}', style: TextStyle(color: AppColors.onPrimary, fontSize: 12)),
          ),
          title: Text(name, style: TextStyle(color: AppColors.onSurface)),
          trailing: Icon(Icons.chevron_right, color: AppColors.hint),
          onTap: () => context.push(
            '/player/${pt.playerId}',
            extra: {'tournamentId': widget.tournamentId, 'teamId': widget.teamId},
          ),
        );
      }).toList(),
    );
  }
}
