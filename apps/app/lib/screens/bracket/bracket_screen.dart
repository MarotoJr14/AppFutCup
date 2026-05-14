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
import '../../widgets/loading_widget.dart';
import '../../widgets/scaffold_with_menu.dart';

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
    final selectedId = ref.watch(selectedTournamentIdProvider);
    final followedIds = ref.watch(followedTournamentIdsProvider).valueOrNull ?? [];
    final user = ref.watch(authProvider).valueOrNull;
    final isOrg = user?.isOrg ?? false;

    if (_tournament != null) {
      final found = allTournaments.where((t) => t.id == _tournament!.id).toList();
      _tournament = found.isNotEmpty ? found.first : null;
    }

    if (isOrg) {
      final activeAsync = ref.watch(activeTournamentProvider);
      return activeAsync.when(
        loading: () => ScaffoldWithMenu(title: AppStrings.bracket, backToHomeOnSystemBack: true, body: LoadingWidget()),
        error: (e, _) => ScaffoldWithMenu(title: AppStrings.bracket, backToHomeOnSystemBack: true, body: Center(child: Text(e.toString(), style: TextStyle(color: AppColors.error)))),
        data: (active) {
          if (_tournament == null && active != null) {
            final found = allTournaments.where((t) => t.id == active.id).toList();
            _tournament = found.isNotEmpty ? found.first : null;
          }
          return _BracketWithSelector(
            allTournaments: allTournaments,
            initialTournament: _tournament,
            onTournamentChanged: (t) => setState(() => _tournament = t),
          );
        },
      );
    }

    if (followedIds.isNotEmpty && _tournament == null && selectedId != null) {
      final found = allTournaments.where((t) => t.id == selectedId).toList();
      if (found.isNotEmpty) _tournament = found.first;
    }

    return _BracketWithSelector(
      allTournaments: allTournaments,
      initialTournament: _tournament,
      onTournamentChanged: (t) => setState(() => _tournament = t),
    );
  }
}

class _BracketWithSelector extends StatelessWidget {
  final List<TournamentModel> allTournaments;
  final TournamentModel? initialTournament;
  final ValueChanged<TournamentModel?> onTournamentChanged;

  const _BracketWithSelector({
    required this.allTournaments,
    required this.initialTournament,
    required this.onTournamentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithMenu(
      title: AppStrings.bracket,
      backToHomeOnSystemBack: true,
      body: Column(
        children: [
          Padding(
            padding : EdgeInsets.all(12),
            child: allTournaments.isEmpty
                ? SizedBox()
                : DropdownButtonFormField<TournamentModel>(
                    value: initialTournament,
                    dropdownColor: AppColors.surfaceAlt,
                    style: TextStyle(color: AppColors.onSurface),
                    hint: Text('Selecciona un torneo', style: TextStyle(color: AppColors.hint)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
                    ),
                    items: allTournaments.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                    onChanged: onTournamentChanged,
                  ),
          ),
          Expanded(
            child: initialTournament == null
                ? Center(child: Text('Selecciona un torneo para ver el cuadro', style: TextStyle(color: AppColors.hint)))
                : _BracketView(tournamentId: initialTournament!.id),
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
    final allAsync = ref.watch(matchesProvider(MatchesQuery(tournamentId: tournamentId)));

    return allAsync.when(
      loading: () => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allTournamentsProvider);
          ref.invalidate(activeTournamentProvider);
          ref.invalidate(followedTournamentIdsProvider);
          await ref.read(allTournamentsProvider.future);
          final q = MatchesQuery(tournamentId: tournamentId);
          ref.invalidate(matchesProvider(q));
          await ref.read(matchesProvider(q).future);
        },
        child: ListView(
          physics : AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: 140), Center(child: LoadingWidget())],
        ),
      ),
      error: (e, _) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allTournamentsProvider);
          ref.invalidate(activeTournamentProvider);
          ref.invalidate(followedTournamentIdsProvider);
          await ref.read(allTournamentsProvider.future);
          final q = MatchesQuery(tournamentId: tournamentId);
          ref.invalidate(matchesProvider(q));
          await ref.read(matchesProvider(q).future);
        },
        child: ListView(
          physics : AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: 80), Center(child: Text(e.toString(), style: TextStyle(color: AppColors.error)))],
        ),
      ),
      data: (matches) {
        const rounds = ['RoundOf16', 'Quarterfinal', 'Semifinal', 'Final'];
        final roundLabels = {
          'RoundOf16': AppStrings.roundOf16,
          'Quarterfinal': AppStrings.quarterfinal,
          'Semifinal': AppStrings.semifinal,
          'Final': AppStrings.finalRound,
        };

        const double cardWidth = 180;
        const double cardHeight = 96;
        const double colGap = 20;
        const double vGap = 16;
        const double topPadding = 12;
        const double leftPadding = 12;
        const double headerHeight = 28;
        const double headerGap = 10;

        int _cmp(MatchModel a, MatchModel b) {
          final ad = a.matchDatetime;
          final bd = b.matchDatetime;
          if (ad == null && bd != null) return 1;
          if (ad != null && bd == null) return -1;
          if (ad != null && bd != null) {
            final c = ad.compareTo(bd);
            if (c != 0) return c;
          }
          final af = (a.field ?? '').trim();
          final bf = (b.field ?? '').trim();
          final c2 = af.toLowerCase().compareTo(bf.toLowerCase());
          if (c2 != 0) return c2;
          return a.id.compareTo(b.id);
        }

        final byRound = <String, List<MatchModel>>{
          for (final r in rounds) r: matches.where((m) => m.round == r).toList()..sort(_cmp),
        };

        final yPos = <int, double>{};
        final base = byRound['RoundOf16'] ?? const <MatchModel>[];
        for (var i = 0; i < base.length; i++) {
          yPos[base[i].id] = i * (cardHeight + vGap);
        }

        void computeNext(String round, String prevRound) {
          final curr = byRound[round] ?? const <MatchModel>[];
          final prev = byRound[prevRound] ?? const <MatchModel>[];
          for (var i = 0; i < curr.length; i++) {
            final a = i * 2;
            final b = i * 2 + 1;
            if (a < prev.length && b < prev.length) {
              final ya = yPos[prev[a].id];
              final yb = yPos[prev[b].id];
              if (ya != null && yb != null) {
                yPos[curr[i].id] = (ya + yb) / 2;
                continue;
              }
            }
            yPos[curr[i].id] = i * (cardHeight + vGap);
          }
        }

        computeNext('Quarterfinal', 'RoundOf16');
        computeNext('Semifinal', 'Quarterfinal');
        computeNext('Final', 'Semifinal');

        final baseHeight = base.isEmpty
            ? 240.0
            : ((base.length - 1) * (cardHeight + vGap) + cardHeight);
        final canvasHeight = topPadding + headerHeight + headerGap + baseHeight + topPadding;
        final canvasWidth = leftPadding + rounds.length * cardWidth + (rounds.length - 1) * colGap + leftPadding;

        final positioned = <Widget>[];
        for (var col = 0; col < rounds.length; col++) {
          final r = rounds[col];
          final x = leftPadding + col * (cardWidth + colGap);
          positioned.add(
            Positioned(
              left: x,
              top: topPadding,
              width: cardWidth,
              height: headerHeight,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  roundLabels[r] ?? r,
                  style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          );

          final rMatches = byRound[r] ?? const <MatchModel>[];
          for (final m in rMatches) {
            final y = yPos[m.id] ?? 0;
            positioned.add(
              Positioned(
                left: x,
                top: topPadding + headerHeight + headerGap + y,
                width: cardWidth,
                height: cardHeight,
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: _BracketMatchCard(match: m),
                ),
              ),
            );
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allTournamentsProvider);
            ref.invalidate(activeTournamentProvider);
            ref.invalidate(followedTournamentIdsProvider);
            await ref.read(allTournamentsProvider.future);
            final q = MatchesQuery(tournamentId: tournamentId);
            ref.invalidate(matchesProvider(q));
            await ref.read(matchesProvider(q).future);
          },
          child: ListView(
            physics : AlwaysScrollableScrollPhysics(),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasHeight,
                  child: Stack(children: positioned),
                ),
              ),
            ],
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
    final hasScore = match.goalsHome != null && match.goalsAway != null;
    final isFinished = match.status == 'Finished';
    final hasPens = match.penHome != null && match.penAway != null;
    final showPens = match.status == 'Penalties' || (match.status == 'Finished' && hasPens);
    final scoreDraw = isFinished && hasScore && match.goalsHome == match.goalsAway;
    final homeWinner = isFinished &&
        hasScore &&
        ((match.goalsHome! > match.goalsAway!) || (scoreDraw && hasPens && match.penHome! > match.penAway!));
    final awayWinner = isFinished &&
        hasScore &&
        ((match.goalsAway! > match.goalsHome!) || (scoreDraw && hasPens && match.penAway! > match.penHome!));
    final isDraw = scoreDraw && (!hasPens || match.penHome == match.penAway);

    return GestureDetector(
      onTap: () => context.push('/match/${match.id}'),
      child: Card(
        color: AppColors.surface,
        margin : EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppColors.divider)),
        child: Padding(
          padding : EdgeInsets.all(10),
          child: Column(
            children: [
              _teamRow(
                homeTeam?.name ?? 'Por definir',
                match.goalsHome,
                pen: showPens ? match.penHome : null,
                isTop: true,
                background: isFinished
                    ? (homeWinner ? AppColors.success.withOpacity(0.25) : (!isDraw ? AppColors.redCard.withOpacity(0.25) : AppColors.surfaceAlt))
                    : null,
                forceWhiteText: isFinished,
              ),
              Divider(color: AppColors.divider, height: 10),
              _teamRow(
                awayTeam?.name ?? 'Por definir',
                match.goalsAway,
                pen: showPens ? match.penAway : null,
                isTop: false,
                background: isFinished
                    ? (awayWinner ? AppColors.success.withOpacity(0.25) : (!isDraw ? AppColors.redCard.withOpacity(0.25) : AppColors.surfaceAlt))
                    : null,
                forceWhiteText: isFinished,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamRow(
    String name,
    int? goals, {
    int? pen,
    required bool isTop,
    Color? background,
    required bool forceWhiteText,
  }) {
    final textColor = forceWhiteText ? AppColors.onSurface : AppColors.onSurface;
    final scoreColor = forceWhiteText ? AppColors.onSurface : AppColors.primary;
    final scoreText = goals != null ? (pen != null ? '$goals ($pen)' : '$goals') : null;

    return Container(
      padding : EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.vertical(
          top: isTop ? Radius.circular(6) : Radius.zero,
          bottom: !isTop ? Radius.circular(6) : Radius.zero,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (scoreText != null)
            Text(
              scoreText,
              style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
