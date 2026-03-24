import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'app_top_bar.dart';
import 'side_menu.dart';
import 'app_footer.dart';

class ScaffoldWithMenu extends ConsumerStatefulWidget {
  final String title;
  final Widget body;
  final Widget? fab;

  const ScaffoldWithMenu({super.key, required this.title, required this.body, this.fab});

  @override
  ConsumerState<ScaffoldWithMenu> createState() => _ScaffoldWithMenuState();
}

class _ScaffoldWithMenuState extends ConsumerState<ScaffoldWithMenu> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.valueOrNull;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF121212),
      appBar: AppTopBar(
        title: widget.title,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        username: user?.username ?? '',
        role: user?.role ?? '',
      ),
      drawer: SideMenu(onClose: () => _scaffoldKey.currentState?.closeDrawer()),
      floatingActionButton: widget.fab,
      body: Column(
        children: [
          Expanded(child: widget.body),
          const AppFooter(),
        ],
      ),
    );
  }
}
