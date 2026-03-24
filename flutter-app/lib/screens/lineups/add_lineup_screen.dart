import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/player_team_model.dart';
import '../../providers/match_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/lineup_provider.dart';
import '../../repositories/lineup_repository.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';

class AddLineupScreen extends ConsumerStatefulWidget {
  final int matchId;
  const AddLineupScreen({super.key, required this.matchId});
  @override
  ConsumerState<AddLineupScreen> createState() => _AddLineupScreenState();
}

class _AddLineupScreenState extends ConsumerState<AddLineupScreen> {
  bool _showHome = true;
  // player_id -> role
  final Map<int, String> _homeRoles = {};
  final Map<int, String> _awayRoles = {};

  Future<void> _submit(int homeTeamId, int awayTeamId, List<PlayerTeamModel> homePlayers, List<PlayerTeamModel> awayPlayers) async {
    if (_homeRoles.length < homePlayers.length || _awayRoles.length < awayPlayers.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asigna rol a todos los jugadores'), backgroundColor: AppColors.error));
      return;
    }
    final lineups = [
      ...homePlayers.map((p) => {'match_id': widget.matchId, 'team_id': homeTeamId, 'player_id': p.playerId, 'role': _homeRoles[p.playerId]}),
      ...awayPlayers.map((p) => {'match_id': widget.matchId, 'team_id': awayTeamId, 'player_id': p.playerId, 'role': _awayRoles[p.playerId]}),
    ];
    try {
      await LineupRepository().bulkCreate(lineups.cast<Map<String, dynamic>>());
      ref.invalidate(matchLineupsProvider(widget.matchId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    return matchAsync.when(
      loading: () => const ScaffoldWithMenu(title: 'Añadir Alineaciones', body: LoadingWidget()),
      error: (e, _) => ScaffoldWithMenu(title: 'Añadir Alineaciones', body: Center(child: Text(e.toString()))),
      data: (match) {
        final homeId = match.teamHomeId;
        final awayId = match.teamAwayId;
        if (homeId == null || awayId == null) {
          return const ScaffoldWithMenu(title: 'Añadir Alineaciones', body: Center(child: Text('El partido necesita tener ambos equipos asignados', style: TextStyle(color: AppColors.hint))));
        }
        final homeTeam = ref.watch(teamDetailProvider(homeId)).valueOrNull;
        final awayTeam = ref.watch(teamDetailProvider(awayId)).valueOrNull;
        final homePlayers = ref.watch(teamPlayersProvider(homeId)).valueOrNull ?? [];
        final awayPlayers = ref.watch(teamPlayersProvider(awayId)).valueOrNull ?? [];
        final currentPlayers = _showHome ? homePlayers : awayPlayers;
        final currentRoles = _showHome ? _homeRoles : _awayRoles;

        final allAssigned = _homeRoles.length >= homePlayers.length && _awayRoles.length >= awayPlayers.length;

        return ScaffoldWithMenu(
          title: 'Añadir Alineaciones',
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: _teamBtn(homeTeam?.name ?? 'Local', _showHome, () => setState(() => _showHome = true))),
                    const SizedBox(width: 10),
                    Expanded(child: _teamBtn(awayTeam?.name ?? 'Visitante', !_showHome, () => setState(() => _showHome = false))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: currentPlayers.length,
                  itemBuilder: (_, i) {
                    final pt = currentPlayers[i];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: AppColors.primary, child: Text('${pt.number}', style: const TextStyle(color: AppColors.onPrimary, fontSize: 12))),
                      title: Text('Jugador ${pt.playerId}', style: const TextStyle(color: AppColors.onSurface)),
                      trailing: DropdownButton<String>(
                        value: currentRoles[pt.playerId],
                        dropdownColor: AppColors.surfaceAlt,
                        style: const TextStyle(color: AppColors.onSurface),
                        hint: const Text('Rol', style: TextStyle(color: AppColors.hint)),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'Starter', child: Text(AppStrings.starter)),
                          DropdownMenuItem(value: 'Bench', child: Text(AppStrings.bench)),
                        ],
                        onChanged: (v) => setState(() => currentRoles[pt.playerId] = v!),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: allAssigned ? () => _submit(homeId, awayId, homePlayers, awayPlayers) : null,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, disabledBackgroundColor: AppColors.hint),
                    child: const Text('Cargar alineaciones', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _teamBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(color: active ? AppColors.onPrimary : AppColors.hint, fontWeight: FontWeight.bold)),
    ),
  );
}
