import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/player_team_model.dart';
import '../../providers/match_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/lineup_provider.dart';
import '../../providers/player_provider.dart';
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
  final Map<int, String?> _homeRoles = {};
  final Map<int, String?> _awayRoles = {};
  bool _loadedExisting = false;

  Future<void> _submit(int homeTeamId, int awayTeamId, List<PlayerTeamModel> homePlayers, List<PlayerTeamModel> awayPlayers) async {
    String? validateTeam(String teamLabel, Map<int, String?> roles) {
      final starters = roles.values.where((r) => r == 'Starter').length;
      final bench = roles.values.where((r) => r == 'Bench').length;

      if (starters > 5) return '$teamLabel: Se ha excedido el máximo de titulares.';
      if (starters < 5 && bench > 0) return '$teamLabel: No se pueden incluir suplentes si hay menos de 5 titulares.';
      if (bench == 0 && starters < 4) return '$teamLabel: Se deben incluir al menos 4 titulares.';
      return null;
    }

    final homeErr = validateTeam('Equipo local', _homeRoles);
    if (homeErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(homeErr), backgroundColor: AppColors.error, duration: const Duration(seconds: 3)));
      return;
    }
    final awayErr = validateTeam('Equipo visitante', _awayRoles);
    if (awayErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(awayErr), backgroundColor: AppColors.error, duration: const Duration(seconds: 3)));
      return;
    }

    final lineups = <Map<String, dynamic>>[
      ...homePlayers
          .where((p) => _homeRoles[p.playerId] != null)
          .map((p) => {'match_id': widget.matchId, 'team_id': homeTeamId, 'player_id': p.playerId, 'role': _homeRoles[p.playerId]}),
      ...awayPlayers
          .where((p) => _awayRoles[p.playerId] != null)
          .map((p) => {'match_id': widget.matchId, 'team_id': awayTeamId, 'player_id': p.playerId, 'role': _awayRoles[p.playerId]}),
    ];
    try {
      await LineupRepository().bulkCreate(lineups);
      ref.invalidate(matchLineupsProvider(widget.matchId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error, duration: const Duration(seconds: 3)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    return matchAsync.when(
      loading: () => ScaffoldWithMenu(title: 'Añadir Alineaciones', body: LoadingWidget()),
      error: (e, _) => ScaffoldWithMenu(title: 'Añadir Alineaciones', body: Center(child: Text(e.toString()))),
      data: (match) {
        if (match.status != 'Pending') {
          return ScaffoldWithMenu(
            title: 'Añadir Alineaciones',
            body: Center(
              child: Text(
                'Las alineaciones solo se pueden cargar cuando el partido está pendiente',
                style: TextStyle(color: AppColors.hint),
              ),
            ),
          );
        }
        final homeId = match.teamHomeId;
        final awayId = match.teamAwayId;
        if (homeId == null || awayId == null) {
          return ScaffoldWithMenu(title: 'Añadir Alineaciones', body: Center(child: Text('El partido necesita tener ambos equipos asignados', style: TextStyle(color: AppColors.hint))));
        }
        final homeTeam = ref.watch(teamDetailProvider(homeId)).valueOrNull;
        final awayTeam = ref.watch(teamDetailProvider(awayId)).valueOrNull;
        final homePlayers = ref.watch(teamPlayersProvider(homeId)).valueOrNull ?? [];
        final awayPlayers = ref.watch(teamPlayersProvider(awayId)).valueOrNull ?? [];
        final existingAsync = ref.watch(matchLineupsProvider(widget.matchId));
        final existing = existingAsync.valueOrNull;
        if (!_loadedExisting && existing != null && _homeRoles.isEmpty && _awayRoles.isEmpty) {
          _homeRoles.clear();
          _awayRoles.clear();
          for (final l in existing) {
            if (l.teamId == homeId) _homeRoles[l.playerId] = l.role;
            if (l.teamId == awayId) _awayRoles[l.playerId] = l.role;
          }
          _loadedExisting = true;
        }
        final currentPlayers = _showHome ? homePlayers : awayPlayers;
        final currentRoles = _showHome ? _homeRoles : _awayRoles;

        return ScaffoldWithMenu(
          title: 'Añadir Alineaciones',
          body: Column(
            children: [
              Padding(
                padding : EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: _teamBtn(homeTeam?.name ?? 'Local', _showHome, () => setState(() => _showHome = true))),
                    SizedBox(width: 10),
                    Expanded(child: _teamBtn(awayTeam?.name ?? 'Visitante', !_showHome, () => setState(() => _showHome = false))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: currentPlayers.length,
                  itemBuilder: (_, i) {
                    final pt = currentPlayers[i];
                    final playerAsync = ref.watch(playerDetailProvider(pt.playerId));
                    final playerName = playerAsync.valueOrNull?.name ?? 'Jugador ${pt.playerId}';
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: AppColors.primary, child: Text('${pt.number}', style: TextStyle(color: AppColors.onPrimary, fontSize: 12))),
                      title: Text(playerName, style: TextStyle(color: AppColors.onSurface)),
                      trailing: DropdownButton<String?>(
                        value: currentRoles[pt.playerId],
                        dropdownColor: AppColors.surfaceAlt,
                        style: TextStyle(color: AppColors.onSurface),
                        hint: Text('—', style: TextStyle(color: AppColors.hint)),
                        underline : SizedBox(),
                        items : [
                          DropdownMenuItem<String?>(value: null, child: Text('—')),
                          DropdownMenuItem<String?>(value: 'Starter', child: Text(AppStrings.starter)),
                          DropdownMenuItem<String?>(value: 'Bench', child: Text(AppStrings.bench)),
                        ],
                        onChanged: (v) => setState(() {
                          if (v == null) {
                            currentRoles.remove(pt.playerId);
                          } else {
                            currentRoles[pt.playerId] = v;
                          }
                        }),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding : EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: () => _submit(homeId, awayId, homePlayers, awayPlayers),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                    child: Text('Cargar alineaciones', style: TextStyle(fontWeight: FontWeight.bold)),
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
      padding : EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(color: active ? AppColors.onPrimary : AppColors.hint, fontWeight: FontWeight.bold)),
    ),
  );
}
