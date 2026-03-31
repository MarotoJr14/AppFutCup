import '../../core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/tournament_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../repositories/tournament_repository.dart';
import '../../widgets/scaffold_with_menu.dart';
import '../../widgets/loading_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Edit username
  final _usernameCtrl = TextEditingController();
  bool _editingUsername = false;

  // Change password
  final _passCtrl    = TextEditingController();
  final _passNew1Ctrl = TextEditingController();
  final _passNew2Ctrl = TextEditingController();
  bool _editingPass  = false;
  bool _obscure0 = true, _obscure1 = true, _obscure2 = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _passNew1Ctrl.dispose();
    _passNew2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final newUsername = _usernameCtrl.text.trim();
    if (newUsername.isEmpty) return;
    try {
      await ref.read(authProvider.notifier).updateProfile(username: newUsername);
      setState(() => _editingUsername = false);
      if (mounted) _snack('Nombre de usuario actualizado', success: true);
    } catch (e) {
      if (mounted) _snack(e.toString());
    }
  }

  Future<void> _savePassword() async {
    final current = _passCtrl.text;
    final p1 = _passNew1Ctrl.text;
    final p2 = _passNew2Ctrl.text;
    if (current.isEmpty) { _snack('Introduce tu contraseña actual'); return; }
    if (p1 != p2) { _snack('Las contraseñas no coinciden'); return; }
    if (p1.length < 8) { _snack('Mínimo 8 caracteres'); return; }
    try {
      await ref.read(authProvider.notifier).updateProfile(password: p1, currentPassword: current);
      setState(() { _editingPass = false; _passCtrl.clear(); _passNew1Ctrl.clear(); _passNew2Ctrl.clear(); });
      if (mounted) _snack('Contraseña actualizada', success: true);
    } catch (e) {
      if (mounted) _snack(e.toString());
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    if (user == null) return ScaffoldWithMenu(title: 'Perfil', body: LoadingWidget());

    final allAsync      = ref.watch(allTournamentsProvider);
    final followedAsync = ref.watch(followedTournamentIdsProvider);

    return ScaffoldWithMenu(
      title: AppStrings.profile,
      body: SingleChildScrollView(
        padding : EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Avatar + basic info ───────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: TextStyle(color: AppColors.onPrimary, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(user.username, style: TextStyle(color: AppColors.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Container(
                    padding : EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(user.role, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(height: 4),
                  Text(user.email, style: TextStyle(color: AppColors.hint, fontSize: 13)),
                ],
              ),
            ),

            SizedBox(height: 28),

            // ── Change username ───────────────────────────────────────────────
            _sectionTitle('Nombre de usuario'),
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding : EdgeInsets.all(14),
                child: _editingUsername
                    ? Column(
                        children: [
                          _field(_usernameCtrl, 'Nuevo nombre de usuario', Icons.person_outline),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: OutlinedButton(
                                onPressed: () => setState(() => _editingUsername = false),
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.hint, side: BorderSide(color: AppColors.divider)),
                                child: Text('Cancelar'),
                              )),
                              SizedBox(width: 10),
                              Expanded(child: ElevatedButton(
                                onPressed: _saveUsername,
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                                child: Text('Guardar'),
                              )),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                          SizedBox(width: 10),
                          Expanded(child: Text(user.username, style: TextStyle(color: AppColors.onSurface, fontSize: 15))),
                          TextButton(
                            onPressed: () { _usernameCtrl.text = user.username; setState(() => _editingUsername = true); },
                            child: Text('Cambiar', style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
              ),
            ),

            SizedBox(height: 16),

            // ── Change password ───────────────────────────────────────────────
            _sectionTitle('Contraseña'),
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding : EdgeInsets.all(14),
                child: _editingPass
                    ? Column(
                        children: [
                          _field(_passCtrl, 'Contraseña actual', Icons.lock_outline,
                              obscure: _obscure0,
                              toggle: () => setState(() => _obscure0 = !_obscure0)),
                          SizedBox(height: 10),
                          _field(_passNew1Ctrl, 'Nueva contraseña', Icons.lock_outline,
                              obscure: _obscure1,
                              toggle: () => setState(() => _obscure1 = !_obscure1)),
                          SizedBox(height: 10),
                          _field(_passNew2Ctrl, 'Repetir contraseña', Icons.lock_outline,
                              obscure: _obscure2,
                              toggle: () => setState(() => _obscure2 = !_obscure2)),
                          SizedBox(height: 6),
                          Text(
                            '• Mín. 8 caracteres, 1 mayúscula, 1 número y 1 carácter especial',
                            style: TextStyle(color: AppColors.hint, fontSize: 11),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: OutlinedButton(
                                onPressed: () => setState(() => _editingPass = false),
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.hint, side: BorderSide(color: AppColors.divider)),
                                child: Text('Cancelar'),
                              )),
                              SizedBox(width: 10),
                              Expanded(child: ElevatedButton(
                                onPressed: _savePassword,
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
                                child: Text('Guardar'),
                              )),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                          SizedBox(width: 10),
                          Expanded(child: Text('••••••••', style: TextStyle(color: AppColors.onSurface, fontSize: 18, letterSpacing: 4))),
                          TextButton(
                            onPressed: () => setState(() => _editingPass = true),
                            child: Text('Cambiar', style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
              ),
            ),

            SizedBox(height: 28),

            // ── Followed tournaments ──────────────────────────────────────────
            _sectionTitle('Torneos que sigues'),
            allAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Text(e.toString(), style: TextStyle(color: AppColors.error)),
              data: (all) {
                final followedIds = followedAsync.valueOrNull ?? [];
                final followed = all.where((t) => followedIds.contains(t.id)).toList();
                if (followed.isEmpty) {
                  return Card(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No sigues ningún torneo todavía.', style: TextStyle(color: AppColors.hint)),
                    ),
                  );
                }
                return Column(
                  children: followed.map((t) => _TournamentTile(tournament: t)).toList(),
                );
              },
            ),

            SizedBox(height: 32),

            // ── Logout button ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.logout),
                label: Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding : EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool obscure = false, VoidCallback? toggle}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: AppColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.hint),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary)),
        suffixIcon: toggle != null
            ? IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.hint), onPressed: toggle)
            : null,
      ),
    );
  }
}

class _TournamentTile extends ConsumerWidget {
  final TournamentModel tournament;
  const _TournamentTile({required this.tournament});

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sameDay = tournament.dateIni.day == tournament.dateEnd.day &&
        tournament.dateIni.month == tournament.dateEnd.month &&
        tournament.dateIni.year == tournament.dateEnd.year;
    final dateStr = sameDay ? _fmt(tournament.dateIni) : '${_fmt(tournament.dateIni)} – ${_fmt(tournament.dateEnd)}';

    return Card(
      color: AppColors.surface,
      margin : EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading : CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.emoji_events, color: AppColors.onPrimary, size: 18),
        ),
        title: Text(tournament.name, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w500)),
        subtitle: Text(dateStr, style: TextStyle(color: AppColors.hint, fontSize: 12)),
        trailing: Container(
          padding : EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: tournament.isActive ? AppColors.success.withOpacity(0.15) : AppColors.hint.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tournament.isActive ? 'Activo' : 'Inactivo',
            style: TextStyle(color: tournament.isActive ? AppColors.success : AppColors.hint, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Dejar de seguir', style: TextStyle(color: AppColors.onSurface)),
              content: Text('¿Quieres dejar de seguir "${tournament.name}"?', style: TextStyle(color: AppColors.hint)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: AppColors.hint))),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: Text('Dejar de seguir', style: TextStyle(color: AppColors.onPrimary)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            try {
              await TournamentRepository().unfollow(tournament.id);
              ref.invalidate(followedTournamentIdsProvider);
            } catch (_) {}
          }
        },
      ),
    );
  }
}
