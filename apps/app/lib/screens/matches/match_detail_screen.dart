import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_strings.dart';
import '../../models/event_model.dart';
import '../../models/lineup_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/lineup_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class MatchDetailScreen extends ConsumerWidget {
  final int matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(matchId));
    final user = ref.watch(authProvider).valueOrNull;
    final isOrg = user?.isOrg ?? false;

    return matchAsync.when(
      loading: () => ScaffoldWithMenu(title: 'Ficha del Partido', body: LoadingWidget()),
      error: (e, _) => ScaffoldWithMenu(title: 'Ficha del Partido', body: AppErrorWidget(message: e.toString())),
      data: (match) {
        final tournamentAsync = ref.watch(activeTournamentProvider);
        final isActive = tournamentAsync.valueOrNull?.id == match.tournamentId && (tournamentAsync.valueOrNull?.isActive ?? false);

        final homeTeam = match.teamHomeId != null ? ref.watch(teamDetailProvider(match.teamHomeId!)).valueOrNull : null;
        final awayTeam = match.teamAwayId != null ? ref.watch(teamDetailProvider(match.teamAwayId!)).valueOrNull : null;
        final eventsAsync = ref.watch(matchEventsProvider(matchId));
        final lineupsAsync = ref.watch(matchLineupsProvider(matchId));
        final showPenaltiesSection = match.status == 'Penalties' || (match.status == 'Finished' && (match.penHome != null || match.penAway != null));
        final scoreText = (match.status == 'Playing' || match.status == 'Penalties' || match.status == 'Finished')
            ? '${match.goalsHome ?? 0} - ${match.goalsAway ?? 0}'
            : '-';
        final penaltiesText = showPenaltiesSection ? '(Pen.: ${match.penHome ?? 0}-${match.penAway ?? 0})' : null;

        return ScaffoldWithMenu(
          title: 'Ficha del Partido',
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeTournamentProvider);
              ref.invalidate(matchDetailProvider(matchId));
              ref.invalidate(matchEventsProvider(matchId));
              ref.invalidate(matchLineupsProvider(matchId));
              await ref.read(activeTournamentProvider.future);
              await ref.read(matchDetailProvider(matchId).future);
              await ref.read(matchEventsProvider(matchId).future);
              await ref.read(matchLineupsProvider(matchId).future);
            },
            child: SingleChildScrollView(
              physics : AlwaysScrollableScrollPhysics(),
              padding : EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOrg && isActive && match.status != 'Finished')
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.push('/match/$matchId/edit'),
                      icon: Icon(Icons.edit, color: AppColors.primary),
                      label: Text('Editar partido', style: TextStyle(color: AppColors.primary)),
                    ),
                  ),
                // Match info card
                Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.primary)),
                        child: Padding(
                          padding : EdgeInsets.all(16),
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
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: GestureDetector(onTap: match.teamHomeId != null ? () => context.push('/team/${match.teamHomeId}') : null, child: Text(homeTeam?.name ?? 'Por definir', textAlign: TextAlign.center, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)))),
                            Padding(
                              padding : EdgeInsets.symmetric(horizontal: 12),
                              child: Text(scoreText, style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(child: GestureDetector(onTap: match.teamAwayId != null ? () => context.push('/team/${match.teamAwayId}') : null, child: Text(awayTeam?.name ?? 'Por definir', textAlign: TextAlign.center, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)))),
                          ],
                        ),
                        if (penaltiesText != null) ...[
                          SizedBox(height: 6),
                          Text(penaltiesText, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                        SizedBox(height: 12),
                        Image.asset(AppAssets.logoForTheme(context), height: 50),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Events
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Eventos del partido', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isOrg && isActive && match.status == 'Playing')
                      IconButton(onPressed: () => context.push('/match/$matchId/add-event'), icon: Icon(Icons.add_circle, color: AppColors.primary)),
                  ],
                ),
                eventsAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (events) {
                    final normalEvents = events.where((e) => e.eventType != 'PenaltyScored' && e.eventType != 'PenaltyMissed').toList();
                    final penEvents = events.where((e) => e.eventType == 'PenaltyScored' || e.eventType == 'PenaltyMissed').toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (normalEvents.isEmpty)
                          Padding(padding: EdgeInsets.all(16), child: Text('Sin eventos', style: TextStyle(color: AppColors.hint)))
                        else
                          Column(children: normalEvents.map((e) => _EventRow(event: e, homeTeamId: match.teamHomeId)).toList()),

                        if (showPenaltiesSection) ...[
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tanda de penaltis', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                              if (isOrg && isActive && match.status == 'Penalties')
                                IconButton(
                                  onPressed: () => context.push('/match/$matchId/add-penalty'),
                                  icon: Icon(Icons.add_circle, color: AppColors.primary),
                                ),
                            ],
                          ),
                          if (penEvents.isEmpty)
                            Padding(padding: EdgeInsets.all(16), child: Text('Sin penaltis registrados', style: TextStyle(color: AppColors.hint)))
                          else
                            Column(children: penEvents.map((e) => _EventRow(event: e, homeTeamId: match.teamHomeId)).toList()),
                        ],
                      ],
                    );
                  },
                ),
                SizedBox(height: 20),
                // Lineups
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Alineaciones', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isOrg && isActive && match.status == 'Pending')
                      IconButton(onPressed: () => context.push('/match/$matchId/add-lineup'), icon: Icon(Icons.add_circle, color: AppColors.primary)),
                  ],
                ),
                lineupsAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (lineups) => _LineupsSection(
                    lineups: lineups,
                    homeTeamId: match.teamHomeId,
                    awayTeamId: match.teamAwayId,
                    homeTeamName: homeTeam?.name,
                    awayTeamName: awayTeam?.name,
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

  String _roundLabel(String r) {
    if(r == 'RoundOf16') return AppStrings.roundOf16;
    if (r == 'Quarterfinal') return AppStrings.quarterfinal;
    if (r == 'Semifinal') return AppStrings.semifinal;
    return AppStrings.finalRound;
  }

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

class _EventRow extends ConsumerWidget {
  final EventModel event;
  final int? homeTeamId;
  const _EventRow({required this.event, this.homeTeamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerDetailProvider(event.playerId));
    final playerName = playerAsync.valueOrNull?.name ?? 'Jugador ${event.playerId}';
    final ptAsync = ref.watch(playerTeamProvider(PlayerTeamParams(event.teamId, event.playerId)));
    final number = ptAsync.valueOrNull?.number;
    final baseLabel = number != null ? '$number. $playerName' : playerName;
    final label = event.eventType == 'Owngoal' ? '$baseLabel (p.p)' : baseLabel;
    final isHomeTeam = event.teamId == homeTeamId;
    final isHomeColumn = event.eventType == 'Owngoal' ? !isHomeTeam : isHomeTeam;
    final color = _eventColor(event.eventType);
    final iconWidget = _eventIconWidget(event.eventType, color);

    return Padding(
      padding : EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: isHomeColumn ? Row(children: [iconWidget, SizedBox(width: 6), Flexible(child: Text(label, style: TextStyle(color: AppColors.onSurface)))])  : SizedBox()),
          SizedBox(width: 40, child: Center(child: event.minute != null ? Text("${event.minute}'", style: TextStyle(color: AppColors.hint, fontSize: 11))  : SizedBox())),
          Expanded(child: !isHomeColumn ? Row(mainAxisAlignment: MainAxisAlignment.end, children: [Flexible(child: Text(label, style: TextStyle(color: AppColors.onSurface))), SizedBox(width: 6), iconWidget])  : SizedBox()),
        ],
      ),
    );
  }

  Widget _eventIconWidget(String t, Color color) {
    if (t == 'YellowX2') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.square, color: AppColors.yellowCard, size: 14),
          Icon(Icons.square, color: AppColors.redCard, size: 14),
        ],
      );
    }
    return Icon(_eventIcon(t), color: color, size: 18);
  }

  IconData _eventIcon(String t) {
    switch (t) {
      case 'Goal': return Icons.sports_soccer;
      case 'Owngoal': return Icons.sports_soccer;
      case 'Yellow': return Icons.square;
      case 'Red': return Icons.square;
      case 'PenaltyScored': return Icons.check_circle;
      case 'PenaltyMissed': return Icons.cancel;
      default: return Icons.circle;
    }
  }

  Color _eventColor(String t) {
    switch (t) {
      case 'Goal': return AppColors.goalColor;
      case 'Owngoal': return AppColors.error;
      case 'Yellow': return AppColors.yellowCard;
      case 'YellowX2': return AppColors.warning;
      case 'Red': return AppColors.redCard;
      case 'PenaltyScored': return AppColors.success;
      case 'PenaltyMissed': return AppColors.error;
      default: return AppColors.hint;
    }
  }
}

class _LineupsSection extends ConsumerWidget {
  final List<LineupModel> lineups;
  final int? homeTeamId;
  final int? awayTeamId;
  final String? homeTeamName;
  final String? awayTeamName;

  const _LineupsSection({
    required this.lineups,
    this.homeTeamId,
    this.awayTeamId,
    this.homeTeamName,
    this.awayTeamName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lineups.isEmpty) return Padding(padding: EdgeInsets.all(16), child: Text('Sin alineaciones', style: TextStyle(color: AppColors.hint)));
    final homeStarters = lineups.where((l) => l.teamId == homeTeamId && l.role == 'Starter').toList();
    final homeBench = lineups.where((l) => l.teamId == homeTeamId && l.role == 'Bench').toList();
    final awayStarters = lineups.where((l) => l.teamId == awayTeamId && l.role == 'Starter').toList();
    final awayBench = lineups.where((l) => l.teamId == awayTeamId && l.role == 'Bench').toList();

    final hasHome = homeTeamId != null || homeStarters.isNotEmpty || homeBench.isNotEmpty;
    final hasAway = awayTeamId != null || awayStarters.isNotEmpty || awayBench.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasHome)
          _teamLineups(
            ref,
            teamName: homeTeamName ?? 'Equipo local',
            starters: homeStarters,
            bench: homeBench,
          ),
        if (hasHome && hasAway) SizedBox(height: 14),
        if (hasAway)
          _teamLineups(
            ref,
            teamName: awayTeamName ?? 'Equipo visitante',
            starters: awayStarters,
            bench: awayBench,
          ),
      ],
    );
  }

  Widget _teamLineups(
    WidgetRef ref, {
    required String teamName,
    required List<LineupModel> starters,
    required List<LineupModel> bench,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(teamName, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
        SizedBox(height: 6),
        _roleTitle('Titulares'),
        if (starters.isEmpty)
          Padding(padding: EdgeInsets.symmetric(vertical: 2), child: Text('Sin titulares', style: TextStyle(color: AppColors.hint))),
        ..._playerRows(ref, starters),
        SizedBox(height: 8),
        _roleTitle('Suplentes'),
        if (bench.isEmpty)
          Padding(padding: EdgeInsets.symmetric(vertical: 2), child: Text('Sin suplentes', style: TextStyle(color: AppColors.hint))),
        ..._playerRows(ref, bench),
      ],
    );
  }

  Widget _roleTitle(String t) => Padding(
    padding : EdgeInsets.only(bottom: 4),
    child: Text(t, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600, fontSize: 12)),
  );

  List<Widget> _playerRows(WidgetRef ref, List<LineupModel> l) => l.map((e) {
    final playerAsync = ref.watch(playerDetailProvider(e.playerId));
    final name = playerAsync.valueOrNull?.name ?? 'Jugador ${e.playerId}';
    final ptAsync = ref.watch(playerTeamProvider(PlayerTeamParams(e.teamId, e.playerId)));
    final number = ptAsync.valueOrNull?.number;
    final label = number != null ? '$number. $name' : name;
    return Padding(
      padding : EdgeInsets.symmetric(vertical: 2),
      child: Text(label, style: TextStyle(color: AppColors.onSurface)),
    );
  }).toList();
}
