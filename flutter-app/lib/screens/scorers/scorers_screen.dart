import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/tournament_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

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
    _tournament ??= allTournaments.isNotEmpty ? allTournaments.first : null;

    return ScaffoldWithMenu(
      title: AppStrings.scorers,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: allTournaments.isEmpty
                ? const SizedBox()
                : DropdownButtonFormField<TournamentModel>(
              value: _tournament,
              dropdownColor: AppColors.surfaceAlt,
              style: const TextStyle(color: AppColors.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
              ),
              items: allTournaments.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
              onChanged: (t) => setState(() { _tournament = t; _page = 0; }),
            ),
          ),
          Expanded(
            child: _tournament == null
                ? const Center(child: Text('Selecciona un torneo', style: TextStyle(color: AppColors.hint)))
                : Consumer(
              builder: (_, ref, __) {
                final scorersAsync = ref.watch(topScorersProvider(_tournament!.id));
                return scorersAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (scorers) {
                    if (scorers.isEmpty) {
                      return const Center(child: Text('Sin goleadores', style: TextStyle(color: AppColors.hint)));
                    }

                    final totalPages = (scorers.length / _pageSize).ceil();
                    final start = _page * _pageSize;
                    final end   = (start + _pageSize).clamp(0, scorers.length);
                    final page  = scorers.sublist(start, end);
                    // Global rank offset for display
                    final offset = start;

                    return Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: AppColors.surfaceAlt,
                          child: const Row(
                            children: [
                              SizedBox(width: 36, child: Text('#', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                              Expanded(child: Text('Jugador', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                              Text('Equipo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              SizedBox(width: 12),
                              SizedBox(width: 36, child: Text('Goles', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                            ],
                          ),
                        ),
                        // List
                        Expanded(
                          child: ListView.builder(
                            itemCount: page.length,
                            itemBuilder: (_, i) {
                              final s    = page[i];
                              final rank = offset + i; // global rank
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: rank == 0
                                      ? AppColors.primary
                                      : rank == 1
                                      ? AppColors.hint
                                      : AppColors.surfaceAlt,
                                  child: Text(
                                    '${rank + 1}',
                                    style: TextStyle(
                                      color: rank < 2 ? AppColors.onPrimary : AppColors.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(s.playerName, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w500)),
                                subtitle: Text(s.teamName, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('${s.goals}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                                onTap: () => context.push('/player/${s.playerId}', extra: _tournament!.id),
                              );
                            },
                          ),
                        ),
                        // Pagination
                        if (totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _page > 0 ? () => setState(() => _page--) : null,
                                  icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                                ),
                                Text(
                                  '${_page + 1} / $totalPages',
                                  style: const TextStyle(color: AppColors.onSurface),
                                ),
                                IconButton(
                                  onPressed: _page < totalPages - 1 ? () => setState(() => _page++) : null,
                                  icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
