import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_assets.dart';
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
      body: isOrg ? _OrgHome()  : _UserHome(),
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
          ? Center(child: Text('No hay torneo activo', style: TextStyle(color: AppColors.hint)))
          : Padding(padding : EdgeInsets.all(16), child: _TournamentCard(tournament: t)),
    );
  }
}

class _UserHome extends ConsumerStatefulWidget {
  const _UserHome();
  @override
  ConsumerState<_UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends ConsumerState<_UserHome> {
  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allTournamentsProvider);
    final followedAsync = ref.watch(followedTournamentIdsProvider);
    final selectedId = ref.watch(selectedTournamentIdProvider);

    return allAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (all) {
        final followedIds = followedAsync.valueOrNull ?? [];
        final followed = all.where((t) => followedIds.contains(t.id)).toList();
        if (followed.isEmpty) {
          return Center(child: Text('No sigues ningún torneo todavía.\nUsa el menú para seguir torneos.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.hint)));
        }
        if (selectedId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedTournamentIdProvider.notifier).state = followed.first.id;
          });
        }
        final selectedTournament = selectedId != null
            ? (followed.firstWhere((t) => t.id == selectedId, orElse: () => followed.first))
            : followed.first;
        return Padding(
          padding : EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<TournamentModel>(
                value: selectedTournament,
                dropdownColor: AppColors.surfaceAlt,
                style: TextStyle(color: AppColors.onSurface),
                decoration: InputDecoration(filled: true, fillColor: AppColors.surfaceAlt, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider))),
                items: followed.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                onChanged: (t) => ref.read(selectedTournamentIdProvider.notifier).state = t?.id,
              ),
              SizedBox(height: 20),
              _TournamentCard(tournament: selectedTournament),
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

    return Center(
      child: ConstrainedBox(
        constraints : BoxConstraints(maxWidth: 520),
        child: Card(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.primary, width: 1.5)),
          child: Padding(
            padding : EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AppAssets.logoForTheme(context), height: 80),
                SizedBox(height: 16),
                Text(tournament.name, style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                SizedBox(height: 8),
                Row(children: [Icon(Icons.location_on_outlined, color: AppColors.hint, size: 16), SizedBox(width: 4), Expanded(child: Text(tournament.place, style: TextStyle(color: AppColors.onSurface)))]),
                SizedBox(height: 6),
                Row(children: [Icon(Icons.calendar_today_outlined, color: AppColors.hint, size: 16), SizedBox(width: 4), Text(dateText, style: TextStyle(color: AppColors.onSurface))]),
                SizedBox(height: 8),
                Container(
                  padding : EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: tournament.isActive ? AppColors.success.withOpacity(0.2) : AppColors.hint.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(tournament.isActive ? 'Activo' : 'Inactivo', style: TextStyle(color: tournament.isActive ? AppColors.success : AppColors.hint, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
