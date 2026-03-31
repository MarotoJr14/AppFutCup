import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_top_bar.dart';
import 'side_menu.dart';
import 'app_footer.dart';

class ScaffoldWithMenu extends ConsumerStatefulWidget {
  final String title;
  final Widget body;
  final Widget? fab;
  final bool backToHomeOnSystemBack;

  ScaffoldWithMenu({
    super.key,
    required this.title,
    required this.body,
    this.fab,
    this.backToHomeOnSystemBack = false,
  });

  @override
  ConsumerState<ScaffoldWithMenu> createState() => _ScaffoldWithMenuState();
}

class _ScaffoldWithMenuState extends ConsumerState<ScaffoldWithMenu> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        title: widget.title,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
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

    if (!widget.backToHomeOnSystemBack) return scaffold;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final goRouter = GoRouter.of(context);
        final path = goRouter.routeInformationProvider.value.uri.path;
        if (path != '/home') {
          context.go('/home');
        }
      },
      child: scaffold,
    );
  }
}
