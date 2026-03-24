import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onClose;

  const SideMenu({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(Icons.home_outlined, AppStrings.home, '/home'),
      _MenuItem(Icons.bookmark_outline, AppStrings.followTournaments, '/follow-tournaments'),
      _MenuItem(Icons.calendar_month_outlined, AppStrings.calendar, '/calendar'),
      _MenuItem(Icons.account_tree_outlined, AppStrings.bracket, '/bracket'),
      _MenuItem(Icons.groups_outlined, AppStrings.teams, '/teams'),
      _MenuItem(Icons.sports_soccer_outlined, AppStrings.scorers, '/scorers'),
    ];

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset('assets/images/futcup2026_logo.png', height: 70),
            ),
            const Divider(color: AppColors.divider),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) => ListTile(
                  leading: Icon(items[i].icon, color: AppColors.primary),
                  title: Text(items[i].label, style: const TextStyle(color: AppColors.onSurface)),
                  onTap: () {
                    onClose();
                    context.go(items[i].route);
                  },
                ),
              ),
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
