import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/team_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../repositories/team_repository.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/scaffold_with_menu.dart';

class EditTeamScreen extends ConsumerStatefulWidget {
  final int teamId;
  const EditTeamScreen({super.key, required this.teamId});

  @override
  ConsumerState<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends ConsumerState<EditTeamScreen> {
  final _nameCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loaded = false;

  Future<void> _submit(int tournamentId) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await TeamRepository().update(
        widget.teamId,
        name: _nameCtrl.text.trim(),
        group: _groupCtrl.text.trim(),
        kitColor: _colorCtrl.text.trim(),
      );
      ref.invalidate(teamDetailProvider(widget.teamId));
      ref.invalidate(teamsProvider(tournamentId));
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
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamDetailProvider(widget.teamId));
    final allTournaments = ref.watch(allTournamentsProvider).valueOrNull ?? [];

    return teamAsync.when(
      loading: () => ScaffoldWithMenu(title: 'Editar información', body: LoadingWidget()),
      error: (e, _) => ScaffoldWithMenu(title: 'Editar información', body: AppErrorWidget(message: e.toString())),
      data: (team) {
        if (!_loaded) {
          _nameCtrl.text = team.name;
          _groupCtrl.text = team.group;
          _colorCtrl.text = team.kitColor;
          _loaded = true;
        }
        var tournamentName = '—';
        for (final t in allTournaments) {
          if (t.id == team.tournamentId) {
            tournamentName = t.name;
            break;
          }
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
                    initialValue: tournamentName,
                    readOnly: true,
                    style: TextStyle(color: AppColors.hint),
                    decoration: _deco('Torneo (fijo)'),
                  ),
                  SizedBox(height: 14),
                  _field(_nameCtrl, 'Nombre del equipo *', validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null),
                  SizedBox(height: 14),
                  _field(_groupCtrl, 'Grupos de clase *', validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null),
                  SizedBox(height: 14),
                  _field(_colorCtrl, 'Color de equipación *', validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null),
                  SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _submit(team.tournamentId),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                      child: Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController ctrl, String label, {String? Function(String?)? validator}) => TextFormField(
        controller: ctrl,
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
