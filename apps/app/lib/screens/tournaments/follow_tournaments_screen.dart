import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/tournament_model.dart';
import '../../providers/tournament_provider.dart';
import '../../repositories/tournament_repository.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

const int _pageSize = 10;

class FollowTournamentsScreen extends ConsumerStatefulWidget {
  const FollowTournamentsScreen({super.key});
  @override
  ConsumerState<FollowTournamentsScreen> createState() => _FollowTournamentsScreenState();
}

class _FollowTournamentsScreenState extends ConsumerState<FollowTournamentsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _page = 0;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  /// Same date format as home screen card
  String _fmtDate(TournamentModel t) {
    final sameDay = t.dateIni.day   == t.dateEnd.day   &&
        t.dateIni.month == t.dateEnd.month  &&
        t.dateIni.year  == t.dateEnd.year;
    final ini = _fmt(t.dateIni);
    return sameDay ? ini : '$ini – ${_fmt(t.dateEnd)}';
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final allAsync      = ref.watch(allTournamentsProvider);
    final followedAsync = ref.watch(followedTournamentIdsProvider);

    return ScaffoldWithMenu(
      title: AppStrings.followTournaments,
      backToHomeOnSystemBack: true,
      body: Column(
        children: [
          Padding(
            padding : EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar torneo...',
                hintStyle: TextStyle(color: AppColors.hint),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
              ),
              onChanged: (v) => setState(() { _query = v.toLowerCase(); _page = 0; }),
            ),
          ),
          Expanded(
            child: allAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (all) {
                final followedIds = followedAsync.valueOrNull ?? [];

                // Sort by dateIni descending (most recent first)
                final sorted = [...all]
                  ..sort((a, b) => b.dateIni.compareTo(a.dateIni));

                final filtered = _query.isEmpty
                    ? sorted
                    : sorted.where((t) => t.name.toLowerCase().contains(_query)).toList();

                final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 9999);
                final start = _page * _pageSize;
                final end   = (start + _pageSize).clamp(0, filtered.length);
                final page  = filtered.sublist(start, end);

                return Column(
                  children: [
                    Expanded(
                      child: page.isEmpty
                          ? Center(
                        child: Text('Sin resultados', style: TextStyle(color: AppColors.hint)),
                      )
                          : ListView.builder(
                        itemCount: page.length,
                        itemBuilder: (_, i) {
                          final t           = page[i];
                          final isFollowing = followedIds.contains(t.id);
                          return ListTile(
                            title: Text(
                              t.name,
                              style: TextStyle(color: AppColors.onSurface),
                            ),
                            subtitle: Text(
                              _fmtDate(t),
                              style: TextStyle(color: AppColors.hint, fontSize: 12),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                final repo = TournamentRepository();
                                try {
                                  if (isFollowing) await repo.unfollow(t.id);
                                  else             await repo.follow(t.id);
                                  ref.invalidate(followedTournamentIdsProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: AppColors.error, duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing ? AppColors.surfaceAlt : AppColors.primary,
                                foregroundColor: isFollowing ? AppColors.hint : AppColors.onPrimary,
                                padding : EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
                            ),
                          );
                        },
                      ),
                    ),
                    if (totalPages > 1)
                      Padding(
                        padding : EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _page > 0 ? () => setState(() => _page--) : null,
                              icon: Icon(Icons.chevron_left, color: AppColors.primary),
                            ),
                            Text(
                              '${_page + 1} / $totalPages',
                              style: TextStyle(color: AppColors.onSurface),
                            ),
                            IconButton(
                              onPressed: _page < totalPages - 1 ? () => setState(() => _page++) : null,
                              icon: Icon(Icons.chevron_right, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
