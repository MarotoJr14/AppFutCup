import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../repositories/tournament_repository.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class FollowTournamentsScreen extends ConsumerStatefulWidget {
  const FollowTournamentsScreen({super.key});
  @override
  ConsumerState<FollowTournamentsScreen> createState() => _FollowTournamentsScreenState();
}

class _FollowTournamentsScreenState extends ConsumerState<FollowTournamentsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allTournamentsProvider);
    final followedAsync = ref.watch(followedTournamentIdsProvider);

    return ScaffoldWithMenu(
      title: AppStrings.followTournaments,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar torneo...', hintStyle: const TextStyle(color: AppColors.hint),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true, fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: allAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (all) {
                final followedIds = followedAsync.valueOrNull ?? [];
                final filtered = _query.isEmpty ? all : all.where((t) => t.name.toLowerCase().contains(_query)).toList();
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final t = filtered[i];
                    final isFollowing = followedIds.contains(t.id);
                    return ListTile(
                      title: Text(t.name, style: const TextStyle(color: AppColors.onSurface)),
                      subtitle: Text(t.place, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final repo = TournamentRepository();
                          try {
                            if (isFollowing) {
                              await repo.unfollow(t.id);
                            } else {
                              await repo.follow(t.id);
                            }
                            ref.invalidate(followedTournamentIdsProvider);
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing ? AppColors.surfaceAlt : AppColors.primary,
                          foregroundColor: isFollowing ? AppColors.hint : AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
                      ),
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
