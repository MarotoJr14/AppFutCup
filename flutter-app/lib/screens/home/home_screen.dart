import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/tournament_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final isOrg = user?.isOrg ?? false;

    return ScaffoldWithMenu(
      title: AppStrings.home,
      body: isOrg ? const _OrgHome() : const _UserHome(),
    );
  }
}

class _OrgHome extends ConsumerWidget {
  const _OrgHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeTournamentProvider);
    return activeAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(activeTournamentProvider)),
      data: (t) => t == null
          ? const Center(child: Text('No hay torneo activo', style: TextStyle(color: AppColors.hint)))
          : Padding(padding: const EdgeInsets.all(16), child: _TournamentCard(tournament: t)),
    );
  }
}

class _UserHome extends ConsumerStatefulWidget {
  const _UserHome();
  @override
  ConsumerState<_UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends ConsumerState<_UserHome> {
  TournamentModel? _selected;

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allTournamentsProvider);
    final followedAsync = ref.watch(followedTournamentIdsProvider);

    return allAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (all) {
        final followedIds = followedAsync.valueOrNull ?? [];
        final followed = all.where((t) => followedIds.contains(t.id)).toList();
        if (followed.isEmpty) {
          return const Center(child: Text('No sigues ningún torneo todavía.\nUsa el menú para seguir torneos.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.hint)));
        }
        _selected ??= followed.first;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<TournamentModel>(
                value: _selected,
                dropdownColor: AppColors.surfaceAlt,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: InputDecoration(filled: true, fillColor: AppColors.surfaceAlt, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider))),
                items: followed.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                onChanged: (t) => setState(() => _selected = t),
              ),
              const SizedBox(height: 20),
              if (_selected != null) _TournamentCard(tournament: _selected!),
            ],
          ),
        );
      },
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final sameDay = tournament.dateIni.day == tournament.dateEnd.day &&
        tournament.dateIni.month == tournament.dateEnd.month &&
        tournament.dateIni.year == tournament.dateEnd.year;

    String dateText = _fmt(tournament.dateIni);
    if (!sameDay) dateText += ' – ${_fmt(tournament.dateEnd)}';

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.primary, width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Image.asset('assets/images/futcup2026_logo.png', height: 80),
            const SizedBox(height: 16),
            Text(tournament.name, style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.location_on_outlined, color: AppColors.hint, size: 16), const SizedBox(width: 4), Expanded(child: Text(tournament.place, style: const TextStyle(color: AppColors.onSurface)))]),
            const SizedBox(height: 6),
            Row(children: [const Icon(Icons.calendar_today_outlined, color: AppColors.hint, size: 16), const SizedBox(width: 4), Text(dateText, style: const TextStyle(color: AppColors.onSurface))]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: tournament.isActive ? AppColors.success.withOpacity(0.2) : AppColors.hint.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(tournament.isActive ? 'Activo' : 'Inactivo', style: TextStyle(color: tournament.isActive ? AppColors.success : AppColors.hint, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
