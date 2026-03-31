import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/tournament_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/scaffold_with_menu.dart';

class TeamsListScreen extends ConsumerStatefulWidget {
  const TeamsListScreen({super.key});
  @override
  ConsumerState<TeamsListScreen> createState() => _TeamsListScreenState();
}

class _TeamsListScreenState extends ConsumerState<TeamsListScreen> {
  TournamentModel? _tournament;

  @override
  Widget build(BuildContext context) {
    final allTournaments = ref.watch(allTournamentsProvider).valueOrNull ?? [];
    final selectedId = ref.watch(selectedTournamentIdProvider);
    final followedIds = ref.watch(followedTournamentIdsProvider).valueOrNull ?? [];
    final user = ref.watch(authProvider).valueOrNull;
    final isOrg = user?.isOrg ?? false;

    if (isOrg) {
      final activeAsync = ref.watch(activeTournamentProvider);
      return activeAsync.when(
        loading: () => ScaffoldWithMenu(title: AppStrings.teams, backToHomeOnSystemBack: true, body: LoadingWidget()),
        error: (e, _) => ScaffoldWithMenu(title: AppStrings.teams, backToHomeOnSystemBack: true, body: AppErrorWidget(message: e.toString())),
        data: (active) => _buildBody(allTournaments, selectedId, followedIds.isNotEmpty, isOrg: true, activeTournament: active),
      );
    }

    return _buildBody(allTournaments, selectedId, followedIds.isNotEmpty, isOrg: false, activeTournament: null);
  }

  Widget _buildBody(
    List<TournamentModel> allTournaments,
    int? selectedId,
    bool hasFollowed, {
    required bool isOrg,
    required TournamentModel? activeTournament,
  }) {
    if (_tournament != null) {
      final found = allTournaments.where((t) => t.id == _tournament!.id).toList();
      _tournament = found.isNotEmpty ? found.first : null;
    }

    if (isOrg) {
      if (_tournament == null && activeTournament != null) {
        final found = allTournaments.where((t) => t.id == activeTournament.id).toList();
        _tournament = found.isNotEmpty ? found.first : null;
      }
    } else {
      if (hasFollowed && _tournament == null && selectedId != null) {
        final found = allTournaments.where((t) => t.id == selectedId).toList();
        if (found.isNotEmpty) _tournament = found.first;
      }
    }

    final tournament = _tournament;
    final teamsAsync = tournament != null ? ref.watch(teamsProvider(tournament.id)) : null;
    final showAddTeam = isOrg && tournament != null && tournament.isActive;

    return ScaffoldWithMenu(
      title: AppStrings.teams,
      backToHomeOnSystemBack: true,
      body: Column(
        children: [
          Padding(
            padding : EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<TournamentModel>(
                  value: _tournament,
                  dropdownColor: AppColors.surfaceAlt,
                  style: TextStyle(color: AppColors.onSurface),
                  hint: Text('Selecciona un torneo', style: TextStyle(color: AppColors.hint)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
                  ),
                  items: allTournaments.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                  onChanged: (t) => setState(() => _tournament = t),
                ),
                if (showAddTeam) ...[
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/add-team', extra: tournament!.id),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                      icon: Icon(Icons.add),
                      label: Text('Añadir equipo'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allTournamentsProvider);
                ref.invalidate(activeTournamentProvider);
                ref.invalidate(followedTournamentIdsProvider);
                await ref.read(allTournamentsProvider.future);
                final t = _tournament;
                if (t != null) {
                  ref.invalidate(teamsProvider(t.id));
                  await ref.read(teamsProvider(t.id).future);
                }
              },
              child: tournament == null
                  ? ListView(
                      physics : AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 140),
                        Center(child: Text('Selecciona un torneo para ver los equipos', style: TextStyle(color: AppColors.hint))),
                      ],
                    )
                  : teamsAsync!.when(
                      loading: () => ListView(
                        physics : AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 140),
                          Center(child: LoadingWidget()),
                        ],
                      ),
                      error: (e, _) => ListView(
                        physics : AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 80),
                          AppErrorWidget(message: e.toString()),
                        ],
                      ),
                      data: (teams) => teams.isEmpty
                          ? ListView(
                              physics : AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: 140),
                                Center(child: Text('No hay equipos', style: TextStyle(color: AppColors.hint))),
                              ],
                            )
                          : ListView.builder(
                              physics : AlwaysScrollableScrollPhysics(),
                              itemCount: teams.length,
                              itemBuilder: (_, i) => ListTile(
                                leading : CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.shield, color: AppColors.onPrimary)),
                                title: Text(teams[i].name, style: TextStyle(color: AppColors.onSurface)),
                                subtitle: Text(teams[i].group, style: TextStyle(color: AppColors.hint)),
                                trailing: Icon(Icons.chevron_right, color: AppColors.hint),
                                onTap: () => context.push('/team/${teams[i].id}'),
                              ),
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
