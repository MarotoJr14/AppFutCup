import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/tournament_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/scaffold_with_menu.dart';

const int _pageSize = 10;

class ScorersScreen extends ConsumerStatefulWidget {
  const ScorersScreen({super.key});
  @override
  ConsumerState<ScorersScreen> createState() => _ScorersScreenState();
}

class _ScorersScreenState extends ConsumerState<ScorersScreen> {
  TournamentModel? _tournament;
  int _page = 0;

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
        loading: () => ScaffoldWithMenu(title: AppStrings.scorers, backToHomeOnSystemBack: true, body: LoadingWidget()),
        error: (e, _) => ScaffoldWithMenu(title: AppStrings.scorers, backToHomeOnSystemBack: true, body: AppErrorWidget(message: e.toString())),
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

    return ScaffoldWithMenu(
      title: AppStrings.scorers,
      backToHomeOnSystemBack: true,
      body: Column(
        children: [
          Padding(
            padding : EdgeInsets.all(12),
            child: allTournaments.isEmpty
                ? SizedBox()
                : DropdownButtonFormField<TournamentModel>(
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
                    onChanged: (t) => setState(() {
                      _tournament = t;
                      _page = 0;
                    }),
                  ),
          ),
          Expanded(
            child: tournament == null
                ? Center(child: Text('Selecciona un torneo para ver los goleadores', style: TextStyle(color: AppColors.hint)))
                : Consumer(builder: (_, ref, __) {
                    final scorersAsync = ref.watch(topScorersProvider(tournament.id));
                    return scorersAsync.when(
                      loading: () => RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(allTournamentsProvider);
                          ref.invalidate(activeTournamentProvider);
                          ref.invalidate(followedTournamentIdsProvider);
                          ref.invalidate(topScorersProvider(tournament.id));
                          await ref.read(allTournamentsProvider.future);
                          await ref.read(topScorersProvider(tournament.id).future);
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
                          ref.invalidate(topScorersProvider(tournament.id));
                          await ref.read(allTournamentsProvider.future);
                          await ref.read(topScorersProvider(tournament.id).future);
                        },
                        child: ListView(
                          physics : AlwaysScrollableScrollPhysics(),
                          children: [SizedBox(height: 80), AppErrorWidget(message: e.toString())],
                        ),
                      ),
                      data: (scorers) {
                        if (scorers.isEmpty) {
                          return RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(allTournamentsProvider);
                              ref.invalidate(activeTournamentProvider);
                              ref.invalidate(followedTournamentIdsProvider);
                              ref.invalidate(topScorersProvider(tournament.id));
                              await ref.read(allTournamentsProvider.future);
                              await ref.read(topScorersProvider(tournament.id).future);
                            },
                            child: ListView(
                              physics : AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: 140),
                                Center(child: Text('Sin goleadores', style: TextStyle(color: AppColors.hint))),
                              ],
                            ),
                          );
                        }
                        final sortedScorers = [...scorers]..sort((a, b) {
                            final goals = b.goals.compareTo(a.goals);
                            if (goals != 0) return goals;
                            final matches = a.matchesPlayed.compareTo(b.matchesPlayed);
                            if (matches != 0) return matches;
                            final team = a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
                            if (team != 0) return team;
                            return a.playerName.toLowerCase().compareTo(b.playerName.toLowerCase());
                          });

                        final avgCents = sortedScorers.map((s) {
                          if (s.matchesPlayed <= 0) return 0;
                          final avg = s.goals / s.matchesPlayed;
                          return (avg * 100).round();
                        }).toList(growable: false);
                        final ranks = List<int>.filled(sortedScorers.length, 0);
                        for (var i = 0; i < sortedScorers.length; i++) {
                          if (i == 0) {
                            ranks[i] = 1;
                            continue;
                          }
                          final curr = sortedScorers[i];
                          final prev = sortedScorers[i - 1];
                          final tied = curr.goals == prev.goals && avgCents[i] == avgCents[i - 1];
                          ranks[i] = tied ? ranks[i - 1] : i + 1;
                        }

                        final totalPages = (sortedScorers.length / _pageSize).ceil();
                        final start = _page * _pageSize;
                        final end = (start + _pageSize).clamp(0, sortedScorers.length);
                        final pageItems = sortedScorers.sublist(start, end);

                        return Column(
                          children: [
                            Container(
                              padding : EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: AppColors.surfaceAlt,
                              child: Row(children: [
                                SizedBox(width: 36, child: Text('#', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                                Expanded(child: Text('Jugador', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                                Text('Equipo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                SizedBox(width: 12),
                                SizedBox(width: 36, child: Text('Goles', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                                SizedBox(width: 12),
                                SizedBox(width: 52, child: Text('Prom.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                              ]),
                            ),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  ref.invalidate(allTournamentsProvider);
                                  ref.invalidate(activeTournamentProvider);
                                  ref.invalidate(followedTournamentIdsProvider);
                                  ref.invalidate(topScorersProvider(tournament.id));
                                  await ref.read(allTournamentsProvider.future);
                                  await ref.read(topScorersProvider(tournament.id).future);
                                },
                                child: ListView.builder(
                                  physics : AlwaysScrollableScrollPhysics(),
                                  itemCount: pageItems.length,
                                  itemBuilder: (_, i) {
                                    final s = pageItems[i];
                                    final rank = ranks[start + i];
                                    final avg = s.matchesPlayed > 0 ? (s.goals / s.matchesPlayed) : 0.0;
                                    final medalColor = rank == 1
                                        ? AppColors.primary
                                        : rank == 2
                                            ? AppColors.hint
                                            : rank == 3
                                                ? AppColors.bronze
                                                : AppColors.surfaceAlt;
                                    final medalTextColor = rank <= 3 ? AppColors.onPrimary : AppColors.onSurface;
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: medalColor,
                                        child: Text('$rank', style: TextStyle(color: medalTextColor, fontWeight: FontWeight.bold)),
                                      ),
                                      title: Text(s.playerName, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w500)),
                                      subtitle: Text(s.teamName, style: TextStyle(color: AppColors.hint, fontSize: 12)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding : EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                                            child: Text('${s.goals}', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                                          ),
                                          SizedBox(width: 12),
                                          SizedBox(
                                            width: 52,
                                            child: Text(
                                              avg.toStringAsFixed(2),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: AppColors.hint, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () => context.push('/player/${s.playerId}', extra: tournament.id),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (totalPages > 1)
                              Padding(
                                padding : EdgeInsets.symmetric(vertical: 8),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  IconButton(
                                    onPressed: _page > 0 ? () => setState(() => _page--) : null,
                                    icon: Icon(Icons.chevron_left, color: AppColors.primary),
                                  ),
                                  Text('${_page + 1} / $totalPages', style: TextStyle(color: AppColors.onSurface)),
                                  IconButton(
                                    onPressed: _page < totalPages - 1 ? () => setState(() => _page++) : null,
                                    icon: Icon(Icons.chevron_right, color: AppColors.primary),
                                  ),
                                ]),
                              ),
                          ],
                        );
                      },
                    );
                  }),
          ),
        ],
      ),
    );
  }
}
