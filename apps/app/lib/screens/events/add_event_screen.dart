import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/match_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/player_provider.dart';
import '../../repositories/event_repository.dart';
import '../../models/event_model.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';

class AddEventScreen extends ConsumerStatefulWidget {
  final int matchId;
  const AddEventScreen({super.key, required this.matchId});
  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  int? _teamId, _playerId;
  String? _eventType;
  final _minuteCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _eventTypes = ['Goal', 'Owngoal', 'Yellow', 'YellowX2', 'Red'];
  final _eventLabels = {'Goal': AppStrings.goal, 'Owngoal': AppStrings.ownGoal, 'Yellow': AppStrings.yellowCard, 'YellowX2': AppStrings.secondYellow, 'Red': AppStrings.redCard};

  String? _validatePlayerEventRules(List<EventModel> events, int playerId, String eventType) {
    final playerEvents = events.where((e) => e.playerId == playerId).toList();
    final expelled = playerEvents.any((e) => e.eventType == 'YellowX2' || e.eventType == 'Red');
    if (expelled) return 'El jugador está expulsado en el partido.';

    final yellowCount = playerEvents.where((e) => e.eventType == 'Yellow').length;

    if (eventType == 'YellowX2') {
      if (yellowCount == 0) {
        return 'El jugador no puede recibir la segunda amarilla porque no ha recibido una tarjeta amarilla aún.';
      }
    }

    if (eventType == 'Yellow') {
      if (yellowCount >= 1) {
        return 'El jugador ya tiene una tarjeta amarilla y debe seleccionar "Doble amarilla".';
      }
    }

    return null;
  }

  Future<void> _submit() async {
    if (_teamId == null || _playerId == null || _eventType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rellena todos los campos obligatorios'), backgroundColor: AppColors.error));
      return;
    }

    final eventsState = ref.read(matchEventsProvider(widget.matchId));
    final events = eventsState.valueOrNull;
    if (events == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cargando eventos del partido...'), backgroundColor: AppColors.error));
      }
      return;
    }

    final validationError = _validatePlayerEventRules(events, _playerId!, _eventType!);
    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError), backgroundColor: AppColors.error));
      }
      return;
    }

    try {
      await EventRepository().create({
        'match_id': widget.matchId, 'team_id': _teamId, 'player_id': _playerId,
        'event_type': _eventType,
        if (_minuteCtrl.text.isNotEmpty) 'minute': int.tryParse(_minuteCtrl.text),
        if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text,
      });
      ref.invalidate(matchEventsProvider(widget.matchId));
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
      loading: () => ScaffoldWithMenu(title: 'Añadir Evento', body: LoadingWidget()),
      error: (e, _) => ScaffoldWithMenu(title: 'Añadir Evento', body: Center(child: Text(e.toString()))),
      data: (match) {
        if (match.status == 'Finished') {
          return ScaffoldWithMenu(
            title: 'Añadir Evento',
            body: Center(
              child: Text(
                'No se pueden añadir eventos a un partido finalizado',
                style: TextStyle(color: AppColors.hint),
              ),
            ),
          );
        }
        if (match.status != 'Playing') {
          return ScaffoldWithMenu(
            title: 'Añadir Evento',
            body: Center(
              child: Text(
                'Pon el partido en juego para añadir eventos',
                style: TextStyle(color: AppColors.hint),
              ),
            ),
          );
        }
        final teamIds = [if (match.teamHomeId != null) match.teamHomeId!, if (match.teamAwayId != null) match.teamAwayId!];
        if (teamIds.length != 2) {
          return ScaffoldWithMenu(
            title: 'Añadir Evento',
            body: Center(
              child: Text(
                'El partido necesita tener ambos equipos asignados',
                style: TextStyle(color: AppColors.hint),
              ),
            ),
          );
        }
        final teamsAsync = ref.watch(teamsProvider(match.tournamentId));
        final allTeams = teamsAsync.valueOrNull ?? [];
        final matchTeams = allTeams.where((t) => teamIds.contains(t.id)).toList();

        final playersAsync = _teamId != null ? ref.watch(teamPlayersProvider(_teamId!)) : null;
        final players = playersAsync?.valueOrNull ?? [];

        return ScaffoldWithMenu(
          title: 'Añadir Evento',
          body: SingleChildScrollView(
            padding : EdgeInsets.all(20),
            child: Column(
              children: [
                DropdownButtonFormField(
                  value: matchTeams.isNotEmpty && _teamId != null ? matchTeams.firstWhere((t) => t.id == _teamId, orElse: () => matchTeams.first) : null,
                  dropdownColor: AppColors.surfaceAlt,
                  style: TextStyle(color: AppColors.onSurface),
                  decoration: _deco('Equipo *'),
                  hint: Text('Selecciona equipo', style: TextStyle(color: AppColors.hint)),
                  items: matchTeams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                  onChanged: (t) => setState(() { _teamId = t?.id; _playerId = null; }),
                ),
                SizedBox(height: 14),
                DropdownButtonFormField(
                  value: players.isNotEmpty && _playerId != null ? players.firstWhere((p) => p.playerId == _playerId, orElse: () => players.first) : null,
                  dropdownColor: AppColors.surfaceAlt,
                  style: TextStyle(color: AppColors.onSurface),
                  decoration: _deco('Jugador *'),
                  hint: Text('Selecciona jugador', style: TextStyle(color: AppColors.hint)),
                  items: players.map((p) {
                    final playerAsync = ref.watch(playerDetailProvider(p.playerId));
                    final name = playerAsync.valueOrNull?.name ?? 'Jugador ${p.playerId}';
                    return DropdownMenuItem(value: p, child: Text('#${p.number} – $name'));
                  }).toList(),
                  onChanged: (p) => setState(() => _playerId = p?.playerId),
                ),
                SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _eventType,
                  dropdownColor: AppColors.surfaceAlt,
                  style: TextStyle(color: AppColors.onSurface),
                  decoration: _deco('Tipo de evento *'),
                  hint: Text('Selecciona tipo', style: TextStyle(color: AppColors.hint)),
                  items: _eventTypes.map((e) => DropdownMenuItem(value: e, child: Text(_eventLabels[e]!))).toList(),
                  onChanged: (v) => setState(() => _eventType = v),
                ),
                SizedBox(height: 14),
                TextFormField(controller: _minuteCtrl, keyboardType: TextInputType.number, style: TextStyle(color: AppColors.onSurface), decoration: _deco('Minuto (opcional)')),
                SizedBox(height: 14),
                TextFormField(controller: _descCtrl, style: TextStyle(color: AppColors.onSurface), decoration: _deco('Descripción (opcional)'), maxLines: 2),
                SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                    child: Text('Crear evento', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label, labelStyle: TextStyle(color: AppColors.hint),
    filled: true, fillColor: AppColors.surfaceAlt,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
  );
}
