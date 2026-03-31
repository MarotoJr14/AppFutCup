import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/theme_provider.dart';
import '../core/constants/app_assets.dart';

class SideMenu extends ConsumerWidget {
  final VoidCallback onClose;

  const SideMenu({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      _MenuItem(Icons.home_outlined, AppStrings.home, '/home'),
      _MenuItem(Icons.bookmark_outline, AppStrings.followTournaments, '/follow-tournaments'),
      _MenuItem(Icons.calendar_month_outlined, AppStrings.calendar, '/calendar'),
      _MenuItem(Icons.account_tree_outlined, AppStrings.bracket, '/bracket'),
      _MenuItem(Icons.groups_outlined, AppStrings.teams, '/teams'),
      _MenuItem(Icons.sports_soccer_outlined, AppStrings.scorers, '/scorers'),
    ];

    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode != ThemeMode.light;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding : EdgeInsets.all(20),
              child: Image.asset(AppAssets.logoForTheme(context), height: 70),
            ),
            Divider(color: AppColors.divider),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) => ListTile(
                  leading: Icon(items[i].icon, color: AppColors.primary),
                  title: Text(items[i].label, style: TextStyle(color: AppColors.onSurface)),
                  onTap: () {
                    onClose();
                    context.go(items[i].route);
                  },
                ),
              ),
            ),
            Divider(color: AppColors.divider),
            SwitchListTile.adaptive(
              value: !isDark,
              onChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v ? ThemeMode.light : ThemeMode.dark),
              title: Text('Tema claro', style: TextStyle(color: AppColors.onSurface)),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  _MenuItem(this.icon, this.label, this.route);
}
