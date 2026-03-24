import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/tournament_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/team_provider.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class TeamsListScreen extends ConsumerStatefulWidget {
  const TeamsListScreen({super.key});
  @override
  ConsumerState<TeamsListScreen> createState() => _TeamsListScreenState();
}

class _TeamsListScreenState extends ConsumerState<TeamsListScreen> {
  TournamentModel? _tournament;

  @override
  Widget build(BuildContext context) {
    final allTournaments = ref.watch(allTournamentsProvider).valueOrNull ?? [];
    _tournament ??= allTournaments.isNotEmpty ? allTournaments.first : null;
    final user = ref.watch(authProvider).valueOrNull;
    final isOrg = user?.isOrg ?? false;

    return ScaffoldWithMenu(
      title: AppStrings.teams,
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
                    decoration: InputDecoration(filled: true, fillColor: AppColors.surfaceAlt, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider))),
                    items: allTournaments.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                    onChanged: (t) => setState(() => _tournament = t),
                  ),
                if (isOrg && _tournament != null && _tournament!.isActive) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/add-team', extra: _tournament!.id),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir equipo'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _tournament == null
                ? const Center(child: Text('Selecciona un torneo', style: TextStyle(color: AppColors.hint)))
                : Consumer(builder: (_, ref, __) {
                    final teamsAsync = ref.watch(teamsProvider(_tournament!.id));
                    return teamsAsync.when(
                      loading: () => const LoadingWidget(),
                      error: (e, _) => AppErrorWidget(message: e.toString()),
                      data: (teams) => teams.isEmpty
                          ? const Center(child: Text('No hay equipos', style: TextStyle(color: AppColors.hint)))
                          : ListView.builder(
                              itemCount: teams.length,
                              itemBuilder: (_, i) => ListTile(
                                leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.shield, color: AppColors.onPrimary)),
                                title: Text(teams[i].name, style: const TextStyle(color: AppColors.onSurface)),
                                subtitle: Text(teams[i].group, style: const TextStyle(color: AppColors.hint)),
                                trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
                                onTap: () => context.push('/team/${teams[i].id}'),
                              ),
                            ),
                    );
                  }),
          ),
        ],
      ),
    );
  }
}
