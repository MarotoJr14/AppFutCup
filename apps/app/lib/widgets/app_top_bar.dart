import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenuTap;

  const AppTopBar({
    super.key,
    required this.title,
    required this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final username = user?.username ?? '';
    final role = user?.role ?? '';
    final initial = username.trim().isNotEmpty ? username.trim()[0].toUpperCase() : '?';

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: AppColors.primary),
        onPressed: onMenuTap,
      ),
      title: Text(
        title,
        style: TextStyle(color: AppColors.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      actions: [
        // Tappable user info → profile screen
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Padding(
            padding : EdgeInsets.only(right: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initial,
                    style: TextStyle(color: AppColors.onPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 6),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(username, style: TextStyle(color: AppColors.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(role, style: TextStyle(color: AppColors.primary, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Logout button
        IconButton(
          icon: Icon(Icons.logout, color: AppColors.hint, size: 20),
          tooltip: 'Cerrar sesión',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: Text('Cerrar sesión', style: TextStyle(color: AppColors.onSurface)),
                content: Text('¿Quieres cerrar la sesión?', style: TextStyle(color: AppColors.hint)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancelar', style: TextStyle(color: AppColors.hint)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: Text('Cerrar sesión', style: TextStyle(color: AppColors.onPrimary)),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              await ref.read(authProvider.notifier).logout();
            }
          },
        ),
        SizedBox(width: 4),
      ],
    );
  }
}
