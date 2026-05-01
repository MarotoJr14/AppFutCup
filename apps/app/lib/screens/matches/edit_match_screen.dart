import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../models/match_model.dart';
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
  int? _origHomeId, _origAwayId;
  String? _field, _status;
  DateTime? _datetime;
  String? _origField, _origStatus;
  DateTime? _origDatetime;
  int? _tournamentId;
  String? _round;
  bool _loaded = false;
  final _dtFocus = FocusNode();

  final _statuses = ['Pending', 'Playing', 'Penalties', 'Finished'];
  final _statusLabels = {'Pending': 'Pendiente', 'Playing': 'En juego', 'Penalties': 'Penaltis', 'Finished': 'Finalizado'};

  @override
  void dispose() {
    _dtFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      if (_tournamentId != null && _round != null) {
        final home = _homeId;
        final away = _awayId;
        final assigningHome = (_origHomeId == null && home != null);
        final assigningAway = (_origAwayId == null && away != null);

        if ((assigningHome || assigningAway) && home != null && away != null && home == away) {
          throw ApiException('Un equipo no puede estar como local y visitante en el mismo partido.');
        }

        // Validación: en una misma ronda de un mismo torneo, un equipo solo puede estar en un partido.
        if (assigningHome || assigningAway) {
          final matches = await ref.read(matchesProvider(MatchesQuery(tournamentId: _tournamentId!)).future);
          final used = <int, int>{}; // teamId -> matchId (misma ronda)
          for (final m in matches) {
            if (m.id == widget.matchId) continue;
            if (m.round != _round) continue;
            final h = m.teamHomeId;
            final a = m.teamAwayId;
            if (h != null) used.putIfAbsent(h, () => m.id);
            if (a != null) used.putIfAbsent(a, () => m.id);
          }

          String teamName(int id) {
            final teams = ref.read(teamsProvider(_tournamentId!)).valueOrNull ?? const [];
            for (final t in teams) {
              if (t.id == id) return t.name;
            }
            return '#$id';
          }

          final roundLabel = _roundLabel(_round!);
          if (assigningHome) {
            final homeId = home!;
            if (used.containsKey(homeId)) {
              throw ApiException('El equipo "${teamName(homeId)}" ya está asignado al partido #${used[homeId]} en $roundLabel.');
            }
          }
          if (assigningAway) {
            final awayId = away!;
            if (used.containsKey(awayId)) {
              throw ApiException('El equipo "${teamName(awayId)}" ya está asignado al partido #${used[awayId]} en $roundLabel.');
            }
          }

          // Validación: si un equipo ha perdido en una ronda, no puede aparecer en rondas siguientes.
          final currIdx = _roundIndex(_round!);
          if (currIdx > 0) {
            final eliminated = <int, MatchModel>{}; // teamId -> match donde perdió
            for (final m in matches) {
              if (m.id == widget.matchId) continue;
              final rIdx = _roundIndex(m.round);
              if (rIdx < 0 || rIdx >= currIdx) continue;
              final loserId = _loserTeamId(m);
              if (loserId != null) eliminated.putIfAbsent(loserId, () => m);
            }

            if (assigningHome) {
              final homeId = home!;
              final lostMatch = eliminated[homeId];
              if (lostMatch != null) {
                throw ApiException(
                  'El equipo "${teamName(homeId)}" fue eliminado en ${_roundLabel(lostMatch.round)} (partido #${lostMatch.id}) y no puede jugar en rondas posteriores.',
                );
              }
            }
            if (assigningAway) {
              final awayId = away!;
              final lostMatch = eliminated[awayId];
              if (lostMatch != null) {
                throw ApiException(
                  'El equipo "${teamName(awayId)}" fue eliminado en ${_roundLabel(lostMatch.round)} (partido #${lostMatch.id}) y no puede jugar en rondas posteriores.',
                );
              }
            }
          }
        }
      }

      final data = <String, dynamic>{};
      if (_origHomeId == null && _homeId != null) data['team_home_id'] = _homeId;
      if (_origAwayId == null && _awayId != null) data['team_away_id'] = _awayId;
      if (_field != null && _field!.isNotEmpty && _field != _origField) data['field'] = _field;
      if (_status != null && _status != _origStatus) data['status'] = _status;
      if (_datetime != null && _origDatetime != null && !_datetime!.isAtSameMomentAs(_origDatetime!)) {
        data['datetime'] = _datetime!.toIso8601String();
      }
      if (_datetime != null && _origDatetime == null) data['datetime'] = _datetime!.toIso8601String();
      if (data.isEmpty) {
        if (mounted) context.pop();
        return;
      }
      await MatchRepository().update(widget.matchId, data);
      ref.invalidate(matchDetailProvider(widget.matchId));
      if (mounted) context.pop();
    } catch (e) {
      final msg = (e is ApiException) ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error, duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _pickDateTime({required bool disabled}) async {
    if (disabled) return;
    final d = await showDatePicker(context: context, initialDate: _datetime ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_datetime ?? DateTime.now()));
    if (t == null) return;
    setState(() => _datetime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    return matchAsync.when(
      loading: () => ScaffoldWithMenu(title: 'Editar Partido', body: LoadingWidget()),
      error: (e, _) => ScaffoldWithMenu(title: 'Editar Partido', body: Center(child: Text(e.toString(), style: TextStyle(color: AppColors.error)))),
      data: (match) {
        if (!_loaded) {
          _homeId = match.teamHomeId; _awayId = match.teamAwayId;
          _origHomeId = match.teamHomeId; _origAwayId = match.teamAwayId;
          _field = match.field; _status = match.status;
          _datetime = match.matchDatetime;
          _origField = match.field; _origStatus = match.status; _origDatetime = match.matchDatetime;
          _tournamentId = match.tournamentId;
          _round = match.round;
          _loaded = true;
        }
        final teamsAsync = ref.watch(teamsProvider(match.tournamentId));
        final teams = teamsAsync.valueOrNull ?? [];

        final isPlaying = match.status == 'Playing';
        final isPenalties = match.status == 'Penalties';
        final isFinished = match.status == 'Finished';
        final lockInfo = isPlaying || isPenalties || isFinished;

        final homeLocked = lockInfo || match.teamHomeId != null;
        final awayLocked = lockInfo || match.teamAwayId != null;
        final isDraw = (match.goalsHome ?? 0) == (match.goalsAway ?? 0);
        final statusOptions = match.status == 'Pending'
            ? ['Pending', 'Playing']
            : (match.status == 'Playing'
                ? (isDraw ? ['Playing', 'Penalties'] : ['Playing', 'Finished'])
                : (match.status == 'Penalties' ? ['Penalties', 'Finished'] : ['Finished']));

        return ScaffoldWithMenu(
          title: 'Editar Partido',
          body: SingleChildScrollView(
            padding : EdgeInsets.all(20),
            child: Column(
              children: [
                _dropTeam('Equipo local', _homeId, teams, (v) => setState(() => _homeId = v?.id), disabled: homeLocked),
                SizedBox(height: 14),
                _dropTeam('Equipo visitante', _awayId, teams, (v) => setState(() => _awayId = v?.id), disabled: awayLocked),
                SizedBox(height: 14),
                TextFormField(
                  initialValue: _field,
                  style: TextStyle(color: AppColors.onSurface),
                  decoration: _deco('Campo'),
                  enabled: !lockInfo,
                  onChanged: (v) => _field = v,
                ),
                SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _status,
                  dropdownColor: AppColors.surfaceAlt,
                  style: TextStyle(color: AppColors.onSurface),
                  decoration: _deco('Estado'),
                  items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(_statusLabels[s]!))).toList(),
                  onChanged: isFinished ? null : (v) => setState(() => _status = v),
                ),
                SizedBox(height: 14),
                Focus(
                  focusNode: _dtFocus,
                  child: Builder(
                    builder: (context) {
                      final hasFocus = Focus.of(context).hasFocus;
                      final valueText = _datetime != null ? _fmtDt(_datetime!) : 'Selecciona fecha y hora';
                      final valueColor = _datetime != null ? AppColors.onSurface : AppColors.hint;

                      return InkWell(
                        onTap: lockInfo
                            ? null
                            : () async {
                                _dtFocus.requestFocus();
                                await _pickDateTime(disabled: lockInfo);
                                if (mounted) _dtFocus.unfocus();
                              },
                        child: InputDecorator(
                          isFocused: hasFocus,
                          decoration: _deco('Fecha y hora').copyWith(
                            suffixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
                          ),
                          child: Text(valueText, style: TextStyle(color: valueColor)),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: isFinished ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                    child: Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dropTeam(String label, int? value, List<dynamic> teams, Function(dynamic) onChange, {bool disabled = false}) {
    Object? teamModel;
    if (value != null) {
      for (final t in teams) {
        if (t.id == value) {
          teamModel = t;
          break;
        }
      }
    }

    return DropdownButtonFormField<Object?>(
      value: teamModel,
      dropdownColor: AppColors.surfaceAlt,
      style: TextStyle(color: AppColors.onSurface),
      decoration: _deco(label),
      items: <DropdownMenuItem<Object?>>[
        if (!disabled)
          DropdownMenuItem<Object?>(
            value: null,
            child: Text('Sin asignar', style: TextStyle(color: AppColors.hint)),
          ),
        ...teams.map<DropdownMenuItem<Object?>>(
              (t) => DropdownMenuItem<Object?>(value: t, child: Text(t.name)),
        ),
      ],
      onChanged: disabled ? null : onChange,
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label, labelStyle: TextStyle(color: AppColors.hint),
    filled: true, fillColor: AppColors.surfaceAlt,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary)),
    disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
  );

  String _fmtDt(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  String _roundLabel(String r) => const {
    'RoundOf16': AppStrings.roundOf16,
    'Quarterfinal': AppStrings.quarterfinal,
    'Semifinal': AppStrings.semifinal,
    'Final': AppStrings.finalRound,
  }[r] ?? r;

  int _roundIndex(String r) => const {
    'RoundOf16': 0,
    'Quarterfinal': 1,
    'Semifinal': 2,
    'Final': 3,
  }[r] ?? -1;

  int? _loserTeamId(MatchModel m) {
    if (m.status != 'Finished') return null;
    final homeId = m.teamHomeId;
    final awayId = m.teamAwayId;
    if (homeId == null || awayId == null) return null;
    final gh = m.goalsHome;
    final ga = m.goalsAway;
    if (gh == null || ga == null) return null;

    if (gh > ga) return awayId;
    if (ga > gh) return homeId;

    final ph = m.penHome;
    final pa = m.penAway;
    if (ph == null || pa == null) return null;
    if (ph > pa) return awayId;
    if (pa > ph) return homeId;
    return null;
  }
}
