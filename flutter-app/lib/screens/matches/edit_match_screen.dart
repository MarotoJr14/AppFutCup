import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/match_provider.dart';
import '../../providers/team_provider.dart';
import '../../repositories/match_repository.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';

class EditMatchScreen extends ConsumerStatefulWidget {
  final int matchId;
  const EditMatchScreen({super.key, required this.matchId});
  @override
  ConsumerState<EditMatchScreen> createState() => _EditMatchScreenState();
}

class _EditMatchScreenState extends ConsumerState<EditMatchScreen> {
  int? _homeId, _awayId;
  String? _field, _status;
  DateTime? _datetime;
  bool _loaded = false;

  final _statuses = ['Pending', 'Playing', 'Finished'];
  final _statusLabels = {'Pending': 'Pendiente', 'Playing': 'En juego', 'Finished': 'Finalizado'};

  Future<void> _save() async {
    try {
      final data = <String, dynamic>{};
      if (_homeId != null) data['team_home_id'] = _homeId;
      if (_awayId != null) data['team_away_id'] = _awayId;
      if (_field != null && _field!.isNotEmpty) data['field'] = _field;
      if (_status != null) data['status'] = _status;
      if (_datetime != null) data['datetime'] = _datetime!.toIso8601String();
      await MatchRepository().update(widget.matchId, data);
      ref.invalidate(matchDetailProvider(widget.matchId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    return matchAsync.when(
      loading: () => const ScaffoldWithMenu(title: 'Editar Partido', body: LoadingWidget()),
      error: (e, _) => ScaffoldWithMenu(title: 'Editar Partido', body: Center(child: Text(e.toString(), style: const TextStyle(color: AppColors.error)))),
      data: (match) {
        if (!_loaded) {
          _homeId = match.teamHomeId; _awayId = match.teamAwayId;
          _field = match.field; _status = match.status;
          _datetime = match.matchDatetime; _loaded = true;
        }
        final teamsAsync = ref.watch(teamsProvider(match.tournamentId));
        final teams = teamsAsync.valueOrNull ?? [];

        return ScaffoldWithMenu(
          title: 'Editar Partido',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _dropTeam('Equipo local', _homeId, teams, (v) => setState(() => _homeId = v?.id)),
                const SizedBox(height: 14),
                _dropTeam('Equipo visitante', _awayId, teams, (v) => setState(() => _awayId = v?.id)),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: _field,
                  style: const TextStyle(color: AppColors.onSurface),
                  decoration: _deco('Campo'),
                  onChanged: (v) => _field = v,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _status,
                  dropdownColor: AppColors.surfaceAlt,
                  style: const TextStyle(color: AppColors.onSurface),
                  decoration: _deco('Estado'),
                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(_statusLabels[s]!))).toList(),
                  onChanged: (v) => setState(() => _status = v),
                ),
                const SizedBox(height: 14),
                ListTile(
                  tileColor: AppColors.surfaceAlt,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  title: Text(_datetime != null ? _fmtDt(_datetime!) : 'Fecha y hora', style: TextStyle(color: _datetime != null ? AppColors.onSurface : AppColors.hint)),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _datetime ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
                    if (d == null) return;
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_datetime ?? DateTime.now()));
                    if (t == null) return;
                    setState(() => _datetime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                    child: const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dropTeam(String label, int? value, List<dynamic> teams, Function(dynamic) onChange) {
    final teamModel = (value != null && teams.isNotEmpty)
        ? teams.firstWhere((t) => t.id == value, orElse: () => null)
        : null;

    return DropdownButtonFormField<Object?>(
      value: teamModel,
      dropdownColor: AppColors.surfaceAlt,
      style: const TextStyle(color: AppColors.onSurface),
      decoration: _deco(label),
      items: <DropdownMenuItem<Object?>>[
        const DropdownMenuItem<Object?>(
          value: null,
          child: Text('Sin asignar', style: TextStyle(color: AppColors.hint)),
        ),
        ...teams.map<DropdownMenuItem<Object?>>(
              (t) => DropdownMenuItem<Object?>(value: t, child: Text(t.name)),
        ),
      ],
      onChanged: onChange,
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label, labelStyle: const TextStyle(color: AppColors.hint),
    filled: true, fillColor: AppColors.surfaceAlt,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
  );

  String _fmtDt(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}
