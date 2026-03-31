import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/player_model.dart';
import '../../providers/team_provider.dart';
import '../../repositories/player_repository.dart';
import '../../widgets/scaffold_with_menu.dart';

class AddPlayerScreen extends ConsumerStatefulWidget {
  final int teamId;
  const AddPlayerScreen({super.key, required this.teamId});
  @override
  ConsumerState<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends ConsumerState<AddPlayerScreen> {
  final _dniCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();

  PlayerModel? _found;
  bool _searched = false;
  bool _notFound = false;

  String _normalizeDni(String v) => v.trim().toUpperCase();
  bool _isValidDni(String v) => RegExp(r'^[0-9]{8}[A-Z]$').hasMatch(v);
  bool _isValidNumber(int v) => v >= 1 && v <= 99;

  void _setDniText(String v) {
    _dniCtrl.value = TextEditingValue(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
    );
  }

  Future<void> _search() async {
    if (_dniCtrl.text.isEmpty) return;
    final dni = _normalizeDni(_dniCtrl.text);
    _setDniText(dni);
    if (!_isValidDni(dni)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DNI inválido (ej: 12345678A)'), backgroundColor: AppColors.error),
        );
      }
      return;
    }
    try {
      final player = await PlayerRepository().searchByDni(dni);
      setState(() { _found = player; _searched = true; _notFound = player == null; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  Future<void> _submit() async {
    final number = int.tryParse(_numberCtrl.text);
    if (number == null || !_isValidNumber(number)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dorsal inválido (1-99)'), backgroundColor: AppColors.error));
      return;
    }
    final dni = _normalizeDni(_dniCtrl.text);
    _setDniText(dni);
    if (!_isValidDni(dni)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DNI inválido (ej: 12345678A)'), backgroundColor: AppColors.error));
      return;
    }
    try {
      await PlayerRepository().register(
        dni: dni,
        name: _notFound ? _nameCtrl.text.trim() : null,
        teamId: widget.teamId,
        number: number,
      );
      ref.invalidate(teamPlayersProvider(widget.teamId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithMenu(
      title: 'Añadir Jugador',
      body: SingleChildScrollView(
        padding : EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _field(
                    _dniCtrl,
                    'DNI del jugador',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]')),
                      _UpperCaseTextFormatter(),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                  child: Text('Buscar'),
                ),
              ],
            ),
            if (_searched) ...[
              SizedBox(height: 16),
              if (_found != null)
                Card(
                  color: AppColors.surfaceAlt,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppColors.success)),
                  child: ListTile(
                    leading: Icon(Icons.person_outline, color: AppColors.success),
                    title: Text(_found!.name, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                    subtitle: Text(_found!.dni, style: TextStyle(color: AppColors.hint)),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jugador no encontrado. Completa los datos:', style: TextStyle(color: AppColors.hint)),
                    SizedBox(height: 10),
                    _field(_nameCtrl, 'Nombre del jugador'),
                    SizedBox(height: 10),
                    TextFormField(
                      initialValue: _dniCtrl.text,
                      readOnly: true,
                      style: TextStyle(color: AppColors.hint),
                      decoration: _deco('DNI (fijo)'),
                    ),
                  ],
                ),
              SizedBox(height: 14),
              _field(_numberCtrl, 'Dorsal *', keyboardType: TextInputType.number),
              SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                  child: Text('Añadir jugador', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) => TextFormField(
    controller: ctrl, keyboardType: keyboardType,
    inputFormatters: inputFormatters ?? (ctrl == _numberCtrl ? [FilteringTextInputFormatter.digitsOnly] : null),
    style: TextStyle(color: AppColors.onSurface),
    decoration: _deco(label),
  );

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label, labelStyle: TextStyle(color: AppColors.hint),
    filled: true, fillColor: AppColors.surfaceAlt,
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
