import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenuTap;
  final String username;
  final String role;

  const AppTopBar({
    super.key, required this.title, required this.onMenuTap,
    required this.username, required this.role,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.primary),
        onPressed: onMenuTap,
      ),
      title: Text(title, style: const TextStyle(color: AppColors.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              const CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Icon(Icons.person, size: 16, color: AppColors.onPrimary)),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(username, style: const TextStyle(color: AppColors.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(role, style: const TextStyle(color: AppColors.primary, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
