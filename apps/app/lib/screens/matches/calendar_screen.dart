import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/match_model.dart';
import '../../models/tournament_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../repositories/match_repository.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/scaffold_with_menu.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  TournamentModel? _tournament;
  String? _round;

  final _rounds = ['RoundOf16', 'Quarterfinal', 'Semifinal', 'Final'];
  final _roundLimits = const {
    'RoundOf16': 8,
    'Quarterfinal': 4,
    'Semifinal': 2,
    'Final': 1,
  };
  final _roundLabels = {
    'RoundOf16': AppStrings.roundOf16,
    'Quarterfinal': AppStrings.quarterfinal,
    'Semifinal': AppStrings.semifinal,
    'Final': AppStrings.finalRound,
  };

  Future<void> _addMatch({required int tournamentId, required String round}) async {
    try {
      await MatchRepository().create(tournamentId: tournamentId, round: round);
      ref.invalidate(matchesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

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
        loading: () => ScaffoldWithMenu(title: AppStrings.calendar, backToHomeOnSystemBack: true, body: LoadingWidget()),
        error: (e, _) => ScaffoldWithMenu(title: AppStrings.calendar, backToHomeOnSystemBack: true, body: AppErrorWidget(message: e.toString())),
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
    final canLoad = tournament != null && _round != null;
    final matchesAsync = canLoad ? ref.watch(matchesProvider(MatchesQuery(tournamentId: tournament!.id, round: _round!))) : null;

    final limit = _round != null ? _roundLimits[_round!] : null;
    final currentCount = matchesAsync?.valueOrNull?.length ?? 0;
    final limitReached = limit != null && currentCount >= limit;

    final canAdd = isOrg && tournament != null && tournament.isActive && _round != null && !limitReached;

    return ScaffoldWithMenu(
      title: AppStrings.calendar,
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
                  decoration: _dropDeco('Torneo'),
                  hint: Text('Selecciona un torneo', style: TextStyle(color: AppColors.hint)),
                  items: allTournaments.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                  onChanged: (t) => setState(() => _tournament = t),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _round,
                  dropdownColor: AppColors.surfaceAlt,
                  style: TextStyle(color: AppColors.onSurface),
                  decoration: _dropDeco('Ronda'),
                  hint: Text('Selecciona una ronda', style: TextStyle(color: AppColors.hint)),
                  items: _rounds.map((r) => DropdownMenuItem(value: r, child: Text(_roundLabels[r]!))).toList(),
                  onChanged: (r) => setState(() => _round = r),
                ),
                if (canAdd) ...[
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final l = _roundLimits[_round!];
                        final c = matchesAsync?.valueOrNull?.length ?? 0;
                        if (l != null && c >= l) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Límite alcanzado: máximo $l partidos en ${_roundLabels[_round!]!}'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                          return;
                        }
                        _addMatch(tournamentId: tournament!.id, round: _round!);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                      icon: Icon(Icons.add),
                      label: Text('Añadir partido'),
                    ),
                  ),
                ],
                if (isOrg && tournament != null && tournament.isActive && _round != null && limitReached) ...[
                  SizedBox(height: 8),
                  Text(
                    'Límite alcanzado: máximo $limit partidos en ${_roundLabels[_round!]!}',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
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
                if (tournament != null && _round != null) {
                  final q = MatchesQuery(tournamentId: tournament.id, round: _round!);
                  ref.invalidate(matchesProvider(q));
                  await ref.read(matchesProvider(q).future);
                }
              },
              child: !canLoad
                  ? ListView(
                      physics : AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 140),
                        Center(
                          child: Text(
                            'Selecciona un torneo y una ronda\npara ver los partidos',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.hint),
                          ),
                        ),
                      ],
                    )
                  : matchesAsync!.when(
                      loading: () => ListView(
                        physics : AlwaysScrollableScrollPhysics(),
                        children: [SizedBox(height: 140), Center(child: LoadingWidget())],
                      ),
                      error: (e, _) => ListView(
                        physics : AlwaysScrollableScrollPhysics(),
                        children: [SizedBox(height: 80), AppErrorWidget(message: e.toString())],
                      ),
                      data: (matches) => matches.isEmpty
                          ? ListView(
                              physics : AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: 140),
                                Center(child: Text('No hay partidos en esta ronda', style: TextStyle(color: AppColors.hint))),
                              ],
                            )
                          : (() {
                              final sorted = [...matches]..sort((a, b) => a.id.compareTo(b.id));
                              return ListView.builder(
                              physics : AlwaysScrollableScrollPhysics(),
                              padding : EdgeInsets.symmetric(horizontal: 12),
                              itemCount: sorted.length,
                              itemBuilder: (_, i) => _MatchCard(match: sorted[i], tournamentId: tournament.id),
                            );
                            })(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dropDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.hint),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
      );
}

class _MatchCard extends ConsumerWidget {
  final MatchModel match;
  final int tournamentId;
  const _MatchCard({required this.match, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeTeam = match.teamHomeId != null ? ref.watch(teamDetailProvider(match.teamHomeId!)) : null;
    final awayTeam = match.teamAwayId != null ? ref.watch(teamDetailProvider(match.teamAwayId!)) : null;
    final homeStr = homeTeam?.valueOrNull?.name ?? (match.teamHomeId != null ? '...' : 'Por definir');
    final awayStr = awayTeam?.valueOrNull?.name ?? (match.teamAwayId != null ? '...' : 'Por definir');
    final statusColor = match.status == 'Playing'
        ? AppColors.success
        : match.status == 'Penalties'
            ? AppColors.warning
            : match.status == 'Finished'
                ? AppColors.hint
                : AppColors.warning;
    final statusLabel = match.status == 'Playing'
        ? AppStrings.playing
        : match.status == 'Penalties'
            ? 'Penaltis'
            : match.status == 'Finished'
                ? AppStrings.finished
                : AppStrings.pending;
    final showPens = match.status == 'Penalties' || (match.status == 'Finished' && (match.penHome != null || match.penAway != null));
    final pensText = showPens ? '(Pen.: ${match.penHome ?? 0}-${match.penAway ?? 0})' : null;

    return Card(
      color: AppColors.surface,
      margin : EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding : EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _roundLabel(match.round),
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.matchDatetime != null ? _fmtDateTime(match.matchDatetime!) : '',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.field ?? '',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            Divider(color: AppColors.divider),
            Row(
              children: [
                Expanded(child: GestureDetector(onTap: match.teamHomeId != null ? () => context.push('/team/${match.teamHomeId}') : null, child: Text(homeStr, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600), textAlign: TextAlign.center))),
                Container(
                  padding : EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Column(children: [
                    Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10)),
                    if (match.status == 'Finished' || match.status == 'Playing' || match.status == 'Penalties')
                      Text('${match.goalsHome ?? 0} - ${match.goalsAway ?? 0}', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
                    if (pensText != null) Text(pensText, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600, fontSize: 11)),
                  ]),
                ),
                Expanded(child: GestureDetector(onTap: match.teamAwayId != null ? () => context.push('/team/${match.teamAwayId}') : null, child: Text(awayStr, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600), textAlign: TextAlign.center))),
              ],
            ),
            SizedBox(height: 8),
            TextButton(onPressed: () => context.push('/match/${match.id}'), style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero), child: Text('Ver ficha del partido →')),
          ],
        ),
      ),
    );
  }

  String _roundLabel(String r) => {'RoundOf16': AppStrings.roundOf16, 'Quarterfinal': AppStrings.quarterfinal, 'Semifinal': AppStrings.semifinal, 'Final': AppStrings.finalRound}[r] ?? r;
  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}
