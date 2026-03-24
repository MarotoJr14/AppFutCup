import 'package:flutter/material.dart';
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

  Future<void> _search() async {
    if (_dniCtrl.text.isEmpty) return;
    try {
      final player = await PlayerRepository().searchByDni(_dniCtrl.text.trim());
      setState(() { _found = player; _searched = true; _notFound = player == null; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  Future<void> _submit() async {
    final number = int.tryParse(_numberCtrl.text);
    if (number == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dorsal inválido'), backgroundColor: AppColors.error));
      return;
    }
    try {
      await PlayerRepository().register(
        dni: _dniCtrl.text.trim(),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _field(_dniCtrl, 'DNI del jugador')),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                  child: const Text('Buscar'),
                ),
              ],
            ),
            if (_searched) ...[
              const SizedBox(height: 16),
              if (_found != null)
                Card(
                  color: AppColors.surfaceAlt,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.success)),
                  child: ListTile(
                    leading: const Icon(Icons.person_outline, color: AppColors.success),
                    title: Text(_found!.name, style: const TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                    subtitle: Text(_found!.dni, style: const TextStyle(color: AppColors.hint)),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jugador no encontrado. Completa los datos:', style: TextStyle(color: AppColors.hint)),
                    const SizedBox(height: 10),
                    _field(_nameCtrl, 'Nombre del jugador'),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: _dniCtrl.text,
                      readOnly: true,
                      style: const TextStyle(color: AppColors.hint),
                      decoration: _deco('DNI (fijo)'),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              _field(_numberCtrl, 'Dorsal *', keyboardType: TextInputType.number),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                  child: const Text('Añadir jugador', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {TextInputType? keyboardType}) => TextFormField(
    controller: ctrl, keyboardType: keyboardType,
    style: const TextStyle(color: AppColors.onSurface),
    decoration: _deco(label),
  );

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label, labelStyle: const TextStyle(color: AppColors.hint),
    filled: true, fillColor: AppColors.surfaceAlt,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
  );
}
