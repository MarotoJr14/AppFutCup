import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/event_model.dart';
import '../../models/lineup_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/lineup_provider.dart';
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
      loading: () => const ScaffoldWithMenu(title: 'Ficha del Partido', body: LoadingWidget()),
      error: (e, _) => ScaffoldWithMenu(title: 'Ficha del Partido', body: AppErrorWidget(message: e.toString())),
      data: (match) {
        final tournamentAsync = ref.watch(activeTournamentProvider);
        final isActive = tournamentAsync.valueOrNull?.id == match.tournamentId && (tournamentAsync.valueOrNull?.isActive ?? false);

        final homeTeam = match.teamHomeId != null ? ref.watch(teamDetailProvider(match.teamHomeId!)).valueOrNull : null;
        final awayTeam = match.teamAwayId != null ? ref.watch(teamDetailProvider(match.teamAwayId!)).valueOrNull : null;
        final eventsAsync = ref.watch(matchEventsProvider(matchId));
        final lineupsAsync = ref.watch(matchLineupsProvider(matchId));

        return ScaffoldWithMenu(
          title: 'Ficha del Partido',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOrg && isActive)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.push('/match/$matchId/edit'),
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      label: const Text('Editar partido', style: TextStyle(color: AppColors.primary)),
                    ),
                  ),
                // Match info card
                Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.primary)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(_roundLabel(match.round), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        if (match.matchDatetime != null) Text(_fmtDateTime(match.matchDatetime!), style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                        if (match.field != null) Text('Campo: ${match.field}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: GestureDetector(onTap: match.teamHomeId != null ? () => context.push('/team/${match.teamHomeId}') : null, child: Text(homeTeam?.name ?? 'Por definir', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('${match.goalsHome ?? '-'} : ${match.goalsAway ?? '-'}', style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(child: GestureDetector(onTap: match.teamAwayId != null ? () => context.push('/team/${match.teamAwayId}') : null, child: Text(awayTeam?.name ?? 'Por definir', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Image.asset('assets/images/futcup2026_logo.png', height: 50),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Events
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Eventos del partido', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isOrg && isActive)
                      IconButton(onPressed: () => context.push('/match/$matchId/add-event'), icon: const Icon(Icons.add_circle, color: AppColors.primary)),
                  ],
                ),
                eventsAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (events) => events.isEmpty
                      ? const Padding(padding: EdgeInsets.all(16), child: Text('Sin eventos', style: TextStyle(color: AppColors.hint)))
                      : Column(children: events.map((e) => _EventRow(event: e, homeTeamId: match.teamHomeId)).toList()),
                ),
                const SizedBox(height: 20),
                // Lineups
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Alineaciones', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isOrg && isActive)
                      IconButton(onPressed: () => context.push('/match/$matchId/add-lineup'), icon: const Icon(Icons.add_circle, color: AppColors.primary)),
                  ],
                ),
                lineupsAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (lineups) => _LineupsSection(lineups: lineups, homeTeamId: match.teamHomeId, awayTeamId: match.teamAwayId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _roundLabel(String r) {
    if (r == 'Quarterfinal') return AppStrings.quarterfinal;
    if (r == 'Semifinal') return AppStrings.semifinal;
    return AppStrings.finalRound;
  }

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

class _EventRow extends StatelessWidget {
  final EventModel event;
  final int? homeTeamId;
  const _EventRow({required this.event, this.homeTeamId});

  @override
  Widget build(BuildContext context) {
    final isHome = event.teamId == homeTeamId;
    final icon = _eventIcon(event.eventType);
    final color = _eventColor(event.eventType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: isHome ? Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 6), Flexible(child: Text(_playerLabel(event), style: const TextStyle(color: AppColors.onSurface)))]) : const SizedBox()),
          SizedBox(width: 40, child: Center(child: event.minute != null ? Text("${event.minute}'", style: const TextStyle(color: AppColors.hint, fontSize: 11)) : const SizedBox())),
          Expanded(child: !isHome ? Row(mainAxisAlignment: MainAxisAlignment.end, children: [Flexible(child: Text(_playerLabel(event), style: const TextStyle(color: AppColors.onSurface))), const SizedBox(width: 6), Icon(icon, color: color, size: 18)]) : const SizedBox()),
        ],
      ),
    );
  }

  String _playerLabel(EventModel e) => 'Jugador ${e.playerId}';

  IconData _eventIcon(String t) {
    switch (t) {
      case 'Goal': return Icons.sports_soccer;
      case 'Owngoal': return Icons.sports_soccer;
      case 'Yellow': return Icons.square;
      case 'YellowX2': return Icons.square;
      case 'Red': return Icons.square;
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
      default: return AppColors.hint;
    }
  }
}

class _LineupsSection extends StatelessWidget {
  final List<LineupModel> lineups;
  final int? homeTeamId;
  final int? awayTeamId;
  const _LineupsSection({required this.lineups, this.homeTeamId, this.awayTeamId});

  @override
  Widget build(BuildContext context) {
    if (lineups.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Sin alineaciones', style: TextStyle(color: AppColors.hint)));
    final homeStarters = lineups.where((l) => l.teamId == homeTeamId && l.role == 'Starter').toList();
    final homeBench = lineups.where((l) => l.teamId == homeTeamId && l.role == 'Bench').toList();
    final awayStarters = lineups.where((l) => l.teamId == awayTeamId && l.role == 'Starter').toList();
    final awayBench = lineups.where((l) => l.teamId == awayTeamId && l.role == 'Bench').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (homeStarters.isNotEmpty) ...[_sectionTitle('Equipo local – Titulares'), ..._rows(homeStarters)],
        if (homeBench.isNotEmpty) ...[_sectionTitle('Equipo local – Suplentes'), ..._rows(homeBench)],
        if (awayStarters.isNotEmpty) ...[_sectionTitle('Equipo visitante – Titulares'), ..._rows(awayStarters)],
        if (awayBench.isNotEmpty) ...[_sectionTitle('Equipo visitante – Suplentes'), ..._rows(awayBench)],
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 4), child: Text(t, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)));

  List<Widget> _rows(List<LineupModel> l) => l.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('Jugador ${e.playerId}', style: const TextStyle(color: AppColors.onSurface)))).toList();
}
