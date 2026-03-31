import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/player_provider.dart';
import '../../providers/team_provider.dart' show teamDetailProvider, teamPlayersProvider;
import '../../repositories/player_repository.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/scaffold_with_menu.dart';

class EditPlayerScreen extends ConsumerStatefulWidget {
  final int playerId;
  final int tournamentId;
  final int teamId;

  const EditPlayerScreen({
    super.key,
    required this.playerId,
    required this.tournamentId,
    required this.teamId,
  });

  @override
  ConsumerState<EditPlayerScreen> createState() => _EditPlayerScreenState();
}

class _EditPlayerScreenState extends ConsumerState<EditPlayerScreen> {
  final _nameCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loaded = false;

  String _normalizeDni(String v) => v.trim().toUpperCase();
  bool _isValidDni(String v) => RegExp(r'^[0-9]{8}[A-Z]$').hasMatch(v);
  bool _isValidNumber(int v) => v >= 1 && v <= 99;

  Future<void> _submit({required int ptId}) async {
    if (!_formKey.currentState!.validate()) return;

    final number = int.tryParse(_numberCtrl.text.trim());
    if (number == null || !_isValidNumber(number)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dorsal inválido (1-99)'), backgroundColor: AppColors.error),
      );
      return;
    }

    final dni = _normalizeDni(_dniCtrl.text);
    _dniCtrl.value = TextEditingValue(text: dni, selection: TextSelection.collapsed(offset: dni.length));
    if (!_isValidDni(dni)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DNI inválido (ej: 12345678A)'), backgroundColor: AppColors.error),
      );
      return;
    }

    try {
      await PlayerRepository().update(
        widget.playerId,
        name: _nameCtrl.text.trim(),
        dni: dni,
      );
      await PlayerRepository().updatePlayerTeam(ptId, number: number);

      ref.invalidate(playerDetailProvider(widget.playerId));
      ref.invalidate(playerTeamProvider(PlayerTeamParams(widget.teamId, widget.playerId)));
      ref.invalidate(teamPlayersProvider(widget.teamId));
      ref.invalidate(playerStatsProvider(PlayerStatsParams(widget.playerId, widget.tournamentId)));

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dniCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerAsync = ref.watch(playerDetailProvider(widget.playerId));
    final teamAsync = ref.watch(teamDetailProvider(widget.teamId));
    final ptAsync = ref.watch(playerTeamProvider(PlayerTeamParams(widget.teamId, widget.playerId)));

    if (playerAsync.isLoading || teamAsync.isLoading || ptAsync.isLoading) {
      return ScaffoldWithMenu(title: 'Editar información', body: LoadingWidget());
    }
    final playerErr = playerAsync.error;
    if (playerErr != null) {
      return ScaffoldWithMenu(title: 'Editar información', body: AppErrorWidget(message: playerErr.toString()));
    }
    final teamErr = teamAsync.error;
    if (teamErr != null) {
      return ScaffoldWithMenu(title: 'Editar información', body: AppErrorWidget(message: teamErr.toString()));
    }
    final ptErr = ptAsync.error;
    if (ptErr != null) {
      return ScaffoldWithMenu(title: 'Editar información', body: AppErrorWidget(message: ptErr.toString()));
    }

    final player = playerAsync.value!;
    final team = teamAsync.value!;
    final pt = ptAsync.value;

    if (pt == null) {
      return ScaffoldWithMenu(
        title: 'Editar información',
        body: AppErrorWidget(message: 'No se encontró la relación jugador-equipo.'),
      );
    }

    if (!_loaded) {
      _nameCtrl.text = player.name;
      _dniCtrl.text = player.dni;
      _numberCtrl.text = pt.number.toString();
      _loaded = true;
    }

    return ScaffoldWithMenu(
      title: 'Editar información',
      body: SingleChildScrollView(
        padding : EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: team.name,
                readOnly: true,
                style: TextStyle(color: AppColors.hint),
                decoration: _deco('Equipo (fijo)'),
              ),
              SizedBox(height: 14),
              _field(_nameCtrl, 'Nombre del jugador *', validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null),
              SizedBox(height: 14),
              _field(
                _dniCtrl,
                'DNI del jugador *',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]')),
                  _UpperCaseTextFormatter(),
                ],
                validator: (v) {
                  final s = (v ?? '').trim().toUpperCase();
                  if (s.isEmpty) return 'Campo requerido';
                  if (!RegExp(r'^[0-9]{8}[A-Z]$').hasMatch(s)) return 'DNI inválido (ej: 12345678A)';
                  return null;
                },
              ),
              SizedBox(height: 14),
              _field(
                _numberCtrl,
                'Dorsal *',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'Dorsal inválido';
                  if (n < 1 || n > 99) return 'Dorsal inválido (1-99)';
                  return null;
                },
              ),
              SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _submit(ptId: pt.id),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                  child: Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: AppColors.onSurface),
        validator: validator,
        decoration: _deco(label),
      );

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.hint),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary)),
      );
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
