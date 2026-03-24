import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/match_model.dart';
import '../../models/tournament_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/team_provider.dart';
import '../../repositories/match_repository.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  TournamentModel? _tournament;
  String _round = 'Quarterfinal';

  final _rounds = ['RoundOf16', 'Quarterfinal', 'Semifinal', 'Final'];
  final _roundLabels = {
    'RoundOf16': AppStrings.roundOf16,
    'Quarterfinal': AppStrings.quarterfinal,
    'Semifinal': AppStrings.semifinal,
    'Final': AppStrings.finalRound,
  };

  Future<void> _addMatch() async {
    if (_tournament == null) return;
    try {
      await MatchRepository().create(tournamentId: _tournament!.id, round: _round);
      ref.invalidate(matchesProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTournaments = ref.watch(allTournamentsProvider).valueOrNull ?? [];
    final user = ref.watch(authProvider).valueOrNull;
    final isOrg = user?.isOrg ?? false;

    _tournament ??= allTournaments.isNotEmpty ? allTournaments.first : null;

    final matchesAsync = _tournament != null
        ? ref.watch(matchesProvider({'tournament_id': _tournament!.id, 'round': _round}))
        : null;

    return ScaffoldWithMenu(
      title: AppStrings.calendar,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (allTournaments.isNotEmpty)
                  DropdownButtonFormField<TournamentModel>(
                    value: _tournament,
                    dropdownColor: AppColors.surfaceAlt,
                    style: const TextStyle(color: AppColors.onSurface),
                    decoration: _dropDeco('Torneo'),
                    items: allTournaments.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                    onChanged: (t) => setState(() => _tournament = t),
                  ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _round,
                  dropdownColor: AppColors.surfaceAlt,
                  style: const TextStyle(color: AppColors.onSurface),
                  decoration: _dropDeco('Ronda'),
                  items: _rounds.map((r) => DropdownMenuItem(value: r, child: Text(_roundLabels[r]!))).toList(),
                  onChanged: (r) => setState(() => _round = r!),
                ),
                if (isOrg && _tournament != null && _tournament!.isActive) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addMatch,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir partido'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: matchesAsync == null
                ? const Center(child: Text('Selecciona un torneo', style: TextStyle(color: AppColors.hint)))
                : matchesAsync.when(
                    loading: () => const LoadingWidget(),
                    error: (e, _) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(matchesProvider)),
                    data: (matches) => matches.isEmpty
                        ? const Center(child: Text('No hay partidos', style: TextStyle(color: AppColors.hint)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: matches.length,
                            itemBuilder: (_, i) => _MatchCard(match: matches[i], tournamentId: _tournament!.id),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dropDeco(String label) => InputDecoration(
    labelText: label, labelStyle: const TextStyle(color: AppColors.hint),
    filled: true, fillColor: AppColors.surfaceAlt,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
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

    final statusColor = match.status == 'Playing' ? AppColors.success : match.status == 'Finished' ? AppColors.hint : AppColors.warning;
    final statusLabel = match.status == 'Playing' ? AppStrings.playing : match.status == 'Finished' ? AppStrings.finished : AppStrings.pending;

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(_roundLabel(match.round), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                if (match.matchDatetime != null) Text(_fmtDateTime(match.matchDatetime!), style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                if (match.field != null) ...[const SizedBox(width: 8), Text(match.field!, style: const TextStyle(color: AppColors.hint, fontSize: 11))],
              ],
            ),
            const Divider(color: AppColors.divider),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: match.teamHomeId != null ? () => context.push('/team/${match.teamHomeId}') : null,
                    child: Text(homeStr, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Column(
                    children: [
                      Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10)),
                      if (match.status == 'Finished' || match.status == 'Playing')
                        Text('${match.goalsHome ?? 0} - ${match.goalsAway ?? 0}', style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: match.teamAwayId != null ? () => context.push('/team/${match.teamAwayId}') : null,
                    child: Text(awayStr, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/match/${match.id}'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
              child: const Text('Ver ficha del partido →'),
            ),
          ],
        ),
      ),
    );
  }

  String _roundLabel(String r) {
    if (r == 'RoundOf16') return AppStrings.roundOf16;
    if (r == 'Quarterfinal') return AppStrings.quarterfinal;
    if (r == 'Semifinal') return AppStrings.semifinal;
    return AppStrings.finalRound;
  }

  String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}
