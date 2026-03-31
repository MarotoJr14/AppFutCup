import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/team_provider.dart';
import '../../repositories/team_repository.dart';
import '../../widgets/scaffold_with_menu.dart';

class AddTeamScreen extends ConsumerStatefulWidget {
  final int tournamentId;
  const AddTeamScreen({super.key, required this.tournamentId});
  @override
  ConsumerState<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends ConsumerState<AddTeamScreen> {
  final _nameCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await TeamRepository().create(name: _nameCtrl.text.trim(), group: _groupCtrl.text.trim(), kitColor: _colorCtrl.text.trim(), tournamentId: widget.tournamentId);
      ref.invalidate(teamsProvider(widget.tournamentId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error, duration: const Duration(seconds: 3)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithMenu(
      title: 'Añadir Equipo',
      body: SingleChildScrollView(
        padding : EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_nameCtrl, 'Nombre del equipo *', validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null),
              SizedBox(height: 14),
              _field(_groupCtrl, 'Grupos de clase *', validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null),
              SizedBox(height: 14),
              _field(_colorCtrl, 'Color de equipación *', validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null),
              SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                  child: Text('Crear equipo', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {String? Function(String?)? validator}) => TextFormField(
    controller: ctrl,
    style: TextStyle(color: AppColors.onSurface),
    validator: validator,
    decoration: InputDecoration(
      labelText: label, labelStyle: TextStyle(color: AppColors.hint),
      filled: true, fillColor: AppColors.surfaceAlt,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary)),
    ),
  );
}
