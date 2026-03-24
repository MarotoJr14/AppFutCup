import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/match_model.dart';
import '../../models/tournament_model.dart';
import '../../providers/match_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/team_provider.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';

class BracketScreen extends ConsumerStatefulWidget {
  const BracketScreen({super.key});
  @override
  ConsumerState<BracketScreen> createState() => _BracketScreenState();
}

class _BracketScreenState extends ConsumerState<BracketScreen> {
  TournamentModel? _tournament;

  @override
  Widget build(BuildContext context) {
    final allTournaments = ref.watch(allTournamentsProvider).valueOrNull ?? [];
    _tournament ??= allTournaments.isNotEmpty ? allTournaments.first : null;

    return ScaffoldWithMenu(
      title: AppStrings.bracket,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: allTournaments.isEmpty ? const SizedBox() : DropdownButtonFormField<TournamentModel>(
              value: _tournament,
              dropdownColor: AppColors.surfaceAlt,
              style: const TextStyle(color: AppColors.onSurface),
              decoration: InputDecoration(filled: true, fillColor: AppColors.surfaceAlt, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider))),
              items: allTournaments.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
              onChanged: (t) => setState(() => _tournament = t),
            ),
          ),
          Expanded(
            child: _tournament == null
                ? const Center(child: Text('Selecciona un torneo', style: TextStyle(color: AppColors.hint)))
                : _BracketView(tournamentId: _tournament!.id),
          ),
        ],
      ),
    );
  }
}

class _BracketView extends ConsumerWidget {
  final int tournamentId;
  const _BracketView({required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(matchesProvider({'tournament_id': tournamentId}));

    return allAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: AppColors.error))),
      data: (matches) {
        final rounds = ['RoundOf16', 'Quarterfinal', 'Semifinal', 'Final'];
        final roundLabels = {'RoundOf16': AppStrings.roundOf16, 'Quarterfinal': AppStrings.quarterfinal, 'Semifinal': AppStrings.semifinal, 'Final': AppStrings.finalRound};

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rounds.map((r) {
              final rMatches = matches.where((m) => m.round == r).toList();
              return Container(
                width: 180,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: Text(roundLabels[r]!, style: const TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(height: 10),
                    ...rMatches.map((m) => _BracketMatchCard(match: m)),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _BracketMatchCard extends ConsumerWidget {
  final MatchModel match;
  const _BracketMatchCard({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeTeam = match.teamHomeId != null ? ref.watch(teamDetailProvider(match.teamHomeId!)).valueOrNull : null;
    final awayTeam = match.teamAwayId != null ? ref.watch(teamDetailProvider(match.teamAwayId!)).valueOrNull : null;

    return GestureDetector(
      onTap: () => context.push('/match/${match.id}'),
      child: Card(
        color: AppColors.surface,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.divider)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _teamRow(homeTeam?.name ?? 'Por definir', match.goalsHome),
              const Divider(color: AppColors.divider, height: 10),
              _teamRow(awayTeam?.name ?? 'Por definir', match.goalsAway),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamRow(String name, int? goals) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: Text(name, style: const TextStyle(color: AppColors.onSurface, fontSize: 12), overflow: TextOverflow.ellipsis)),
      if (goals != null) Text('$goals', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
    ],
  );
}
